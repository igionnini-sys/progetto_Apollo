extends RefCounted
## Facciate procedurali sobrie su impronte reali; dettagli non rilevati dichiarati stimati.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const Batch = preload("res://scripts/environment/town_batch.gd")
var batch = Batch.new()
var reference: RefCounted
var school_model: RefCounted = preload("res://scripts/environment/school_building.gd").new()
var road_segments: Array = []
var road_index: Dictionary = {}
var detail_route: Array[Vector2] = []
var detail_streets: Array = []
var footprints: Array[PackedVector2Array] = []
var parked_colliders: Array = []
var entrances: Array[Transform3D] = []
var stats: Dictionary = {"buildings": 0, "windows": 0, "trees": 0, "lamps": 0, "benches": 0, "crossings": 0, "signals": 0, "landmarks": 0, "cars": 0, "street_signs": 0, "shopfronts": 0, "portals": 0, "detailed_facades": 0, "paved_frontages": 0}
## Toni meno saturi: intonaco crema, grigio, sabbia, ocra e mattone.
var palette: Array[Color] = [Color("d2c9b8"), Color("c4beb0"), Color("ded5bd"), Color("c5ad8b"), Color("c5b4a4"), Color("d0bd95"), Color("b9aaa0")]
var shutter_palette: Array[Color] = [Color("4d5c4e"), Color("655b4d"), Color("646c6b"), Color("62644f"), Color("46554e")]
var car_palette: Array[Color] = [Color("8b3933"), Color("b6b5af"), Color("42566b"), Color("626b63"), Color("deddd6"), Color("4c4b4c"), Color("333b40"), Color("a2a4a4")]
var leaf_palette: Array[Color] = [Color("7fb35a"), Color("6aa250"), Color("90c464"), Color("5f9a4f"), Color("9cc66a")]
var autumn_palette: Array[Color] = [Color("e8a53e"), Color("dd8238"), Color("ebc65a")]

func box(pos: Vector3, size: Vector3, color: Color, yaw: float = 0.0, look: String = "plain") -> void:
	batch.add("box", pos, size, color, yaw, look)

func cylinder(pos: Vector3, diameter: float, height: float, color: Color, look: String = "plain") -> void:
	batch.add("cylinder", pos, Vector3(diameter, height, diameter), color, 0.0, look)

func sphere(pos: Vector3, size: Vector3, color: Color, look: String = "plain") -> void:
	batch.add("sphere", pos, size, color, 0.0, look)

func local(pos: Vector3, yaw: float, offset: Vector3) -> Vector3:
	return pos + Basis(Vector3.UP, yaw) * offset

func height(building: Dictionary) -> float:
	if reference != null:
		var profile: Dictionary = reference.building_profile(building)
		if profile.has("height"):
			return float(profile.height)
	if int(building.id) == 417795500:
		return 10.0
	if int(building.id) == 897476177:
		return 9.0
	if int(building.id) == 215468999:
		return 4.0
	if building.get("kind", "") in ["garage", "garages", "shed"]:
		return 2.7
	if building.get("kind", "") in ["industrial", "warehouse"]:
		return 5.5
	var levels := str(building.get("levels", "")).to_int()
	return clampf(float(levels) * 3.0, 3, 24) if levels > 0 else 6.2

func wall_color(building: Dictionary) -> Color:
	if reference != null:
		var profile: Dictionary = reference.building_profile(building)
		if not profile.is_empty():
			return Color(profile.color)
	var id := int(building.id)
	if id == 215468999:
		return Color("b4543b")
	if building.get("kind", "") in ["garage", "garages", "shed"]:
		return Color("cdbfa6")
	if building.get("kind", "") in ["industrial", "warehouse"]:
		return Color("b1b0a7")
	var base: Color = palette[id % palette.size()]
	return base.lightened(float(posmod(id * 7, 5)) * 0.012)

func register_roads(roads: Array) -> void:
	for road: Dictionary in roads:
		for i in range(road.points.size() - 1):
			var a: Array = road.points[i]
			var b: Array = road.points[i + 1]
			road_segments.append([Vector2(a[0], a[1]), Vector2(b[0], b[1]), float(road.width) * 0.5])
			if road.name == "Via Trento":
				detail_streets.append([Vector2(a[0], a[1]), Vector2(b[0], b[1])])
	# Celle da 32 m: copertura di 18 m per le facciate e raggio fino a 4 m per gli arredi.
	for segment: Array in road_segments:
		var reach := maxf(18.0, float(segment[2]) + 4.0)
		var low: Vector2 = segment[0].min(segment[1]) - Vector2.ONE * reach
		var high: Vector2 = segment[0].max(segment[1]) + Vector2.ONE * reach
		for x in range(floori(low.x / 32.0), floori(high.x / 32.0) + 1):
			for y in range(floori(low.y / 32.0), floori(high.y / 32.0) + 1):
				var key := Vector2i(x, y)
				if not road_index.has(key):
					road_index[key] = []
				road_index[key].append(segment)

