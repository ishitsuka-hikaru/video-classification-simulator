import glob
import json
import matplotlib.pyplot as plt
import numpy as np
import os
import re


class SweepData:
    def __init__(self, root, dtype='hemi'):
        self.root = root
        self.dtype = dtype
        self.init()

    def init(self):
        self._results = self.load(self.root)
        self._results = sorted(self._results, key=lambda x: x['id'])

        if self.dtype == 'rad':
            pass
        else:
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
        assert self.dtype == 'hemi', 'this method is not available for this data'
            
        # h = int((90+self._step_theta)/self._step_theta)
        # w = int((360+self._step_phi)/self._step_phi)
        #h = int(90/self._step_theta + self._step_theta)
        h = int(90/self._step_theta)+1
        #w = int(360/self._step_phi + self._step_phi)
        w = int(360/self._step_phi)+1
        
        self.hmap = np.zeros((h,w)) * np.nan
        for i, res in enumerate(self._results):
            r, phi, theta = res['location']
            model = res['model']
            for pred in res['prediction']:
                if pred['label'] == label:
                    u = i % w
                    v = i // w
                    #v = self.hmap.shape[0]-1 - i // w
                    self.hmap[v,u] = pred['score']
                    break

        return self.hmap

    def plot_heatmap(self, hmap=None, projection=None, save_path=None):
        assert self.dtype == 'hemi', 'this method is not available for this data'
        
        hmap = self.hmap if hmap is None else hmap
        
        if projection == 'polar':
            fig, ax = plt.subplots(figsize=(5,4))
            ax = plt.subplot(projection=projection)
        
            #lon = np.linspace(0, np.pi*2, int((360+self._step_phi)/self._step_phi))
            lon = np.linspace(0, np.pi*2, int(360/self._step_phi)+1)
            #lat = np.linspace(0, np.pi/2, int((90+self._step_theta)/self._step_theta))
            lat = np.linspace(0, np.pi/2, int(90/self._step_theta)+1)
            Lon, Lat = np.meshgrid(lon, lat)
        
            im = ax.pcolormesh(Lon, Lat, hmap, vmin=0, vmax=1)

            xticks = [np.degrees(_-np.pi) for _ in ax.get_xticks()]
            xticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in xticks]
            ax.set_xticklabels(xticklabels)
            
            ax.set_yticks(np.radians([0, 30, 45, 60, 90]))
            yticks = np.around(np.degrees(ax.get_yticks()))
            yticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in yticks]
            ax.set_yticklabels(yticklabels)
            ax.invert_yaxis()

            fig.colorbar(im, ax=ax, orientation='vertical', aspect=30, pad=0.1)
        elif projection == 'mollweide':
            fig, ax = plt.subplots(figsize=(5,3))
            ax = plt.subplot(projection=projection)
        
            #lon = np.linspace(-np.pi, np.pi, int((360+self._step_phi)/self._step_phi))
            #lon = np.linspace(-np.pi, np.pi, int(360/self._step_phi + self._step_phi))
            lon = np.linspace(-np.pi, np.pi, int(360/self._step_phi)+1)
            #lat = np.linspace(0, np.pi/2, int((90+self._step_theta)/self._step_theta))
            #lat = np.linspace(0, np.pi/2, int(90/self._step_theta + self._step_theta))
            lat = np.linspace(0, np.pi/2, int(90/self._step_theta)+1)
            Lon, Lat = np.meshgrid(lon, lat)
            
            im = ax.pcolormesh(Lon, Lat, hmap, vmin=0, vmax=1)
            
            xticks = np.around(np.degrees(ax.get_xticks()))
            yticks = np.around(np.degrees(ax.get_yticks()))
            xticklabels = ["\n${:.0f}^{{\circ}}$".format(_) for _ in xticks]
            yticklabels = ['${:.0f}^{{\circ}}$'.format(_) if _ >= 0 else '' for _ in yticks]
            ax.set_xticklabels(xticklabels, va='top')
            ax.set_yticklabels(yticklabels)
            
            fig.colorbar(im, ax=ax, orientation='horizontal', aspect=50, pad=0.05)
        else:
            fig, ax = plt.subplots(figsize=(7,3))
            ax = plt.subplot(projection=projection)
        
            im = ax.imshow(hmap, interpolation='none', vmin=0, vmax=1)
            
            #ax.set_xticks(np.arange(0, (360+self._step_phi)//self._step_phi, 60//self._step_phi))
            #ax.set_xticks(np.arange(0, 360/self._step_phi + self._step_phi, 60/self._step_phi))
            ax.set_xticks(np.arange(0, 360/self._step_phi+1, 60/self._step_phi))
            #ax.set_yticks(np.arange(0, (90+self._step_theta)//self._step_theta, 30//self._step_theta))
            ax.set_yticks(np.arange(0, 90/self._step_theta+1, 30/self._step_theta))
            xticks = ax.get_xticks() * self._step_phi - 180
            yticks = ax.get_yticks() * self._step_theta
            xticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in xticks]
            yticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in yticks]
            ax.set_xticklabels(xticklabels)
            ax.set_yticklabels(yticklabels)
            ax.set_xlabel('longitude')
            ax.set_ylabel('latitude')
            ax.invert_yaxis()
            
            fig.colorbar(im, ax=ax, orientation='horizontal', aspect=60, pad=0.2)
            
        ax.grid(linewidth=0.75, linestyle='--')
        fig.tight_layout()

        if save_path:
            d = os.path.dirname(save_path)
            if not os.path.exists(d):
                os.makedirs(d)
            fig.savefig(save_path)

    def plot_radius_dependency(self, label):
        assert self.dtype == 'rad', 'this method is not available for this data'

        X, Y = [], []
        for res in self._results:
            r, phi, theta = res['location']
            model = res['model']
            for pred in res['prediction']:
                if pred['label'] == label:
                    X.append(r)
                    Y.append(pred['score'])
                    break

        fig, ax = plt.subplots(figsize=(5,4))
        ax.plot(X, Y, lw=1)
        ax.set(xlabel='radius [m]', ylabel=f'likelihood of "{label}"')
        ax.set_ylim(-0.01, 1.01)
        ax.set_title(f'model, longitude, latitude = {model}, ${phi}^\circ$, ${theta}^\circ$', fontsize=10)
        fig.tight_layout()

    def step_phi(self):
        return self._step_phi
    
    def step_theta(self):
        return self._step_theta
