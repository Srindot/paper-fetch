# Paper-Fetch 
A automated shell-script to store and organize research paper in local file-system.

## Installation 

### Package Dependencies 

- wget
- poppler-utils
- perl-image-exiftool

### installation Script

Use the [install.sh](install.sh) to mv the scrip to bin, to use the scrip across the filesystem.

## Usage

- For statically displayed pdf in the web:

```bash
fetchpaper <url>
```
- If the above didn't work, download the pdf manually in the local dir. Then, pass the address to the fetchpaper.

```bash
fetchpaper <relative_path>
```

The above commamd will take the relative path of the pdf locally, and then moves to the targeted location where the command ran and then organizes it.

## Issues 
If you face any troubles, raise a issue.