func nearby_roads(pos: Vector2, radius: float) -> Array:
	if road_index.is_empty() or radius > 4.0:
		return road_segments
	return road_index.get(Vector2i(floori(pos.x / 32.0), floori(pos.y / 32.0)), [])

func clear_position(pos: Vector3, radius: float) -> bool:
	var xy := Vector2(pos.x, pos.z)
	for segment: Array in nearby_roads(xy, radius):
		if Geometry2D.get_closest_point_to_segment(xy, segment[0], segment[1]).distance_to(xy) < segment[2] + radius:
			return false
	for outline: PackedVector2Array in footprints:
		if Geometry2D.is_point_in_polygon(xy, outline):
			return false
		for i in outline.size():
			if Geometry2D.get_closest_point_to_segment(xy, outline[i], outline[(i + 1) % outline.size()]).distance_to(xy) < radius:
				return false
	return true

## Arredi delle facciate rivolte verso una strada, senza cambiare le impronte OSM.
func faces_street(pos: Vector3, normal: Vector3) -> bool:
	var xy := Vector2(pos.x, pos.z)
	var nearest := INF
	var direction := Vector2.ZERO
	for segment: Array in nearby_roads(xy, 0.0):
		var offset := Geometry2D.get_closest_point_to_segment(xy, segment[0], segment[1]) - xy
		if offset.length_squared() < nearest:
			nearest = offset.length_squared()
			direction = offset
	return nearest < 18.0 * 18.0 and direction.dot(Vector2(normal.x, normal.z)) > 0.0

func near_route(pos: Vector3) -> bool:
	var xy := Vector2(pos.x, pos.z)
	for segment: Array in detail_streets:
		if Geometry2D.get_closest_point_to_segment(xy, segment[0], segment[1]).distance_squared_to(xy) < 55.0 * 55.0:
			return true
	for i in range(detail_route.size() - 1):
		if Geometry2D.get_closest_point_to_segment(xy, detail_route[i], detail_route[i + 1]).distance_squared_to(xy) < 55.0 * 55.0:
			return true
	return false

func paved_frontage(a: Vector2, b: Vector2, normal: Vector3, yaw: float) -> void:
	for depth in [2.0, 1.25, 0.75]:
		var clear := true
		for fraction in [0.05, 0.5, 0.95]:
			var p := a.lerp(b, fraction)
			clear = clear and clear_position(Vector3(p.x, 0, p.y) + normal * depth, 0.12)
		if clear:
			var middle := (a + b) * 0.5
			var size := Vector3(a.distance_to(b), 0.032, depth)
			box(Vector3(middle.x, -0.1, middle.y) + normal * depth * 0.5, size, Color.WHITE, yaw, "paving")
			stats.paved_frontages += 1
			return

func portal(pos: Vector3, tangent: Vector3, normal: Vector3, yaw: float, seed_value: int) -> void:
	entrances.append(Transform3D(Basis(Vector3.UP, yaw), pos + Vector3.UP * 1.3 + normal * 0.2))
	var wood: Color = [Color("62432f"), Color("6c4031"), Color("3c6556")][posmod(seed_value, 3)]
	var stone := Color("d6b79c")
	box(pos + Vector3.UP * 1.28 + normal * 0.075, Vector3(1.65, 2.56, 0.08), wood.darkened(0.24), yaw)
	for side in [-1.0, 1.0]:
		box(pos + tangent * side * 0.9 + Vector3.UP * 1.33 + normal * 0.12, Vector3(0.14, 2.66, 0.15), stone, yaw)
	box(pos + Vector3.UP * 2.68 + normal * 0.12, Vector3(1.94, 0.14, 0.15), stone, yaw)
	box(pos + Vector3.UP * 1.05 + normal * 0.14, Vector3(0.035, 2.1, 0.055), wood.darkened(0.45), yaw)
	for side in [-1.0, 1.0]:
		for y in [0.48, 1.21, 1.88]:
			var p: Vector3 = pos + tangent * side * 0.31 + Vector3.UP * y + normal * 0.13
			box(p, Vector3(0.49, 0.55, 0.065), wood.lightened(0.08), yaw)
			box(p + normal * 0.04, Vector3(0.37, 0.42, 0.025), wood, yaw)
		sphere(pos + tangent * side * 0.1 + Vector3.UP * 1.09 + normal * 0.23, Vector3(0.065, 0.065, 0.065), Color("b89957"), "metal")
	box(pos + Vector3.UP * 0.01 + normal * 0.31, Vector3(1.9, 0.14, 0.65), Color("b2aea0"), yaw)
	stats.portals += 1

