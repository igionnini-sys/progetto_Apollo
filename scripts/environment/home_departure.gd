extends Node3D
## Casa e cancello dalle foto esterne dell'utente. Posizione e civico solo in local/.
## Riferimento locale: cancello su z = 0, cortile verso +z, sinistra entrando (casa) = +x.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const Meshes = preload("res://scripts/utilities/meshes.gd")
const Batch = preload("res://scripts/environment/town_batch.gd")
var settings: Dictionary = {}
var vehicle: CharacterBody3D
var leaves: Array[AnimatableBody3D] = []
var opening := 0.0
var automatic := true
var batch = Batch.new()
## Apollo parte nel cortile con il muso fuori dalla corsa delle ante (2,58 m).
const SPAWN_DEPTH := 7.0
## Casa sull'impronta OSM d'angolo: timpano su Via Trento, fronte lungo sul cortile (-x).
const HOUSE_X0 := 5.4
const HOUSE_W := 10.6
const HOUSE_Z0 := 0.6
const HOUSE_D := 12.0
## Scala esterna: sale verso la strada fino al pianerottolo del balcone.
const STAIR_TOP := 3.1
const STAIR_STEPS := 13
const RAIL := Color("b4b8b1")
const IRON := Color("5d5c5a")
var plaster := Color("cf8360")
# Casa, cortile e giardino con le palme lungo Via Trento.
var property_outline := PackedVector2Array([Vector2(-18.4, -1.6), Vector2(16.8, -1.6), Vector2(16.8, 14.2), Vector2(-18.4, 14.2)])
## Dall'altra parte di Via Trento: vicolo di ghiaia con palazzo, capannone e casa della bambina.
const LANE_X0 := -2.4
const LANE_X1 := 2.6
const LANE_Z0 := -11.0
const LANE_Z1 := -38.5
var lane_outline := PackedVector2Array([Vector2(-22.0, -10.0), Vector2(11.0, -10.0), Vector2(11.0, -47.0), Vector2(-22.0, -47.0)])

static func load_settings(tree: SceneTree) -> Dictionary:
	# I test pubblici restano riproducibili senza configurazioni personali della macchina.
	var runner: Script = tree.get_script()
	if runner != null and runner.resource_path.begins_with("res://tests/") and not "--with-home" in OS.get_cmdline_user_args():
		return {}
	if not FileAccess.file_exists("res://local/home_departure.json"):
		return {}
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://local/home_departure.json"))
	return result if result is Dictionary and result.get("enabled", false) else {}

static func resolve(data: Dictionary, config: Dictionary) -> Dictionary:
	if config.is_empty():
		return {}
	var trento_points: Array = []
	for road: Dictionary in data.roads:
		if road.name == "Via Trento":
			trento_points.append_array(road.points)
	for road: Dictionary in data.roads:
		if road.name != str(config.get("corner_street", "")):
			continue
		for p: Array in road.points:
			if p in trento_points:
				var result := config.duplicate(true)
				var offset: Array = config.get("gate_offset_from_corner", [0, 0])
				if offset.size() != 2 or not data.nodes.has(str(config.get("public_join_node", ""))):
					return {}
				result["origin"] = [float(p[0]) + float(offset[0]), float(p[1]) + float(offset[1])]
				return result
	return {}

static func path_to(data: Dictionary, start: String, goal: String) -> Array:
	var adjacency: Dictionary = {}
	for edge: Array in data.edges:
		if not adjacency.has(edge[0]):
			adjacency[edge[0]] = []
		adjacency[edge[0]].append(edge[1])
	var costs := {start: 0.0}
	var previous: Dictionary = {}
	var queue: Array = [start]
	while not queue.is_empty():
		queue.sort_custom(func(a: String, b: String) -> bool: return costs[a] < costs[b])
		var current: String = queue.pop_front()
		if current == goal:
			var path: Array = [goal]
			while path[0] != start:
				path.push_front(previous[path[0]])
			return path
		var a := Vector2(data.nodes[current][0], data.nodes[current][1])
		for other: String in adjacency.get(current, []):
			var b := Vector2(data.nodes[other][0], data.nodes[other][1])
			var cost: float = costs[current] + a.distance_to(b)
			if cost < float(costs.get(other, INF)):
				costs[other] = cost
				previous[other] = current
				if not queue.has(other):
					queue.append(other)
	return []

