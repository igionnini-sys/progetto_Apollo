extends RefCounted
## Via Trieste (SP3) e parcheggio della scuola in Via Fiume, dalle foto dell'utente (giugno 2026).
## Marciapiedi in autobloccanti rosati, recinzioni diverse da casa a casa, lampioni a braccio,
## attraversamenti rialzati con fasce arancioni, scritte "Via Trieste" e "SP3" sull'asfalto.
## Posizioni degli arredi e dei parcheggi stimate; nessuna foto usata come texture.
const G = preload("res://scripts/utilities/geometry.gd")
const PAINT := -0.058
const ROAD_WIDTH := 7.2
const WALK := 1.6
const FIUME_JUNCTION := Vector2(598.558, -95.694)
var lines: Array = []
var fiume: Array[Vector2] = []
var stats := {"fence_spans": 0, "lamps": 0, "crossings": 0, "lot_cars": 0, "street_cars": 0}

func prepare(roads: Array) -> void:
	for road: Dictionary in roads:
		if road.name == "Via Trieste":
			road.width = ROAD_WIDTH
			road.sidewalk = "both"
			var line: Array[Vector2] = []
			for p: Array in road.points:
				line.append(Vector2(p[0], p[1]))
			lines.append(line)
		elif int(road.id) == 125383891:
			for p: Array in road.points:
				fiume.append(Vector2(p[0], p[1]))

func along(line: Array, s: float) -> Array:
	var remaining := maxf(s, 0.0)
	for i in range(line.size() - 1):
		var d: float = line[i].distance_to(line[i + 1])
		if remaining <= d or i == line.size() - 2:
			var t := clampf(remaining / maxf(d, 0.001), 0.0, 1.0)
			return [line[i].lerp(line[i + 1], t), (line[i + 1] - line[i]).normalized()]
		remaining -= d
	return [line[-1], Vector2.RIGHT]

func polyline_length(line: Array) -> float:
	var total := 0.0
	for i in range(line.size() - 1):
		total += line[i].distance_to(line[i + 1])
	return total

func nearest(line: Array, target: Vector2) -> Array:
	var best := 0.0
	var close := INF
	var s := 0.0
	var length := polyline_length(line)
	while s <= length:
		var d: float = (along(line, s)[0] as Vector2).distance_to(target)
		if d < close:
			close = d
			best = s
		s += 1.0
	return [best, close]

func v3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)

func add(world: Node3D, bounds: AABB) -> void:
	var town: RefCounted = world.town
	var reference: RefCounted = world.trento
	var serial := 0
	var half := ROAD_WIDTH * 0.5
	for line: Array in lines:
		var length := polyline_length(line)
		var step := 6.0
		for i in floori(length / step):
			serial += 1
			var s := i * step
			var info: Array = along(line, s + step * 0.5)
			var c: Vector2 = info[0]
			var tangent: Vector2 = info[1]
			var t3 := Vector3(tangent.x, 0, tangent.y)
			var side := Vector3(tangent.y, 0, -tangent.x)
			var yaw := atan2(-t3.z, t3.x)
			for sign_side in [1.0, -1.0]:
				var offset: Vector3 = side * sign_side * (half + WALK + 0.35)
				var start: Vector3 = v3(c) + offset - t3 * (step * 0.5 - 0.1)
				var finish: Vector3 = v3(c) + offset + t3 * (step * 0.5 - 0.1)
				if not bounds.has_point(start) or not bounds.has_point(finish):
					continue
				var clear := true
				for fraction in [0.0, 0.5, 1.0]:
					clear = clear and town.clear_position(start.lerp(finish, fraction), 0.3)
				if not clear:
					continue
				var pick := posmod(serial * 5 + int(sign_side) * 2 + i, 11)
				var industrial: bool = c.x > 330.0 and c.x < 470.0 and sign_side < 0.0 and c.y > 150.0
				if industrial:
					mesh_fence(town, start, finish, 1.9, yaw)
				elif pick <= 2:
					reference.picket(town, start, finish, 0.45, Color("e9e7e0"))
				elif pick == 3 or pick == 4:
					mesh_fence(town, start, finish, 1.3, yaw)
				elif pick == 5 or pick == 6:
					reference.hedge(town, start, finish, 1.4, false, 0.55)
				elif pick == 7:
					reference.pasubio_gate(town, start, finish, side * -sign_side)
				elif pick == 8:
					reference.picket(town, start, finish, 0.8, Color("6e777a"))
				else:
					reference.hedge(town, start, finish, 0.7, true, 0.6)
				stats.fence_spans += 1
			# Guard-rail lungo il fosso a ovest, nel tratto del sottopasso e dei campi.
			if c.y > 230.0 and c.y < 440.0 and c.x < 420.0:
				var rail_side := -1.0 if side.x > 0.0 else 1.0
				var a: Vector3 = v3(c) + side * rail_side * (half + WALK + 1.7) - t3 * step * 0.5
				var b: Vector3 = a + t3 * step
				if bounds.has_point(a) and town.clear_position(a, 0.2):
					reference.rail(town, a, b, 0.0)
			# Lampioni alti con braccio, alternati sui due lati.
			if i % 6 == 3:
				var lamp_side := 1.0 if (i / 6) % 2 == 0 else -1.0
				var pole: Vector3 = v3(c) + side * lamp_side * (half + WALK * 0.8)
				if bounds.has_point(pole) and town.clear_position(pole, 0.2):
					town.cylinder(pole + Vector3.UP * 4.2, 0.14, 8.4, Color("959b96"), "metal")
					town.box(pole - side * lamp_side * 0.7 + Vector3.UP * 8.3, Vector3(0.05, 0.05, 1.5), Color("959b96"), yaw + PI * 0.5, "metal")
					town.sphere(pole - side * lamp_side * 1.45 + Vector3.UP * 8.2, Vector3(0.55, 0.14, 0.3), Color("6c726d"), "metal")
					stats.lamps += 1
	var main: Array = lines[0]
	crossings(world, bounds)
	road_text(world, main)
	school_lot(world, bounds)
	fiume_cars(world, bounds)

