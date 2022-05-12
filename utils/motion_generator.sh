#!/bin/bash
#------------------------------------------------------------------------------#
# setting                                                                      #
#------------------------------------------------------------------------------#
NUM=10  # number of motions
DSTDIR=data/output_motions  # destination of motions
MODELS=(f00 f01 f02 f03 f04 f05 f06 f07 f08 m00 m01 m02 m03 m05 m06 m07 m08)
MOTIONS=(
    "run" "jump" "clean" "walk" "dance" "motorcycle" "carry suitcases"
    "stand" "pick up" "march" "drink" "kick" "swing" "throw" "dribble"
    "push" "duck" "climb" "chicken" "comfort" "wait" "eat" "reach" "stretch"
    "cartwheel" "hop turn" "prairie dog" "swim" "monkey" "wave" "pull"
)
X_RANGE=($(seq 10 70))  # -> [1.0, 7.0], unit: meters
Y_RANGE=($(seq -10 10))
Z_RANGE=($(seq 15 25))
RX_RANGE=($(seq 425 475))  # -> [37.5, 42.5], unit: degrees
RY_RANGE=($(seq -5 5))
RZ_RANGE=($(seq 875 925))
# OPT="--checker_floor"  # comment out if not needed


#------------------------------------------------------------------------------#
# main process                                                                 #
#------------------------------------------------------------------------------#
TMPDIR=data/makehuman_videos/`basename $DSTDIR`
if [ -e $DSTDIR ]; then
    rm -fr $DSTDIR
fi
mkdir -p $DSTDIR
readonly date_begin=$(date "+%Y-%m-%d %H:%M:%S")
readonly t_begin=$SECONDS
i=0
while [ $i -lt $NUM ];
do
    t=$SECONDS
    MODEL=${MODELS[$(($RANDOM % ${#MODELS[@]}))]}
    MOTION=${MOTIONS[$(($RANDOM % ${#MOTIONS[@]}))]}
    CAM_X=`echo "scale=1; ${X_RANGE[$(($RANDOM % ${#X_RANGE[@]}))]} / 10" | bc -l | awk '{printf "%.1f\n", $0}'`
    CAM_Y=`echo "scale=1; ${Y_RANGE[$(($RANDOM % ${#Y_RANGE[@]}))]} / 10" | bc -l | awk '{printf "%.1f\n", $0}'`
    CAM_Z=`echo "scale=1; ${Z_RANGE[$(($RANDOM % ${#Z_RANGE[@]}))]} / 10" | bc -l | awk '{printf "%.1f\n", $0}'`
    CAM_RX=`echo "scale=1; ${RX_RANGE[$(($RANDOM % ${#RX_RANGE[@]}))]} / 10" | bc -l | awk '{printf "%.1f\n", $0}'`
    CAM_RY=`echo "scale=1; ${RY_RANGE[$(($RANDOM % ${#RY_RANGE[@]}))]} / 10" | bc -l | awk '{printf "%.1f\n", $0}'`
    CAM_RZ=`echo "scale=1; ${RZ_RANGE[$(($RANDOM % ${#RZ_RANGE[@]}))]} / 10" | bc -l | awk '{printf "%.1f\n", $0}'`
    SEED=$RANDOM

    echo "---------------- parameters ----------------"
    echo "               #: $((i+1))/$NUM"
    echo "     destination: $DSTDIR"
    echo "           model: $MODEL"
    echo "          motion: $MOTION"
    echo " camera location: ($CAM_X, $CAM_Y, $CAM_Z)"
    echo " camera rotation: ($CAM_RX, $CAM_RY, $CAM_RZ)"
    echo "     random seed: $SEED"
    echo "         options: $OPT"
    echo "--------------------------------------------"

    ./sim.sh -m $MODEL -l $MOTION\
    	     --cam_x $CAM_X --cam_y $CAM_Y --cam_z $CAM_Z \
    	     --cam_rx $CAM_RX --cam_ry $CAM_RY --cam_rz $CAM_RZ \
    	     --no_recognition --seed $SEED --tmp_dir `basename $DSTDIR` \
    	     $OPT --quiet
    
    SRCDIR=${TMPDIR}/*/*
    if [ ! -e $SRCDIR ]; then
	echo "error: '$SRCDIR' not found"
    	continue
    fi
    
    rm $SRCDIR/image_00001.png
    mv $SRCDIR $DSTDIR

    printf "succeeded! (%d sec)\n\n" $((SECONDS - t))
    ((i++))
done

rm -fr $TMPDIR

function displaytime {
    local T=$1
    local D=$((T/60/60/24))
    local H=$((T/60/60%24))
    local M=$((T/60%60))
    local S=$((T%60))
    (( $D > 0 )) && printf '%d days, ' $D
    printf '%02d:%02d:%02d\n' $H $M $S
}

date_end=$(date "+%Y-%m-%d %H:%M:%S")

echo "all completed!"
echo "-------------------------------"
echo "    begin: $date_begin"
echo "      end: $date_end"
echo " walltime: `displaytime $((SECONDS - t_begin))`"
echo ""
