#!/bin/bash
PATH_3D_RESNETS=../3D-ResNets-PyTorch
PATH_MOGEN=../mogen
PATH_MOCAP_LABELS=utils/mocap_labels.json
PATH_CLASS_LABELS=$PATH_3D_RESNETS/util_scripts/makehuman-31.json

function usage() {
    cat <<EOM
Usage: $(basename "$0") [OPTION]...

    -m, --model   	     string   Specify model ID (f00|...|f04|m00|...|m04), default f00
    -l, --label	  	     string   Specify motion label (walk|run|jump|...), default walk
    --camera_angle	     int      Specify camera angle (1|2|3|4), default 1
    --cam_x		     float    Specify camera location x, default 0
    --cam_y		     float    Specify camera location y, default 0
    --cam_z		     float    Specify camera location z, default 0
    --cam_rx		     float    Specify camera rotation x, default 0
    --cam_ry		     float    Specify camera rotation y, default 0
    --cam_rz		     float    Specify camera rotation z, default 0
    -a, --averaging	              Averaging per video, default false
    -c, --camera_constraint  string   Active camera control (none|track_to|copy_location), default none
    -s, --seed		     int      Random seed for the label selection, default 0
    --tmp_dir		     string   Rendering image location, default jpg
    --floor_texture	     string   Add floor texture, default none
    --checker_floor	     	      Add floor texture
    --show_labels	     	      Show all ground-truth class labels
    --no_recognition		      Stop at video generation
    -q, --quiet	  	     	      Quiet
    -h, --help			      Help

EOM

    exit 1
}

function set_default() {
    mhxid=f00
    bvhid=walk
    seed=0
    camid=1
    cam_x=0
    cam_y=0
    cam_z=0
    cam_rx=45
    cam_ry=0
    cam_rz=0
    #is_averaging=false
    is_ave=false
    #is_tracking=false
    camera_constraint=none
    show_labels=false
    no_recognition=false
    tmp_dir=jpg
    floor_texture=none
    checker_floor=
}


OPTS=`getopt -o m:l:ac:s:qh --long model:,label:,camera_angle:,cam_x:,cam_y:,cam_z:,cam_rx:,cam_ry:,cam_rz:,averaging,camera_constraint:,seed:,tmp_dir:,floor_texture:,checker_floor:,show_labels,no_recognition,quiet,help -n 'parse-options' -- "$@"`

if [ $? != 0 ]; then
    usage
fi

eval set -- "$OPTS"

set_default

while true; do
    case "$1" in
	-m | --model)
	    mhxid=$2; shift; shift ;;
	-l | --label)
	    bvhid=$2; shift; shift ;;
	--camera_angle)
	    camid=$2; shift; shift ;;
	--cam_x)
	    cam_x=$2; shift; shift ;;
	--cam_y)
	    cam_y=$2; shift; shift ;;
	--cam_z)
	    cam_z=$2; shift; shift ;;
	--cam_rx)
	    cam_rx=$2; shift; shift ;;
	--cam_ry)
	    cam_ry=$2; shift; shift ;;
	--cam_rz)
	    cam_rz=$2; shift; shift ;;
	-a | --averaging)
	    is_ave=true; shift ;;
	-c | --camera_constraint)
	    camera_constraint=$2; shift; shift ;;
	-s | --seed)
	    seed=$2; shift; shift ;;
	--tmp_dir)
	    tmp_dir=$2; shift; shift ;;
	--floor_texture)
	    floor_texture=$2; shift; shift ;;
	--checker_floor)
	    checker_floor=--checker_floor; shift ;;
	--show_labels)
	    show_labels=true; shift ;;
	--no_recognition)
	    no_recognition=true; shift ;;
	-q | --quiet)
	    quiet=">/dev/null 2>&1"; shift ;;
	-h | --help)
	    usage; shift ;;
	--)
	    shift; break ;;
	*)
	    break ;;
    esac
done


if "$show_labels"; then
    cat $PATH_CLASS_LABELS
    exit 1
fi


motion_label=`python3 utils/mocap_labels.py --label $bvhid --seed $seed`


# mogen options
model_path=$PATH_MOGEN/models/$mhxid.mhx2
motion_path=$PATH_MOGEN/mocap/$motion_label.bvh
camera=$camid

# 3D-ResNets-PyTorch options
root_path=data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
result_path=results/${mhxid}_${bvhid}_${cam_x}_${cam_y}_${cam_z}
dataset=makehuman
resume_path=models/MakeHuman-100k-31.pth
n_classes=31
model=resnet
model_depth=34
n_threads=`cat /proc/cpuinfo | grep processor | wc -l`
output_topk=$n_classes
inference_batch_size=1
inference_subset=test
inference_crop=nocrop  # (center|nocrop)


# Init.
mkdir -p $root_path/$result_path
if [ -e $root_path/$video_path ]; then
    rm -r $root_path/$video_path
fi


# Generate motion video
# if [ $cam_x -eq 0 ] && [ $cam_y -eq 0 ] && [ $cam_z -eq 0 ]; then
if [ `echo "$cam_x == 0" | bc` == 1 ] && [ `echo "$cam_y == 0" | bc` == 1 ] && [ `echo "$cam_z == 0" | bc` == 1 ]; then
    eval blender -noaudio -b -P $PATH_MOGEN/mogen.py -- \
	 --model $model_path \
	 --motion $motion_path \
	 --camera $camera \
	 --camera_constraint $camera_constraint \
	 --image_type $tmp_dir \
	 --floor_texture_path $floor_texture \
	 $checker_floor $quiet
else
    # Set camera location and rotation
    camera_loc="$cam_x $cam_y $cam_z"
    camera_rot="$cam_rx $cam_ry $cam_rz"

    eval blender -noaudio -b -P $PATH_MOGEN/mogen.py -- \
	 --model $model_path \
	 --motion $motion_path \
	 --camera $camera \
	 --location $camera_loc \
	 --rotation $camera_rot \
	 --camera_constraint $camera_constraint \
	 --image_type $tmp_dir \
	 --floor_texture_path $floor_texture \
	 $checker_floor $quiet
fi

if "$no_recognition"; then
    exit 1
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
if "$is_ave"; then
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
if ! "$is_ave"; then
    python3 utils/visualizer.py \
	    --root_path $root_path \
	    --annotation_path $annotation_path \
	    --result_path $result_path/test_no_average.json
fi
