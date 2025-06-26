# braille_translate.py
"""
Braille translation utility using the 'braille' Python package.
Usage: python braille_translate.py "Your text here"
"""
import sys
try:
    from braille import encode, decode
except ImportError:
    print("Please install the 'braille' package: pip install braille")
    sys.exit(1)

def text_to_braille(text):
    return encode(text)

def braille_to_text(braille_str):
    return decode(braille_str)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python braille_translate.py 'Your text here'")
        sys.exit(1)
    input_text = sys.argv[1]
    braille = text_to_braille(input_text)
    print(braille)
