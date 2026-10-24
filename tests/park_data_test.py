"""Vincoli geografici e riproducibilità del catalogo parchi."""
import json
import math
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools'))
from import_osm import project
from import_parks import generate


def inside(p, polygon):
    result = False
    for a, b in zip(polygon, polygon[1:]+polygon[:1]):
        if (a[1] > p[1]) != (b[1] > p[1]) and p[0] < (b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:
            result = not result
    return result


def corners(park):
    x, z = project(park['lat'], park['lon'])
    w, d = park['size']
    yaw = park['yaw']
    return [[x+math.cos(yaw)*a+math.sin(yaw)*b, z-math.sin(yaw)*a+math.cos(yaw)*b]
            for a, b in [(-w/2, -d/2), (w/2, -d/2), (w/2, d/2), (-w/2, d/2)]]


class ParkDataTests(unittest.TestCase):
    def setUp(self):
        self.catalog = json.loads((ROOT/'data/map/parks.json').read_text(encoding='utf-8'))
        self.town = json.loads((ROOT/'data/map/volpiano.json').read_text(encoding='utf-8'))

    def test_accessible_approaches(self):
        edges = {tuple(e) for e in self.town['edges']}
        for park in self.catalog['parks']:
            a, b = park['route']
            self.assertIn((a, b), edges)
            self.assertLess(math.dist(self.town['nodes'][b], project(park['lat'], park['lon'])), 50)

    def test_mapped_boundary(self):
        park = next(p for p in self.catalog['parks'] if p['id'] == 'madonna')
        outline = [project(*p) for p in park['outline_lat_lon']]
        self.assertTrue(all(inside(c, outline) for c in corners(park)))

    def test_no_building_overlap(self):
        for park in self.catalog['parks']:
            rectangle = corners(park)
            samples = rectangle + [[sum(p[i] for p in rectangle)/4 for i in range(2)]]
            for building in self.town['buildings']:
                outline = building['outline'][:-1]
                self.assertFalse(any(inside(p, outline) for p in samples), (park['id'], building['id']))
                self.assertFalse(any(inside(p, rectangle) for p in outline), (park['id'], building['id']))

    def test_unverified_locations_not_active(self):
        active = {p['id'] for p in self.catalog['parks']}
        pending = {p['id'] for p in self.catalog['pending']}
        self.assertFalse(active & pending)
        self.assertEqual(pending, {'de_gasperi', 'pertini', 'riviera'})
        self.assertTrue(all(p['source'].startswith('https://www.comune.volpiano.to.it/') for p in self.catalog['parks']))

    def test_reproducible_catalog(self):
        path = ROOT/'local/volpiano.parks.osm.json'
        if not path.exists():
            self.skipTest('Estratto originale di sviluppo non presente.')
        source = json.loads(path.read_text(encoding='utf-8'))
        manifest = json.loads((ROOT/'data/map/park_sources.json').read_text(encoding='utf-8'))
        self.assertEqual(generate(manifest, source, self.town), self.catalog)


if __name__ == '__main__':
    unittest.main()
