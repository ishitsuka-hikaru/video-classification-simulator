#!/bin/bash
INPUT=$1
FPS=10
WIDTH=256
LOGLEVEL=quiet  # quiet | error | info | debug

if [ -z "$2" ]; then
    OUTPUT=${INPUT:0:-4}.gif
else
    OUTPUT=$2
fi

ffmpeg -y -i $INPUT -filter_complex "[0:v] fps=${FPS},scale=${WIDTH}:-1,split [a][b];[a] palettegen [p];[b][p] paletteuse" $OUTPUT -loglevel $LOGLEVEL
