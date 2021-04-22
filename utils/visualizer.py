import argparse
import cv2
import glob
import json
import numpy as np
import os
import re
import shutil
import subprocess


class Visualizer:
    def __init__(
            self,
            root_path,
            annotation_path,
            result_path,
            output_path,
            img_type='jpg',
            tmp_dir='.vis'
    ):
        self.root_path = root_path
        self.annotation_path = os.path.join(root_path, annotation_path)
        self.result_path = os.path.join(root_path, result_path)
        self.output_path = os.path.join(root_path, output_path)
        self.img_type = img_type
        self.tmp_dir = tmp_dir

        if not os.path.exists(self.output_path):
            os.makedirs(self.output_path)

        if os.path.exists(tmp_dir):
            shutil.rmtree(tmp_dir)
        os.makedirs(tmp_dir)

        self._annotation = self.load(self.annotation_path)
        self._result = self.load(self.result_path)

    def load(self, fname):
        with open(fname, 'r') as f:
            return json.load(f)

    def labels(self):
        return sorted(self._annotation['labels'])

    def annotation(self):
        return self._annotation['database']

    def result(self):
        return self._result['results']
    
    def visualize(self, topk=1):
        for k, vals in self.annotation().items():
            video_id = k
            video_path = vals['video_path']
            label = vals['annotations']['label']
                
        output = os.path.join(self.output_path, f'{video_id}_{label}.mp4')
        result = self.result()
        preds = result[video_id]
        assert os.path.exists(video_path), f'video_path not found: {video_path}'
        
        videos = glob.glob(os.path.join(video_path, f'*.{self.img_type}'))
        for pred in preds:
            seg_beg, seg_end = pred['segment']
            for img_path in sorted(videos):
                m = re.match(
                    r'image_(\d+).{}'.format(self.img_type),
                    os.path.basename(img_path)
                )
                fid = int(m.group(1))
                
                if fid < seg_beg and seg_end > fid:
                    continue
            
                img = cv2.imread(img_path)
                nrows, ncols = img.shape[:2]
                for i, p in enumerate(pred['result'][:topk]):
                    cv2.putText(
                        img,
                        f"{p['label']}: {p['score']:5.1%}",
                        (ncols//50, nrows//10*(i+1)),
                        cv2.FONT_HERSHEY_DUPLEX,
                        0.75,
                        (0,255,0)
                    )
                    cv2.imwrite(
                        os.path.join(self.tmp_dir, '{:05d}.jpg'.format(fid)),
                        img
                    )
                    
        # ffmpeg: jpg to mp4
        cmd = f'ffmpeg -y -framerate 16 -i {self.tmp_dir}/%05d.{self.img_type} -vcodec libx264 -pix_fmt yuv420p -r 16 {output} -loglevel quiet'
        subprocess.run(cmd, shell=True)
                    
        # delete tmp
        shutil.rmtree(self.tmp_dir)
                    
        return {'video_id': video_id, 'label': label, 'output': output}


def get_opts():
    p = argparse.ArgumentParser()
    p.add_argument('--root_path', type=str, default='data')
    p.add_argument('--annotation_path', type=str, default='makehuman.json')
    p.add_argument('--result_path', type=str, default='results/test_no_average.json')
    p.add_argument('--output_path', type=str, default='mp4')
    p.add_argument('--img_type', type=str, default='jpg')
    p.add_argument('--tmp_dir', type=str, default='.vis')
    return p.parse_args()
    
if __name__ == '__main__':
    opt = get_opts()
    vis = Visualizer(
        opt.root_path,
        opt.annotation_path,
        opt.result_path,
        opt.output_path,
        opt.img_type,
        opt.tmp_dir
    )
    ret = vis.visualize()
    print(ret)
    
