#!/bin/bash
PATH_3D_RESNETS=../3D-ResNets-PyTorch
PATH_MOGEN=../mogen
PATH_MOCAP_LABELS=utils/mocap_labels.json

function usage() {
    cat <<EOM
Usage: $(basename "$0") [OPTION]...

    -m string	  Specify model ID (f00|...|f04|m00|...|m04)
    -l string	  Specify motion label (walk|run|jump|...), see utils/mocap_labels.json
    -r float	  Radius
    -i float	  Step for longitude/latitude (degrees)
    -s int	  Random seed for the label selection	  
    -q 		  Quiet
    -h 		  Help

EOM

    exit 1
}

function set_default() {
    mhxid=f00
    bvhid=walk
    lon_min=0
    lon_max=360
    lon_step=1
    lat_min=0
    lat_max=90
    lat_step=1
    radius=10
    seed=0
    quiet=">/dev/null 2>&1"
}

set_default

while getopts ":m:l:r:i:s:qh" OPT; do
    case $OPT in
	m)
	    mhxid=$OPTARG
	    ;;
	l)
	    bvhid=$OPTARG
	    ;;
	r)
	    radius=$OPTARG
	    ;;
	i)
	    lon_step=$OPTARG
	    lat_step=$OPTARG
	    ;;
	s)
	    seed=$OPTARG
	    ;;
	q)
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


# 3D-ResNets-PyTorch options
root_path=data
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
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


# progress bar
tot=$(((lon_max-lon_min)/lon_step * (lat_max-lat_min)/lat_step))
t_begin=$SECONDS
bar="=============================="


i=0
for lat in $(seq $lat_max -$lat_step $lat_min); do
    for lon in $(seq $lon_min $lon_step $lon_max); do
	# Generate motion video
	if [ -e $root_path/$video_path ]; then
	    rm -r $root_path/$video_path
	fi

	eval blender -b -noaudio -P sweep.py -- \
	     --model_path $model_path \
	     --motion_path $motion_path \
	     --radius $radius \
	     --longitude $lon \
	     --latitude $lat \
	     --id $i \
	     --root $root_path $quiet

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
	result_path=results/${i}_${bvhid}_${radius}_${lon}_${lat}
	mkdir -p $root_path/$result_path
	
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

	#printf "(i, longitude, latitude) = (%5d, %3.0f, %2.0f)\n" $i $lon $lat

	# progress bar
	per=$((100*i/tot))
	b=$((29*i/tot+1))
	t=$((SECONDS-t_begin))
	h=$((t/3600))
	m=$((t%3600/60))
	s=$((t%60))
	t_=$((t*(tot-i)/i))
	h_=$((t_/3600))
	m_=$((t_%3600/60))
	s_=$((t_%60))

	printf "%3d%% [%-30s] %d/%d [%02d:%02d:%02d<%02d:%02d:%02d]\r" \
	       $per ${bar:0:$b} $i $tot $h $m $s $h_ $m_ $s_

	((i++))
    done
done