static func attach_route(data: Dictionary, config: Dictionary) -> bool:
	var path := path_to(data, str(config.public_join_node), str(data.route[0]))
	if path.is_empty():
		return false
	var gate := Vector2(config.origin[0], config.origin[1])
	var street := Vector2.INF
	for road: Dictionary in data.roads:
		if road.name != "Via Trento" or not road.drivable:
			continue
		for i in range(road.points.size() - 1):
			var a := Vector2(road.points[i][0], road.points[i][1])
			var b := Vector2(road.points[i + 1][0], road.points[i + 1][1])
			var p := Geometry2D.get_closest_point_to_segment(gate, a, b)
			if p.distance_squared_to(gate) < street.distance_squared_to(gate):
				street = p
	if not is_finite(street.x) or street.distance_to(gate) > 20.0:
		return false
	var inside := Basis(Vector3.UP, deg_to_rad(float(config.get("yaw_degrees", 0)))) * Vector3(0, 0, SPAWN_DEPTH)
	data.nodes["home_spawn"] = [gate.x + inside.x, gate.y + inside.z]
	data.nodes["home_street"] = [street.x, street.y]
	# Raccordo privato dichiarato, solo in memoria: nessun falso arco OSM distribuito.
	data.route = ["home_spawn", "home_street"] + path.slice(0, path.size() - 1) + data.route
	data.metadata["local_home_departure"] = true
	return true

func _ready() -> void:
	name = "CasaApollo"
	house()
	street_front()
	garden()
	lane()
	apartment_block()
	warehouse()
	girl_house()
	box(Vector3(1.0, -0.082, 7.0), Vector3(7.6, 0.03, 14.0), Color.WHITE, false, "trento_paving")
	box(Vector3(1.0, -0.079, -0.4), Vector3(7.6, 0.025, 0.8), Color.WHITE, false, "trento_paving")
	var details := Node3D.new()
	details.name = "DettagliCasa"
	add_child(details)
	batch.flush(details)
	make_leaf(-2.6, 1.0)
	make_leaf(2.6, -1.0)
	if str(settings.get("house_number", "")) != "":
		var label := G.label(self, str(settings.house_number), Vector3(2.6, 1.7, -0.29), 32)
		label.rotation.y = PI
		label.pixel_size = 0.006
		label.outline_size = 0
		label.modulate = Color("49483f")

func box(pos: Vector3, size: Vector3, color: Color, solid: bool = false, look: String = "plain") -> void:
	batch.add("box", pos, size, color, 0.0, look)
	if solid:
		var body := StaticBody3D.new()
		body.position = pos
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		add_child(body)

## Elemento di facciata: `offset` nel riferimento della parete, -z verso l'esterno.
func facade_box(origin: Vector3, yaw: float, offset: Vector3, size: Vector3, color: Color, look: String = "plain") -> void:
	batch.add("box", origin + Basis(Vector3.UP, yaw) * offset, size, color, yaw, look)

func beam(a: Vector3, b: Vector3, thickness: float, color: Color, target_batch: RefCounted = null) -> void:
	if target_batch == null:
		target_batch = batch
	var direction := b - a
	var basis := Basis(Quaternion(Vector3.UP, direction.normalized())).scaled_local(Vector3(thickness, direction.length(), thickness))
	target_batch.add_transform("cylinder", Transform3D(basis, (a + b) * 0.5), color, "metal")

func house() -> void:
	# Timpano giallo sulla strada; fronte arancione con balcone lungo verso il cortile.
	box(Vector3(HOUSE_X0 + HOUSE_W * 0.5, 3.3, HOUSE_Z0 + HOUSE_D * 0.5), Vector3(HOUSE_W, 6.6, HOUSE_D), plaster, true)
	box(Vector3(HOUSE_X0 + HOUSE_W * 0.5, 3.3, HOUSE_Z0 - 0.03), Vector3(HOUSE_W + 0.02, 6.6, 0.06), Color("e2c58e"))
	for item in [[Vector3(HOUSE_X0 - 0.04, 0.4, HOUSE_Z0 + HOUSE_D * 0.5), Vector3(0.1, 0.8, HOUSE_D)], [Vector3(HOUSE_X0 + HOUSE_W * 0.5, 0.4, HOUSE_Z0 - 0.08), Vector3(HOUSE_W, 0.8, 0.1)]]:
		box(item[0], item[1], Color("d9cdb3"), false, "stone")
	var street := Vector3(0, 0, HOUSE_Z0)
	for x in [8.4, 13.6]:
		window(street + Vector3(x, 4.7, 0), 0.0, 1.6)
		window(street + Vector3(x, 1.95, 0), 0.0, 1.35)
	window(street + Vector3(HOUSE_X0 + HOUSE_W * 0.5, 7.7, 0), 0.0, 0.7, 0.7)
	# Fronte sul cortile: porta finestre al piano del balcone, piano rialzato sotto.
	var court := Vector3(HOUSE_X0, 0, 0)
	for z in [3.0, 6.9, 10.8]:
		window(court + Vector3(0, 4.55, z), PI * 0.5, 2.1)
	window(court + Vector3(0, 1.9, 6.9), PI * 0.5, 1.3)
	window(court + Vector3(0, 1.9, 10.8), PI * 0.5, 1.3)
	door(court + Vector3(0, 0, 1.8), PI * 0.5)
	for z in [3.5, 9.5]:
		window(Vector3(HOUSE_X0 + HOUSE_W, 4.6, z), -PI * 0.5, 1.6)
	for x in [HOUSE_X0 - 0.06, HOUSE_X0 + HOUSE_W + 0.06]:
		batch.add("cylinder", Vector3(x, 3.3, HOUSE_Z0 - 0.08), Vector3(0.10, 6.6, 0.10), Color("8a7660"), 0.0, "metal")
	# Fronte opposto, visto dal vicolo: finestra al piano, porta e finestra al piano terra.
	var back := HOUSE_Z0 + HOUSE_D
	window(Vector3(HOUSE_X0 + 2.6, 4.7, back), PI, 1.5)
	window(Vector3(HOUSE_X0 + 2.6, 1.9, back), PI, 1.3)
	door(Vector3(HOUSE_X0 + 7.0, 0, back), PI)
	window(Vector3(HOUSE_X0 + HOUSE_W * 0.5, 7.7, back), PI, 0.7, 0.7)
	balcony()
	roof()

