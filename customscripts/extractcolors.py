
from colorthief import ColorThief
import pdb
import sys

def get_lightness(color):
    # Convert the color from hex to RGB
    r, g, b = tuple(int(color[i:i+2], 16) for i in (1, 3, 5))
    # Calculate the perceived brightness or lightness of the color
    return (0.2126*r + 0.7152*g + 0.0722*b) / 255

# Get the filename from the command line
if len(sys.argv) < 2:
    print("Usage: python3 extractcolors.py <filename>")
    sys.exit(1)
filename = sys.argv[1]

# Create a ColorThief object using the filename
color_thief = ColorThief(filename)

# Get the dominant color
dominant_color = color_thief.get_color(quality=1)

# Build a color palette
palette = color_thief.get_palette(color_count=6)

# Convert RGB values to hex format
hex_colors = ["#{:02x}{:02x}{:02x}".format(*color) for color in palette]

# Sort the palette by perceived lightness
sorted_palette = sorted(hex_colors, key=get_lightness)

# Output the sorted colors one by one
for color in sorted_palette:
    print(color)

