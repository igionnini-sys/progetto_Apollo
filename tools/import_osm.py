"""Estratto OSM offline per Apollo. Solo libreria standard, Python 3.11+."""
import argparse
import heapq
import json
import math
from pathlib import Path
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
BBOX = (45.185, 7.758, 45.211, 7.788)
ORIGIN = (45.198, 7.773)
DRIVABLE = {'residential', 'unclassified', 'tertiary', 'secondary', 'living_street', 'service'}
QUERY = ('[out:json][timeout:60];('
         f'way["highway"]{BBOX};way["building"]{BBOX};'
         f'relation["type"="restriction"]{BBOX};);out body;>;out skel qt;')
DETAIL_QUERY = ('[out:json][timeout:60];('
                f'node["highway"~"^(crossing|traffic_signals)$"]{BBOX};'
                f'node["natural"="tree"]{BBOX};node["amenity"="bench"]{BBOX};'
                f'way["amenity"="school"]{BBOX};);out body;>;out skel qt;')


def project(lat, lon, origin=ORIGIN, scale=1.0):
    """Piano equirettangolare locale: X est, Z sud; un'unità = un metro."""
    return [round(math.radians(lon-origin[1])*6371000*math.cos(math.radians(origin[0]))*scale, 3),
            round(-math.radians(lat-origin[0])*6371000*scale, 3)]


def direction(tags):
    value = tags.get('oneway:motor_vehicle', tags.get('oneway', ''))
    if value == '-1':
        return -1
    if value in {'yes', '1', 'true'} or (not value and tags.get('junction') == 'roundabout'):
        return 1
    if value in {'', 'no', '0', 'false'}:
        return 0
    return None  # reversibile/alternato: escluso finché non verificato


def accessible(tags):
    if tags.get('highway') not in DRIVABLE or tags.get('area') == 'yes':
        return False
    if any('conditional' in k for k in tags):
        return False  # nessun tentativo di indovinare orari o deroghe
    access = next((tags[k] for k in ('motorcar', 'motor_vehicle', 'vehicle', 'access') if k in tags), 'yes')
    return access in {'yes', 'permissive', 'designated'} and direction(tags) is not None


def road_profile(tags):
    """Aspetto della via separato dai permessi di guida. Misure mancanti stimate."""
    kind = tags.get('highway', '')
    carriageway = kind in DRIVABLE | {'primary', 'primary_link', 'secondary_link', 'tertiary_link', 'trunk', 'trunk_link', 'motorway', 'motorway_link'}
    fallback = 7.0 if kind in {'primary', 'secondary', 'tertiary'} else 6.0
    try:
        width = float(tags.get('width', fallback))
        if not math.isfinite(width) or not 2.0 <= width <= 25.0:
            width = fallback
    except (ValueError, TypeError):
        width = fallback
    return {'highway': kind, 'carriageway': carriageway, 'width': width if carriageway else 3.0,
            'sidewalk': tags.get('sidewalk', 'left' if tags.get('sidewalk:left') == 'yes' else 'both' if carriageway else 'no')}


def shortest(nodes, edges, start, goal):
    adjacency = {key: [] for key in nodes}
    for a, b in edges:
        adjacency[a].append(b)
    queue = [(0.0, start)]
    costs, previous = {start: 0.0}, {}
    while queue:
        cost, current = heapq.heappop(queue)
        if cost != costs[current]:
            continue
        if current == goal:
            route = [goal]
            while route[-1] != start:
                route.append(previous[route[-1]])
            return route[::-1]
        for other in adjacency[current]:
            candidate = cost + math.dist(nodes[current], nodes[other])
            if candidate < costs.get(other, math.inf):
                costs[other], previous[other] = candidate, current
                heapq.heappush(queue, (candidate, other))
    raise ValueError('Nessun percorso accessibile: non generare collegamenti fittizi.')