func mesh_fence(town: RefCounted, a: Vector3, b: Vector3, height: float, yaw: float) -> void:
	var length := a.distance_to(b)
	var middle := (a + b) * 0.5
	town.box(middle + Vector3.UP * 0.25, Vector3(length, 0.5, 0.25), Color("a9a698"), yaw, "stone")
	var wires := ceili(length / 0.3)
	for k in wires:
		town.box(a.lerp(b, (k + 0.5) / wires) + Vector3.UP * (0.5 + height * 0.5), Vector3(0.02, height, 0.02), Color("7a8b82"), yaw, "metal")
	for y in [0.55, 0.5 + height * 0.5, 0.5 + height]:
		town.box(middle + Vector3.UP * y, Vector3(length, 0.05, 0.05), Color("707a76"), yaw, "metal")
	for p in [a, b]:
		town.box(p + Vector3.UP * (0.5 + height * 0.5), Vector3(0.1, height, 0.1), Color("65706c"), yaw, "metal")

func crossings(world: Node3D, bounds: AABB) -> void:
	var town: RefCounted = world.town
	var main: Array = lines[0]
	var existing: Array = []
	for feature: Dictionary in world.data.get("features", []):
		if feature.kind == "crossing":
			existing.append(Vector2(feature.point[0], feature.point[1]))
	for target: Vector2 in [Vector2(499.1, 107.5), Vector2(460.2, 188.7), Vector2(598.6, -95.7), Vector2(545.5, 9.3), Vector2(393.3, 330.0), Vector2(620.0, -135.0)]:
		var found: Array = nearest(main, target)
		var info: Array = along(main, found[0])
		var c: Vector2 = info[0]
		var tangent: Vector2 = info[1]
		var skip := false
		for p: Vector2 in existing:
			skip = skip or p.distance_to(c) < 10.0
		var t3 := Vector3(tangent.x, 0, tangent.y)
		var side := Vector3(tangent.y, 0, -tangent.x)
		var yaw := atan2(-t3.z, t3.x)
		if skip or not bounds.has_point(v3(c)):
			continue
		for k in 9:
			var offset: float = (k - 4) * 0.8
			var center: Vector3 = v3(c) + side * offset + Vector3.UP * (PAINT + 0.004)
			town.box(center, Vector3(2.9, 0.012, 0.45), Color("eeebe0"), yaw)
		# Fascia arancione e gialla dell'attraversamento rialzato.
		for k in 6:
			var tone := Color("e3a52d") if k % 2 == 0 else Color("efe6c4")
			town.box(v3(c) + side * (k - 2.5) * 1.0 + t3 * -2.3 + Vector3.UP * (PAINT + 0.006), Vector3(0.95, 0.012, 0.6), tone, yaw)
		for sign_side in [1.0, -1.0]:
			var pole: Vector3 = v3(c) + side * sign_side * (ROAD_WIDTH * 0.5 + WALK * 0.7) + t3 * 2.2
			if town.clear_position(pole, 0.1):
				town.cylinder(pole + Vector3.UP * 1.3, 0.07, 2.6, Color("858a82"), "metal")
				town.box(pole + Vector3(0, 2.75, 0), Vector3(0.65, 0.65, 0.05), Color("1f5fb0"), yaw + PI * 0.5)
				town.box(pole + Vector3(0, 2.75, 0), Vector3(0.05, 0.4, 0.06), Color("f2f2ee"), yaw + PI * 0.5)
		stats.crossings += 1