func window_stonework(pos: Vector3, tangent: Vector3, normal: Vector3, yaw: float, frame: Color, variant: int) -> void:
	for side in [-1.0, 1.0]:
		box(pos + tangent * side * 0.56 + normal * 0.12, Vector3(0.13, 1.61, 0.22), frame, yaw)
	box(pos + Vector3.UP * 0.83 + normal * 0.14, Vector3(1.36, 0.14, 0.27), frame, yaw)
	if variant % 2 == 0:
		box(pos + Vector3.UP * 0.96 + normal * 0.12, Vector3(0.23, 0.22, 0.27), frame.lightened(0.08), yaw)
	else:
		for side in [-1.0, 1.0]:
			box(pos + tangent * side * 0.62 + Vector3.UP * 0.66 + normal * 0.14, Vector3(0.28, 0.22, 0.26), frame, yaw)

func shopfront(pos: Vector3, tangent: Vector3, normal: Vector3, yaw: float, seed_value: int) -> void:
	var paint: Color = [Color("376745"), Color("2c6251"), Color("3c7073"), Color("927345"), Color("804f41")][posmod(seed_value * 7 + 11, 5)]
	# Vetrina incorniciata, porta, pannelli in legno e piccola tenda a righe.
	box(pos + Vector3.UP * 1.3 + normal * 0.12, Vector3(2.6, 2.6, 0.18), paint.darkened(0.25), yaw)
	box(pos - tangent * 0.36 + Vector3.UP * 1.45 + normal * 0.23, Vector3(1.45, 1.65, 0.07), Color("628b99"), yaw, "window")
	box(pos + tangent * 0.89 + Vector3.UP * 1.22 + normal * 0.24, Vector3(0.68, 2.3, 0.08), paint, yaw)
	box(pos + tangent * 0.89 + Vector3.UP * 1.6 + normal * 0.3, Vector3(0.47, 1.27, 0.04), Color("638e98"), yaw, "window")
	for x in [-1.23, 0.46, 1.23]:
		box(pos + tangent * x + Vector3.UP * 1.35 + normal * 0.3, Vector3(0.1, 2.7, 0.16), paint, yaw)
	box(pos + Vector3.UP * 0.36 + normal * 0.29, Vector3(2.5, 0.64, 0.12), paint, yaw)
	for x in [-0.78, -0.1, 0.88]:
		box(pos + tangent * x + Vector3.UP * 0.36 + normal * 0.37, Vector3(0.5, 0.42, 0.06), paint.lightened(0.1), yaw)
	box(pos + Vector3.UP * 2.48 + normal * 0.3, Vector3(2.85, 0.3, 0.26), paint, yaw)
	box(pos + Vector3.UP * 2.7 + normal * 0.36, Vector3(3.0, 0.11, 0.4), paint.lightened(0.18), yaw)
	box(pos + Vector3.UP * 2.82 + normal * 0.28, Vector3(3.05, 0.075, 0.35), paint, yaw)
	for side in [-1.0, 1.0]:
		box(pos + tangent * side * 1.22 + Vector3.UP * 2.32 + normal * 0.36, Vector3(0.23, 0.16, 0.23), paint.lightened(0.12), yaw)
	for i in 7:
		var stripe: Color = Color("eee0bf") if i % 2 == 0 else paint.lightened(0.14)
		var p := pos + tangent * (i - 3) * 0.4 + Vector3.UP * 2.64 + normal * 0.66
		var basis := Basis(Vector3.UP, yaw)
		var slope := 0.18 if basis.z.dot(normal) > 0.0 else -0.18
		basis = basis * Basis(Vector3.RIGHT, slope)
		batch.add_transform("box", Transform3D(basis.scaled_local(Vector3(0.4, 0.06, 0.75)), p), stripe)
		box(p + normal * 0.36 - Vector3.UP * 0.13, Vector3(0.4, 0.16, 0.04), stripe, yaw)
	var sign_pos := pos + tangent * 1.46 + Vector3.UP * 2.2 + normal * 0.86
	box(sign_pos + Vector3.UP * 0.37 - normal * 0.3, Vector3(0.06, 0.07, 0.85), paint.darkened(0.25), yaw, "metal")
	batch.add("sphere", sign_pos, Vector3(0.12, 0.58, 0.58), Color("bfa36b"), yaw, "metal")
	for side in [-1.0, 1.0]:
		batch.add("sphere", sign_pos + tangent * side * 0.055, Vector3(0.035, 0.48, 0.48), paint, yaw)
	box(pos + tangent * 0.65 + Vector3.UP * 1.15 + normal * 0.37, Vector3(0.06, 0.2, 0.06), Color("c5ba94"), yaw, "metal")
	stats.shopfronts += 1

