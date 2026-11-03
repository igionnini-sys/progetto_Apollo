import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class StoryDataTests(unittest.TestCase):
    def test_route_on_accessible_roads(self):
        town = json.loads((ROOT/'data/map/volpiano.json').read_text(encoding='utf-8'))
        story = json.loads((ROOT/'data/map/story_route.json').read_text(encoding='utf-8'))
        edges = {tuple(edge) for edge in town['edges']}
        self.assertTrue(all((a, b) in edges for a, b in zip(story['route'], story['route'][1:])))
        self.assertTrue(story['metadata']['preview'])
        self.assertFalse(story['metadata']['school_vehicle_access_verified'])
        self.assertGreater(story['metadata']['length_m'], 600)

    def test_route_follows_pasubio_novara_trieste(self):
        town = json.loads((ROOT/'data/map/volpiano.json').read_text(encoding='utf-8'))
        story = json.loads((ROOT/'data/map/story_route.json').read_text(encoding='utf-8'))
        names = {}
        for road in town['roads']:
            for p in road['points']:
                names.setdefault(tuple(p), set()).add(road['name'])
        order = [next(iter(n for n in ('Via Pasubio', 'Via Novara', 'Via Trieste') if n in names[tuple(town['nodes'][i])]), '') for i in story['route']]
        order = [n for n in order if n]
        first = {n: order.index(n) for n in ('Via Pasubio', 'Via Novara', 'Via Trieste')}
        self.assertLess(first['Via Pasubio'], first['Via Novara'])
        self.assertLess(first['Via Novara'], first['Via Trieste'])
        self.assertEqual(order[-1], 'Via Trieste')

    def test_traffic_point_is_on_route(self):
        story = json.loads((ROOT/'data/map/story_route.json').read_text(encoding='utf-8'))
        self.assertIn(story['traffic_node'], story['route'][1:-1])

    def test_dialogue_roles_and_sequences(self):
        family = json.loads((ROOT/'data/characters/family.json').read_text(encoding='utf-8'))
        dialogue = json.loads((ROOT/'data/dialogue/school.json').read_text(encoding='utf-8'))
        for key in ['intro', 'parking_intro', 'ending', 'parking_ending']:
            self.assertGreaterEqual(len(dialogue[key]), 2)
        for value in dialogue.values():
            for line in value if isinstance(value, list) else [value]:
                self.assertIn(line['speaker'], family)
                self.assertTrue(line['text'].strip())


if __name__ == '__main__':
    unittest.main()
