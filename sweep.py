MOGEN_PATH = '../mogen/'
import argparse
import numpy as np
import os
import shutil
import subprocess
import sys
sys.path.append(MOGEN_PATH)
from mogen import HumanMotionGenerator


def get_opts():
    p = argparse.ArgumentParser()
    p.add_argument('--model_path', type=str)
    p.add_argument('--motion_path', type=str)
    p.add_argument('--results', type=str, default='results/sweep')
    p.add_argument('--radius', type=float)
    p.add_argument('--longitude', type=float)
    p.add_argument('--latitude', type=float)
    p.add_argument('--camera_constraint', type=str, default='none')
    p.add_argument('--id', type=int)
    p.add_argument('--root', type=str, default='data')
    p.add_argument('--video_type', type=str, default='makehuman_videos')
    p.add_argument('--image_type', type=str, default='jpg')
    return p.parse_args(sys.argv[sys.argv.index('--')+1:])


if __name__ == '__main__':
    opt = get_opts()
    r = opt.radius
    phi = np.radians(opt.longitude)
    theta = np.radians(opt.latitude)

    if not os.path.exists(opt.results):
        os.makedirs(opt.results)
    
    h = HumanMotionGenerator()
    h.remove_temporary_files()
    h.import_mhx2(opt.model_path)
    h.load_and_retarget(opt.motion_path)

    x = r * np.sin(theta) * np.cos(phi)
    y = r * np.sin(theta) * np.sin(phi)
    z = r * np.cos(theta)
    loc = x, y, z
    #rot = 90-opt.latitude, 0, opt.longitude+90
    rot = opt.latitude, 0, opt.longitude+90
    
    h.set_camera_location(loc)
    h.set_camera_rotation(rot)

    if opt.camera_constraint == 'track_to':
        h.track_to()
    elif opt.camera_constraint == 'copy_location':
        h.copy_location()
    elif opt.camera_constraint == 'track_and_copy':
        h.track_to()
        h.copy_location()

    model_name = os.path.basename(opt.model_path)[:-5]
    class_name = os.path.basename(opt.motion_path)[:-4]
    loc_name = f'{r:.1f}_{opt.longitude:.0f}_{opt.latitude:.0f}'
    rot_name = '{:.0f}_{:.0f}_{:.0f}'.format(*rot)
    frame_end = h.get_frame_end()
    
    video_name = f'{opt.id:05d}-'
    video_name += f'{model_name}-'
    video_name += f'{class_name}-'
    video_name += f'loc{loc_name}-'
    video_name += f'rot{rot_name}-'
    video_name += f'end{frame_end}'

    savedir = os.path.join(
        opt.root, opt.video_type, opt.image_type, class_name, video_name
    )
    h.render_anim(savedir)
