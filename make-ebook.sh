#!/usr/bin/env bash

filename="${1##*/}"
name="${filename%.*}"

convert -background white -fill black -font Linux-Biolinum-O-Bold \
        -size 600x900  -gravity center \
        label:"${name^}" out/cover.png

pandoc \
		-s \
		--filter hyphenate.py \
		--section-divs \
		--toc-depth=1 \
		--epub-cover-image out/cover.png \
		-o out/"$name".epub \
		-c ebook.css \
		--template template.t \
		-t epub3 \
		"$1"

kindlegen out/"$name".epub