def convert(raw, origin=ORIGIN, scale=1.0):
    elements = raw['elements']
    locations = {str(e['id']): project(e['lat'], e['lon'], origin, scale) for e in elements if e['type'] == 'node'}
    # Conservativo: escludere tutte le vie coinvolte in restrizioni di svolta.
    # Mantiene percorsi validi senza fingere supporto completo delle relazioni OSM.
    restricted = {m['ref'] for e in elements if e['type'] == 'relation'
                  and e.get('tags', {}).get('type') == 'restriction'
                  for m in e.get('members', []) if m['type'] == 'way'}
    roads, buildings, edges, nodes = [], [], [], {}
    for e in elements:
        if e['type'] != 'way':
            continue
        tags = e.get('tags', {})
        ids = [str(n) for n in e['nodes']]
        if any(n not in locations for n in ids):
            continue
        if 'building' in tags and ids[0] == ids[-1]:
            buildings.append({'id': e['id'], 'outline': [locations[n] for n in ids],
                              'kind': tags.get('building', 'yes'),
                              'public_name': tags.get('name', '') if tags.get('amenity') in {'townhall', 'school', 'place_of_worship'} else '',
                              'levels': tags.get('building:levels', ''),
                              'roof_shape': tags.get('roof:shape', ''),
                              'commercial': tags.get('building') in {'retail', 'commercial'} or 'shop' in tags})
        # Via Trieste esclusa dalla guida in attesa di verifica della strada scolastica.
        allowed = accessible(tags) and e['id'] not in restricted and tags.get('name') != 'Via Trieste'
        if 'highway' not in tags:
            continue
        roads.append({'id': e['id'], 'name': tags.get('name', ''), 'points': [locations[n] for n in ids],
                      'drivable': allowed, 'oneway': direction(tags) or 0,
                      **road_profile(tags)})
        if allowed:
            nodes.update({n: locations[n] for n in ids})
            for a, b in zip(ids, ids[1:]):
                if a == b:
                    continue
                if direction(tags) != -1:
                    edges.append([a, b])
                if direction(tags) != 1:
                    edges.append([b, a])
    return {'metadata': {'source': 'OpenStreetMap', 'attribution': '© OpenStreetMap contributors',
                         'license': 'ODbL 1.0', 'source_timestamp': raw.get('osm3s', {}).get('timestamp_osm_base'),
                         'bbox': BBOX, 'origin': origin, 'scale': scale,
                         'school_access_verified': False,
                         'restriction_policy': 'Exclude all ways in turn restriction relations; exclude conditional access and Via Trieste'},
            'nodes': nodes, 'edges': edges, 'roads': roads, 'buildings': buildings}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--download', action='store_true')
    parser.add_argument('--download-details', action='store_true')
    parser.add_argument('--config', type=Path, help='Configurazione privata sotto local/, mai distribuita')
    args = parser.parse_args()
    source = ROOT/'local/volpiano.osm.json'
    details_source = ROOT/'local/volpiano.details.osm.json'
    if args.download_details:
        details_source.parent.mkdir(exist_ok=True)
        url = 'https://overpass-api.de/api/interpreter?' + urllib.parse.urlencode({'data': DETAIL_QUERY})
        with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Apollo-local-prototype/0.3'}), timeout=90) as response:
            payload = response.read()
        details = json.loads(payload)
        if details.get('remark'):
            raise ValueError(details['remark'])
        details_source.write_bytes(payload)
    if args.download:
        source.parent.mkdir(exist_ok=True)
        url = 'https://overpass-api.de/api/interpreter?' + urllib.parse.urlencode({'data': QUERY})
        request = urllib.request.Request(url, headers={'User-Agent': 'Apollo-local-prototype/0.2'})
        with urllib.request.urlopen(request, timeout=90) as response:
            payload = response.read()
        raw = json.loads(payload)
        if raw.get('remark'):
            raise ValueError(raw['remark'])
        source.write_bytes(payload)
    raw = json.loads(source.read_text(encoding='utf-8'))
    config = {}
    if args.config:
        private_path = args.config.resolve()
        if not private_path.is_relative_to((ROOT/'local').resolve()):
            raise ValueError('La configurazione privata deve essere in local/.')
        config = json.loads(private_path.read_text(encoding='utf-8'))
    scale = float(config.get('scale', 1.0))
    if not math.isfinite(scale) or scale <= 0:
        raise ValueError('Scala non valida.')
    origin = tuple(config.get('origin', ORIGIN))
    data = convert(raw, origin, scale)
    data['features'] = []
    if details_source.exists():
        details = json.loads(details_source.read_text(encoding='utf-8'))
        data['metadata']['details_timestamp'] = details.get('osm3s', {}).get('timestamp_osm_base')
        for e in details['elements']:
            tags = e.get('tags', {})
            if e['type'] != 'node':
                continue
            kind = tags.get('highway', tags.get('natural', tags.get('amenity', '')))
            if kind in {'crossing', 'traffic_signals', 'tree', 'bench'}:
                data['features'].append({'id': e['id'], 'kind': kind, 'point': project(e['lat'], e['lon'], origin, scale)})
    # Partenza pubblica su Via Trento: nessun civico privato, nessuna ricostruzione casa.
    def street_nodes(name):
        ways = [e for e in raw['elements'] if e['type'] == 'way' and e.get('tags', {}).get('name') == name]
        return sorted({str(n) for e in ways for n in e['nodes'] if str(n) in data['nodes']})
    starts = street_nodes('Via Trento')
    goals = street_nodes('Via Brandizzo')
    if not starts or not goals:
        raise ValueError('Vie di riferimento mancanti nell’estratto.')
    # Estremo nord di Via Brandizzo, avvicinamento pubblico al quartiere scolastico.
    goal = min(goals, key=lambda n: data['nodes'][n][1])
    start = min(starts, key=lambda n: math.dist(data['nodes'][n], data['nodes'][goal]))
    if 'spawn_lat_lon' in config:
        xy = project(*config['spawn_lat_lon'], origin, scale)
        start = min(data['nodes'], key=lambda n: math.dist(data['nodes'][n], xy))
        if math.dist(data['nodes'][start], xy) > 30 * scale:
            raise ValueError('Partenza distante dai nodi stradali: verificare manualmente il punto.')
    data['route'] = shortest(data['nodes'], data['edges'], start, goal)
    data['metadata']['route_description'] = 'Esplorazione Via Trento → Via Brandizzo; non accesso scolastico'
    # Anche la rotta derivata da coordinate private resta locale.
    destination = ROOT/('local/volpiano.private.json' if args.config else 'data/map/volpiano.json')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')), encoding='utf-8')
    print(f'{len(data["roads"])} vie, {len(data["nodes"])} nodi, {len(data["edges"])} archi; percorso {len(data["route"])} nodi')


if __name__ == '__main__':
    main()
