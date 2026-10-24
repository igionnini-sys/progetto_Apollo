extends RefCounted
## Dettagli originali da foto esterne dell'utente; nessuna texture tratta dalle foto.
## Il ponte è ancorato a OSM. Associazioni foto/edifici e misure restano stimate.
const Materials = preload("res://scripts/utilities/materials.gd")
const G = preload("res://scripts/utilities/geometry.gd")
const Meshes = preload("res://scripts/utilities/meshes.gd")
var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map/trento_reference.json"))
var segments: Array = []
var stats := {"fence_spans": 0, "bridge_rails": 0, "photo_facades": 0, "lamps": 0, "parked_cars": 0, "signs": 0}

func prepare(roads: Array) -> void:
	for road: Dictionary in roads:
		if road.name != "Via Trento" or road.get("highway", "") != "tertiary":
			continue
		road.width = float(catalog.road_width_estimate)
		for i in range(road.points.size() - 1):
			segments.append([Vector2(road.points[i][0], road.points[i][1]), Vector2(road.points[i + 1][0], road.points[i + 1][1])])

func distance_to_street(pos: Vector2) -> float:
	var nearest := INF
	for segment: Array in segments:
		nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(pos, segment[0], segment[1]).distance_to(pos))
	return nearest

func profile(building: Dictionary, center: Vector2) -> Dictionary:
	var key := str(int(building.id))
	if catalog.profiles.has(key):
		return catalog.profiles[key]
	if distance_to_street(center) > 24.0 or building.get("kind", "") in ["garage", "garages", "shed", "industrial", "warehouse"]:
		return {}
	# Grammatica delle foto per il resto del corridoio, senza fingere un rilievo.
	var tones := ["e3d6ba", "d8c7b2", "e9e5d9", "d3b4a0"]
	return {"style": "house", "color": tones[posmod(int(building.id), tones.size())], "accent": "b9b7ab", "window": "shutter", "balcony": "individual", "base_height": 0.8}

func building_profile(building: Dictionary) -> Dictionary:
	var center := Vector2.ZERO
	for p: Array in building.outline:
		center += Vector2(p[0], p[1])
	return profile(building, center / building.outline.size())

func balcony(town: RefCounted, origin: Vector3, tangent: Vector3, normal: Vector3, width: float, yaw: float, solid: bool = false) -> void:
	var metal := Color("4c514b")
	town.box(origin + normal * 0.58, Vector3(width + 0.2, 0.16, 1.25), Color("bcb9ad"), yaw)
	if solid:
		town.box(origin + normal * 1.14 + Vector3.UP * 0.48, Vector3(width, 0.8, 0.12), Color("dfd8c7"), yaw)
	else:
		town.box(origin + normal * 1.14 + Vector3.UP * 0.98, Vector3(width, 0.05, 0.05), metal, yaw, "metal")
		for i in ceili(width / 0.14):
			var p := origin + tangent * (-width * 0.5 + i * 0.14) + normal * 1.14 + Vector3.UP * 0.52
			town.box(p, Vector3(0.024, 0.9, 0.024), metal, yaw, "metal")
	for side in [-1.0, 1.0]:
		var p: Vector3 = origin + tangent * side * width * 0.5 + normal * 0.6
		town.box(p + Vector3.UP * 0.98, Vector3(0.05, 0.05, 1.15), metal, yaw, "metal")
		for i in 7:
			town.box(p + normal * (i * 0.15 - 0.5) + Vector3.UP * 0.52, Vector3(0.025, 0.9, 0.025), metal, yaw, "metal")

