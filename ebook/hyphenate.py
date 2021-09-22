#!/usr/bin/env python3

from pandocfilters import Para, Str, toJSONFilter, walk
from pyphen import Pyphen
import re
import sys

word_detection_pattern = re.compile(r'\w{7,}', re.UNICODE)

dic = None

def initialize_dic_if_none(lang):
    global dic
    if dic is None:
        dic = Pyphen(lang=lang, left=3, right=3)


def inpara(key, value, format, meta):
    initialize_dic_if_none(meta['language']['c'])
    if key == 'Para':
        return Para(walk(value, hyphenate, format, meta))


def hyphenate(key, value, format, meta):
    if key == 'Str':
        return Str(
            word_detection_pattern.sub(
                lambda match: dic.inserted(match.group(0), hyphen='­'), value))


def main():
    toJSONFilter(inpara)


if __name__ == "__main__":
    main()
