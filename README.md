# video-classification-simulator
Video classification simulator by using [3D-ResNets-PyTorch][3d-resnets-pytorch].

<img src="imgs/demo.gif" width="640px">

[3d-resnets-pytorch]: https://github.com/kenshohara/3D-ResNets-PyTorch


## Requirements
- Python 3.x
- PyTorch 1.x
- Blender 2.79b
- FFmpeg
- GNU Bash 4.x


## Installation
On Ubuntu 18.04

Clone [mogen][mogen] repository:

    $ git clone https://github.com/ishitsuka-hikaru/mogen.git
    
Clone [3D-ResNets-PyTorch for MakeHuman][3d-resnets-pytorch-makehuman] repository:

    $ git clone https://github.com/ishitsuka-hikaru/3D-ResNets-PyTorch.git
    
Each module installation and usage refere to its README.md.

Edit line-2, line-3 in run_sim.sh:

    run_sim.sh
    1  #!/bin/bash
    2  PATH_3D_RESNETS=<3D-ResNets-PyTorch repository>
    3  PATH_MOGEN=<mogen repository>
    4  ...

Download pre-train model from [here][makehuman-100k-31] (only AIST internal).  
This model is trained on Kinetics-700, and fine-tuned by MakeHuman-100k dataset.

Make directory and move to the model:

    $ mkdir -p data/models && mv <MakeHuman-100k-31.pth> data/models    

[mogen]: https://github.com/ishitsuka-hikaru/mogen
[3d-resnets-pytorch-makehuman]: https://github.com/ishitsuka-hikaru/3D-ResNets-PyTorch
[makehuman-100k-31]: https://aistmail-my.sharepoint.com/:u:/g/personal/ishitsuka_hikaru_aist_go_jp/EQfx3gQlaVREpqPcj0b_DyMBouq0d-57N6QKxQyzI4sBkQ?e=9PPLUE


# Usage
## Demo

Show help:

    $ ./run_sim.sh -h
    Usage: run_sim.sh [OPTION]...

    -m string     Specify model ID (f00|...|f04|m00|...|m04)
    -l string     Specify motion label (walk|run|jump|...), see utils/mocap_labels.json
    -s int        Random seed for the label selection
    -c int        Specify camera angle (1|2|3|4)
    -q            Quiet
    -h            Help

Run simulation:

    $ ./run_sim.sh -m f00 -l walk -c 1
    
where "f00" is MakeHuman model name (female-00), "walk" is ground-truth video label, "1" is camera angle (camera 1).

Result is here by default:

    $ ls data/mp4/
    f00-107_03-loc3.0_-3.0_3.0-rot60_0_45-end102_walk.mp4
    $ ls data/results/
    opts.json  test_no_average.json


## Sweep mode
Generate heatmap

    $ ./sweep.sh -h
	Usage: sweep.sh.tmp4 [OPTION]...
	
	    -m, --model                 string  Specify model ID (f00|...|f04|m00|...|m04)
		-l, --label                 string  Specify motion label (walk|run|jump|...), see utils/mocap_labels.json
		--r_min                     float   Minimum radius (meters), default 10
		--r_max                     float   Maximum radius (meters), default 10
		--r_step                    float   Radius step (meters), default 1
		--r_fixed                   float   Fixed radius (meters)
		--lon_min                   float   Minimum longitude (degrees), default 0
		--lon_max                   float   Maximum longitude (degrees), default 360
		--lon_step                  float   Longitude step (degrees), default 1
		--lat_min                   float   Minimum latitude (degrees), default 0
		--lat_max                   float   Maximum latitude (degrees), default 90
		--lat_step                  float   Latitude step (degrees), default 1
		--lat_fixed                 float   Fixed latitude (degrees)
		-c, --camera_constraint     string  Active camera control (none|track_to|copy_location|track_and_copy), default none
		-s, --seed                  int     Random seed for the label selection
		-r, --retry                 int     Number of retry, default 10
		-v, --verbose                       Show blender stdout/stderr
		-g, --gen_sample                    Generate sample animation, not eval
		-h, --help                          Help
																				
    
# Reference
- <https://github.com/kenshohara/3D-ResNets-PyTorch>