func facade(town: RefCounted, outline: PackedVector2Array, h: float, style: Dictionary) -> void:
	stats.photo_facades += 1
	var center := Vector2.ZERO
	for p in outline:
		center += p
	center /= outline.size()
	var barn: bool = style.style == "barn"
	var accent := Color(style.accent)
	var base: float = style.base_height
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var length := a.distance_to(b)
		if length < 2.4:
			continue
		var tangent := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
		var normal := Vector3(tangent.z, 0, -tangent.x)
		var middle := Vector3((a.x + b.x) * 0.5, 0, (a.y + b.y) * 0.5)
		if normal.dot(middle - Vector3(center.x, 0, center.y)) < 0.0:
			normal = -normal
		var yaw := atan2(-tangent.z, tangent.x)
		var street: bool = town.faces_street(middle, normal)
		town.box(middle + Vector3.UP * base * 0.5 + normal * 0.06, Vector3(length, base, 0.14), Color("a6a69c"), yaw, "stone")
		town.box(middle + Vector3.UP * (h - 0.08) + normal * 0.25, Vector3(length + 0.25, 0.14, 0.14), Color("68665e"), yaw, "metal")
		var downpipe := Vector3(b.x, h * 0.5, b.y) - tangent * 0.25 + normal * 0.18
		town.cylinder(downpipe, 0.09, h, Color("7e7b70"), "metal")
		if street:
			town.stats.detailed_facades += 1
		var levels := maxi(1, roundi(h / 3.0))
		var columns := maxi(1, floori(length / 3.2))
		var spacing := length / columns
		if barn:
			# Vecchia muratura, corsi orizzontali e portone ad arco osservato nelle foto.
			for course in floori(h / 0.9):
				town.box(middle + Vector3.UP * (0.35 + course * 0.9) + normal * 0.08, Vector3(length, 0.09, 0.12), accent, yaw, "stone")
			if street:
				town.batch.add("arch_fill", middle + Vector3.UP * 1.4 + normal * 0.12, Vector3(2.0, 2.8, 0.10), Color("686050"), yaw)
				town.batch.add("arch_frame", middle + Vector3.UP * 1.4 + normal * 0.18, Vector3(2.0, 2.8, 0.13), accent, yaw)
			else:
				town.box(middle + Vector3.UP * 2.9 + normal * 0.12, Vector3(length * 0.45, 1.1, 0.1), Color("4c4b40"), yaw)
			continue
		for level in levels:
			var y := 1.55 + level * 2.95
			var continuous: bool = style.balcony == "continuous" and level > 0 and street
			if continuous:
				balcony(town, middle + Vector3.UP * (y - 1.0), tangent, normal, length - 0.8, yaw)
			for col in columns:
				var pos := Vector3(a.x, y, a.y) + tangent * spacing * (col + 0.5) + normal * 0.12
				var roller: bool = style.window == "roller"
				var serial := col + level * 7 + int(absf(center.y))
				if style.style == "apartment":
					var pier := Vector3(a.x, base + (h - base) * 0.5, a.y) + tangent * spacing * col + normal * 0.055
					town.box(pier, Vector3(0.6, h - base, 0.12), accent, yaw, "stone")
				if level == 0 and col == 0 and street:
					town.portal(pos - Vector3.UP * y, tangent, normal, yaw, serial)
					continue
				var wh := 2.0 if continuous else 1.45
				var frame := Color("d8d5c9") if roller else Color("b5ad9a")
				town.box(pos, Vector3(1.35, wh + 0.16, 0.11), frame, yaw)
				town.box(pos + normal * 0.06, Vector3(1.12, wh, 0.08), Color("48555b"), yaw, "window")
				town.box(pos + normal * 0.12, Vector3(0.055, wh, 0.04), frame, yaw)
				if roller:
					var closure: float = [0.15, 0.55, 0.95, 0.3][posmod(serial, 4)]
					town.box(pos + normal * 0.15 + Vector3.UP * wh * (1.0 - closure) * 0.5, Vector3(1.12, wh * closure, 0.045), Color("d8d7ce"), yaw, "roller")
				else:
					for side in [-1.0, 1.0]:
						town.box(pos + tangent * side * 0.83 + normal * 0.10, Vector3(0.43, wh, 0.09), Color("665f50"), yaw, "shutter")
				if level == 0:
					for bar in 5:
						town.box(pos + tangent * (bar - 2) * 0.2 + normal * 0.19, Vector3(0.025, wh, 0.025), Color("4f5049"), yaw, "metal")
				if level > 0 and style.balcony == "individual" and col == columns / 2 and street:
					balcony(town, pos - Vector3.UP * (wh * 0.5 + 0.1), tangent, normal, 2.4, yaw, true)
					# Tenda chiara domestica, una per fronte; non una vetrina commerciale.
					town.box(pos + normal * 0.55 + Vector3.UP * (wh * 0.5 + 0.35), Vector3(2.5, 0.12, 1.0), Color("c9bda4"), yaw)
					town.box(pos + normal * 1.0 + Vector3.UP * (wh * 0.5 + 0.18), Vector3(2.5, 0.3, 0.05), Color("d8ceb9"), yaw)
				town.stats.windows += 1

func rail(town: RefCounted, a: Vector3, b: Vector3, base: float = 0.45, bridge: bool = false) -> void:
	var tangent := (b - a).normalized()
	var yaw := atan2(-tangent.z, tangent.x)
	var length := a.distance_to(b)
	var middle := (a + b) * 0.5
	var metal := Color("667b6b") if bridge else Color("545c55")
	if base > 0.0:
		town.box(middle + Vector3.UP * base * 0.5, Vector3(length, base, 0.28), Color("a29e90"), yaw, "stone")
		town.box(middle + Vector3.UP * (base + 0.04), Vector3(length + 0.05, 0.08, 0.36), Color("bcb9aa"), yaw)
	for y in [base + 0.14, base + 1.0]:
		town.box(middle + Vector3.UP * y, Vector3(length, 0.055, 0.055), metal, yaw, "metal")
	for i in maxi(2, ceili(length / 0.16)):
		var p := a.lerp(b, float(i) / maxi(1, ceili(length / 0.16) - 1))
		town.box(p + Vector3.UP * (base + 0.57), Vector3(0.025, 0.85, 0.025), metal, yaw, "metal")
	for p in [a, b]:
		town.box(p + Vector3.UP * (base + 0.57), Vector3(0.075, 1.14, 0.075), metal, yaw, "metal")