func facade(outline: PackedVector2Array, building: Dictionary, h: float) -> void:
	stats.buildings += 1
	var id := int(building.id)
	var center := Vector2.ZERO
	for p in outline:
		center += p
	center /= outline.size()
	var landmark := id in [417795500, 897476177]
	var school := id == 215468999
	# Fuori dal corridoio di guida restano volumi e coperture reali; evitare migliaia
	# di dettagli lontani allargando la mappa fino al fondo di Via Trento.
	var detailed_area := near_route(Vector3(center.x, 0, center.y))
	if not detailed_area and not landmark and not school:
		return
	if school:
		school_model.facade(self, outline, h)
		return
	if reference != null and not landmark and not school:
		var profile: Dictionary = reference.profile(building, center)
		if not profile.is_empty():
			reference.facade(self, outline, h, profile)
			return
	var shed: bool = building.get("kind", "") in ["garage", "garages", "shed"]
	var shutter: Color = Color("5f8a72") if landmark else shutter_palette[posmod(id * 3, shutter_palette.size())]
	var frame := Color("d6d1c5")
	var trim_color := wall_color(building).lerp(Color("eedbc4"), 0.55)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var length := a.distance_to(b)
		if length < 2.4:
			continue
		var tangent := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
		var normal := Vector3(tangent.z, 0, -tangent.x)
		var middle := Vector3((a.x + b.x) / 2, 0, (a.y + b.y) / 2)
		if normal.dot(middle - Vector3(center.x, 0, center.y)) < 0:
			normal = -normal
		var yaw := atan2(-tangent.z, tangent.x)
		var street_side := faces_street(middle, normal) if not shed else false
		var detailed := not landmark and not school and not shed and street_side and near_route(middle)
		var shutters := landmark or id % 3 == 0
		if detailed:
			stats.detailed_facades += 1
			paved_frontage(a, b, normal, yaw)
		# Zoccolo in pietra e cornicione sotto la gronda.
		box(middle + Vector3.UP * 0.35 + normal * 0.05, Vector3(length, 0.7, 0.12), Color("b3a48a"), yaw)
		box(middle + Vector3.UP * (h - 0.2) + normal * 0.13, Vector3(length + 0.2, 0.24, 0.32), trim_color, yaw)
		box(middle + Vector3.UP * (h - 0.42) + normal * 0.08, Vector3(length + 0.1, 0.1, 0.18), trim_color, yaw)
		# Fasce tra i piani, grondaia e pluviale nei gruppi MultiMesh condivisi.
		var floors := maxi(1, floori(h / 3.0))
		for level in range(1, floors):
			box(middle + Vector3.UP * (2.85 + (level - 1) * 2.8) + normal * 0.07, Vector3(length, 0.14, 0.18), trim_color, yaw)
		box(middle + Vector3.UP * (h - 0.03) + normal * 0.25, Vector3(length + 0.3, 0.12, 0.15), Color("71847f"), yaw, "metal")
		if length > 5.0 and not shed:
			var pipe := Vector3(b.x, 0, b.y) - tangent * 0.3 + normal * 0.23
			cylinder(pipe + Vector3.UP * (h - 0.15) * 0.5, 0.105, h - 0.15, Color("788c85"), "metal")
			for y in [0.5, h * 0.5, h - 0.6]:
				box(pipe + Vector3.UP * y, Vector3(0.18, 0.07, 0.18), Color("586f69"), yaw, "metal")
		if id == 417795500 or shed:
			continue
		var columns := mini(12, maxi(1, floori(length / 3.3)))
		var has_shop: bool = building.get("commercial", false) and length > 7.0 and street_side
		for floor_index in floors:
			for col in columns:
				var pos := Vector3(a.x, 0, a.y) + tangent * (length * (col + 0.5) / columns)
				pos += Vector3.UP * (1.65 + floor_index * 2.8) + normal * 0.09
				var serial := posmod(id + floor_index * 17 + col * 31, 13)
				if floor_index == 0 and has_shop and col == columns / 2:
					shopfront(pos - Vector3.UP * 1.65, tangent, normal, yaw, id)
					continue
				# Porta al piano terra al posto di qualche finestra.
				if floor_index == 0 and detailed and col == 0:
					portal(pos - Vector3.UP * 1.65, tangent, normal, yaw, id)
					continue
				if floor_index == 0 and not school and serial == 0:
					box(pos - Vector3.UP * 0.45 + normal * 0.02, Vector3(1.45, 2.5, 0.12), frame, yaw)
					box(pos - Vector3.UP * 0.5 + normal * 0.08, Vector3(1.15, 2.3, 0.1), Color("6e4b33"), yaw)
					box(pos - Vector3.UP * 1.6 + normal * 0.3, Vector3(1.6, 0.14, 0.5), Color("b9ad98"), yaw)
					continue
				box(pos, Vector3(1.15, 1.55, 0.13), frame, yaw)
				box(pos + normal * 0.08, Vector3(0.91, 1.31, 0.12), Color("658fa4").darkened(float(serial % 4) * 0.035), yaw, "window")
				box(pos + normal * 0.16, Vector3(0.07, 1.32, 0.05), frame, yaw)
				box(pos + normal * 0.16, Vector3(0.92, 0.06, 0.05), frame, yaw)
				if landmark:
					window_stonework(pos, tangent, normal, yaw, frame, id)
				if not school and shutters:
					if serial in [3, 8]:
						# Persiane chiuse: un tocco di vita sulle facciate.
						box(pos + normal * 0.2, Vector3(0.95, 1.36, 0.06), shutter, yaw, "shutter")
					else:
						for side in [-1, 1]:
							box(pos + tangent * side * 0.77 + normal * 0.08, Vector3(0.37, 1.49, 0.14), shutter, yaw, "shutter")
				box(pos - Vector3.UP * 0.81 + normal * 0.15, Vector3(1.4, 0.12, 0.4), frame, yaw)
				stats.windows += 1
				if not school and floor_index >= 1 and col % 3 == id % 3:
					box(pos - Vector3.UP * 0.83 + normal * 0.45, Vector3(1.8, 0.16, 1.0), Color("d8c6a6"), yaw)
					box(pos - Vector3.UP * 0.35 + normal * 0.91, Vector3(1.8, 0.06, 0.06), Color("3c4b4a"), yaw, "metal")
					for rail in 7:
						box(pos + tangent * (rail - 3) * 0.28 - Vector3.UP * 0.59 + normal * 0.91, Vector3(0.04, 0.48, 0.04), Color("3c4b4a"), yaw, "metal")
					# Vasi fioriti sul balcone.
					if serial % 2 == 0:
						var pot := pos - Vector3.UP * 0.62 + normal * 0.62 + tangent * 0.5
						box(pot, Vector3(0.5, 0.26, 0.24), Color("c0714d"), yaw)
						batch.add("blob", pot + Vector3.UP * 0.22, Vector3(0.55, 0.35, 0.32), [Color("e5566a"), Color("f2c14e"), Color("e98ab4")][serial % 3], yaw, "foliage")

