import argparse
import json
import os
import random


class MocapLabels:
    def __init__(self, mocap_labels_path):
        self.mocap_labels_path = mocap_labels_path
        self.mocap_labels = self.load(mocap_labels_path)

    def load(self, fname):
        with open(fname, 'r') as f:
            return json.load(f)

    def get_motion_ids(self, label):
        ret = []
        for k, v in self.mocap_labels.items():
            if v['label'] == label:
                ret.append(k)
        return ret

    def get_motion_labels(self):
        ret = []
        for k, v in self.mocap_labels.items():
            ret.append(v['label'])
        return set(ret)

    def get_motion_id(self, label, seed=0):
        random.seed(seed)
        ids = self.get_motion_ids(label)
        return random.choice(ids)

    def get_motion_path(self, label, seed=0):
        base = self.get_motion_id(label, seed)
        dir, _ = base.split('_')
        return os.path.join(dir, base)


def get_opts():
    p = argparse.ArgumentParser()
    p.add_argument('--label', type=str, default='walk')
    p.add_argument('--mocap_labels', type=str, default='utils/mocap_labels.json')
    p.add_argument('--seed', type=int, default=0)
    p.add_argument('--show_labels', action='store_true')
    return p.parse_args()

    
if __name__ == '__main__':
    opt = get_opts()
    ml = MocapLabels(opt.mocap_labels)

    if opt.show_labels:
        print(ml.get_motion_labels())
    else:
        print(ml.get_motion_path(opt.label, opt.seed))