## Balcone lungo con mensole, parapetti bianchi e scala che sale verso la strada.
func balcony() -> void:
	var edge := HOUSE_X0 - 1.3
	var z1 := HOUSE_Z0 + HOUSE_D
	box(Vector3(HOUSE_X0 - 0.65, 3.3, (HOUSE_Z0 + z1) * 0.5), Vector3(1.3, 0.22, z1 - HOUSE_Z0), Color("e8e4d8"))
	for z in [HOUSE_Z0 + 0.4, 4.9, 8.9, z1 - 0.4]:
		box(Vector3(HOUSE_X0 - 0.35, 2.95, z), Vector3(0.7, 0.5, 0.18), Color("e8e4d8"))
	# Parapetti pieni all'angolo e accanto alla scala, ringhiera nel resto.
	box(Vector3(edge + 0.06, 3.95, HOUSE_Z0 + 0.5), Vector3(0.12, 1.1, 1.0), Color("f0ede4"))
	box(Vector3(edge + 0.06, 3.95, 8.0), Vector3(0.12, 1.1, 1.6), Color("f0ede4"))
	fence_panel(Vector3(edge + 0.06, 3.41, STAIR_TOP), Vector3(edge + 0.06, 3.41, 7.2), 0.0, 1.0)
	fence_panel(Vector3(edge + 0.06, 3.41, 8.8), Vector3(edge + 0.06, 3.41, z1 - 0.06), 0.0, 1.0)
	# Pianerottolo e rampa fuori dal balcone, liberi dalla corsa delle ante.
	var stair_x := edge - 0.62
	box(Vector3(stair_x, 3.3, (HOUSE_Z0 + 1.0 + STAIR_TOP) * 0.5), Vector3(1.24, 0.22, STAIR_TOP - HOUSE_Z0 - 1.0), Color("e8e4d8"))
	box(Vector3(stair_x, 1.6, HOUSE_Z0 + 1.15), Vector3(0.3, 3.2, 0.3), Color("e8e4d8"), true)
	fence_panel(Vector3(edge - 1.2, 3.41, HOUSE_Z0 + 1.0), Vector3(edge - 1.2, 3.41, STAIR_TOP), 0.0, 1.0)
	fence_panel(Vector3(edge - 1.2, 3.41, HOUSE_Z0 + 1.0), Vector3(edge, 3.41, HOUSE_Z0 + 1.0), 0.0, 1.0)
	# Gradini a sbalzo su una soletta inclinata: sotto resta vuoto, come nella foto.
	for step in STAIR_STEPS:
		var h := (STAIR_STEPS - step) * 0.26
		var z: float = STAIR_TOP + (step + 0.5) * 0.42
		box(Vector3(stair_x, h - 0.13, z), Vector3(1.24, 0.26, 0.42), Color("e5e1d6"))
		beam(Vector3(edge - 1.2, h, z), Vector3(edge - 1.2, h + 0.95, z), 0.03, RAIL)
	var bottom := STAIR_TOP + STAIR_STEPS * 0.42
	var run := Vector3(0, -STAIR_STEPS * 0.26, bottom - STAIR_TOP)
	var slab := Basis(Vector3.RIGHT, -atan2(run.y, run.z)).scaled_local(Vector3(1.24, 0.2, run.length()))
	batch.add_transform("box", Transform3D(slab, Vector3(stair_x, STAIR_STEPS * 0.13 - 0.3, (STAIR_TOP + bottom) * 0.5)), Color("dedad0"))
	# Ingombro fisico unico della rampa, senza muro visibile.
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.24, 1.8, bottom - STAIR_TOP)
	collision.shape = shape
	blocker.position = Vector3(stair_x, 0.9, (STAIR_TOP + bottom) * 0.5)
	blocker.add_child(collision)
	add_child(blocker)
	beam(Vector3(edge - 1.2, 1.2, bottom), Vector3(edge - 1.2, 4.35, STAIR_TOP), 0.05, RAIL)
	for z in [4.2, 6.0, 10.0, 12.0]:
		box(Vector3(edge + 0.2, 3.62, z), Vector3(0.22, 0.2, 0.5), Color("a96545"))
		batch.add("blob", Vector3(edge + 0.1, 3.7, z), Vector3(0.55, 0.55, 0.6), Color("c94a86"), z, "foliage")