func chimney(pos: Vector3, height_above: float) -> void:
	box(pos + Vector3.UP * height_above * 0.5, Vector3(0.55, height_above, 0.55), Color("b56a50"))
	box(pos + Vector3.UP * height_above, Vector3(0.75, 0.12, 0.75), Color("8e5440"))

func tree(pos: Vector3, seed_value: int) -> void:
	var size := 0.85 + float(posmod(seed_value * 13, 5)) * 0.09
	var kind := posmod(seed_value, 7)
	stats.trees += 1
	if kind == 0:
		# Cipresso slanciato.
		batch.add("trunk", pos + Vector3.UP * 0.6 * size, Vector3(0.4, 1.2, 0.4) * size, Color("7a5a40"))
		batch.add("cone", pos + Vector3.UP * 4.0 * size, Vector3(1.9, 7.2, 1.9) * size, Color("3f6d43"), 0.0, "foliage")
		batch.add("cone", pos + Vector3.UP * 2.6 * size, Vector3(2.3, 4.4, 2.3) * size, Color("4a7a49"), float(seed_value), "foliage")
		return
	var leaves: Color = leaf_palette[posmod(seed_value * 31, leaf_palette.size())]
	if posmod(seed_value * 17, 9) == 0:
		leaves = autumn_palette[posmod(seed_value, autumn_palette.size())]
	var yaw := float(posmod(seed_value * 7, 628)) / 100.0
	batch.add("trunk", pos + Vector3.UP * 1.6 * size, Vector3(0.5, 3.2, 0.5) * size, Color("86664a"))
	batch.add("blob", pos + Vector3.UP * 3.9 * size, Vector3(3.8, 3.3, 3.8) * size, leaves, yaw, "foliage")
	batch.add("blob", local(pos, yaw, Vector3(0.9, 4.7, 0.3)) + Vector3.UP * (size - 1.0) * 4.7, Vector3(2.6, 2.4, 2.6) * size, leaves.lightened(0.12), yaw + 1.0, "foliage")
	batch.add("blob", local(pos, yaw, Vector3(-0.8, 4.4, -0.6)) + Vector3.UP * (size - 1.0) * 4.4, Vector3(2.3, 2.1, 2.3) * size, leaves.darkened(0.08), yaw + 2.0, "foliage")

