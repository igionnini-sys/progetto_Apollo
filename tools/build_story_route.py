"""Percorso pubblico narrativo: nessuna deduzione dell'abitazione o del cancello."""
import json
import math
from pathlib import Path
from import_osm import project, shortest

ROOT = Path(__file__).resolve().parents[1]
town = json.loads((ROOT/'data/map/volpiano.json').read_text(encoding='utf-8'))
school = project(45.1993144, 7.781281)
street = {tuple(p) for road in town['roads'] if road['name'] == 'Via Brandizzo' and road['drivable'] for p in road['points']}
candidates = [n for n, p in town['nodes'].items() if tuple(p) in street]
goal = min(candidates, key=lambda n: math.dist(town['nodes'][n], school))
route = shortest(town['nodes'], town['edges'], town['route'][0], goal)
assert '286093393' in route, 'Semaforo previsto non incluso nel nuovo percorso: verificare i dati.'
result = {'route': route, 'traffic_node': '286093393', 'school_lat_lon': [45.1993144, 7.781281],
          'metadata': {'preview': True, 'school_vehicle_access_verified': False, 'length_m': round(sum(math.dist(town['nodes'][a], town['nodes'][b]) for a, b in zip(route, route[1:]))),
                       'description': 'Partenza pubblica su Via Trento; sosta narrativa su Via Brandizzo; ultimo tratto a piedi raccontato, non simulato.',
                       'attribution': '© OpenStreetMap contributors', 'license': 'ODbL 1.0'}}
(ROOT/'data/map/story_route.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Percorso narrativo: {len(route)-1} segmenti, {result["metadata"]["length_m"]} m; accesso carrabile scolastico non attivato')