func road_text(world: Node3D, main: Array) -> void:
	var targets := [["SP3", Vector2(352.0, 412.0)], ["Via Trieste", Vector2(446.0, 214.0)], ["Via Trieste", Vector2(512.0, 80.0)], ["Via Trieste", Vector2(580.0, -62.0)]]
	for item in targets:
		var found: Array = nearest(main, item[1])
		var info: Array = along(main, found[0])
		var tangent: Vector2 = info[1]
		var side := Vector3(tangent.y, 0, -tangent.x)
		var pos: Vector3 = v3(info[0]) + side * 1.7 + Vector3.UP * (PAINT + 0.003)
		var label := G.label(world, item[0], pos, 64)
		# Scritta distesa a terra, leggibile viaggiando verso la scuola (nord).
		label.rotation = Vector3(-PI * 0.5, atan2(tangent.x, tangent.y) + PI * 0.5 + PI, 0)
		label.pixel_size = 0.016
		label.modulate = Color("e8e6dc")
		label.outline_size = 0

## Parcheggio all'angolo fra Via Trieste e Via Fiume: autobloccanti rosati, aiuola con rete, auto di traverso.
func school_lot(world: Node3D, bounds: AABB) -> void:
	var town: RefCounted = world.town
	var main: Array = lines[0]
	var found: Array = nearest(main, FIUME_JUNCTION)
	var base: Array = along(main, found[0])
	var c0: Vector2 = base[0]
	var tangent: Vector2 = base[1]
	var t3 := Vector3(tangent.x, 0, tangent.y)
	var east := Vector3(-tangent.y, 0, tangent.x)
	if east.x < 0.0:
		east = -east
	var yaw := atan2(-t3.z, t3.x)
	var origin: Vector3 = v3(c0)
	# Autobloccanti dell'intero piazzale, aiuola con rete lungo la strada.
	for u in range(8, 44, 4):
		var cell: Vector3 = origin + t3 * (u + 2.0) + east * 23.0
		if bounds.has_point(cell) and town.clear_position(cell, 0.5):
			town.box(cell + Vector3.DOWN * 0.075, Vector3(4.05, 0.03, 31.0), Color.WHITE, yaw, "trento_paving")
	var strip: Vector3 = origin + t3 * 26.0 + east * 8.4
	town.box(strip + Vector3.DOWN * 0.04, Vector3(30.0, 0.06, 2.2), Color("7f9a4c"), yaw)
	for k in 30:
		town.batch.add("blob", strip + t3 * (-14.0 + k) + Vector3.UP * 0.5, Vector3(0.9, 1.0, 0.7), Color("6f8f45"), k, "foliage")
	mesh_fence(town, strip - t3 * 15.0 + east * 1.1, strip + t3 * 15.0 + east * 1.1, 1.0, yaw)
	# Auto in sosta, di traverso su due file.
	for row in 2:
		for u in range(10, 42, 3):
			if (u + row * 2) % 7 == 0:
				continue
			var pos: Vector3 = origin + t3 * u + east * (14.0 + row * 12.0)
			if bounds.has_point(pos) and town.clear_position(pos, 1.0):
				town.parked_car(pos, yaw + PI * 0.5)
				stats.lot_cars += 1
	# Transenne rosse e segnali scolastici all'angolo.
	for item in [[8.0, 9.5], [10.5, 9.5]]:
		var p: Vector3 = origin + t3 * item[0] + east * item[1]
		town.box(p + Vector3.UP * 0.5, Vector3(1.2, 0.9, 0.12), Color("d1362d"), yaw)
	var pole: Vector3 = origin + t3 * 6.5 + east * 6.2
	if town.clear_position(pole, 0.1):
		town.cylinder(pole + Vector3.UP * 1.5, 0.07, 3.0, Color("858a82"), "metal")
		town.box(pole + Vector3(0, 3.0, 0), Vector3(0.75, 0.75, 0.05), Color("c8372d"), yaw + PI * 0.5)
		town.box(pole + Vector3(0, 3.0, 0.03), Vector3(0.5, 0.5, 0.03), Color("f1eee2"), yaw + PI * 0.5)
		town.cylinder(pole + Vector3(0, 2.2, 0), 0.55, 0.05, Color("f1eee2"), "plain")

## Via Fiume: auto parcheggiate sui due bordi, come nell'ultima foto.
func fiume_cars(world: Node3D, bounds: AABB) -> void:
	if fiume.size() < 2:
		return
	var town: RefCounted = world.town
	for i in 14:
		var info: Array = along(fiume, 12.0 + i * 5.5)
		var tangent: Vector2 = info[1]
		var t3 := Vector3(tangent.x, 0, tangent.y)
		var side := Vector3(tangent.y, 0, -tangent.x)
		var yaw := atan2(-t3.z, t3.x)
		for sign_side in [1.0, -1.0]:
			if (i + int(sign_side) * 3) % 3 == 0:
				continue
			var pos: Vector3 = v3(info[0]) + side * sign_side * 2.0
			if bounds.has_point(pos) and town.clear_position(pos + side * sign_side * 3.5, 0.5):
				town.parked_car(pos, yaw)
				stats.street_cars += 1
