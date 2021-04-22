#!/bin/bash

# function usage() {
#     cat <<EOM
# Usage: $(basename "$0") [OPTION]...

#     -x
# EOM
# }

model=f00
label=walk
xmin=-5
xmax=5
ymin=-5
ymax=5
z=5

for y in $(seq $ymin $ymax); do
    for x in $(seq $xmin $xmax); do
	echo "x, y = $x, $y"
	./sim.sh -m $model -l $label -x $x -y $y -z $z -a -q -t
    done
done