func bush(pos: Vector3, seed_value: int, scale_factor: float = 1.0) -> void:
	var leaves: Color = leaf_palette[posmod(seed_value, leaf_palette.size())].darkened(0.1)
	batch.add("blob", pos + Vector3.UP * 0.45 * scale_factor, Vector3(1.6, 1.1, 1.5) * scale_factor, leaves, float(seed_value), "foliage")
	if seed_value % 3 == 0:
		for i in 4:
			var angle := float(i) * TAU / 4.0 + float(seed_value)
			batch.add("blob", pos + Vector3(cos(angle) * 0.5, 0.95, sin(angle) * 0.45) * scale_factor, Vector3.ONE * 0.24 * scale_factor, [Color("f2f0e6"), Color("e98ab4"), Color("f5c94e")][seed_value % 3], 0.0, "foliage")

func grass_tuft(pos: Vector3, seed_value: int) -> void:
	var tone: Color = leaf_palette[posmod(seed_value, leaf_palette.size())].darkened(0.05)
	var s := 0.7 + float(posmod(seed_value * 5, 6)) * 0.12
	batch.add("cone", pos + Vector3.UP * 0.18 * s, Vector3(0.35, 0.45, 0.35) * s, tone, float(seed_value), "foliage")
	batch.add("cone", pos + Vector3(0.14, 0.14, 0.08) * s, Vector3(0.28, 0.32, 0.28) * s, tone.lightened(0.1), float(seed_value) + 1.0, "foliage")
	if posmod(seed_value, 4) == 0:
		var petal: Color = [Color("ffffff"), Color("ffd84a"), Color("f28cb1"), Color("b99af2")][posmod(seed_value / 4, 4)]
		batch.add("blob", pos + Vector3(-0.08, 0.42, 0.05) * s, Vector3.ONE * 0.16 * s, petal, 0.0, "foliage")

func lamp(pos: Vector3, yaw: float) -> void:
	var pole := Color("747873")
	cylinder(pos + Vector3.UP * 0.25, 0.32, 0.5, pole, "metal")
	cylinder(pos + Vector3.UP * 2.8, 0.13, 5.6, pole, "metal")
	box(local(pos, yaw, Vector3(0.45, 5.55, 0)), Vector3(0.9, 0.1, 0.1), pole, yaw, "metal")
	box(local(pos, yaw, Vector3(0.85, 5.35, 0)), Vector3(0.42, 0.18, 0.42), pole, yaw, "metal")
	box(local(pos, yaw, Vector3(0.85, 5.24, 0)), Vector3(0.36, 0.025, 0.36), Color("dddcd3"), yaw)
	stats.lamps += 1

func bollard(pos: Vector3) -> void:
	var metal := Color("476d59")
	cylinder(pos + Vector3.UP * 0.055, 0.23, 0.11, metal.darkened(0.14), "metal")
	cylinder(pos + Vector3.UP * 0.43, 0.13, 0.8, metal, "metal")
	cylinder(pos + Vector3.UP * 0.78, 0.17, 0.08, metal.lightened(0.12), "metal")
	sphere(pos + Vector3.UP * 0.88, Vector3.ONE * 0.18, metal, "metal")

