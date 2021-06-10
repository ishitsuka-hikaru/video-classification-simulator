import glob
import json
import matplotlib.pyplot as plt
import numpy as np
import os
import re


class SweepData:
    def __init__(self, root, fixed_axis='r', r_range=None, lon_range=None, lat_range=None):
        self.root = root
        self.fixed_axis = fixed_axis  # "r" or "lat"

        if isinstance(r_range, list) and len(r_range) == 3:
            self.r_min, self.r_max, self.r_step = r_range
        if isinstance(lon_range, list) and len(lon_range) == 3:
            self.lon_min, self.lon_max, self.lon_step = np.radians(lon_range)
        if isinstance(lat_range, list) and len(lat_range) == 3:
            self.lat_min, self.lat_max, self.lat_step = np.radians(lat_range)
        
        self.init()

    def init(self):
        self._results = self.load(self.root)
        self._results = sorted(self._results, key=lambda x: x['id'])

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

    def get_data(self, location):
        for res in self._results:
            if location == res['location']:
                return res

    def heatmap(self, label):
        if self.fixed_axis == 'r':
            h = int((self.lat_max - self.lat_min) / self.lat_step) + 1
            w = int((self.lon_max - self.lon_min) / self.lon_step) + 1
        elif self.fixed_axis == 'lat':
            h = int((self.r_max - self.r_min) / self.r_step) + 1
            w = int((self.lon_max - self.lon_min) / self.lon_step) + 1

        self.hmap = np.zeros((h,w)) * np.nan
        self.data = []
        for res in self._results:
            i = res['id']
            r, phi, theta = res['location']
            for pred in res['prediction']:
                if pred['label'] == label:
                    s = pred['score']
                    if self.fixed_axis == 'r':
                        u = i % w
                        v = i // w
                    elif self.fixed_axis == 'lat':
                        u = i // h
                        v = i % h
                    self.hmap[v,u] = s
                    self.data.append([r, phi, theta, s])
                    break

        return self.hmap, np.array(self.data)

    def plot(self, hmap=None, projection=None, save_path=None, aspect=1.0, figsize=None, grid=True, title=None):
        hmap = self.hmap if hmap is None else hmap
        
        if projection == 'polar':
            figsize = figsize if figsize else (5, 4)
            fig, ax = plt.subplots(figsize=figsize)
            ax = plt.subplot(projection=projection)

            if self.fixed_axis == 'r':
                lon = np.arange(self.lon_min, self.lon_max + self.lon_step, self.lon_step) - np.pi
                lat = np.arange(self.lat_max, self.lat_min - self.lat_step, -self.lat_step)
            elif self.fixed_axis == 'lat':
                lon = np.arange(self.lon_min, self.lon_max + self.lon_step, self.lon_step) - np.pi
                lat = np.arange(self.r_min, self.r_max + self.r_step, self.r_step)

            Lon, Lat = np.meshgrid(lon, lat)
            im = ax.pcolormesh(Lon, Lat, hmap, vmin=0, vmax=1)
            xticks = [np.degrees(_-np.pi) for _ in ax.get_xticks()]
            xticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in xticks]
            ax.set_xticklabels(xticklabels)

            if self.fixed_axis == 'r':
                ax.set_yticks(np.radians([0, 30, 45, 60, 90]))
                yticks = np.around(np.degrees(ax.get_yticks()))
                yticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in yticks]
                ax.set_yticklabels(yticklabels)
                ax.invert_yaxis()

            if np.nanmedian(hmap) < 0.3:
                ax.tick_params(axis='y', colors='white')

            fig.colorbar(im, ax=ax, orientation='vertical', aspect=30, pad=0.1)
        elif projection == 'mollweide' or projection == 'hammer' or projection == 'rectilinear':
            figsize = figsize if figsize else (7, 2.5)
            fig, ax = plt.subplots(figsize=figsize)
            ax = plt.subplot(projection=projection)

            if self.fixed_axis == 'r':
                lon = np.arange(self.lon_min, self.lon_max + self.lon_step, self.lon_step)
                lat = np.arange(self.lat_max, self.lat_min - self.lat_step, -self.lat_step)
            elif self.fixed_axis == 'lat':
                lon = np.arange(self.lon_min, self.lon_max + self.lon_step, self.lon_step)
                lat = np.arange(np.pi/2 - self.r_min/self.r_max*np.pi/2, -self.r_step/self.r_max*np.pi/2, -self.r_step/self.r_max*np.pi/2)
                                
            Lon, Lat = np.meshgrid(lon, lat)
            im = ax.pcolormesh(Lon, Lat, hmap, vmin=0, vmax=1)
            
            xticks = np.around(np.degrees(ax.get_xticks()))
            xticklabels = ["\n${:.0f}^{{\circ}}$".format(_) for _ in xticks]
            ax.set_xticklabels(xticklabels, va='top')

            if self.fixed_axis == 'r':
                yticks = np.around(np.degrees(ax.get_yticks()))
                yticklabels = ['${:.0f}^{{\circ}}$'.format(_) if _ >= 0 else '' for _ in yticks]
            elif self.fixed_axis == 'lat':
                yticks = np.linspace(-self.r_max, self.r_max, 11)
                yticklabels = ['{:.0f}'.format(abs(_-self.r_max)) if _ >= 0 else '' for _ in yticks]
            ax.set_yticklabels(yticklabels)
            
            fig.colorbar(im, ax=ax, aspect=20, pad=0.02)
        else:
            if self.fixed_axis == 'lat':
                h, w = hmap.shape
                h = 1 if self.r_min < self.r_step else self.r_min // self.r_step
                offset = np.zeros((h,w)) * np.nan
                hmap = np.vstack([offset, hmap.copy()])

            figsize = figsize if figsize else (7, 1.9)
            fig, ax = plt.subplots(figsize=figsize)
            ax = plt.subplot(projection=projection)
            im = ax.imshow(hmap, interpolation='none', vmin=0, vmax=1, aspect=aspect)
            ax.set_xticks(np.arange(0, np.pi*2/self.lon_step+1, np.pi/3/self.lon_step))
            xticks = ax.get_xticks() * np.degrees(self.lon_step) - 180
            xticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in xticks]
            ax.set_xticklabels(xticklabels)
            ax.set_xlabel('longitude')
            
            if self.fixed_axis == 'r':
                ax.set_yticks(np.arange(0, np.pi/2/self.lat_step+1, np.pi/6/self.lat_step))
                yticks = ax.get_yticks() * np.degrees(self.lat_step)
                yticklabels = ['${:.0f}^{{\circ}}$'.format(_) for _ in yticks]
                ax.set_yticklabels(yticklabels)
                ax.set_ylabel('latitude')
                ax.invert_yaxis()
            elif self.fixed_axis == 'lat':
                ax.set_ylabel('radius')
            
            fig.colorbar(im, ax=ax, aspect=15, pad=0.02)

        if grid:
            ax.grid(linewidth=0.6, linestyle='--')

        if title:
            ax.set_title(title, loc='left')
            
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