func add_boundaries(world: Node3D, bounds: AABB) -> void:
	var town: RefCounted = world.town
	var serial := 0
	for segment: Array in segments:
		var a := Vector3(segment[0].x, 0, segment[0].y)
		var b := Vector3(segment[1].x, 0, segment[1].y)
		var length := a.distance_to(b)
		if length < 8.0:
			continue
		var tangent := (b - a).normalized()
		var side := Vector3(tangent.z, 0, -tangent.x)
		var count := maxi(1, floori(length / 12.0))
		for i in count:
			serial += 1
			for sign_side in [-1.0, 1.0]:
				var center: Vector3 = a.lerp(b, (i + 0.5) / count) + side * sign_side * 4.85
				var half_span := minf(4.6, length / count * 0.38)
				var start := center - tangent * half_span
				var finish := center + tangent * half_span
				var clear := bounds.has_point(start) and bounds.has_point(finish)
				for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
					clear = clear and town.clear_position(start.lerp(finish, fraction), 0.35)
				if not clear:
					continue
				var yaw := atan2(-tangent.z, tangent.x)
				# Varchi e cancelli interrompono il fronte; mai sopra gli incroci OSM.
				if serial % 3 == 0:
					var gate_start := center - tangent * 1.35
					var gate_end := center + tangent * 1.35
					rail(town, start, gate_start)
					rail(town, gate_start, gate_end, 0.0)
					rail(town, gate_end, finish)
					for p in [gate_start, gate_end]:
						town.box(p + Vector3.UP * 0.9, Vector3(0.32, 1.8, 0.32), Color("a77860"), yaw, "stone")
				else:
					rail(town, start, finish, 0.7 if serial % 2 == 0 else 0.35)
				stats.fence_spans += 1
				town.box(center + side * sign_side * 0.35 - Vector3.UP * 0.09, Vector3(half_span * 2.0, 0.025, 1.35), Color.WHITE, yaw, "trento_paving")
				# Pochi arbusti dietro le recinzioni, a scala contenuta.
				var shrub: Vector3 = center + side * sign_side * 0.8
				if serial % 2 == 0 and town.clear_position(shrub, 0.8):
					town.batch.add("blob", shrub + Vector3.UP * 0.7, Vector3(1.6, 1.5, 1.6), Color("4e6745"), yaw, "foliage")
	# Il ponticello visibile nelle foto, way OSM 889238377.
	for road: Dictionary in world.data.roads:
		if int(road.id) != 889238377:
			continue
		var a: Vector3 = world.point(road.points[0])
		var b: Vector3 = world.point(road.points[-1])
		if not bounds.has_point(a) or not bounds.has_point(b):
			continue
		var direction: Vector3 = (b - a).normalized()
		var side := Vector3(direction.z, 0, -direction.x)
		for sign_side in [-1.0, 1.0]:
			var offset: Vector3 = side * sign_side * 4.55
			rail(town, a + offset - direction * 1.8, b + offset + direction * 1.8, 0.12, true)
			stats.bridge_rails += 1
		# Lampioni con braccio orizzontale e corpo lenticolare, come nelle foto.
		for z_offset in [-42.0, 36.0, 85.0, 130.0]:
			var probe: Vector2 = Vector2((a.x + b.x) * 0.5, (a.z + b.z) * 0.5 + z_offset)
			var nearest := Vector2.INF
			for segment: Array in segments:
				var candidate := Geometry2D.get_closest_point_to_segment(probe, segment[0], segment[1])
				if candidate.distance_squared_to(probe) < nearest.distance_squared_to(probe):
					nearest = candidate
			for sign_side in [1.0, -1.0]:
				var p: Vector3 = Vector3(nearest.x + sign_side * 4.3, 0, nearest.y)
				if not town.clear_position(p, 0.15):
					continue
				town.cylinder(p + Vector3.UP * 3.4, 0.10, 6.8, Color("9a9f98"), "metal")
				town.box(p + Vector3(-0.65, 6.7, 0), Vector3(1.3, 0.065, 0.065), Color("9a9f98"), 0.0, "metal")
				town.sphere(p + Vector3(-1.3, 6.65, 0), Vector3(0.5, 0.13, 0.27), Color("777d77"), "metal")
				stats.lamps += 1
				break
		# Due chiusini, più caditoie sul bordo: dettagli visivi a filo asfalto.
		for z_offset in [-23.0, 25.0, 60.0]:
			var center: Vector3 = (a + b) * 0.5 + Vector3(2.0, 0, z_offset)
			var closest := Vector2.INF
			for segment: Array in segments:
				var p := Geometry2D.get_closest_point_to_segment(Vector2(center.x, center.z), segment[0], segment[1])
				if p.distance_squared_to(Vector2(center.x, center.z)) < closest.distance_squared_to(Vector2(center.x, center.z)):
					closest = p
			town.cylinder(Vector3(closest.x + 0.9, -0.059, closest.y), 0.57, 0.012, Color("454744"), "metal")
			for sign_side in [-1.0, 1.0]:
				var drain := Vector3(closest.x + sign_side * 3.0, -0.058, closest.y)
				town.box(drain, Vector3(0.34, 0.015, 0.52), Color("65675f"), 0.0, "metal")
				for slot in 6:
					town.box(drain + Vector3(0, 0.01, -0.2 + slot * 0.08), Vector3(0.26, 0.008, 0.025), Color("323630"))
		# Auto ferme sul bordo della carreggiata, come nella vista della palazzina.
		# I collisori lasciano oltre 1,7 m liberi fra auto e asse stradale.
		for z in [-31.0, -23.0, -15.0]:
			var probe := Vector2(150.0, z)
			var street := Vector2.INF
			for segment: Array in segments:
				var p := Geometry2D.get_closest_point_to_segment(probe, segment[0], segment[1])
				if p.distance_squared_to(probe) < street.distance_squared_to(probe):
					street = p
			var pos := Vector3(street.x + 2.65, 0, street.y)
			var footprint := PackedVector2Array([Vector2(pos.x - 1.0, pos.z - 2.0), Vector2(pos.x + 1.0, pos.z - 2.0), Vector2(pos.x + 1.0, pos.z + 2.0), Vector2(pos.x - 1.0, pos.z + 2.0)])
			var clear := true
			for outline: PackedVector2Array in town.footprints:
				if not Geometry2D.intersect_polygons(footprint, outline).is_empty():
					clear = false
					break
			if clear:
				town.parked_car(pos, 0.0)
				stats.parked_cars += 1
		add_signs(world, Vector3(a.x + 5.0, 0, a.z + 11.0))

