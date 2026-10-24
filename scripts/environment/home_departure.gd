extends Node3D
## Casa e cancello da riferimento esterno dell'utente. Posizione e civico solo in local/.
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
var metal := Color("aaaea5")
var plaster := Color("cc8b61")
var property_outline := PackedVector2Array([Vector2(-14, -1.6), Vector2(18, -1.6), Vector2(18, 17), Vector2(2, 17), Vector2(2, 14.5), Vector2(-14, 14.5)])

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
	var inside := Basis(Vector3.UP, deg_to_rad(float(config.get("yaw_degrees", 0)))) * Vector3(0, 0, 7.0)
	data.nodes["home_spawn"] = [gate.x + inside.x, gate.y + inside.z]
	data.nodes["home_street"] = [street.x, street.y]
	# Raccordo privato dichiarato, solo in memoria: nessun falso arco OSM distribuito.
	data.route = ["home_spawn", "home_street"] + path.slice(0, path.size() - 1) + data.route
	data.metadata["local_home_departure"] = true
	return true

func _ready() -> void:
	name = "CasaApollo"
	house()
	front_fence()
	palm(Vector3(-6.0, 0, 7.5))
	for p in [Vector3(-10, 1.2, 11.5), Vector3(-11, 1.0, 6.0), Vector3(-4, 1.1, 12.0)]:
		batch.add("blob", p, Vector3(3.1, 2.5, 2.7), Color("446338"), p.x, "foliage")
	box(Vector3(-7, 0.3, 13.5), Vector3(13.5, 0.65, 0.45), Color("cbbba1"), true)
	box(Vector3(0, -0.082, 6.5), Vector3(4.8, 0.03, 13.8), Color.WHITE, false, "trento_paving")
	box(Vector3(0, -0.079, -0.7), Vector3(5.4, 0.025, 1.4), Color.WHITE, false, "trento_paving")
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

func beam(a: Vector3, b: Vector3, thickness: float, color: Color, target_batch: RefCounted = null) -> void:
	if target_batch == null:
		target_batch = batch
	var direction := b - a
	var basis := Basis(Quaternion(Vector3.UP, direction.normalized())).scaled_local(Vector3(thickness, direction.length(), thickness))
	target_batch.add_transform("cylinder", Transform3D(basis, (a + b) * 0.5), color, "metal")

func house() -> void:
	box(Vector3(9.4, 3.2, 9.9), Vector3(12.8, 6.4, 13.0), plaster, true)
	box(Vector3(9.4, 0.25, 3.34), Vector3(12.8, 0.5, 0.15), Color("bdb9ad"), false, "stone")
	box(Vector3(9.4, 3.13, 2.75), Vector3(13.2, 0.24, 1.4), Color("dfdccd"))
	# Tre aperture, persiane brune e ingresso al piano rialzato.
	for x in [4.7, 8.7, 12.7]:
		window(Vector3(x, 4.35, 3.30), true)
		window(Vector3(x, 1.45, 3.30), false)
	for x in [3.0, 15.8]:
		box(Vector3(x, 3.7, 2.2), Vector3(1.0, 1.0, 0.16), Color("e2dfd2"))
	fence_panel(Vector3(3.5, 3.25, 2.1), Vector3(6.6, 3.25, 2.1), 0.0, 1.0)
	fence_panel(Vector3(8.4, 3.25, 2.1), Vector3(15.3, 3.25, 2.1), 0.0, 1.0)
	# Scala laterale: alzata 25 cm, pedata 42 cm; fuori dal passaggio di Apollo.
	for step in 13:
		var h := (step + 1) * 0.25
		box(Vector3(2.0 + (step + 0.5) * 0.42, h * 0.5, 1.45), Vector3(0.42, h, 1.35), Color("dedbd0"), true)
		for z in [0.8, 2.1]:
			beam(Vector3(2.0 + step * 0.42, h, z), Vector3(2.0 + step * 0.42, h + 0.95, z), 0.035, metal)
	for z in [0.8, 2.1]:
		beam(Vector3(2, 1.1, z), Vector3(7.45, 4.25, z), 0.05, metal)
	for x in [4.2, 11.2, 14.0]:
		box(Vector3(x, 3.5, 1.95), Vector3(0.65, 0.32, 0.25), Color("a96545"))
		batch.add("blob", Vector3(x, 3.85, 1.9), Vector3(0.65, 0.5, 0.4), Color("9e4968"), x, "foliage")
	for x in [3.05, 15.75]:
		batch.add("cylinder", Vector3(x, 3.1, 3.18), Vector3(0.10, 6.2, 0.10), Color("76614c"), 0.0, "metal")
	for item in [[4.35, 8.2], [1.5, 12.2]]:
		var y: float = item[0]
		var z: float = item[1]
		box(Vector3(2.94, y, z), Vector3(0.12, 1.65, 1.4), Color("725044"))
		box(Vector3(2.86, y, z), Vector3(0.07, 1.4, 1.15), Color("3e5158"), false, "window")
		for side in [-1.0, 1.0]:
			box(Vector3(2.9, y, z + side * 0.9), Vector3(0.1, 1.65, 0.45), Color("654a3d"), false, "shutter")
	roof()

