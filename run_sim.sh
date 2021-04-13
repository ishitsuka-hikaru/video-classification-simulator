#!/bin/bash
PATH_3D_RESNETS=../3D-ResNets-PyTorch
PATH_MOGEN=../mogen
PATH_MOCAP_LABELS=utils/mocap_labels.json

function usage() {
    cat <<EOM
Usage: $(basename "$0") [OPTION]...

    -m VALUE	  Specify model ID (f00|...|f04|m00|...|m04)
    -l VALUE	  Specify motion label (walk|run|jump|...), see utils/mocap_labels.json
    -c VALUE	  Specify camera angle (1|2|3|4)
    -h 		  Display help
EOM

    exit 1
}

while getopts ":m:l:c:h" OPT; do
    case $OPT in
	m)
	    mhxid=$OPTARG
	    ;;
	l)
	    bvhid=`python3 utils/mocap_labels.py --label $OPTARG --seed 0`
	    ;;
	c)
	    camid=$OPTARG
	    ;;
	h)
	    usage
	    ;;
	\?)
	    usage
	    ;;
    esac
done


# mogen options
model_path=$PATH_MOGEN/models/$mhxid.mhx2
motion_path=$PATH_MOGEN/mocap/$bvhid.bvh
camera=$camid

# 3D-ResNets-PyTorch options
root_path=data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
result_path=results
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
blender -noaudio -b -P $PATH_MOGEN/mogen.py -- \
	--model $model_path \
	--motion $motion_path \
	--camera $camera >/dev/null 2>&1

# Make annotation file
python3 $PATH_3D_RESNETS/util_scripts/makehuman_json.py \
	--root $root_path \
	--dataset $dataset \
	--min_inst 1 \
	--mocap_labels $PATH_MOCAP_LABELS \
	--data_split testing \
	--filename $annotation_path \
	--class_labels $PATH_3D_RESNETS/util_scripts/makehuman-31.json

# Forward 3D-ResNets
python3 $PATH_3D_RESNETS/main.py \
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
	--inference_no_average

# Visualize the result
python3 utils/visualizer.py \
	--root_path $root_path \
	--annotation_path $annotation_path \
	--result_path $result_path/test_no_average.json