func bench(pos: Vector3, yaw: float) -> void:
	var wood := Color("c08a55")
	for k in 3:
		box(local(pos, yaw, Vector3(0, 0.55, -0.22 + k * 0.22)), Vector3(2.1, 0.07, 0.18), wood.darkened(k * 0.04), yaw)
	for k in 2:
		box(local(pos, yaw, Vector3(0, 0.8 + k * 0.24, 0.32)), Vector3(2.1, 0.16, 0.06), wood, yaw)
	for side in [-1, 1]:
		box(local(pos, yaw, Vector3(side * 0.85, 0.3, 0.02)), Vector3(0.08, 0.6, 0.62), Color("3c4b4a"), yaw, "metal")
		box(local(pos, yaw, Vector3(side * 0.85, 0.85, 0.33)), Vector3(0.08, 0.6, 0.06), Color("3c4b4a"), yaw, "metal")
	stats.benches += 1

func planter(pos: Vector3) -> void:
	cylinder(pos + Vector3.UP * 0.3, 1.4, 0.6, Color("c47a55"))
	cylinder(pos + Vector3.UP * 0.62, 1.5, 0.08, Color("d79470"))
	batch.add("blob", pos + Vector3.UP * 0.8, Vector3(1.2, 0.6, 1.2), Color("6a9a4c"), 0.0, "foliage")
	for i in 6:
		var angle := float(i) * TAU / 6
		batch.add("blob", pos + Vector3(cos(angle) * 0.38, 1.02, sin(angle) * 0.38), Vector3.ONE * 0.26, [Color("f5c04e"), Color("e5566a"), Color("f2f0e6")][i % 3], 0.0, "foliage")

func parked_car(pos: Vector3, yaw: float) -> void:
	var color: Color = car_palette[posmod(int(pos.x * 7.0 + pos.z * 3.0), car_palette.size())]
	var shape := Vector3(0.98, 0.98, 0.95)
	batch.add("car_body", pos, shape, color, yaw, "paint")
	batch.add("car_glass", pos, shape, Color("2e4a57"), yaw, "glass")
	var wheel_basis := Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI / 2.0) * Basis.from_scale(Vector3(0.64, 0.24, 0.64))
	for x in [-0.78, 0.78]:
		for z in [-1.12, 1.12]:
			batch.add_transform("cylinder", Transform3D(wheel_basis, local(pos, yaw, Vector3(x, 0.32, z))), Color("2d3437"))
	for x in [-0.55, 0.55]:
		box(local(pos, yaw, Vector3(x, 0.74, 1.79)), Vector3(0.32, 0.14, 0.06), Color("fff3cf"), yaw, "glow")
		box(local(pos, yaw, Vector3(x, 0.8, -1.73)), Vector3(0.3, 0.14, 0.06), Color("d8473f"), yaw)
	stats.cars += 1
	parked_colliders.append([pos, yaw])

func add_collisions(parent: Node3D) -> void:
	for entry: Array in parked_colliders:
		var body := StaticBody3D.new()
		body.position = entry[0] + Vector3.UP * 0.8
		body.rotation.y = entry[1]
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.7, 1.6, 3.4)
		collision.shape = shape
		body.add_child(collision)
		parent.add_child(body)

