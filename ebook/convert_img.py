#!/usr/bin/env python3

from pandocfilters import Link, Str, toJSONFilter


def convert_img(key, value, format, meta):
    if key == 'Image':
        [[ident, classes, keyvals], inline, target] = value
        return Link([ident, [], []], [Str(target[0])], target)


def main():
    toJSONFilter(convert_img)


if __name__ == "__main__":
    main()
