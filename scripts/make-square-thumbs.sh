#!/bin/bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/Pictures/Wallpapers/.thumbs"

mkdir -p "$THUMB_DIR"

find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -print0 | \
while IFS= read -r -d '' file; do
    filename=$(basename "$file")
    thumb="$THUMB_DIR/$filename"

    if [ -f "$thumb" ]; then
        continue
    fi

    magick "$file" -resize 400x400^ -gravity center -extent 400x400 "$thumb"
    echo "Created thumbnail: $filename"
done

echo "Done."