func landmarks(parent: Node3D, ids: Dictionary) -> void:
	# Facciata occidentale della chiesa, sull'impronta OSM 417795500.
	if ids.has(417795500):
		var origin: Vector3 = ids[417795500].origin
		# Coordinate ottenute dalla stessa proiezione della mappa, incluse configurazioni private.
		var scale_factor: float = ids[417795500].scale
		var root := Node3D.new()
		root.name = "ChiesaSantiPietroPaolo"
		root.position = origin
		root.scale = Vector3.ONE * scale_factor
		parent.add_child(root)
		var facade_shape := CSGPolygon3D.new()
		facade_shape.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(10, 0), Vector2(10, 9), Vector2(6, 9), Vector2(6, 13), Vector2(0, 16), Vector2(-6, 13), Vector2(-6, 9), Vector2(-10, 9)])
		facade_shape.depth = 0.45
		facade_shape.rotation.y = PI / 2
		facade_shape.material = G.material(Color("ecd6ab"))
		root.add_child(facade_shape)
		G.box(root, Vector3(-0.65, 2.3, 0), Vector3(0.2, 4.6, 2.8), Color("6e4b33"))
		G.box(root, Vector3(-0.6, 4.75, 0), Vector3(0.3, 0.3, 3.4), Color("f6e8c8"))
		# Rosone e portali laterali, semplificati dalla fotografia comunale.
		var rose := G.sphere(root, Vector3(-0.65, 8, 0), 1.3, Color("4f7690"))
		rose.scale = Vector3(0.08, 1, 1)
		rose.material_override = Materials.glass(Color(0.3, 0.46, 0.56, 0.95))
		var rose_frame := G.cylinder(root, Vector3(-0.6, 8, 0), 1.45, 0.12, Color("f6e8c8"))
		rose_frame.rotation.z = PI / 2
		for z in [-7.5, 7.5]:
			G.box(root, Vector3(-0.65, 2, z), Vector3(0.2, 4, 1.6), Color("7a5a40"))
		for z in [-9.5, -5.5, 5.5, 9.5]:
			G.cylinder(root, Vector3(-0.7, 5.8, z), 0.15, 11.6, Color("f6e8c8"))
			var spire := CylinderMesh.new()
			spire.top_radius = 0
			spire.bottom_radius = 0.35
			spire.height = 1.9
			G.mesh(root, spire, Vector3(-0.2, 12.4, z), Color("5f7a76"))
		var cross := G.box(root, Vector3(-0.3, 17.0, 0), Vector3(0.12, 1.4, 0.12), Color("e3c27a"))
		cross.material_override = Materials.metal(Color("e3c27a"), 0.3)
		G.box(root, Vector3(-0.3, 17.2, 0), Vector3(0.12, 0.12, 0.8), Color("e3c27a")).material_override = cross.material_override
		G.label(root, "SANTI PIETRO E PAOLO", Vector3(-1, 18.5, 0), 28).billboard = BaseMaterial3D.BILLBOARD_ENABLED
		stats.landmarks += 1
	if ids.has(215468999):
		var root := Node3D.new()
		root.name = "PlessoViaTrieste"
		root.position = ids[215468999].origin
		root.scale = Vector3.ONE * float(ids[215468999].scale)
		parent.add_child(root)
		var text := G.label(root, "PLESSO DI VIA TRIESTE\nGuglielmo da Volpiano · Arcobaleno", Vector3(0, 8, 0), 32)
		text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		# Arcobaleno decorativo sopra l'insegna, simbolo cartoon della scuola.
		var colors := [Color("e2574c"), Color("f2b33d"), Color("f5df5a"), Color("63c2a5"), Color("4f8fd6"), Color("8f74d1")]
		# Due archi incrociati: visibili da ogni lato, metà inferiore nascosta nel tetto.
		for turn in [0.0, PI / 2.0]:
			for i in colors.size():
				var arc := MeshInstance3D.new()
				var torus := TorusMesh.new()
				torus.inner_radius = 3.4 - i * 0.26
				torus.outer_radius = 3.66 - i * 0.26
				torus.rings = 40
				torus.ring_segments = 6
				arc.mesh = torus
				arc.material_override = Materials.plastic(colors[i], 0.4)
				arc.position = Vector3(0, 6.4, 0)
				arc.rotation = Vector3(PI / 2, turn, 0)
				root.add_child(arc)
		stats.landmarks += 1
	if ids.has(897476177):
		var pos: Vector3 = ids[897476177].origin
		var root := Node3D.new()
		root.name = "MunicipioVolpiano"
		root.position = pos
		root.scale = Vector3.ONE * float(ids[897476177].scale)
		parent.add_child(root)
		G.box(root, Vector3(0, 1.8, 0.14), Vector3(2, 3.6, 0.2), Color("6e4b33"))
		G.box(root, Vector3(0, 3.8, 0.8), Vector3(4.5, 0.2, 1.6), Color("eedcbc"))
		G.box(root, Vector3(0, 4.4, 1.5), Vector3(4.5, 0.08, 0.08), Color("3c4b4a"))
		for i in 9:
			G.box(root, Vector3((i-4)*0.5, 4.1, 1.5), Vector3(0.05, 0.6, 0.05), Color("3c4b4a"))
		G.label(root, "MUNICIPIO", Vector3(0, 6.9, 0.2), 32)
		G.cylinder(root, Vector3(3.6, 4.6, 0.25), 0.04, 2.4, Color("c9c9c0"))
		for i in 3:
			G.box(root, Vector3(3.8+i*0.36, 5.3, 0.25), Vector3(0.36, 1.0, 0.08), [Color("3f9a5c"), Color("f6f1e1"), Color("d34a45")][i])
		stats.landmarks += 1
