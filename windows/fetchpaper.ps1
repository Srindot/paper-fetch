param(
    [Parameter(Mandatory = $true, HelpMessage = "URL of the paper OR local PDF path")]
    [string]$InputStr
)

$ErrorActionPreference = "Stop"
$TempDir = Join-Path $PWD "temp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

$Url = $InputStr
$TempPdf = Join-Path $TempDir "temp.pdf"

# --- 1. LOCAL FILE BYPASS ---
if (Test-Path $InputStr -PathType Leaf) {
    Write-Host "Local file detected: $InputStr" -ForegroundColor Cyan

    $header = Get-Content $InputStr -TotalCount 1 -ErrorAction SilentlyContinue
    if ($header -notmatch "%PDF") {
        Write-Host "Error: The provided file is not a valid PDF." -ForegroundColor Red
        Remove-Item $TempDir -Recurse -Force
        exit 1
    }

    Copy-Item $InputStr -Destination $TempPdf
    Write-Host "Local PDF successfully loaded." -ForegroundColor Green
    $fileName = Split-Path $InputStr -Leaf
    $Url = "Local File: $fileName"
}
# --- 2. HTTP DOWNLOAD LOGIC ---
elseif ($InputStr -match "^http") {
    if ($InputStr -match "arxiv\.org/abs/") {
        $InputStr = $InputStr -replace "arxiv\.org/abs/", "arxiv.org/pdf/"
        if ($InputStr -notmatch "\.pdf$") {
            $InputStr += ".pdf"
        }
        Write-Host "Auto-converted ArXiv abstract link to direct PDF: $InputStr" -ForegroundColor Yellow
        $Url = $InputStr
    }

    Write-Host "Downloading the paper... " -NoNewline

    try {
        Invoke-WebRequest -Uri $InputStr -OutFile $TempPdf -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0 Safari/537.36" -Headers @{ "Referer" = "https://scholar.google.com/" }

        $header = Get-Content $TempPdf -TotalCount 1 -ErrorAction SilentlyContinue
        if ($header -notmatch "%PDF") {
            Write-Host "`nError: The download failed or the URL did not point directly to a PDF." -ForegroundColor Red
            Remove-Item $TempDir -Recurse -Force
            exit 1
        }
        Write-Host "PDF successfully downloaded." -ForegroundColor Green
    }
    catch {
        Write-Host "`nError downloading file: $_" -ForegroundColor Red
        Remove-Item $TempDir -Recurse -Force
        exit 1
    }
}
else {
    Write-Host "Error: Input must be a valid HTTP URL or a local file path." -ForegroundColor Red
    Remove-Item $TempDir -Recurse -Force
    exit 1
}

# Initialize variables
$Title = ""
$Author = ""
$Year = ""
$Abstract = ""

Write-Host "Attempting to extract metadata..."

# 1. Check for ArXiv ID
if ($Url -match "(?:\d{4}\.\d{4,5})") {
    $ArxivId = $Matches[0]
    Write-Host "ArXiv link detected ($ArxivId). Fetching from ArXiv API..."
    try {
        [xml]$apiResponse = Invoke-RestMethod -Uri "http://export.arxiv.org/api/query?id_list=$ArxivId"
        $entry = $apiResponse.feed.entry
        $Title = $entry.title -replace '\s+', ' ' | Trim
        $Author = ($entry.author.name) -join " and "
        $Year = $entry.published.Substring(0, 4)
        $Abstract = $entry.summary -replace '\s+', ' ' | Trim
    }
    catch {
        Write-Host "Failed to fetch ArXiv metadata." -ForegroundColor DarkGray
    }
}
else {
    # 2. Try to find a Crossref DOI
    $firstPageText = (pdftotext -f 1 -l 1 $TempPdf -) 2>$null
    if ($firstPageText -match "\b10\.\d{4,9}/[-._;()/:A-Z0-9]+\b") {
        $Doi = $Matches[0]
        Write-Host "DOI found ($Doi). Fetching metadata from Crossref API..." -ForegroundColor Cyan
        try {
            $apiResponse = Invoke-RestMethod -Uri "https://api.crossref.org/works/$Doi"
            $Title = $apiResponse.message.title[0]
            $authors = $apiResponse.message.author | ForEach-Object { "$($_.given) $($_.family)" }
            $Author = $authors -join " and "
            $Year = $apiResponse.message.issued.'date-parts'[0][0]
        }
        catch {
            Write-Host "Failed to fetch Crossref metadata." -ForegroundColor Yellow
        }
    }
}

