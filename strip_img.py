from pandocfilters import Image, SoftBreak, toJSONFilter

def strip_img(key, value, format, meta):
    if key == 'Image':
        return SoftBreak()

if __name__ == "__main__":
    toJSONFilter(strip_img)
