#!/bin/bash

# Script to export Typst example files to PNG images (for publishing on Typst universe)

set -e  # Exit on error

# Configuration
DPI=300 
OUTPUT_DIR="gallery"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Typst export process...${NC}"
echo "DPI: $DPI"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Create output directories if they don't exist
mkdir -p "$OUTPUT_DIR/features"
mkdir -p "$OUTPUT_DIR/networks"
mkdir -p "$OUTPUT_DIR/imported"

# Export features examples
echo -e "${GREEN}Exporting features examples...${NC}"
for file in examples/features/*.typ; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .typ)
        typst compile "$file" "$OUTPUT_DIR/features/$filename.png" --ppi "$DPI" --root "."
        echo "Exported $filename.typ"
    fi
done

# Export network examples
echo -e "${GREEN}Exporting network examples...${NC}"
for file in examples/networks/*.typ; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .typ)
        typst compile "$file" "$OUTPUT_DIR/networks/$filename.png" --ppi "$DPI" --root "."
        echo "Exported $filename.typ"
    fi
done

# Export imported-model examples
echo -e "${GREEN}Exporting imported examples...${NC}"
for file in examples/imported/*.typ; do
    if [ -f "$file" ]; then
        filename=$(basename "$file" .typ)
        typst compile "$file" "$OUTPUT_DIR/imported/$filename.png" --ppi "$DPI" --root "."
        echo "Exported $filename.typ"
    fi
done

echo ""
echo -e "${BLUE}Export complete! Images saved to $OUTPUT_DIR/${NC}"