func window(pos: Vector3, upper: bool) -> void:
	box(pos, Vector3(1.5, 1.95 if upper else 1.35, 0.12), Color("725044"))
	box(pos - Vector3(0, 0, 0.08), Vector3(1.25, 1.75 if upper else 1.15, 0.08), Color("3e5158"), false, "window")
	for side in [-1.0, 1.0]:
		box(pos + Vector3(side * 0.98, 0, -0.07), Vector3(0.5, 1.95 if upper else 1.35, 0.12), Color("654a3d"), false, "shutter")
	box(pos + Vector3(0, 0, -0.14), Vector3(0.065, 1.8 if upper else 1.2, 0.04), Color("6b5041"))

func roof() -> void:
	var tiles := SurfaceTool.new()
	var gables := SurfaceTool.new()
	tiles.begin(Mesh.PRIMITIVE_TRIANGLES)
	gables.begin(Mesh.PRIMITIVE_TRIANGLES)
	tiles.set_color(Color("94644c"))
	gables.set_color(plaster)
	var left := 2.6
	var right := 16.2
	var front := 3.0
	var back := 16.8
	var middle := (front + back) * 0.5
	for z in [front, back]:
		var normal := Vector3(0, 1, -1 if z == front else 1)
		Meshes.triangle(tiles, Vector3(left, 6.35, z), Vector3(right, 6.35, z), Vector3(right, 9.7, middle), normal, [Vector2(0, 0), Vector2(13.6, 0), Vector2(13.6, 7.6)])
		Meshes.triangle(tiles, Vector3(left, 6.35, z), Vector3(right, 9.7, middle), Vector3(left, 9.7, middle), normal, [Vector2(0, 0), Vector2(13.6, 7.6), Vector2(0, 7.6)])
	for x in [left, right]:
		Meshes.triangle(gables, Vector3(x, 6.35, front), Vector3(x, 9.7, middle), Vector3(x, 6.35, back), Vector3(-1 if x == left else 1, 0, 0))
	# Abbaino con due ante scure, distinto dal tetto principale.
	box(Vector3(11.2, 7.95, 6.4), Vector3(3.6, 1.65, 3.0), plaster)
	window(Vector3(11.2, 8.0, 4.85), false)
	for side in [-1.0, 1.0]:
		var x: float = 11.2 + side * 2.05
		Meshes.triangle(tiles, Vector3(x, 8.7, 4.6), Vector3(x, 8.7, 8.1), Vector3(11.2, 9.7, 8.1), Vector3(side, 1, 0))
		Meshes.triangle(tiles, Vector3(x, 8.7, 4.6), Vector3(11.2, 9.7, 8.1), Vector3(11.2, 9.7, 4.6), Vector3(side, 1, 0))
	Meshes.triangle(gables, Vector3(9.15, 8.7, 4.8), Vector3(11.2, 9.7, 4.8), Vector3(13.25, 8.7, 4.8), Vector3.FORWARD)
	for item in [[tiles, Materials.roofs(), "CoppiCasa"], [gables, Materials.walls(), "TimpaniCasa"]]:
		var mesh := MeshInstance3D.new()
		mesh.name = item[2]
		mesh.mesh = item[0].commit()
		mesh.material_override = item[1]
		add_child(mesh)

