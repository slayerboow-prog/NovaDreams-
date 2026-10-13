import sys, json
D = sys.argv[1]
want = {"Manzana_Parque", "Manzana_Campo", "Manzana_Deporte"}
out = []
for line in open(f'{D}/parts.tsv'):
    c = line.rstrip('\n').split('\t')
    if c[8] == 'BlockGround' and c[9] in want:
        xs, zs = [], []
        for k in c[7].split(';'):
            x, y, z = map(float, k.split(',')); xs.append(x); zs.append(z)
        out.append(dict(kind=c[9].split('_')[1], x0=int(min(xs)), x1=int(max(xs)), z0=int(min(zs)), z1=int(max(zs)), cx=int(sum(xs) / 8), cz=int(sum(zs) / 8)))
plan = json.load(open(f'{D}/plan.json'))
def inside(poly, x, z):
    c = False; j = len(poly) - 1
    for i in range(len(poly)):
        xi, zi = poly[i]; xj, zj = poly[j]
        if (zi > z) != (zj > z) and x < (xj - xi) * (z - zi) / (zj - zi) + xi:
            c = not c
        j = i
    return c
for o in out:
    o['district'] = next((d['Id'] for d in plan['Districts'] if inside(d['Poly'], o['cx'], o['cz'])), '-')
out.sort(key=lambda o: (o['kind'], o['district'], o['cx']))
for o in out:
    print(o['kind'], o['district'], o['cx'], o['cz'], o['x1'] - o['x0'], 'x', o['z1'] - o['z0'])
json.dump(out, open(f'{D}/blocks.json', 'w'))
