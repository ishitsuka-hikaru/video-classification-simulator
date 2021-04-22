#!/bin/bash
PATH_3D_RESNETS=../3D-ResNets-PyTorch
PATH_MOGEN=../mogen
PATH_MOCAP_LABELS=utils/mocap_labels.json

function usage() {
    cat <<EOM
Usage: $(basename "$0") [OPTION]...

    -m string	  Specify model ID (f00|...|f04|m00|...|m04)
    -l string	  Specify motion label (walk|run|jump|...), see utils/mocap_labels.json
    -s int	  Random seed for the label selection	  
    -c int	  Specify camera angle (1|2|3|4)
    -x float	  Specify camera location x
    -y float	  Specify camera location y
    -z float	  Specify camera location z
    -a 		  Avarage per video (not frame)
    -t 		  Tracking model parts
    -q 		  Quiet
    -h 		  Help

EOM

    exit 1
}

function set_default() {
    mhxid=f00
    bvhid=walk
    seed=0
    camid=1
    camera_x=0
    camera_y=0
    camera_z=0
    is_averaging=false
    is_tracking=false
}

set_default

while getopts ":m:l:s:c:x:y:z:atqh" OPT; do
    case $OPT in
	m)
	    mhxid=$OPTARG
	    ;;
	l)
	    bvhid=$OPTARG
	    ;;
	s)
	    seed=$OPTARG
	    ;;
	c)
	    camid=$OPTARG
	    ;;
	x)
	    camera_x=$OPTARG
	    ;;
	y)
	    camera_y=$OPTARG
	    ;;
	z)
	    camera_z=$OPTARG
	    ;;
	a)
	    is_averaging=true
	    ;;
	t)
	    is_tracking=true
	    ;;
	q)
	    #echo "start simulation! (quiet)"
	    quiet=">/dev/null 2>&1"
	    ;;
	h)
	    usage
	    ;;
	\?)
	    usage
	    ;;
	:)
	    usage
	    ;;
	*)
	    usage
	    ;;
    esac
done


motion_label=`python3 utils/mocap_labels.py --label $bvhid --seed $seed`


# mogen options
model_path=$PATH_MOGEN/models/$mhxid.mhx2
motion_path=$PATH_MOGEN/mocap/$motion_label.bvh
camera=$camid

# 3D-ResNets-PyTorch options
root_path=data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
#result_path=results
#result_path=results/$mhxid/$motion_label/${camera_x}_${camera_y}_${camera_z}
result_path=results/${mhxid}_${bvhid}_${camera_x}_${camera_y}_${camera_z}
dataset=makehuman
resume_path=models/MakeHuman-100k-31.pth
n_classes=31
model=resnet
model_depth=34
n_threads=`cat /proc/cpuinfo | grep processor | wc -l`
output_topk=$n_classes
inference_batch_size=1
inference_subset=test
inference_crop=nocrop  # (center | nocrop)


# Init.
mkdir -p $root_path/$result_path
if [ -e $root_path/$video_path ]; then
    rm -r $root_path/$video_path
fi


# Generate motion video
if [ $camera_x -eq 0 ] && [ $camera_y -eq 0 ] && [ $camera_z -eq 0 ]; then
    if "$is_tracking"; then
	eval blender -noaudio -b -P $PATH_MOGEN/mogen.py -- \
	     --model $model_path \
	     --motion $motion_path \
	     --camera $camera \
	     --tracking $quiet
    else
	eval blender -noaudio -b -P $PATH_MOGEN/mogen.py -- \
	     --model $model_path \
	     --motion $motion_path \
	     --camera $camera $quiet
    fi
else
    # Set camera location
    camera_loc="$camera_x $camera_y $camera_z"

    if "$is_tracking"; then
	eval blender -noaudio -b -P $PATH_MOGEN/mogen.py -- \
	     --model $model_path \
	     --motion $motion_path \
	     --camera $camera \
	     --location $camera_loc \
	     --tracking $quiet
    else
	eval blender -noaudio -b -P $PATH_MOGEN/mogen.py -- \
	     --model $model_path \
	     --motion $motion_path \
	     --camera $camera \
	     --location $camera_loc $quiet
    fi
fi


# Make annotation file
python3 $PATH_3D_RESNETS/util_scripts/makehuman_json.py \
	--root $root_path \
	--dataset $dataset \
	--min_inst 1 \
	--mocap_labels $PATH_MOCAP_LABELS \
	--data_split testing \
	--filename $annotation_path \
	--class_labels $PATH_3D_RESNETS/util_scripts/makehuman-31.json \
	--quiet


# Evaluation
if "$is_averaging"; then
    eval python3 $PATH_3D_RESNETS/main.py \
	 --root_path $root_path \
	 --video_path $video_path \
	 --annotation_path $annotation_path \
	 --result_path $result_path \
	 --dataset $dataset \
	 --resume_path $resume_path \
	 --n_classes $n_classes \
	 --model $model \
	 --model_depth $model_depth \
	 --n_threads $n_threads \
	 --no_train \
	 --no_val \
	 --inference \
	 --output_topk $output_topk \
	 --inference_batch_size $inference_batch_size \
	 --inference_subset $inference_subset \
	 --inference_crop $inference_crop $quiet
else
    eval python3 $PATH_3D_RESNETS/main.py \
	 --root_path $root_path \
	 --video_path $video_path \
	 --annotation_path $annotation_path \
	 --result_path $result_path \
	 --dataset $dataset \
	 --resume_path $resume_path \
	 --n_classes $n_classes \
	 --model $model \
	 --model_depth $model_depth \
	 --n_threads $n_threads \
	 --no_train \
	 --no_val \
	 --inference \
	 --output_topk $output_topk \
	 --inference_batch_size $inference_batch_size \
	 --inference_subset $inference_subset \
	 --inference_crop $inference_crop \
	 --inference_no_average $quiet
fi


# Visualize the result
if ! "$is_averaging"; then
    python3 utils/visualizer.py \
	    --root_path $root_path \
	    --annotation_path $annotation_path \
	    --result_path $result_path/test_no_average.json
fi
