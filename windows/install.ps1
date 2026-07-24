# 1. Create a global scripts directory in your User profile
$ScriptsDir = "$HOME\Scripts"
New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null

# 2. Copy the script into that directory without removing the original from the windows folder
$SourceScript = Join-Path $PSScriptRoot "fetchpaper.ps1"
$InstalledScript = Join-Path $ScriptsDir "fetchpaper.ps1"
Copy-Item -Path $SourceScript -Destination $InstalledScript -Force

# 3. Add this folder to your permanent Windows User PATH (so Windows sees it everywhere)
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$ScriptsDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$ScriptsDir", "User")
    $env:Path += ";$ScriptsDir"
}

# 4. Create a Profile wrapper so you can type just 'fetchpaper' instead of 'fetchpaper.ps1'
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
}

$AliasCode = "`nfunction fetchpaper { & '$InstalledScript' @args }"
if ((Get-Content $PROFILE -ErrorAction SilentlyContinue) -notcontains $AliasCode.Trim()) {
    Add-Content -Path $PROFILE -Value $AliasCode
}

Write-Host "Done! Please restart your terminal. You can now type 'fetchpaper <url>' from any directory." -ForegroundColor Green