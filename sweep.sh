#!/bin/bash
PATH_3D_RESNETS=../3D-ResNets-PyTorch
PATH_MOGEN=../mogen
PATH_MOCAP_LABELS=utils/mocap_labels.json

function usage() {
    cat <<EOM
Usage: $(basename "$0") [OPTION]...

    -m, --model	  string	Specify model ID (f00|...|f04|m00|...|m04)
    -l, --label   string	Specify motion label (walk|run|jump|...), see utils/mocap_labels.json
    --r_min 	  float	  	Minimum radius (meters)
    --r_max 	  float	  	Maximum radius (meters)
    --r_step	  float	  	Radius step (meters)
    --lon_min 	  float	  	Minimum longitude (degrees)
    --lon_max	  float	  	Maximum longitude (degrees)
    --lon_step	  float	  	Longitude step (degrees)
    --lat_min	  float	  	Minimum latitude (degrees)
    --lat_max	  float	  	Maximum latitude (degrees)
    --lat_step	  float	  	Latitude step (degrees)
    -s, --seed 	  int	  	Random seed for the label selection	  
    -v, --verbose		Show blender stdout/stderr
    -h, --help 		  	Help

EOM

    exit 1
}

function set_default() {
    mhxid=f00
    bvhid=walk
    r_min=10
    r_max=10
    r_step=1
    lon_min=0
    lon_max=360
    lon_step=1
    lat_min=0
    lat_max=90
    lat_step=1
    seed=0
    quiet=">/dev/null 2>&1"
}

function echo_params() {
    [ -z "$quiet" ] && verbose=true || verbose=false
    
    printf "%s parameters %s\n" "-------------" "-------------"
    printf "           model: %s\n" $mhxid
    printf "           label: %s\n" $bvhid
    printf "    radius range: [%.1f, %.1f, %.1f]\n" $r_min $r_max $r_step
    printf " longitude range: [%.1f, %.1f, %.1f]\n" $lon_min $lon_max $lon_step
    printf "  latitude range: [%.1f, %.1f, %.1f]\n" $lat_min $lat_max $lat_step
    printf "     random seed: %d\n" $seed
    printf "         verbose: %s\n" $verbose
    printf "%s\n" "--------------------------------------"
}


OPTS=`getopt -o m:l:s:vh --long model:,label:,r_min:,r_max:,r_step:,lon_min:,lon_max:,lon_step:,lat_min:,lat_max:,lat_step:,seed:,verbose,help -n 'parse-options' -- "$@"`

if [ $? != 0 ]; then
    usage
fi

# echo "$OPTS"
eval set -- "$OPTS"

set_default

while true; do
    case "$1" in
	-m | --model)
	    mhxid=$2; shift; shift ;;
	-l | --label)
	    bvhid=$2; shift; shift ;;
	--r_min)
	    r_min=$2; shift; shift ;;
	--r_max)
	    r_max=$2; shift; shift ;;
	--r_step)
	    r_step=$2; shift; shift ;;
	--lon_min)
	    lon_min=$2; shift; shift ;;
	--lon_max)
	    lon_max=$2; shift; shift ;;
	--lon_step)
	    lon_step=$2; shift; shift ;;
	--lat_min)
	    lat_min=$2; shift; shift ;;
	--lat_max)
	    lat_max=$2; shift; shift ;;
	--lat_step)
	    lat_step=$2; shift; shift ;;
	-s | --seed)
	    seed=$2; shift; shift ;;
	-v | --verbose)
	    unset quiet; shift ;;
	-h | --help)
	    usage; shift ;;
	--)
	    shift; break ;;
	*)
	    break ;;
    esac
done

echo_params

# get label id
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
if [ `echo $r_min == $r_max | bc` -eq 1 ]; then
    tot=`echo "($lon_max+$lon_step-$lon_min)/$lon_step * ($lat_max+$lat_step-$lat_min)/$lat_step" | bc`
elif [ `echo $lon_min == $lon_max | bc` -eq 1 -a `echo $lat_min == $lat_max | bc` -eq 1 ]; then
    tot=`echo "($r_max+$r_step-$r_min)/$r_step" | bc`
elif [ `echo $lon_min == $lon_max | bc` -eq 1 ]; then
    tot=`echo "($r_max+$r_step-$r_min)/$r_step * ($lat_max+$lat_step-$lat_min)/$lat_step" | bc`
elif [ `echo $lat_min == $lat_max | bc` -eq 1 ]; then
    tot=`echo "($r_max+$r_step-$r_min)/$r_step * ($lon_max+$lon_step-$lon_min)/lon_step" | bc`
else
    tot=`echo "($r_max+$r_step-$r_min)/$r_step * ($lon_max+$lon_step-$lon_min)/$lon_step * ($lat_max+$lat_step-$lat_min)/$lat_step" | bc`
fi
t_begin=$SECONDS
bar="=============================="


i=0
for lat in $(seq $lat_max -$lat_step $lat_min); do
    for lon in $(seq $lon_min $lon_step $lon_max); do
	for r in $(seq $r_min $r_step $r_max); do
	    # Generate motion video
	    if [ -e $root_path/$video_path ]; then
	    	rm -r $root_path/$video_path
	    fi

	    eval blender -b -noaudio -P sweep.py -- \
	    	 --model_path $model_path \
	    	 --motion_path $motion_path \
	    	 --radius $r \
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
	    result_path=results/${i}_${bvhid}_${r}_${lon}_${lat}
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

	    ((i++))

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

	    printf "%3d%% [%-30s] %d/%d [%02d:%02d:%02d<%02d:%02d:%02d] | (r, lon, lat) = (%5.1f, %5.1f, %5.1f)\r" \
		   $per ${bar:0:$b} $i $tot $h $m $s $h_ $m_ $s_ $r $lon $lat
	done
    done
done

echo ""
