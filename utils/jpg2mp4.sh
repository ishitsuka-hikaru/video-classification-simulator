#!/bin/bash
FPS=30
SRC=${1%/}
FORMAT=image_%05d.jpg
#DST=`basename $SRCDIR`.mp4
DST=$2
LOGLEVEL=quiet

ffmpeg -y -framerate $FPS -i $SRC/$FORMAT -vcodec libx264 -pix_fmt yuv420p -r $FPS $DST -loglevel $LOGLEVEL
