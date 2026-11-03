"""Percorso pubblico narrativo: nessuna deduzione dell'abitazione o del cancello."""
import json
import math
from pathlib import Path
from import_osm import project, shortest

ROOT = Path(__file__).resolve().parents[1]
town = json.loads((ROOT/'data/map/volpiano.json').read_text(encoding='utf-8'))
school = project(45.1993144, 7.781281)
by_id = {str(n): p for n, p in town['nodes'].items()}


def nodes_of(name):
    points = {tuple(p) for road in town['roads'] if road['name'] == name and road['drivable'] for p in road['points']}
    return [n for n, p in by_id.items() if tuple(p) in points]


# Percorso di Apollo: Via Trento (Via Pasubio) -> fondo di Via Pasubio -> Via Novara a destra,
# sottopasso ferroviario -> Via Trieste (SP3) fino alla scuola primaria.
# I tratti intermedi sono archi accessibili: nessun collegamento inventato.
pasubio_start = '837373613'   # Via Trento / Via Pasubio
pasubio_end = '1057112725'    # fondo di Via Pasubio, svolta in Via Novara
underpass = '1393836074'      # sottopasso (maxheight 3,6 m) verso Via Trieste
trieste = nodes_of('Via Trieste')
goal = min(trieste, key=lambda n: math.dist(by_id[n], school))
waypoints = [pasubio_start, pasubio_end, underpass, goal]
route = [waypoints[0]]
for a, b in zip(waypoints, waypoints[1:]):
    route += shortest(town['nodes'], town['edges'], a, b)[1:]
names = {}
for road in town['roads']:
    for p in road['points']:
        names.setdefault(tuple(p), set()).add(road['name'])
for n, label in [(pasubio_end, 'Via Pasubio'), (underpass, 'Via Novara')]:
    assert n in by_id and n in route, f'Tappa mancante nel percorso: {label}'
assert any('Via Pasubio' in names[tuple(by_id[n])] for n in route), 'Via Pasubio non percorsa'
assert any('Via Novara' in names[tuple(by_id[n])] for n in route), 'Via Novara non percorsa'
assert sum('Via Trieste' in names[tuple(by_id[n])] for n in route) > 10, 'Via Trieste non percorsa per intero'
# Semaforo di gioco all'incrocio Via Trieste/Via Fiume, poco prima della scuola: regola narrativa, non impianto reale.
traffic_node = '921141638'
assert traffic_node in route[1:-1], 'Semaforo previsto non incluso nel percorso: verificare i dati.'
result = {'route': route, 'traffic_node': traffic_node, 'school_lat_lon': [45.1993144, 7.781281],
          'metadata': {'preview': True, 'school_vehicle_access_verified': False, 'length_m': round(sum(math.dist(town['nodes'][a], town['nodes'][b]) for a, b in zip(route, route[1:]))),
                       'description': 'Via Trento, Via Pasubio, Via Novara con sottopasso, poi tutta Via Trieste fino alla scuola primaria; ultimo tratto a piedi raccontato, non simulato.',
                       'attribution': '© OpenStreetMap contributors', 'license': 'ODbL 1.0'}}
(ROOT/'data/map/story_route.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Percorso narrativo: {len(route)-1} segmenti, {result["metadata"]["length_m"]} m; accesso carrabile scolastico non attivato')
