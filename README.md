# video-classification-simulator
Video classification simulator by using [3D-ResNets-PyTorch][3d-resnets-pytorch].

<img src="imgs/demo.gif" width="640px">

[3d-resnets-pytorch]: https://github.com/kenshohara/3D-ResNets-PyTorch


## Installation
On Ubuntu 18.04

Clone [mogen][mogen] repository:

    $ git clone https://github.com/ishitsuka-hikaru/mogen.git
    
Clone [3D-ResNets-PyTorch for MakeHuman][3d-resnets-pytorch-makehuman] repository:

    $ git clone https://github.com/ishitsuka-hikaru/3D-ResNets-PyTorch.git
    
Each module installation and usage refere to its README.md.

Edit line-1, line-2 in run_sim.sh:

    run_sim.sh
    1  #!/bin/bash
    2  PATH_3D_RESNETS=<3D-ResNets-PyTorch repository>
    3  PATH_MOGEN=<mogen repository>
    4  ...

[mogen]: https://github.com/ishitsuka-hikaru/mogen
[3d-resnets-pytorch-makehuman]: https://github.com/ishitsuka-hikaru/3D-ResNets-PyTorch


# Usage
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
    
where "f00" is MakeHuman model (female 00), "walk" is ground-truth video label, "1" is camera angle (camera 1).


# Reference
- <https://github.com/kenshohara/3D-ResNets-PyTorch>