## Finestra con cornice, persiane brune e davanzale; `yaw` orienta la parete.
func window(wall: Vector3, yaw: float, h: float, w: float = 1.25) -> void:
	var pos := wall + Basis(Vector3.UP, yaw) * Vector3(0, 0, -0.1)
	facade_box(pos, yaw, Vector3.ZERO, Vector3(w + 0.25, h + 0.2, 0.12), Color("725044"))
	facade_box(pos, yaw, Vector3(0, 0, -0.08), Vector3(w, h, 0.08), Color("3e5158"), "window")
	facade_box(pos, yaw, Vector3(0, -h * 0.5 - 0.12, -0.1), Vector3(w + 0.4, 0.07, 0.26), Color("e3dfd2"))
	if w < 1.0:
		return
	for side in [-1.0, 1.0]:
		facade_box(pos, yaw, Vector3(side * (w * 0.5 + 0.35), 0, -0.07), Vector3(0.5, h + 0.2, 0.12), Color("5e4033"), "shutter")
	facade_box(pos, yaw, Vector3(0, 0, -0.14), Vector3(0.065, h, 0.04), Color("6b5041"))

func door(base: Vector3, yaw: float, w: float = 1.1, h: float = 2.2) -> void:
	facade_box(base, yaw, Vector3(0, h * 0.5 + 0.06, -0.02), Vector3(w + 0.24, h + 0.12, 0.12), Color("e3dfd2"))
	facade_box(base, yaw, Vector3(0, h * 0.5, -0.09), Vector3(w, h, 0.08), Color("6a4b3b"), "shutter")
	facade_box(base, yaw, Vector3(w * 0.3, h * 0.47, -0.15), Vector3(0.12, 0.04, 0.05), Color("c8b27a"), "metal")

func roof() -> void:
	var tiles := SurfaceTool.new()
	var gables := SurfaceTool.new()
	tiles.begin(Mesh.PRIMITIVE_TRIANGLES)
	gables.begin(Mesh.PRIMITIVE_TRIANGLES)
	tiles.set_color(Color("94644c"))
	gables.set_color(plaster)
	var middle := HOUSE_X0 + HOUSE_W * 0.5
	var slope := 2.8 / (HOUSE_W * 0.5)
	# Falde ampie come nella foto: colmo parallelo al fianco, timpano sulla strada.
	gable_roof(tiles, gables, Vector2(middle, HOUSE_Z0 + HOUSE_D * 0.5), HOUSE_W, HOUSE_D, 6.6, 9.4, true, 0.9)
	for side in [-1.0, 1.0]:
		var x: float = middle + side * (HOUSE_W * 0.5 + 0.9)
		box(Vector3(x, 6.6 - 0.9 * slope - 0.1, HOUSE_Z0 + HOUSE_D * 0.5), Vector3(0.08, 0.26, HOUSE_D + 1.8), Color("6b4a35"))
	# Timpano giallo verso la strada, sopra il colore del corpo.
	gables.set_color(Color("e2c58e"))
	Meshes.triangle(gables, Vector3(HOUSE_X0, 6.6, HOUSE_Z0 - 0.04), Vector3(HOUSE_X0 + HOUSE_W, 6.6, HOUSE_Z0 - 0.04), Vector3(middle, 9.4, HOUSE_Z0 - 0.04), Vector3.FORWARD)
	gables.set_color(plaster)
	# Abbaino sulla falda del cortile, con il suo piccolo timpano.
	var front := HOUSE_X0 + 1.6
	var roof_at := 6.6 + 1.6 * slope
	box(Vector3(front + 1.4, roof_at + 0.55, 6.9), Vector3(2.8, 1.8, 2.6), plaster)
	window(Vector3(front, roof_at + 0.45, 6.9), PI * 0.5, 0.95, 1.0)
	for side in [-1.0, 1.0]:
		var eave := Vector3(front - 0.35, roof_at + 1.35, 6.9 + side * 1.75)
		var ridge := Vector3(front - 0.35, roof_at + 1.95, 6.9)
		var back := Vector3(4.25, 0, 0)
		Meshes.triangle(tiles, eave, ridge, ridge + back, Vector3(0, 1, side), [Vector2(0, 0), Vector2(0, 1.85), Vector2(4.25, 1.85)])
		Meshes.triangle(tiles, eave, ridge + back, eave + back, Vector3(0, 1, side), [Vector2(0, 0), Vector2(4.25, 1.85), Vector2(4.25, 0)])
	Meshes.triangle(gables, Vector3(front, roof_at + 1.45, 5.6), Vector3(front, roof_at + 1.9, 6.9), Vector3(front, roof_at + 1.45, 8.2), Vector3.LEFT)
	for item in [[Vector3(middle - 2.2, 9.1, HOUSE_Z0 + 1.6), 1.8], [Vector3(middle + 2.0, 9.0, HOUSE_Z0 + 8.4), 1.6]]:
		box(item[0], Vector3(0.55, item[1], 0.55), Color("dcc9a7"))
		box(item[0] + Vector3.UP * (item[1] * 0.5 + 0.08), Vector3(0.8, 0.12, 0.8), Color("8f6d55"))
	for item in [[tiles, Materials.roofs(), "CoppiCasa"], [gables, Materials.walls(), "TimpaniCasa"]]:
		var mesh := MeshInstance3D.new()
		mesh.name = item[2]
		mesh.mesh = item[0].commit()
		mesh.material_override = item[1]
		add_child(mesh)

