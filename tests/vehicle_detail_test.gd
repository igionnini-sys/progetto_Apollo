extends SceneTree
## Proprietà geometriche e animazioni del modello, senza dipendenze dal salvataggio utente.
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if value:
		print("OK: ", message)
	else:
		failures += 1
		push_error(message)

func rear_hit(visual: Node3D, p: Vector2) -> float:
	var nearest := -INF
	var origin := Vector3(p.x, p.y, 2.9)
	for name in ["PortelloneSinistroX250", "PortelloneDestroX250"]:
		var item: MeshInstance3D = visual.get_node(name)
		var vertices: PackedVector3Array = item.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for i in range(0, vertices.size(), 3):
			var hit = Geometry3D.ray_intersects_triangle(origin, Vector3.FORWARD, vertices[i], vertices[i + 1], vertices[i + 2])
			if hit != null:
				nearest = maxf(nearest, hit.z)
	return nearest

func run() -> void:
	var visual := Node3D.new()
	visual.set_script(load("res://scripts/vehicles/apollo_visual.gd"))
	root.add_child(visual)
	var valid_geometry := true
	var valid_winding := true
	var bulbs := 0
	var brake_meshes := 0
	var lenses := 0
	var stack: Array[Node] = [visual]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node in visual.passengers:
			continue
		stack.append_array(node.get_children())
		var item := node as MeshInstance3D
		if item == null:
			continue
		if item.material_override == visual.headlight_material:
			bulbs += 1
		if item.material_override == visual.brake_material:
			brake_meshes += 1
		if str(item.name).begins_with("FaroObliquoX250"):
			lenses += 1
		if not item.mesh is ArrayMesh:
			continue
		var arrays := item.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for i in vertices.size():
			valid_geometry = valid_geometry and vertices[i].is_finite() and normals[i].is_finite() and absf(normals[i].length() - 1.0) < 0.01
		for i in range(0, vertices.size(), 3):
			var cross_product := (vertices[i + 1] - vertices[i]).cross(vertices[i + 2] - vertices[i])
			var normal := normals[i] + normals[i + 1] + normals[i + 2]
			if cross_product.dot(normal) > 0.00001:
				print("Avvolgimento da correggere: ", item.name, " triangolo ", i / 3)
			valid_winding = valid_winding and cross_product.dot(normal) <= 0.00001
	check(valid_geometry, "Pannelli, raccordi e ruote hanno coordinate finite e normali unitarie")
	check(valid_winding, "Triangoli frontali coerenti con le normali delle superfici")
	var front = load("res://scripts/vehicles/ducato_x250_front.gd")
	var hood: MeshInstance3D = visual.get_node("CofanoX250")
	var hood_vertices: PackedVector3Array = hood.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var cavities_open := true
	for side: float in [-1.0, 1.0]:
		for t: float in [0.30, 0.65]:
			var uv: Vector2 = front.optic_uv(Vector2(0, t), side)
			var normal: Vector3 = front.hood_normal(uv)
			var origin: Vector3 = front.hood_point(uv) + normal * 0.05
			for i in range(0, hood_vertices.size(), 3):
				var hit = Geometry3D.ray_intersects_triangle(origin, -normal, hood_vertices[i], hood_vertices[i + 1], hood_vertices[i + 2])
				if hit != null and origin.distance_to(hit) < 0.09:
					cavities_open = false
	check(cavities_open, "Le quattro sedi dei riflettori sono aperte nella lamiera del cofano")
	check(is_inf(rear_hit(visual, Vector2(0, 1.7))) and is_finite(rear_hit(visual, Vector2(-0.435, 1.7))) and is_finite(rear_hit(visual, Vector2(0.435, 1.7))), "I portelloni posteriori sono superfici separate da un gioco centrale aperto")
	var recess := rear_hit(visual, Vector2(-0.435, 0.895))
	var surrounding := rear_hit(visual, Vector2(-0.08, 0.895))
	var plate: MeshInstance3D = visual.get_node("TargaPosteriore")
	var backing: MeshInstance3D = visual.get_node("FondoVanoPortelloni")
	var backing_vertices: PackedVector3Array = backing.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var backing_z := -INF
	for i in range(0, backing_vertices.size(), 3):
		var hit = Geometry3D.ray_intersects_triangle(Vector3(-0.435, 0.895, 2.9), Vector3.FORWARD, backing_vertices[i], backing_vertices[i + 1], backing_vertices[i + 2])
		if hit != null:
			backing_z = maxf(backing_z, hit.z)
	check(surrounding - recess > 0.020 and plate.position.z > recess and plate.position.z < surrounding and is_finite(backing_z) and backing_z < recess, "La targa posteriore resta dentro l'incavo della lamiera senza fondi sovrapposti")
	var tyre: MeshInstance3D
	for item: MeshInstance3D in visual.wheels[0].get_children():
		if str(item.name).contains("_wheel_rubber_"):
			tyre = item
	assert(tyre != null, "Pneumatico importato assente")
	var tyre_arrays := tyre.mesh.surface_get_arrays(0)
	var tyre_vertices: PackedVector3Array = tyre_arrays[Mesh.ARRAY_VERTEX]
	var tyre_normals: PackedVector3Array = tyre_arrays[Mesh.ARRAY_NORMAL]
	var outside := true
	for i in tyre_vertices.size():
		if Vector2(tyre_vertices[i].y, tyre_vertices[i].z).length() > 0.37:
			outside = outside and Vector3(0, tyre_vertices[i].y, tyre_vertices[i].z).dot(tyre_normals[i]) > 0.0
	check(outside, "Il battistrada è orientato verso l'esterno su tutta la circonferenza")
	visual.animate(0.1, 3.0, 0.5, true, true)
	check(bulbs == 2 and lenses == 2 and visual.headlight_material.emission_energy_multiplier > 0.0 and visual.reflector_material.emission_energy_multiplier > 0.0 and visual.lamps.all(func(lamp: SpotLight3D) -> bool: return lamp.visible), "Entrambi i fari si accendono insieme alle luci stradali")
	check(brake_meshes == 3 and visual.brake_material.emission_energy_multiplier > 1.0, "Entrambi gli stop posteriori e il terzo stop rispondono alla frenata")
	check(visual.wheels.size() == 4 and visual.wheels.all(func(wheel: Node3D) -> bool: return absf(wheel.rotation.x) > 0.01) and visual.front_pivots.all(func(pivot: Node3D) -> bool: return absf(pivot.rotation.y) > 0.01), "Le quattro ruote girano e quelle anteriori sterzano")
	visual.animate(0.0, 0.0, 0.0, false, false)
	check(visual.headlight_material.emission_energy_multiplier == 0.0 and visual.reflector_material.emission_energy_multiplier == 0.0 and visual.lamps.all(func(lamp: SpotLight3D) -> bool: return not lamp.visible), "Spegnimento dei fari ripristina entrambe le ottiche")
	visual.queue_free()
	await process_frame
	print("ESITO DETTAGLI APOLLO: %d errori" % failures)
	quit(0 if failures == 0 else 1)
