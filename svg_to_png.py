# svg_to_png.py
"""
Convert SVG to PNG using CairoSVG.
Usage: python svg_to_png.py input.svg output.png
"""
import sys
import cairosvg

def convert_svg_to_png(input_svg, output_png):
    cairosvg.svg2png(url=input_svg, write_to=output_png)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python svg_to_png.py input.svg output.png")
        sys.exit(1)
    input_svg = sys.argv[1]
    output_png = sys.argv[2]
    convert_svg_to_png(input_svg, output_png)
    print(f"Converted {input_svg} to {output_png}")