## Tetto a capanna su pianta rettangolare; colmo lungo z oppure lungo x.
func gable_roof(tiles: SurfaceTool, gables: SurfaceTool, center: Vector2, across: float, along: float, wall: float, ridge: float, along_z: bool, overhang: float = 0.4) -> void:
	var half := across * 0.5
	var drop := (ridge - wall) / half * overhang
	var at := func(u: float, y: float, v: float) -> Vector3:
		return Vector3(center.x + u, y, center.y + v) if along_z else Vector3(center.x + v, y, center.y + u)
	var length := along + overhang * 2.0
	var slope := Vector2(half + overhang, ridge - wall + drop).length()
	for side in [-1.0, 1.0]:
		var v0: float = -along * 0.5 - overhang
		var v1: float = along * 0.5 + overhang
		var e0: Vector3 = at.call(side * (half + overhang), wall - drop, v0)
		var e1: Vector3 = at.call(side * (half + overhang), wall - drop, v1)
		var r0: Vector3 = at.call(0.0, ridge, v0)
		var r1: Vector3 = at.call(0.0, ridge, v1)
		var outward: Vector3 = at.call(side, 1.0, 0.0) - at.call(0.0, 0.0, 0.0)
		Meshes.triangle(tiles, e0, e1, r1, outward, [Vector2(0, 0), Vector2(length, 0), Vector2(length, slope)])
		Meshes.triangle(tiles, e0, r1, r0, outward, [Vector2(0, 0), Vector2(length, slope), Vector2(0, slope)])
	for end in [-1.0, 1.0]:
		var v: float = end * along * 0.5
		var outward: Vector3 = at.call(0.0, 0.0, end) - at.call(0.0, 0.0, 0.0)
		Meshes.triangle(gables, at.call(-half, wall, v), at.call(half, wall, v), at.call(0.0, ridge, v), outward)

## Fronte su Via Trento: pilastro, cancelletto, cancello carraio, poi recinzione del giardino.
func street_front() -> void:
	for x in [HOUSE_X0 - 1.15, 2.6, -2.6, -7.6, -12.6, -17.6]:
		box(Vector3(x, 1.1, 0), Vector3(0.48, 2.2, 0.48), Color("b1704f"), true, "stone")
		box(Vector3(x, 2.25, 0), Vector3(0.62, 0.1, 0.62), Color("e4d9c0"))
	box(Vector3(HOUSE_X0 - 0.45, 0.35, 0), Vector3(0.9, 0.7, 0.3), Color("e6dcc4"), true)
	batch.add("blob", Vector3(HOUSE_X0 - 0.45, 0.95, 0), Vector3(0.8, 0.6, 0.4), Color("c94a86"), 0.0, "foliage")
	var posts := [-2.6, -7.6, -12.6, -17.6]
	for i in range(posts.size() - 1):
		fence_panel(Vector3(posts[i] - 0.24, 0, 0), Vector3(posts[i + 1] + 0.24, 0, 0), 0.6, 1.35)
	# Cancelletto pedonale chiuso davanti alla scala.
	var a := 2.85
	var b := HOUSE_X0 - 1.4
	for y in [0.15, 1.7]:
		beam(Vector3(a, y, 0), Vector3(b, y, 0), 0.04, RAIL)
	for i in 7:
		var x := lerpf(a, b, (i + 0.5) / 7.0)
		beam(Vector3(x, 0.05, 0), Vector3(x, 1.9, 0), 0.022, RAIL)
		batch.add("cone", Vector3(x, 1.97, 0), Vector3(0.05, 0.13, 0.05), RAIL, 0.0, "metal")