func fence_panel(a: Vector3, b: Vector3, base: float = 0.5, height: float = 1.6) -> void:
	var middle := (a + b) * 0.5
	var length := a.distance_to(b)
	if base > 0:
		box(middle + Vector3.UP * base * 0.5, Vector3(length, base, 0.30), Color("d8cbb1"), true)
	for y in [base + 0.12, base + height - 0.12]:
		beam(a + Vector3.UP * y, b + Vector3.UP * y, 0.045, metal)
	for i in ceili(length / 0.18):
		var p := a.lerp(b, float(i) / maxi(1, ceili(length / 0.18) - 1))
		beam(p + Vector3.UP * base, p + Vector3.UP * (base + height), 0.025, metal)
		batch.add("cone", p + Vector3.UP * (base + height + 0.05), Vector3(0.055, 0.14, 0.055), metal, 0.0, "metal")

func front_fence() -> void:
	var pillars := [-13.5, -8.0, -2.6, 2.6, 7.1, 12.0, 17.0]
	for x in pillars:
		box(Vector3(x, 1.1, 0), Vector3(0.45, 2.2, 0.5), Color("b47b59"), true, "stone")
		box(Vector3(x, 2.23, 0), Vector3(0.62, 0.10, 0.65), Color("dfcfae"))
	for i in range(pillars.size() - 1):
		if i == 2:
			continue
		fence_panel(Vector3(pillars[i] + 0.2, 0, 0), Vector3(pillars[i + 1] - 0.2, 0, 0))

func make_leaf(hinge_x: float, sign_side: float) -> void:
	var body := AnimatableBody3D.new()
	body.name = "AntaSinistra" if sign_side > 0 else "AntaDestra"
	body.position.x = hinge_x
	body.sync_to_physics = false
	add_child(body)
	var gate_batch = Batch.new()
	var w := 2.58
	for y in [0.16, 0.42, 1.85]:
		gate_batch.add("box", Vector3(sign_side * w * 0.5, y, 0), Vector3(w, 0.055, 0.07), metal, 0.0, "metal")
	for i in 15:
		var x: float = sign_side * (0.08 + i * 0.17)
		gate_batch.add("box", Vector3(x, 1.05, 0), Vector3(0.025, 1.95, 0.025), metal, 0.0, "metal")
		gate_batch.add("cone", Vector3(x, 2.06, 0), Vector3(0.06, 0.16, 0.06), metal, 0.0, "metal")
		if i % 3 == 0:
			for y in [0.28, 1.25]:
				var basis := Basis(Vector3.FORWARD, PI * 0.25).scaled_local(Vector3(0.16, 0.16, 0.035))
				gate_batch.add_transform("box", Transform3D(basis, Vector3(x, y, -0.035)), metal, "metal")
	gate_batch.flush(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, 2.0, 0.14)
	collision.shape = shape
	collision.position = Vector3(sign_side * w * 0.5, 1.05, 0)
	body.add_child(collision)
	leaves.append(body)

func palm(pos: Vector3) -> void:
	batch.add("trunk", pos + Vector3.UP * 2.4, Vector3(0.45, 4.8, 0.45), Color("75604a"))
	for ring in 24:
		batch.add("cylinder", pos + Vector3.UP * (0.3 + ring * 0.18), Vector3(0.37, 0.055, 0.37), Color("66513c"))
	var fronds := SurfaceTool.new()
	fronds.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 21:
		var angle := float(i) * TAU / 13.0
		var direction := Vector3(cos(angle), 0, sin(angle))
		var side := Vector3(-direction.z, 0, direction.x)
		var stem := pos + Vector3.UP * (4.4 + (i % 4) * 0.18)
		var rising := i % 3 == 0
		var base := stem + direction * 0.85 + Vector3.UP * (0.45 if rising else -0.1)
		beam(stem, base, 0.035, Color("7d8050"))
		var tip := base + direction * (1.2 if rising else 1.7) + Vector3.UP * (0.9 if rising else -0.75)
		fronds.set_color(Color("697b3f") if i % 2 == 0 else Color("4e683b"))
		for rib in 11:
			var spread := (rib - 5) * 0.16
			var edge := tip + side * spread - direction * absf(spread) * 0.35
			Meshes.triangle(fronds, base, edge, edge + side * 0.145, Vector3.UP)
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
		leaves[i].rotation.y = deg_to_rad(-105.0 if i == 0 else 105.0) * smoothstep(0.0, 1.0, opening)

func world_outline() -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in property_outline:
		var global := to_global(Vector3(p.x, 0, p.y))
		result.append(Vector2(global.x, global.z))
	return result

func replaces(id: int) -> bool:
	for value in settings.get("replace_buildings", []):
		if int(value) == id:
			return true
	return false
