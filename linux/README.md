# Paper Fetch for Linux

This folder contains the Bash implementation of Paper Fetch for Linux and Unix-like systems.

## What it does

The Linux script:

- accepts a paper URL or a local PDF path
- downloads the paper when needed
- converts arXiv abstract links into direct PDF links
- extracts metadata from arXiv or Crossref when possible
- creates a paper folder with a PDF and a Markdown notes file
- updates a contents index with a BibTeX-ready entry

## Requirements

Install the required packages first.

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y wget poppler-utils libimage-exiftool-perl curl jq file
```

### Fedora

```bash
sudo dnf install -y wget poppler-utils perl-Image-ExifTool curl jq file
```

### Arch

```bash
sudo pacman -S --needed wget poppler jq file perl-image-exiftool curl
```

## Installation

From the repository root:

```bash
cd linux
chmod +x install.sh
./install.sh
```

This installs the command as fetchpaper in your system path.

## Usage

Run the tool from any directory:

```bash
fetchpaper https://arxiv.org/abs/2401.00001
```

Or use a local PDF:

```bash
fetchpaper ./my-paper.pdf
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

- fetchpaper.sh: the main Bash script
- install.sh: installs the script to /usr/local/bin

## Troubleshooting

If the script fails, check that these commands are available:

```bash
which wget
which pdftotext
which exiftool
which curl
```

If one of them is missing, install the corresponding package and try again.