func garden() -> void:
	# Palme e alberi del giardino a sud del cancello, come nella foto.
	palm(Vector3(-5.8, 0, 3.4), 4.8)
	palm(Vector3(-12.5, 0, 2.6), 8.5)
	utility_pole(Vector3(-10.0, 0, -0.55), Vector3(HOUSE_X0 + 1.0, 6.2, HOUSE_Z0 + 0.5))
	for p in [Vector3(-16.5, 0, 6.5), Vector3(-9.0, 0, 9.5)]:
		batch.add("trunk", p + Vector3.UP * 1.5, Vector3(0.3, 3.0, 0.3), Color("6e5a45"))
		batch.add("blob", p + Vector3.UP * 4.2, Vector3(4.6, 3.6, 4.4), Color("4f6d3b"), p.x, "foliage")
	for p in [Vector3(-4.0, 0.6, 1.4), Vector3(-8.8, 0.7, 1.5), Vector3(-15.0, 0.6, 1.6), Vector3(-16.8, 0.8, 2.5), Vector3(-3.6, 0.7, 11.0)]:
		batch.add("blob", p, Vector3(1.8, 1.4, 1.6), Color("4d6a3c"), p.x, "foliage")

## Vicolo di ghiaia davanti al cancello di Apollo, con cancello scuro aperto e palo dei cavi.
func lane() -> void:
	var length := LANE_Z0 - LANE_Z1
	box(Vector3((LANE_X0 + LANE_X1) * 0.5, -0.08, (LANE_Z0 + LANE_Z1) * 0.5), Vector3(LANE_X1 - LANE_X0, 0.03, length), Color("a69f8f"))
	box(Vector3(-2.9, 1.0, LANE_Z0 - 0.5), Vector3(0.9, 2.0, 0.4), Color("b5b2a8"), true)
	for x in [LANE_X0 + 0.1, LANE_X1 - 0.1]:
		box(Vector3(x, 1.2, LANE_Z0 - 0.5), Vector3(0.14, 2.4, 0.14), IRON, true, "metal")
		fence_panel(Vector3(x, 0, LANE_Z0 - 0.5), Vector3(x, 0, LANE_Z0 - 2.9), 0.0, 1.9, IRON)
	utility_pole(Vector3(3.3, 0, LANE_Z0 + 0.4), Vector3(0.1, 5.6, LANE_Z1))

## Palazzo a sinistra del vicolo: mattoni rossi, fasce crema, balconi con ringhiera scura.
func apartment_block() -> void:
	var cx := -11.9
	var front := -12.0
	var width := 19.0
	var cream := Color("e9e2c8")
	box(Vector3(cx, 2.1, -23.0), Vector3(width + 0.04, 4.2, 22.04), Color("dcd8cc"), true)
	box(Vector3(cx, 11.7, -23.0), Vector3(width, 15.0, 22.0), Color("9a4a3a"), true)
	for i in 4:
		var bay := cx - width * 0.5 + 2.4 + i * 4.75
		box(Vector3(bay, 11.7, front + 0.04), Vector3(3.0, 15.0, 0.08), cream)
		for floor_index in 5:
			var y := 4.2 + floor_index * 3.0
			box(Vector3(bay - 0.6, y + 0.1, front + 0.65), Vector3(2.6, 0.2, 1.3), cream)
			box(Vector3(bay - 0.6, y + 0.65, front + 1.28), Vector3(2.6, 0.9, 0.05), Color("34384a"))
			beam(Vector3(bay - 1.9, y + 1.12, front + 1.28), Vector3(bay + 0.7, y + 1.12, front + 1.28), 0.05, Color("2a2e3c"))
			window(Vector3(bay + 0.95, y + 1.4, front), PI, 1.5, 0.9)
		window(Vector3(bay + 0.2, 2.0, front), PI, 1.2, 1.3)
	door(Vector3(cx - 6.0, 0, front), PI, 1.3, 2.4)
	for floor_index in 5:
		window(Vector3(LANE_X0, 5.6 + floor_index * 3.0, -14.5), -PI * 0.5, 1.2, 0.6)
	box(Vector3(cx, 19.4, -23.0), Vector3(width + 0.6, 0.4, 22.6), cream)
	box(Vector3(cx, 20.0, front - 0.2), Vector3(width + 0.6, 0.8, 0.06), Color("34384a"))
	box(Vector3(cx + 4.0, 20.6, -26.0), Vector3(5.0, 1.6, 5.0), cream)
	# Cancello scorrevole bianco davanti allo zoccolo, verso il vicolo.
	fence_panel(Vector3(-8.2, 0, front + 0.7), Vector3(-3.4, 0, front + 0.7), 0.0, 1.9, Color("e6e6e2"))