# 3. Independent Fallbacks (exiftool)
$exiftoolAvailable = $null -ne (Get-Command exiftool -ErrorAction SilentlyContinue)
if ($exiftoolAvailable) {
    if (-not $Title) { $Title = (exiftool -s3 -Title $TempPdf | Out-String).Trim() }
    if (-not $Author) { $Author = (exiftool -s3 -Author $TempPdf | Out-String).Trim() }
    if (-not $Year) {
        $createDate = (exiftool -s3 -CreateDate $TempPdf | Out-String).Trim()
        if ($createDate -match "\d{4}") {
            $Year = $Matches[0]
        }
    }
}
else {
    Write-Host "exiftool not found; skipping exiftool metadata fallback." -ForegroundColor Yellow
}

# 4. Final Guaranteed Fallbacks
if (-not $Title -or $Title -match "Untitled") {
    $firstPageLines = pdftotext -f 1 -l 1 $TempPdf - 2>$null | Where-Object { $_.Trim() -ne "" -and $_ -notmatch "(?i)(arxiv|downloaded|journal|vol|doi)" }
    if ($firstPageLines) {
        $Title = $firstPageLines[0].Trim()
    }
    else {
        $Title = "Unknown_Title"
    }
}

if (-not $Author) { $Author = "Unknown_Author" }
if (-not $Year) { $Year = (Get-Date).Year.ToString() }

# --- CLEANUP LOGIC ---
$CleanedTitle = $Title -replace "[^A-Za-z0-9_ ]", "" -replace " ", "_"
if ($CleanedTitle.Length -gt 50) {
    $CleanedTitle = $CleanedTitle.Substring(0, 50)
}

$FirstAuthor = ($Author -split " and |;|,")[0].Trim()
$CleanedAuthor = ($FirstAuthor -split " ")[-1] -replace "[^A-Za-z0-9_]", ""

if (-not $CleanedTitle) { $CleanedTitle = "Paper" }
if (-not $CleanedAuthor) { $CleanedAuthor = "Unknown" }

$FolderName = "${CleanedTitle}_${Year}"
$FileName = "${CleanedAuthor}_${Year}"

if (-not (Test-Path $FolderName)) {
    New-Item -ItemType Directory -Path $FolderName -Force | Out-Null
}

# Moves the PDF
Move-Item -Path $TempPdf -Destination "$FolderName\$FileName.pdf" -Force

# Fallback abstract extraction
if (-not $Abstract) {
    Write-Host "Extracting Abstract from PDF..."
    $pdfText = pdftotext -f 1 -l 1 "$FolderName\$FileName.pdf" - 2>$null
    $abstractMatch = $pdfText -match "(?is)Abstract\s*(.*?)(?:\n\n|\Z)"
    if ($abstractMatch) {
        $Abstract = $Matches[1] -replace '\s+', ' '
    }
    else {
        $Abstract = "Abstract extraction failed. Please read the PDF."
    }
}

# --- FULL PAPER CONVERSION ---
Write-Host "Converting entire PDF to Markdown text..."
$FullPaperPath = Join-Path $TempDir "full_paper.md"
pdftotext -layout "$FolderName\$FileName.pdf" $FullPaperPath 2>$null
$FullText = ""
if (Test-Path $FullPaperPath) {
    $FullText = Get-Content $FullPaperPath -Raw -ErrorAction SilentlyContinue
}

# --- MARKDOWN FILE GENERATION ---
Write-Host "Generating Markdown notes file..."
$MdLines = @(
    "# $Title"
    ""
    "**Authors:** $Author"
    "**Year:** $Year"
    "**Source URL:** $Url"
    ""
    "## Abstract"
    $Abstract
    ""
    "## My Notes"
    "- Start typing your research notes here..."
    ""
    "---"
    ""
    "## Full Paper Text"
    $FullText
)

$MdLines -join "`n" | Out-File -FilePath "$FolderName\$FileName.md" -Encoding utf8

# --- CONTENTS.MD UPDATING ---
Write-Host "Updating contents.md index..."
$ContentsFile = "contents.md"
if (-not (Test-Path $ContentsFile)) {
    "# Research Papers Index`n`n" | Out-File -FilePath $ContentsFile -Encoding utf8
}

$IndexLines = @(
    "- **[$Title]($FolderName/$FileName.pdf)** ($Year) - $Author | [Markdown Notes]($FolderName/$FileName.md)"
    ""
    "    **Abstract:** $Abstract"
    ""
    "    **BibTeX:**"
    '    ```bibtex'
    "    @article{$FileName,"
    "      title={$Title},"
    "      author={$Author},"
    "      year={$Year},"
    "      url={$Url}"
    "    }"
    '    ```'
    ""
)

$IndexLines -join "`n" | Out-File -FilePath $ContentsFile -Append -Encoding utf8

# Cleanup
Remove-Item $TempDir -Recurse -Force

if (Test-Path $InputStr -PathType Leaf) {
    Write-Host "Deleting the original referenced file to keep your system clean..." -ForegroundColor Cyan
    Remove-Item $InputStr -Force
}

Write-Host "Success! PDF and Markdown saved to $FolderName" -ForegroundColor Green