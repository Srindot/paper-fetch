#!/bin/bash

URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: fetchpaper <URL of the paper>"
    exit 1
fi

# --- URL PRE-PROCESSING ---
# Automatically convert arXiv /abs/ links to direct /pdf/ links
if [[ "$URL" == *"arxiv.org/abs/"* ]]; then
    URL=$(echo "$URL" | sed 's|arxiv.org/abs/|arxiv.org/pdf/|')
    [[ "$URL" != *".pdf" ]] && URL="${URL}.pdf"
    echo "Auto-converted ArXiv abstract link to direct PDF: $URL"
fi

echo "Downloading the paper... "
mkdir -p temp/
wget -q -O temp/temp.pdf "$URL"

# Initialize variables
TITLE=""
AUTHOR=""
YEAR=""
ABSTRACT=""

echo "Attempting to extract metadata..."

# 1. Check for ArXiv ID in the URL first
ARXIV_ID=$(echo "$URL" | grep -oP '\d{4}\.\d{4,5}')

if [ -n "$ARXIV_ID" ]; then
    echo "ArXiv link detected ($ARXIV_ID). Fetching from ArXiv API..."
    API_RESPONSE=$(curl -sL "http://export.arxiv.org/api/query?id_list=$ARXIV_ID")
    
    # Isolate the main entry block
    ENTRY_BLOCK=$(echo "$API_RESPONSE" | awk '/<entry>/,/<\/entry>/')
    
    TITLE=$(echo "$ENTRY_BLOCK" | tr '\n' ' ' | grep -oP '<title>\K.*?(?=</title>)' | xargs)
    AUTHOR=$(echo "$ENTRY_BLOCK" | grep -oP '<name>\K.*?(?=</name>)' | awk '{printf "%s%s", (NR==1?"":" and "), $0} END{print ""}')
    YEAR=$(echo "$ENTRY_BLOCK" | grep -oP '<published>\K\d{4}')
    ABSTRACT=$(echo "$ENTRY_BLOCK" | tr '\n' ' ' | grep -oP '<summary>\K.*?(?=</summary>)' | xargs)
else
    # 2. Try to find a Crossref DOI in the text if not ArXiv
    DOI=$(pdftotext -f 1 -l 1 temp/temp.pdf - | grep -ioP '\b10\.\d{4,9}/[-._;()/:A-Z0-9]+\b' | head -1)

    if [ -n "$DOI" ]; then
        echo "DOI found ($DOI). Fetching precise metadata from Crossref API..."
        API_RESPONSE=$(curl -sL "https://api.crossref.org/works/$DOI")
        TITLE=$(echo "$API_RESPONSE" | jq -r '.message.title[0] // empty')
        AUTHOR=$(echo "$API_RESPONSE" | jq -r '.message.author | map(.given + " " + .family) | join(" and ") // empty')
        YEAR=$(echo "$API_RESPONSE" | jq -r '.message.issued."date-parts"[0][0] // empty')
    fi
fi

# 3. Independent Fallbacks (exiftool)
[ -z "$TITLE" ] && TITLE=$(exiftool -s3 -Title temp/temp.pdf)
[ -z "$AUTHOR" ] && AUTHOR=$(exiftool -s3 -Author temp/temp.pdf)
[ -z "$YEAR" ] && YEAR=$(exiftool -s3 -CreateDate temp/temp.pdf | grep -oP '\d{4}' | head -1)

# 4. Final Guaranteed Fallbacks
if [ -z "$TITLE" ] || [[ "$TITLE" == *"Untitled"* ]]; then
    TITLE=$(pdftotext -f 1 -l 1 temp/temp.pdf - | grep -vEi '(arxiv|downloaded|journal|vol|doi)' | grep -P '\S' | head -n 1)
    [ -z "$TITLE" ] && TITLE="Unknown_Title"
fi

[ -z "$AUTHOR" ] && AUTHOR="Unknown_Author"
[ -z "$YEAR" ] && YEAR=$(date +%Y)

# --- CLEANUP LOGIC ---
CLEANED_TITLE=$(echo "$TITLE" | tr ' ' '_' | tr -cd 'A-Za-z0-9_' | cut -c 1-50)

# 1. Standardize separators to a pipe "|", then cut the first segment
FIRST_AUTHOR=$(echo "$AUTHOR" | sed -E 's/ and /|/gi; s/;/|/g; s/,/|/g' | cut -d'|' -f1 | xargs)
# 2. Grab the last word of that first author (their surname)
CLEANED_AUTHOR=$(echo "$FIRST_AUTHOR" | awk '{print $NF}' | tr -cd 'A-Za-z0-9_')

[ -z "$CLEANED_TITLE" ] && CLEANED_TITLE="Paper"
[ -z "$CLEANED_AUTHOR" ] && CLEANED_AUTHOR="Unknown"

FOLDER_NAME="${CLEANED_TITLE}_${YEAR}"
FILE_NAME="${CLEANED_AUTHOR}_${YEAR}"

mkdir -p "$FOLDER_NAME"
mv temp/temp.pdf "$FOLDER_NAME/${FILE_NAME}.pdf"

# Fallback abstract extraction
if [ -z "$ABSTRACT" ]; then
    echo "Extracting Abstract from PDF..."
    ABSTRACT=$(pdftotext -f 1 -l 1 "$FOLDER_NAME/${FILE_NAME}.pdf" - | grep -iA 20 -E '^(Abstract|ABSTRACT)' | tail -n +2 | tr '\n' ' ' | sed 's/  */ /g' | xargs)
    [ -z "$ABSTRACT" ] && ABSTRACT="Abstract extraction failed. Please read the PDF."
fi

# --- FULL PAPER CONVERSION ---
echo "Converting entire PDF to Markdown text..."
pdftotext -layout "$FOLDER_NAME/${FILE_NAME}.pdf" - | sed 's/$/  /' > temp/full_paper.md

# --- MARKDOWN FILE GENERATION ---
echo "Generating Markdown notes file..."
cat <<EOF > "$FOLDER_NAME/${FILE_NAME}.md"
# $TITLE

**Authors:** $AUTHOR
**Year:** $YEAR
**Source URL:** $URL

## Abstract
$ABSTRACT

## My Notes
- Start typing your research notes here...

---

## Full Paper Text
$(cat temp/full_paper.md)
EOF

# --- CONTENTS.MD UPDATING ---
echo "Updating contents.md index..."
if [ ! -f "contents.md" ]; then
    echo "# Research Papers Index" > contents.md
    echo "" >> contents.md
fi

BIB_AUTHOR="$AUTHOR"

{
    echo "- **[$TITLE]($FOLDER_NAME/${FILE_NAME}.pdf)** ($YEAR) - $AUTHOR | [📄 Markdown Notes]($FOLDER_NAME/${FILE_NAME}.md)"
    echo ""
    echo "    **Abstract:** $ABSTRACT"
    echo ""
    echo "    **BibTeX:**"
    echo "    \`\`\`bibtex"
    echo "    @article{${FILE_NAME},"
    echo "      title={${TITLE}},"
    echo "      author={${BIB_AUTHOR}},"
    echo "      year={${YEAR}},"
    echo "      url={${URL}}"
    echo "    }"
    echo "    \`\`\`"
    echo ""
} >> contents.md

rm -rf temp/
echo "Success! Saved to $FOLDER_NAME/"
