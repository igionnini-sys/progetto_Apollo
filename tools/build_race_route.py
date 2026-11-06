"""Percorso del livello 2 (sprint A->B): Via Trento -> Corso Regina Margherita (SP40/SP39) -> Via Pinetti.
Usa solo archi del grafo OSM già presente; aggiorna data/levels/level2_race.json mantenendo i campi esistenti."""
import json
import math
from pathlib import Path
from import_osm import shortest

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'data/levels/level2_race.json'
town = json.loads((ROOT / 'data/map/volpiano.json').read_text(encoding='utf-8'))
by_id = {str(n): p for n, p in town['nodes'].items()}
names = {}
widths = {}
for road in town['roads']:
    for p in road['points']:
        names.setdefault(tuple(p), set()).add(road['name'])
        widths[tuple(p)] = min(widths.get(tuple(p), 99.0), road.get('width', 6.0))

START = '837373700'   # Via Trento, all'altezza di Via Ortigara
GOAL = '6205243006'   # Via Pinetti, fine di Corso Regina Margherita
route = shortest(town['nodes'], town['edges'], START, GOAL)
assert any('Via Trento' in names[tuple(by_id[n])] for n in route), 'Via Trento non percorsa'
assert sum('Corso Regina Margherita' in names[tuple(by_id[n])] for n in route) > 15, 'Corso Regina Margherita non percorso'
assert 'Via Pinetti' in names[tuple(by_id[route[-1]])], 'Arrivo non in Via Pinetti'

points = [by_id[n] for n in route]
cumulative = [0.0]
for a, b in zip(points, points[1:]):
    cumulative.append(cumulative[-1] + math.dist(a, b))
length = cumulative[-1]


def at(distance):
    for i in range(1, len(points)):
        if cumulative[i] >= distance:
            t = (distance - cumulative[i - 1]) / max(cumulative[i] - cumulative[i - 1], 1e-6)
            a, b = points[i - 1], points[i]
            return [round(a[0] + (b[0] - a[0]) * t, 2), round(a[1] + (b[1] - a[1]) * t, 2)], i - 1
    return list(points[-1]), len(points) - 2


def heading_change(i):
    if i <= 0 or i >= len(points) - 1:
        return 0.0
    a = math.atan2(points[i][0] - points[i - 1][0], points[i][1] - points[i - 1][1])
    b = math.atan2(points[i + 1][0] - points[i][0], points[i + 1][1] - points[i][1])
    return abs((b - a + math.pi) % (2 * math.pi) - math.pi)


sharp = [(round(cumulative[i]), round(math.degrees(heading_change(i)))) for i in range(len(points)) if heading_change(i) > math.radians(50)]
min_width = min(widths[tuple(p)] for p in points)

# Elementi di gara: cassette ogni ~130 m, strisce turbo ogni ~220 m, punti di controllo ogni ~250 m.
# Cassette e strisce a lato/centro corsia sono rifinite in L2-3/L2-5; qui solo la distanza lungo il percorso.
def series(step, offset):
    out, d = [], offset
    while d < length - 60:
        pos, seg = at(d)
        out.append({'distance': round(d), 'position': pos})
        d += step
    return out


def heading_at(distance):
    a, i = at(max(distance - 4.0, 0.0))
    b, j = at(min(distance + 4.0, length))
    return math.atan2(b[0] - a[0], b[1] - a[1])


def is_straight(distance):
    """Rettilineo davanti: le strisce turbo non vanno messe prima di una curva."""
    for t in range(int(distance) - 10, int(distance) + 75, 5):
        if t < 0 or t > length:
            return False
        turn = abs((heading_at(t + 9) - heading_at(t - 9) + math.pi) % (2 * math.pi) - math.pi)
        if turn > math.radians(8):
            return False
    return True


def boost_pads(spacing=320, first=60):
    out, d = [], first
    while d < length - 90:
        if is_straight(d):
            pos, seg = at(d)
            out.append({'distance': round(d), 'position': pos})
            d += spacing
        else:
            d += 10
    return out


data = json.loads(OUT.read_text(encoding='utf-8'))
data.update({
    'status': 'percorso generato da OSM (L2-0); da verificare a mano in gioco',
    'format': 'sprint',
    'laps': 1,
    'start_node': START,
    'goal_node': GOAL,
    'length_m': round(length),
    'route_nodes': route,
    'route': [[round(p[0], 2), round(p[1], 2)] for p in points],
    'checkpoints': series(250, 250),
    'boost_pads': boost_pads(),
    'item_pickups': series(130, 90),
    'review': {'sharp_turns_deg_at_m': sharp, 'min_road_width_m': min_width},
})
OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Percorso gara: {len(points)} punti, {round(length)} m, larghezza minima {min_width} m; curve secche (m, gradi): {sharp}')
