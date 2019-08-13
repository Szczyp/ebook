#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nodejs imagemagick "python3.withPackages (pkgs: with pkgs; [pandocfilters pyphen])"

set -e

export PATH=$PATH:/home/qb/Downloads/kindlegen

dir=$(pwd)

cd "$(dirname "$0")"

link=$1

sha=$(echo "$link" | md5sum | cut -d ' ' -f 1)

html=out/"$sha".html

curl -s "$link" > "$html"

readable=out/"$sha".readable

node readability.js "$html" > "$readable"

title=$(head -n 1 "$readable" | xargs)
author=$(cat "$readable" | head -n 2 | tail -n 1 | xargs)

name="$title - $author"

cover=out/"$sha".png

convert \
    -background white \
    -size 1560x2560 \
    -bordercolor white \
    -border 100 \
    -bordercolor black \
    -border 10 \
    -gravity center \
    -fill black \
    -font Linux-Libertine-Display-O \
   caption:"$title" \
   "$cover" > /dev/null

pandoc \
		-s \
		--filter hyphenate.py \
		--filter strip_img.py \
		--section-divs \
		--toc-depth=1 \
		--epub-cover-image "$cover" \
		-o out/"$name".epub \
		-c ebook.css \
		--template template.t \
    -f html \
		-t epub3 \
    --metadata title="$title" \
    --metadata author="$author" \
    <(tail -n +3 "$readable") > /dev/null

kindlegen out/"$name".epub > /dev/null

echo "$name"
