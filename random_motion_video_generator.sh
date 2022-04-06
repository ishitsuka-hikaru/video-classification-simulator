#!/bin/bash
readonly NUM=1
# readonly MODELS=(f00 f01 f02 f03 f04 m00 m01 m02 m03 m04)
readonly MODELS=(f00 f01 f02 f03 f04 f05 f06 f07 f08 m00 m01 m02 m03 m05 m06 m07 m08)
readonly MOTIONS=(
    "run" "jump" "clean" "walk" "dance" "motorcycle" "carry suitcases"
    "stand" "pick up" "march" "drink" "kick" "swing" "throw" "dribble"
    "push" "duck" "climb" "chicken" "comfort" "wait" "eat" "reach" "stretch"
    "cartwheel" "hop turn" "prairie dog" "swim" "monkey" "wave" "pull"
)
readonly X_RANGE=($(seq 45 55))      # [1.2, 2.2] meters
readonly Y_RANGE=($(seq 45 55))      # [1.2, 2.2]
readonly Z_RANGE=($(seq 18 22))      # [1.5, 2.5]
readonly RX_RANGE=($(seq 395 405))   # [37.5, 42.5] degrees
readonly RY_RANGE=($(seq -5 5))      # [-0.5, 0.5]
readonly RZ_RANGE=($(seq 1300 1400)) # [130, 140]
# readonly X_RANGE=($(seq 0 50))       # [0.0, 5.0] meters
# readonly Y_RANGE=($(seq 0 50))       # [0.0, 5.0] meters
# readonly Z_RANGE=($(seq 15 25))      # [1.5, 2.5] meters
# readonly RX_RANGE=($(seq 375 425))   # [37.5, 42.5] degrees
# readonly RY_RANGE=($(seq -5 5))      # [-0.5, 0.5] degrees
# readonly RZ_RANGE=($(seq 1300 1400))      # [130, 140] degrees
# readonly DSTDIR=data/fg_fisheye_202203251130
readonly DSTDIR=data/tmp
# readonly DSTDIR=~/sync/wide_lens_makehuman
readonly TMPDIR=data/makehuman_videos/`basename $DSTDIR`
# readonly OPT1=--checker_floor
readonly OPT1="--floor_texture imgs/checker_16x16.png"
readonly OPT2=--quiet

if [ -e $DSTDIR ]; then
    rm -fr $DSTDIR
fi
mkdir $DSTDIR


## main process
readonly date_begin=$(date "+%Y-%m-%d %H:%M:%S")
readonly t_begin=$SECONDS
i=0
while [ $i -lt $NUM ];
do
    t=$SECONDS
    MODEL=${MODELS[$(($RANDOM % ${#MODELS[@]}))]}
    MOTION=${MOTIONS[$(($RANDOM % ${#MOTIONS[@]}))]}
    CAM_X=`echo "scale=1; ${X_RANGE[$(($RANDOM % ${#X_RANGE[@]}))]} / 10" | bc`
    CAM_Y=`echo "scale=1; ${Y_RANGE[$(($RANDOM % ${#Y_RANGE[@]}))]} / 10" | bc`
    CAM_Z=`echo "scale=1; ${Z_RANGE[$(($RANDOM % ${#Z_RANGE[@]}))]} / 10" | bc`
    CAM_RX=`echo "scale=1; ${RX_RANGE[$(($RANDOM % ${#RX_RANGE[@]}))]} / 10" | bc`
    CAM_RY=`echo "scale=1; ${RY_RANGE[$(($RANDOM % ${#RY_RANGE[@]}))]} / 10" | bc`
    CAM_RZ=`echo "scale=1; ${RZ_RANGE[$(($RANDOM % ${#RZ_RANGE[@]}))]} / 10" | bc`
    SEED=$RANDOM

    echo "---------------- parameters ----------------"
    echo "               #: $((i+1))/${NUM}"
    echo "     destination: $DSTDIR"
    echo "           model: $MODEL"
    echo "          motion: $MOTION"
    echo " camera location: $CAM_X, $CAM_Y, $CAM_Z"
    echo " camera rotation: $CAM_RX, $CAM_RY, $CAM_RZ"
    echo "     random seed: $SEED"
    echo "        tmporary: $TMPDIR"
    echo "         option1: $OPT1"
    echo "         option2: $OPT2"
    echo "--------------------------------------------"

    # ./sim.sh -m $MODEL -l $MOTION --cam_x $CAM_X --cam_y $CAM_Y --cam_z $CAM_Z\
    # 	     --no_recognition --seed $SEED --floor_texture imgs/checker.png
    # ./sim.sh -m f00 -l walk\
    # 	     --cam_x $CAM_X --cam_y $CAM_Y --cam_z $CAM_Z\
    # 	     --cam_rx $CAM_RX --cam_ry $CAM_RY --cam_rz $CAM_RZ\
    # 	     --no_recognition --seed $SEED --tmp_dir `basename $DSTDIR`\
    # 	     $OPT1 $OPT2
    ./sim.sh -m $MODEL -l $MOTION\
    	     --cam_x $CAM_X --cam_y $CAM_Y --cam_z $CAM_Z\
    	     --cam_rx $CAM_RX --cam_ry $CAM_RY --cam_rz $CAM_RZ\
    	     --no_recognition --seed $SEED --tmp_dir `basename $DSTDIR`\
    	     $OPT1 $OPT2
    
    #SRCDIR=data/makehuman_videos/jpg/*/*
    SRCDIR=${TMPDIR}/*/*
    if [ ! -e $SRCDIR ]; then
	echo "error: '$SRCDIR' not found"
    	continue
    fi
    
    rm $SRCDIR/image_00001.png
    mv $SRCDIR $DSTDIR

    printf "succeeded! (%d s)\n\n" $((SECONDS - t))
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

echo "     begin time: $date_begin"
echo "       end time: $date_end"
echo " wallclock time: `displaytime $((SECONDS - t_begin))`"
