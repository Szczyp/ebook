#!/usr/bin/env python3

from pandocfilters import Image, SoftBreak, toJSONFilter

def strip_img(key, value, format, meta):
    if key == 'Image':
        return SoftBreak()

def main():
    toJSONFilter(strip_img)

if __name__ == "__main__":
    main()
