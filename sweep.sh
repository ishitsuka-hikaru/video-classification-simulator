#!/bin/bash
PATH_3D_RESNETS=../3D-ResNets-PyTorch
PATH_PRETRAIN=pretrain/MakeHuman-100k-31.pth
PATH_MOGEN=../mogen
PATH_MOCAP_LABELS=utils/mocap_labels.json
PATH_CLASS_LABELS=$PATH_3D_RESNETS/util_scripts/makehuman-31.json
DEBUG_MODE=true

function usage() {
    cat << EOM
Usage: $(basename "$0") [OPTION]...

    -m, --model			string	Specify model ID (f00|...|f04|m00|...|m04)
    -l, --label   		string	Specify motion label (walk|run|jump|...), see utils/mocap_labels.json
    --r_min 	  		float	Minimum radius (meters), default 10
    --r_max 	  		float	Maximum radius (meters), default 10
    --r_step	  		float	Radius step (meters), default 1
    --r_fixed			float	Fixed radius (meters)
    --lon_min 	  		float	Minimum longitude (degrees), default 0
    --lon_max	  		float	Maximum longitude (degrees), default 360
    --lon_step	  		float	Longitude step (degrees), default 1
    --lat_min	  		float	Minimum latitude (degrees), default 0
    --lat_max	  		float	Maximum latitude (degrees), default 90
    --lat_step	  		float	Latitude step (degrees), default 1
    --lat_fixed			float	Fixed latitude (degrees)
    --show_labels			Show all ground-truth class labels
    -d, --destination		string	Destination of result files, default ./data_<TIMESTAMP>
    -c, --camera_constraint	string	Active camera control (none|track_to|copy_location|track_and_copy), default none
    -s, --seed 	  		int	Random seed for the label selection
    -r, --retry		       	int	Number of retry, default 10
    -v, --verbose			Show blender stdout/stderr
    -g, --gen_sample			Generate sample animation, not eval
    -h, --help 		  		Help

EOM

    exit 1
}

function set_default() {
    mhxid=f00
    bvhid=walk
    r_min=10
    r_max=10
    r_step=1
    r_fixed=-1
    lon_min=0
    lon_max=360
    lon_step=1
    lat_min=0
    lat_max=90
    lat_step=1
    lat_fixed=-1
    show_labels=false
    root_path=data_`date "+%s"`
    camera_constraint=none
    seed=0
    retry=10
    is_sample=false
    quiet=">/dev/null 2>&1"
}

function echo_params() {
    [ -z "$quiet" ] && verbose=true || verbose=false
    
    printf "%s parameters %s\n" "-------------" "-------------"
    printf "   makehuman model: %s\n" $mhxid
    printf "      motion label: %s\n" $bvhid
    printf "         motion id: %s\n" $motion_id
    printf "      radius range: [%.1f, %.1f, %.1f]\n" $r_min $r_max $r_step
    printf "   longitude range: [%.1f, %.1f, %.1f]\n" $lon_min $lon_max $lon_step
    printf "    latitude range: [%.1f, %.1f, %.1f]\n" $lat_min $lat_max $lat_step
    printf " camera constraint: %s\n" $camera_constraint
    printf "       random seed: %d\n" $seed
    printf "             retry: %d\n" $retry
    printf "       sample mode: %s\n" $is_sample
    printf "           verbose: %s\n" $verbose
    printf "         root path: %s\n" $root_path
    printf "%s\n" "--------------------------------------"
}

function write_params() {
    cat << EOM > $root_path/params.json
{
	"makehuman_model": "$mhxid",
	"motion_label": "$bvhid",
	"motion_id": "$motion_id",
	"r_range": [$r_min, $r_max, $r_step],
	"lon_range": [$lon_min, $lon_max, $lon_step],
	"lat_range": [$lat_min, $lat_max, $lat_step],
	"camera_constraint": "$camera_constraint",
	"random_seed": $seed,
	"retry": $retry,
	"pretrain_model": "`basename $resume_path`"
}
EOM
}


OPTS=`getopt -o m:l:d:c:s:r:gvh --long model:,label:,r_min:,r_max:,r_step:,r_fixed:,lon_min:,lon_max:,lon_step:,lat_min:,lat_max:,lat_step:,lat_fixed:,show_labels,destination:,camera_constraint:,seed:,retry:,gen_sample,verbose,help -n 'parse-options' -- "$@"`

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
	--r_min)
	    r_min=$2; shift; shift ;;
	--r_max)
	    r_max=$2; shift; shift ;;
	--r_step)
	    r_step=$2; shift; shift ;;
	--r_fixed)
	    r_fixed=$2; shift; shift ;;
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
	--lat_fixed)
	    lat_fixed=$2; shift; shift ;;
	--show_labels)
	    show_labels=true; shift ;;
	-d | --destination)
	    root_path=$2; shift; shift ;;
	-c | --camera_constraint)
	    camera_constraint=$2; shift; shift ;;
	-s | --seed)
	    seed=$2; shift; shift ;;
	-r | --retry)
	    retry=$2; shift; shift ;;
	-g | --gen_sample)
	    is_sample=true; shift ;;
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


