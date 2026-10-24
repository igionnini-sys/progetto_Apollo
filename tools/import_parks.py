"""Crea il catalogo offline dei parchi e brevi avvicinamenti su archi OSM."""
import argparse
import json
import math
from pathlib import Path
import urllib.parse
import urllib.request
from import_osm import project

ROOT = Path(__file__).resolve().parents[1]
QUERY = '[out:json][timeout:60];(nwr["leisure"~"^(park|playground)$"](45.18,7.75,45.22,7.80););out body;>;out skel qt;'


def generate(manifest, source, town):
    by_id = {e['id']: e for e in source['elements'] if e['type'] == 'node'}
    ways = {e['id']: e for e in source['elements'] if e['type'] == 'way'}
    parks = []
    for item in manifest['parks']:
        park = dict(item)
        if park.get('osm_way'):
            way = ways[park['osm_way']]
            if way.get('tags', {}).get('leisure') != 'playground':
                raise ValueError('Impronta non confermata come area giochi.')
            points = [by_id[n] for n in way['nodes'][:-1]]
            # Centroide areale dell'impronta, senza spostarla sul percorso stradale.
            polygon = [project(p['lat'], p['lon']) for p in points]
            pairs = list(zip(polygon, polygon[1:]+polygon[:1]))
            area = sum(a[0]*b[1]-b[0]*a[1] for a, b in pairs)
            center = [sum((a[j]+b[j])*(a[0]*b[1]-b[0]*a[1]) for a, b in pairs)/(3*area) for j in range(2)]
            park['lat'] = 45.198-math.degrees(center[1]/6371000)
            park['lon'] = 7.773+math.degrees(center[0]/6371000/math.cos(math.radians(45.198)))
            park['outline_lat_lon'] = [[p['lat'], p['lon']] for p in points]
        xy = project(park['lat'], park['lon'])
        goal = min(town['nodes'], key=lambda n: math.dist(town['nodes'][n], xy))
        if math.dist(town['nodes'][goal], xy) > 50:
            raise ValueError('Nessun nodo stradale accessibile vicino al parco.')
        incoming = [(a, b) for a, b in town['edges'] if b == goal
                    and 10 < math.dist(town['nodes'][a], town['nodes'][b]) < 100]
        if not incoming:
            raise ValueError('Avvicinamento stradale non disponibile.')
        start, _ = max(incoming, key=lambda edge: math.dist(town['nodes'][edge[0]], town['nodes'][edge[1]]))
        park['route'] = [start, goal]
        if park['id'] == 'san_grato':
            a, b = town['nodes'][start], town['nodes'][goal]
            park['yaw'] = math.atan2(b[0]-a[0], b[1]-a[1])
        parks.append(park)
    return {'metadata': {'verified_on': manifest['verified_on'], 'source_timestamp': source['osm3s']['timestamp_osm_base'],
                         'attribution': '© OpenStreetMap contributors', 'license': 'ODbL 1.0',
                         'visit_mode': 'Selezione dal menu; breve avvicinamento locale, non itinerario dal centro città'},
            'parks': parks, 'pending': manifest['pending']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--download', action='store_true')
    args = parser.parse_args()
    path = ROOT/'local/volpiano.parks.osm.json'
    if args.download:
        url = 'https://overpass-api.de/api/interpreter?' + urllib.parse.urlencode({'data': QUERY})
        with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Apollo-local-prototype/0.4'}), timeout=90) as response:
            payload = response.read()
        raw = json.loads(payload)
        if raw.get('remark'):
            raise ValueError(raw['remark'])
        path.parent.mkdir(exist_ok=True)
        path.write_bytes(payload)
    source = json.loads(path.read_text(encoding='utf-8'))
    manifest = json.loads((ROOT/'data/map/park_sources.json').read_text(encoding='utf-8'))
    town = json.loads((ROOT/'data/map/volpiano.json').read_text(encoding='utf-8'))
    result = generate(manifest, source, town)
    (ROOT/'data/map/parks.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'{len(result["parks"])} parchi visitabili; {len(result["pending"])} da verificare')


if __name__ == '__main__':
    main()
