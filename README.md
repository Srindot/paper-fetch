# Paper Fetch

Paper Fetch is a lightweight command-line tool for researchers that turns a paper URL or local PDF into an organized research archive. It downloads the paper, extracts metadata when available, generates Markdown notes, and builds a BibTeX-friendly index for your collection.

## Why this project exists

Research often involves collecting papers from many places and keeping them in a structure that is easy to browse later. Paper Fetch helps you do that in one step.

## What it does

- accepts a paper URL or a local PDF file
- auto-converts arXiv abstract links to direct PDF links
- extracts metadata from arXiv and Crossref when available
- falls back to PDF text and exiftool metadata when needed
- creates a folder with:
  - the PDF
  - a Markdown notes file
  - an entry in a central contents index

## Repository structure

```text
paper-fetch/
├── linux/
│   ├── fetchpaper.sh
│   └── install.sh
├── windows/
│   ├── fetchpaper.ps1
│   └── install.ps1
└── README.md
```

## Installation

Choose the version that matches your system.

### Linux

Ubuntu / Debian:

```bash
sudo apt update
sudo apt install -y wget poppler-utils libimage-exiftool-perl curl jq file
```

Fedora:

```bash
sudo dnf install -y wget poppler-utils perl-Image-ExifTool curl jq file
```

Arch:

```bash
sudo pacman -S --needed wget poppler jq file perl-image-exiftool curl
```

Then install the CLI:

```bash
cd linux
chmod +x install.sh
./install.sh
```

### Windows

PowerShell 5+ and a modern Windows 10/11 installation are recommended.

Install the required tools first:

```powershell
winget install --id Chocolatey.Chocolatey -y
choco install poppler exiftool -y
```

Then install the script:

```powershell
cd windows
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
./install.ps1
```

## Quick start

### Linux

```bash
fetchpaper https://arxiv.org/abs/2401.00001
```

Or with a local PDF:

```bash
fetchpaper ./my-paper.pdf
```

### Windows

```powershell
fetchpaper https://arxiv.org/abs/2401.00001
```

Or with a local PDF:

```powershell
fetchpaper .\my-paper.pdf
```

## Output

Each run creates a folder named using the cleaned title and year, for example:

```text
My_Paper_2024/
├── Smith_2024.pdf
├── Smith_2024.md
```

It also updates a file named contents.md in the current working directory with the paper entry and BibTeX block.

## Notes

- The Linux version uses Bash and standard Unix tools.
- The Windows version uses PowerShell.
- exiftool is optional, but it improves metadata extraction when available.
- If a command is missing, install it first and try the script again.

## Contributing

Contributions are welcome. If you find a bug or want to improve the workflow, feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.
