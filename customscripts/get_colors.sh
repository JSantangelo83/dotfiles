
#!/bin/bash

generate_colors() {
  num_colors=$1
  increment=$(( 360 / num_colors ))

  for ((i = 0; i < num_colors; i++)); do
    hue=$(( i * increment ))
    color=$(convert -size 1x1 xc:hsv\(0,0,0\) +noise Random -virtual-pixel tile -resize 1x1 -colorspace HSB -fill "hsb(${hue},100%,100%)" -opaque white -depth 8 PNG:- | convert PNG:- -depth 8 txt:- | awk 'NR==2{print $3}')
    echo $color
  done
}

# Usage: ./generate_colors.sh <number_of_colors>
generate_colors $1

