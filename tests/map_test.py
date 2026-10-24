"""Verifica importazione e vincoli geografici senza dipendenze esterne."""
import json
import math
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from import_osm import accessible, convert, direction, project, shortest, road_profile


class MapTests(unittest.TestCase):
    def test_road_appearance_independent_of_access(self):
        for tags in [{'highway': 'primary'}, {'highway': 'tertiary', 'access': 'private'}]:
            self.assertTrue(road_profile(tags)['carriageway'])
            self.assertFalse(accessible(tags))
        self.assertFalse(road_profile({'highway': 'footway'})['carriageway'])
        self.assertEqual(road_profile({'highway': 'tertiary', 'width': '8.5'})['width'], 8.5)
        for value in ['nan', '-2', 'unknown']:
            self.assertEqual(road_profile({'highway': 'tertiary', 'width': value})['width'], 7.0)

    def test_projection(self):
        self.assertEqual(project(45.198, 7.773), [0.0, 0.0])
        self.assertAlmostEqual(project(45.199, 7.773)[1], -111.195, places=2)
        self.assertGreater(project(45.198, 7.774)[0], 78)

    def test_direction(self):
        for tags, expected in [({'oneway': 'yes'}, 1), ({'oneway': '-1'}, -1),
                               ({'junction': 'roundabout'}, 1),
                               ({'junction': 'roundabout', 'oneway': 'no'}, 0),
                               ({'oneway': 'reversible'}, None)]:
            self.assertEqual(direction(tags), expected)

    def test_access(self):
        for tags in [{'access': 'private'}, {'motor_vehicle': 'no'},
                     {'access': 'destination'}, {'access:conditional': 'no @ (08:00-09:00)'},
                     {'highway': 'footway'}, {'oneway': 'alternating'}]:
            self.assertFalse(accessible({'highway': 'residential', **tags}))
        self.assertTrue(accessible({'highway': 'residential', 'access': 'no', 'motorcar': 'yes'}))

    def test_directed_graph(self):
        raw = {'elements': [
            {'type': 'node', 'id': n, 'lat': 45.198, 'lon': 7.773 + n*0.001} for n in range(1, 5)] + [
            {'type': 'way', 'id': 1, 'nodes': [1, 2], 'tags': {'highway': 'residential', 'oneway': '-1'}},
            {'type': 'way', 'id': 2, 'nodes': [2, 3], 'tags': {'highway': 'residential', 'access': 'private'}},
            {'type': 'way', 'id': 3, 'nodes': [3, 4], 'tags': {'highway': 'residential', 'oneway': 'yes'}}]}
        data = convert(raw)
        self.assertEqual(data['edges'], [['2', '1'], ['3', '4']])
        self.assertEqual(shortest(data['nodes'], data['edges'], '2', '1'), ['2', '1'])
        with self.assertRaises(ValueError):
            shortest(data['nodes'], data['edges'], '1', '2')

    def test_turn_relation_exclusion(self):
        raw = {'elements': [
            {'type': 'node', 'id': n, 'lat': 45.198, 'lon': 7.773+n*.001} for n in [1, 2]] + [
            {'type': 'way', 'id': 5, 'nodes': [1, 2], 'tags': {'highway': 'residential'}},
            {'type': 'relation', 'id': 6, 'tags': {'type': 'restriction'},
             'members': [{'type': 'way', 'ref': 5, 'role': 'from'}]}]}
        self.assertEqual(convert(raw)['edges'], [])

    def test_real_route(self):
        data = json.loads((Path(__file__).resolve().parents[1]/'data/map/volpiano.json').read_text(encoding='utf-8'))
        edges = {tuple(edge) for edge in data['edges']}
        route = data['route']
        self.assertGreater(len(route), 2)
        self.assertTrue(all((a, b) in edges for a, b in zip(route, route[1:])))
        self.assertGreater(sum(math.dist(data['nodes'][a], data['nodes'][b]) for a, b in zip(route, route[1:])), 400)
        self.assertFalse(data['metadata']['school_access_verified'])
        self.assertTrue(all(not r['drivable'] for r in data['roads'] if r['name'] == 'Via Trieste'))
        self.assertNotIn('addr:housenumber', json.dumps(data))

    def test_town_source_data(self):
        root = Path(__file__).resolve().parents[1]
        data = json.loads((root/'data/map/volpiano.json').read_text(encoding='utf-8'))
        self.assertTrue({417795500, 897476177, 215468999}.issubset({b['id'] for b in data['buildings']}))
        self.assertEqual(sum(f['kind'] == 'traffic_signals' for f in data['features']), 3)
        self.assertGreater(sum(f['kind'] == 'crossing' for f in data['features']), 50)
        self.assertTrue(all(len(f['point']) == 2 and all(math.isfinite(v) for v in f['point']) for f in data['features']))
        self.assertNotIn('addr:street', json.dumps(data))
        # Se l'estratto di sviluppo esiste, verifica le coordinate contro la fonte, non copie di costanti.
        source = root/'local/volpiano.details.osm.json'
        if source.exists():
            raw = json.loads(source.read_text(encoding='utf-8'))
            original = {e['id']: e for e in raw['elements'] if e['type'] == 'node'}
            for feature in data['features']:
                node = original[feature['id']]
                self.assertEqual(feature['point'], project(node['lat'], node['lon']))


if __name__ == '__main__':
    unittest.main()
