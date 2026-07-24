# Paper Fetch for Windows

This folder contains the PowerShell implementation of Paper Fetch for Windows.

## What it does

The Windows script:

- accepts a paper URL or a local PDF path
- downloads the paper when needed
- converts arXiv abstract links into direct PDF links
- extracts metadata from arXiv or Crossref when possible
- creates a paper folder with a PDF and a Markdown notes file
- updates a contents index with a BibTeX-ready entry

## Requirements

Paper Fetch for Windows works best on Windows 10 or Windows 11 with PowerShell 5+.

Install the required tools first:

```powershell
winget install --id Chocolatey.Chocolatey -y
choco install poppler exiftool -y
```

## Installation

From the repository root:

```powershell
cd windows
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
./install.ps1
```

The installer copies the script to your user Scripts folder and adds that folder to your PATH.

## Usage

After installation, open a new terminal and run:

```powershell
fetchpaper https://arxiv.org/abs/2401.00001
```

Or use a local PDF:

```powershell
fetchpaper .\my-paper.pdf
```

## Output

Each run creates a folder with the cleaned title and year, for example:

```text
My_Paper_2024/
├── Smith_2024.pdf
└── Smith_2024.md
```

It also creates or updates contents.md in the current working directory.

## Files

- fetchpaper.ps1: the main PowerShell script
- install.ps1: installs the script to your user Scripts folder and configures PATH

## Troubleshooting

If the script does not run, verify that PowerShell can execute scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

If pdftotext is missing, reinstall Poppler. If exiftool is missing, install ExifTool and try again.