func add_signs(world: Node3D, pos: Vector3) -> void:
	if not world.town.clear_position(pos, 0.1):
		return
	var signs := Node3D.new()
	signs.name = "SegnaliPonteViaTrento"
	signs.position = pos
	world.add_child(signs)
	G.cylinder(signs, Vector3(0, 1.85, -0.09), 0.055, 3.7, Color("81877d"))
	# 30 e pericolo dosso nella schermata più recente (luglio 2025).
	world.town.sphere(pos + Vector3(0, 2.6, 0), Vector3(0.61, 0.61, 0.055), Color("b53e35"))
	world.town.sphere(pos + Vector3(0, 2.6, -0.032), Vector3(0.60, 0.60, 0.012), Color("93998e"), "metal")
	world.town.sphere(pos + Vector3(0, 2.6, 0.029), Vector3(0.46, 0.46, 0.028), Color("e5e4d8"))
	var label := G.label(signs, "30", Vector3(0, 2.6, 0.05), 48)
	label.pixel_size = 0.005
	label.modulate = Color("242a25")
	label.outline_size = 0
	var triangle := SurfaceTool.new()
	triangle.begin(Mesh.PRIMITIVE_TRIANGLES)
	triangle.set_color(Color("b53e35"))
	Meshes.triangle(triangle, pos + Vector3(0, 3.57, 0.03), pos + Vector3(-0.38, 2.9, 0.03), pos + Vector3(0.38, 2.9, 0.03), Vector3.BACK)
	triangle.set_color(Color("e6e3d6"))
	Meshes.triangle(triangle, pos + Vector3(0, 3.43, 0.04), pos + Vector3(-0.26, 2.97, 0.04), pos + Vector3(0.26, 2.97, 0.04), Vector3.BACK)
	world.surface_node(triangle, "SegnaleDossoViaTrento", Materials.instanced("plain"))
	for i in 7:
		var x := (i - 3) * 0.06
		world.town.box(pos + Vector3(x, 3.06 + 0.08 * cos(x * 7.0), 0.055), Vector3(0.065, 0.045, 0.015), Color("30362f"))
	stats.signs = 2
