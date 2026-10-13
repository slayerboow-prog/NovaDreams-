import numpy as np, json, sys
from scipy import ndimage
D = sys.argv[1]
S = 8.0; X0 = -5000; Z0 = -4400
free = np.load(f'{D}/free.npy'); h = np.load(f'{D}/height.npy')
er = ndimage.binary_erosion(free, iterations=4)  # >= 64 studs de ancho
lab, n = ndimage.label(er)
sizes = ndimage.sum(er, lab, range(1, n + 1))
dt = ndimage.distance_transform_edt(free) * S
out = []
for i, s in enumerate(sizes, 1):
    a = s * S * S
    if a < 40000:
        continue
    m = lab == i
    ys, xs = np.nonzero(m)
    k = np.argmax(np.where(m, dt, 0))
    ky, kx = np.unravel_index(k, m.shape)
    flat = (m & (h < 6)).sum() / m.sum()
    out.append(dict(id=i, area=int(a), cx=int(X0 + xs.mean() * S), cz=int(Z0 + ys.mean() * S), x0=int(X0 + xs.min() * S), x1=int(X0 + xs.max() * S),
                    z0=int(Z0 + ys.min() * S), z1=int(Z0 + ys.max() * S), maxr=int(dt[ky, kx]), bx=int(X0 + kx * S), bz=int(Z0 + ky * S), flat=round(float(flat), 2)))
out.sort(key=lambda o: -o['area'])
for o in out:
    print(o)
np.save(f'{D}/lab.npy', lab)
json.dump(out, open(f'{D}/comps.json', 'w'))