# get label id
motion_label=`python3 utils/mocap_labels.py --label $bvhid --seed $seed`
motion_id=`basename $motion_label`


# mogen options
model_path=$PATH_MOGEN/models/$mhxid.mhx2
motion_path=$PATH_MOGEN/mocap/$motion_label.bvh


# 3D-ResNets-PyTorch options
#root_path=data_`date "+%s"`
video_path=makehuman_videos/jpg
annotation_path=makehuman.json
dataset=makehuman
resume_path=models/`basename $PATH_PRETRAIN`
n_classes=31
model=resnet
model_depth=34
n_threads=`cat /proc/cpuinfo | grep processor | wc -l`
output_topk=$n_classes
inference_batch_size=1
inference_subset=test
inference_crop=nocrop  # (center | nocrop)


if "$show_labels"; then
    cat $PATH_CLASS_LABELS
    exit 1
fi

if ! "$is_sample"; then
    mkdir -p $root_path/models
    cp $PATH_PRETRAIN $root_path/models
else
    lat_min=30
    lat_max=30
fi

if [ $r_fixed -ge 0 ]; then
    r_min=$r_fixed
    r_max=$r_fixed
fi

if [ $lat_fixed -ge 0 ]; then
    lat_min=$lat_fixed
    lat_max=$lat_fixed
fi


# progress bar
if "$is_sample"; then
    tot=1  # dammy
elif [ `echo $r_min == $r_max | bc` -eq 1 ]; then
    tot=`echo "(($lon_max-$lon_min)/$lon_step+1) * (($lat_max-$lat_min)/$lat_step+1)" | bc`
elif [ `echo $lon_min == $lon_max | bc` -eq 1 -a `echo $lat_min == $lat_max | bc` -eq 1 ]; then
    tot=`echo "($r_max-$r_min)/$r_step+1" | bc`
elif [ `echo $lon_min == $lon_max | bc` -eq 1 ]; then
    tot=`echo "(($r_max-$r_min)/$r_step+1) * (($lat_max-$lat_min)/$lat_step+1)" | bc`
elif [ `echo $lat_min == $lat_max | bc` -eq 1 ]; then
    tot=`echo "(($r_max-$r_min)/$r_step+1) * (($lon_max-$lon_min)/$lon_step+1)" | bc`
else
    tot=`echo "(($r_max-$r_min)/$r_step+1) * (($lon_max-$lon_min)/$lon_step+1) * (($lat_max-$lat_min)/$lat_step+1)" | bc`
fi

if [ $tot -eq 0 -o -z $tot ]; then
    echo "scan range invalid"
    usage
fi


echo_params
if ! "$is_sample"; then
    write_params
fi


t_begin=$SECONDS
bar="=============================="
i=0
for lat in $(seq $lat_max -$lat_step $lat_min); do
    for lon in $(seq $lon_min $lon_step $lon_max); do
	for r in $(seq $r_min $r_step $r_max); do

	    if ! $DEBUG_MODE; then
		retry_cnt=0
		while [ $retry_cnt -lt $retry ]; do
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
			 --camera_constraint $camera_constraint \
	    		 --id $i \
	    		 --root $root_path $quiet

		    if "$is_sample"; then
			dst=${mhxid}_${bvhid}_${motion_id}_${camera_constraint}.mp4
			./utils/jpg2mp4.sh $root_path/$video_path/*/*/ $dst
			printf "sample generation succeeded\n"
			printf "\tfilepath: %s\n" `realpath $dst`
			break 3
		    fi

		    # Make annotation file
		    python3 $PATH_3D_RESNETS/util_scripts/makehuman_json.py \
	    		    --root $root_path \
	    		    --dataset $dataset \
	    		    --min_inst 1 \
	    		    --mocap_labels $PATH_MOCAP_LABELS \
	    		    --data_split testing \
	    		    --filename $annotation_path \
	    		    --class_labels $PATH_CLASS_LABELS \
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

		    if [ -e $root_path/$result_path/test.json ]; then
			break
		    fi
		    ((retry_cnt++))
		done
	    fi

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

	    printf "%3d%% [%-30s] %d/%d [%02d:%02d:%02d<%02d:%02d:%02d] | %4.1f, %5.1f, %4.1f\r" \
		   $per ${bar:0:$b} $i $tot $h $m $s $h_ $m_ $s_ $r $lon $lat
	done
    done
done


echo ""
if "$DEBUG_MODE"; then
    rm -fr $root_path
fi

if "$is_sample"; then
    rm -fr $root_path
else
    rm -fr $root_path/models
fi
