#!/bin/bash

URL="$1"

if [ -z "$URL" ]; then
    echo "Usage: fetchpaper <URL of the paper>"
    exit 1
fi

if [[ "$URL" != *pdf* ]]; then
    echo "Error: The link doesn't look like a PDF route!!"
    exit 1
fi

echo "Downloading the paper... "

mkdir -p temp/

wget -q -O temp/temp.pdf "$URL"

TITLE=$(exiftool -s3 -Title temp/temp.pdf)
AUTHOR=$(exiftool -s3 -Author temp/temp.pdf)
YEAR=$(exiftool -s3 -CreateDate temp/temp.pdf | grep -oP '\d{4}' | head -1)

if [ -z "$TITLE" ]; then
    echo "Metadata empty, attempting text scrape..."
    TITLE=$(pdftotext -f 1 -l 1 temp/temp.pdf - | grep -P '\S' | head -n 1)
fi

if [ -z "$AUTHOR" ]; then
    AUTHOR=$(pdfinfo temp/temp.pdf | grep "Author:" | sed 's/Author: *//' | xargs)
fi

if [ -z "$YEAR" ]; then
    YEAR=$(exiftool -s3 -Date temp/temp.pdf | grep -oP '\d{4}' | head -1)
fi

[ -z "$TITLE" ] && TITLE="Unknown_Title"
[ -z "$AUTHOR" ] && AUTHOR="Unknown_Author"
[ -z "$YEAR" ] && YEAR=$(date +%Y)

CLEANED_TITLE=$(echo "$TITLE" | tr ' ' '_' | tr -cd 'A-Za-z0-9_' | cut -c 1-50)
CLEANED_AUTHOR=$(echo "$AUTHOR" | awk -F'[;,]' '{print $1}' | awk '{print $NF}' | tr -cd 'A-Za-z0-9_')

FOLDER_NAME="${CLEANED_TITLE}_${YEAR}"
FILE_NAME="${CLEANED_AUTHOR}_${YEAR}"

mkdir -p "$FOLDER_NAME"
mv temp/temp.pdf "$FOLDER_NAME/${FILE_NAME}.pdf"

echo "Converting to Markdown..."

rm -rf temp/

echo "Extracting Abstract..."
ABSTRACT=$(pdftotext -f 1 -l 1 "$FOLDER_NAME/${FILE_NAME}.pdf" - | grep -iA 30 -E '^Abstract|^ABSTRACT' | tail -n +2 | awk -v RS='' '{gsub(/\n/," "); print $0; exit}' | xargs)

if [ -z "$ABSTRACT" ]; then
    ABSTRACT="Abstract extraction failed. Please refer to the Markdown notes."
fi

# Convert semicolons to 'and' for standard BibTeX author formatting
BIB_AUTHOR=$(echo "$AUTHOR" | sed 's/;/ and /g')

echo "Updating contents.md..."
if [ ! -f "contents.md" ]; then
    echo "# Research Papers Index" > contents.md
    echo "" >> contents.md
fi

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

echo "PDF Saved to $FOLDER_NAME/$FILE_NAME.pdf"
