import glob
import json
import matplotlib.pyplot as plt
import numpy as np
import os
import re


class SweepData:
    def __init__(self, root):
        self.root = root
        self.init()

    def init(self):
        self._results = self.load(self.root)
        self._results = sorted(self._results, key=lambda x: x['id'])
        self._step_phi = self._results[1]['location'][1] - self._results[0]['location'][1]
        self._step_theta = self._results[0]['location'][2] - self._results[int(360/self._step_phi)+1]['location'][2]

    def load(self, root):
        ret = []
        for p in glob.glob(os.path.join(root, '*')):
            f_test = os.path.join(p, 'test.json')
            if not os.path.exists(f_test):
                continue
            
            with open(f_test, 'r') as f:
                res = json.load(f)
                
            for k, v in res['results'].items():
                tmp = {}
                m = re.match(r'(\d+)-(.+?)-(.+?)-loc(-*\d*\.*\d*)_(-*\d*\.*\d*)_(-*\d*\.*\d*)-rot(-*\d+\.*\d*)_(-*\d+\.*\d*)_(-*\d+\.*\d*)*', k)
                tmp['id'] = int(m.group(1))
                tmp['model'] = m.group(2)
                tmp['label'] = m.group(3)
                tmp['location'] = float(m.group(4)), float(m.group(5)), float(m.group(6))
                tmp['rotation'] = float(m.group(7)), float(m.group(8)), float(m.group(9))
                tmp['prediction'] = v
                ret.append(tmp)
                
        return ret
    
    def write(self, dst):
        with open(dst, 'w') as f:
            json.dump(self._results, f, indent=4)

    def results(self):
        return self._results

    def heatmap(self, label):
        h = int((90+self._step_theta)/self._step_theta)
        w = int((360+self._step_phi)/self._step_phi)
        
        self.hmap = np.zeros((h,w)) * np.nan
        for i, res in enumerate(self._results):
            r, phi, theta = res['location']
            model = res['model']
            for pred in res['prediction']:
                if pred['label'] == label:
                    u = i % w
                    v = i // w
                    self.hmap[v,u] = pred['score']
                    break

        return self.hmap

    def plot(self, hmap=None, projection='polar', save_path=None):
        hmap = hmap if hmap else self.hmap
        
        fig, ax = plt.subplots(figsize=(6,4))
        ax = plt.subplot(projection=projection)
        
        if projection == 'polar':
            lon = np.linspace(0, np.pi*2, int((360+self._step_phi)/self._step_phi))
            lat = np.linspace(0, np.pi/2, int((90+self._step_theta)/self._step_theta))
            Lon, Lat = np.meshgrid(lon, lat)
        
            im = ax.pcolormesh(Lon, Lat, hmap, vmin=0, vmax=1)
            
            ax.set_yticks(np.radians([0, 30, 45, 60, 90]))
            yticks = np.around(np.degrees(ax.get_yticks()))
            yticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in yticks]
            ax.set_yticklabels(yticklabels)
            
            fig.colorbar(im, ax=ax, orientation='vertical', aspect=30)
        elif projection == 'mollweide':
            lon = np.linspace(-np.pi, np.pi, int((360+self._step_phi)/self._step_phi))
            lat = np.linspace(np.pi/2, 0, int((90+self._step_theta)/self._step_theta))
            Lon, Lat = np.meshgrid(lon, lat)
            
            im = ax.pcolormesh(Lon, Lat, hmap, vmin=0, vmax=1)
            
            xticks = np.around(180+np.degrees(ax.get_xticks()))
            yticks = np.around(90-np.degrees(ax.get_yticks()))
            xticklabels = ["\n${:.0f}^{{\circ}}$".format(_) for _ in xticks]
            yticklabels = ['${:.0f}^{{\circ}}$'.format(_) if _ <= 90 else '' for _ in yticks]
            ax.set_xticklabels(xticklabels, va='top')
            ax.set_yticklabels(yticklabels)
            
            fig.colorbar(im, ax=ax, orientation='horizontal', aspect=50)
        else:
            im = ax.imshow(hmap, interpolation='none', vmin=0, vmax=1)
            
            ax.set_xticks(np.arange(0, (360+self._step_phi)//self._step_phi, 60//self._step_phi))
            ax.set_yticks(np.arange(0, (90+self._step_theta)//self._step_theta, 30//self._step_theta))
            xticks = ax.get_xticks() * self._step_phi
            yticks = ax.get_yticks() * self._step_theta
            xticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in xticks]
            yticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in yticks]
            ax.set_xticklabels(xticklabels)
            ax.set_yticklabels(yticklabels)
            ax.set_xlabel('longitude')
            ax.set_ylabel('latitude')
            
            fig.colorbar(im, ax=ax, orientation='horizontal', aspect=50)
            
        ax.grid(linewidth=0.75, linestyle='--')
        fig.tight_layout()

        if save_path:
            d = os.path.dirname(save_path)
            if not os.path.exists(d):
                os.makedirs(d)
            fig.savefig(save_path)
        
    def step_phi(self):
        return self._step_phi
    
    def step_theta(self):
        return self._step_theta
    