## Capannone rosso a destra del vicolo, con portone di assi e tetto piatto.
func warehouse() -> void:
	box(Vector3(7.0, 3.1, -23.0), Vector3(6.8, 6.2, 22.0), Color("a8362e"), true)
	box(Vector3(7.0, 6.3, -23.0), Vector3(7.2, 0.25, 22.6), Color("cfc8b8"))
	box(Vector3(8.4, 2.2, -11.94), Vector3(3.4, 4.4, 0.1), Color("7c6a55"), false, "shutter")
	box(Vector3(5.2, 1.7, -11.9), Vector3(3.0, 3.4, 0.15), Color("d7d1bf"))
	for z in [-16.0, -21.0]:
		window(Vector3(3.6, 3.6, z), PI * 0.5, 1.0, 0.9)
	# Nastro bianco e rosso lungo il bordo del vicolo.
	for z in [-14.0, -19.0, -24.0, -28.0]:
		box(Vector3(3.3, 0.8, z), Vector3(0.08, 1.6, 0.08), Color("7a6a58"))
	for i in 3:
		beam(Vector3(3.3, 0.5 + i * 0.4, -14.0), Vector3(3.3, 0.5 + i * 0.4, -28.0), 0.03, Color("d8392c") if i % 2 == 0 else Color("f2f2f2"))

## Casa della bambina in fondo al vicolo: due piani arancioni, timpano verso la strada, annesso basso.
func girl_house() -> void:
	var cz := LANE_Z1 - 4.0
	var tone := Color("e3996a")
	box(Vector3(0.1, 2.8, cz), Vector3(6.4, 5.6, 8.0), tone, true)
	box(Vector3(0.1, 0.5, cz), Vector3(6.5, 1.0, 8.1), Color("e9d6a2"))
	box(Vector3(0.1, 2.85, cz), Vector3(6.5, 0.15, 8.1), Color("f0e6d0"))
	window(Vector3(-1.2, 4.2, LANE_Z1), PI, 1.1, 1.0)
	window(Vector3(-1.2, 1.9, LANE_Z1), PI, 1.2, 1.0)
	door(Vector3(1.4, 0, LANE_Z1), PI, 1.0, 2.1)
	box(Vector3(5.0, 1.6, cz + 1.3), Vector3(3.6, 3.2, 5.4), Color("d98c64"), true)
	box(Vector3(5.0, 3.3, cz + 1.3), Vector3(3.8, 0.15, 5.6), Color("8a5a46"))
	var tiles := SurfaceTool.new()
	var gables := SurfaceTool.new()
	tiles.begin(Mesh.PRIMITIVE_TRIANGLES)
	gables.begin(Mesh.PRIMITIVE_TRIANGLES)
	tiles.set_color(Color("94644c"))
	gables.set_color(tone)
	gable_roof(tiles, gables, Vector2(0.1, cz), 6.4, 8.0, 5.6, 7.7, true, 0.6)
	for item in [[tiles, Materials.roofs(), "CoppiCasaBambina"], [gables, Materials.walls(), "TimpaniCasaBambina"]]:
		var mesh := MeshInstance3D.new()
		mesh.name = item[2]
		mesh.mesh = item[0].commit()
		mesh.material_override = item[1]
		add_child(mesh)

func fence_panel(a: Vector3, b: Vector3, base: float = 0.5, height: float = 1.6, color: Color = RAIL) -> void:
	var middle := (a + b) * 0.5
	var length := a.distance_to(b)
	if base > 0:
		var body_size := Vector3(length, base, 0.30) if absf(b.x - a.x) > absf(b.z - a.z) else Vector3(0.30, base, length)
		box(middle + Vector3.UP * base * 0.5, body_size, Color("e6dcc4"), true)
	for y in [base + 0.12, base + height - 0.12]:
		beam(a + Vector3.UP * y, b + Vector3.UP * y, 0.045, color)
	for i in ceili(length / 0.18):
		var p := a.lerp(b, float(i) / maxi(1, ceili(length / 0.18) - 1))
		beam(p + Vector3.UP * base, p + Vector3.UP * (base + height), 0.025, color)
		batch.add("cone", p + Vector3.UP * (base + height + 0.05), Vector3(0.055, 0.14, 0.055), color, 0.0, "metal")

## Anta in ferro battuto grigio scuro, a lance con cimasa ad arco verso il centro del cancello.
func make_leaf(hinge_x: float, sign_side: float) -> void:
	var body := AnimatableBody3D.new()
	body.name = "AntaSinistra" if sign_side > 0 else "AntaDestra"
	body.position.x = hinge_x
	body.sync_to_physics = false
	add_child(body)
	var gate_batch = Batch.new()
	var w := 2.58
	var top := func(p: float) -> float: return 1.75 + 0.35 * sin(PI * 0.5 * p / w)
	for y in [0.14, 0.5]:
		gate_batch.add("box", Vector3(sign_side * w * 0.5, y, 0), Vector3(w, 0.06, 0.06), IRON, 0.0, "metal")
	for i in 6:
		var p0 := w * i / 6.0
		var p1 := w * (i + 1) / 6.0
		beam(Vector3(sign_side * p0, top.call(p0) - 0.15, 0), Vector3(sign_side * p1, top.call(p1) - 0.15, 0), 0.05, IRON, gate_batch)
	for i in 19:
		var p := 0.08 + i * 0.134
		var h: float = top.call(p)
		gate_batch.add("box", Vector3(sign_side * p, h * 0.5 + 0.05, 0), Vector3(0.024, h - 0.1, 0.024), IRON, 0.0, "metal")
		gate_batch.add("cone", Vector3(sign_side * p, h + 0.03, 0), Vector3(0.06, 0.16, 0.06), IRON, 0.0, "metal")
		if i % 4 == 2:
			# Riccioli decorativi sotto la cimasa.
			var ring := Basis(Vector3.FORWARD, PI * 0.25).scaled_local(Vector3(0.2, 0.2, 0.03))
			gate_batch.add_transform("box", Transform3D(ring, Vector3(sign_side * p, h - 0.45, -0.03)), IRON, "metal")
	gate_batch.flush(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, 2.0, 0.14)
	collision.shape = shape
	collision.position = Vector3(sign_side * w * 0.5, 1.05, 0)
	body.add_child(collision)
	leaves.append(body)

func palm(pos: Vector3, height: float) -> void:
	# Palma a ventaglio (Trachycarpus): tronco fibroso, chioma folta e tondeggiante.
	batch.add("trunk", pos + Vector3.UP * height * 0.5, Vector3(0.5, height, 0.5), Color("6f5a46"))
	for ring in floori(height / 0.32):
		batch.add("cylinder", pos + Vector3.UP * (0.3 + ring * 0.32), Vector3(0.56, 0.12, 0.56), Color("5c4a38"))
	var fronds := SurfaceTool.new()
	fronds.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 30:
		var angle := float(i) * 2.399
		var direction := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-direction.z, 0, direction.x)
		var rising := i % 3 == 0
		var stem := pos + Vector3.UP * (height - 0.1 + (i % 5) * 0.12)
		var base := stem + direction * 0.4 + Vector3.UP * (0.55 if rising else 0.1)
		beam(stem, base, 0.04, Color("7d8050"))
		var tip := base + direction * (0.8 if rising else 1.1) + Vector3.UP * (0.45 if rising else -0.55)
		fronds.set_color(Color("5f7d3c") if i % 2 == 0 else Color("476b34"))
		for rib in 13:
			var spread := (rib - 6) * 0.17
			var edge := tip + side * spread - direction * absf(spread) * 0.45
			Meshes.triangle(fronds, base, edge, edge + side * 0.22, Vector3.UP)
	var mesh := MeshInstance3D.new()
	mesh.name = "PalmaGiardino"
	mesh.mesh = fronds.commit()
	var leaves_material := StandardMaterial3D.new()
	leaves_material.vertex_color_use_as_albedo = true
	leaves_material.vertex_color_is_srgb = true
	leaves_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaves_material.roughness = 0.85
	mesh.material_override = leaves_material
	add_child(mesh)

## Palo di legno con cavi verso la casa, come sul marciapiede della foto.
func utility_pole(pos: Vector3, top: Vector3) -> void:
	batch.add("trunk", pos + Vector3.UP * 3.9, Vector3(0.26, 7.8, 0.26), Color("7a6a58"))
	beam(Vector3(pos.x, 7.5, pos.z), top, 0.015, Color("2e2e30"))
	beam(Vector3(pos.x, 7.2, pos.z), top - Vector3.UP * 0.5, 0.015, Color("2e2e30"))

func _physics_process(delta: float) -> void:
	if not automatic:
		return
	var requested := 0.0
	if is_instance_valid(vehicle):
		var local_pos := to_local(vehicle.global_position)
		if Vector2(local_pos.x, local_pos.z).length() < 15.0:
			requested = 1.0
	opening = move_toward(opening, requested, delta / 1.2)
	for i in leaves.size():
		leaves[i].rotation.y = deg_to_rad(-92.0 if i == 0 else 92.0) * smoothstep(0.0, 1.0, opening)

func world_outline() -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in property_outline:
		var global := to_global(Vector3(p.x, 0, p.y))
		result.append(Vector2(global.x, global.z))
	return result

func lane_world_outline() -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in lane_outline:
		var global := to_global(Vector3(p.x, 0, p.y))
		result.append(Vector2(global.x, global.z))
	return result

func replaces(id: int) -> bool:
	for value in settings.get("replace_buildings", []):
		if int(value) == id:
			return true
	return false
