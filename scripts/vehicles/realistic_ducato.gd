extends RefCounted
## Base CC BY 4.0 di razor24: adattamento a X250 2010 L2H2, frontale separato.
const Materials = preload("res://scripts/utilities/materials.gd")
const SCALE = 2.05 / 207.9417
const FRONT_AXLE = 153.73574
const REAR_AXLE = -146.5175
static var parts: Array = []
static var material_cache: Dictionary = {}

static func map_body(p: Vector3) -> Vector3:
	var z: float
	if p.z >= FRONT_AXLE:
		z = -1.756 - (p.z - FRONT_AXLE) * 0.9505 / (249.4831 - FRONT_AXLE)
	elif p.z <= REAR_AXLE:
		z = 1.694 + (REAR_AXLE - p.z) * 1.0125 / (250.4361 + REAR_AXLE)
	else:
		z = 1.694 - (p.z - REAR_AXLE) * 3.45 / (FRONT_AXLE - REAR_AXLE)
	var y := (p.y - 34.87698) * SCALE + 0.4
	var roof := smoothstep(1.95, 2.2679174, y) * smoothstep(-2.1, -0.85, z)
	y += 0.25608256 * roof
	return Vector3(-p.x * SCALE, y, z)

static func map_normal(p: Vector3, normal: Vector3) -> Vector3:
	var dx := (map_body(p + Vector3.RIGHT * 0.05) - map_body(p - Vector3.RIGHT * 0.05)) / 0.1
	var dy := (map_body(p + Vector3.UP * 0.05) - map_body(p - Vector3.UP * 0.05)) / 0.1
	var dz := (map_body(p + Vector3.BACK * 0.05) - map_body(p - Vector3.BACK * 0.05)) / 0.1
	return (Basis(dx, dy, dz).inverse().transposed() * normal).normalized()

static func clip(poly: Array, axis: int, limit: float, above: bool) -> Array:
	var result: Array = []
	if poly.is_empty():
		return result
	for i in poly.size():
		var a: Array = poly[i]
		var b: Array = poly[(i + 1) % poly.size()]
		var inside_a: bool = a[0][axis] >= limit if above else a[0][axis] <= limit
		var inside_b: bool = b[0][axis] >= limit if above else b[0][axis] <= limit
		if inside_a:
			result.append(a)
		if inside_a != inside_b:
			var t: float = (limit - a[0][axis]) / (b[0][axis] - a[0][axis])
			result.append([a[0].lerp(b[0], t), a[1].lerp(b[1], t).normalized()])
	return result

static func emit(builder: SurfaceTool, poly: Array) -> void:
	for i in range(1, poly.size() - 1):
		var tri := [poly[0], poly[i], poly[i + 1]]
		if (tri[1][0] - tri[0][0]).cross(tri[2][0] - tri[0][0]).length_squared() < 1e-14:
			continue
		if (tri[1][0] - tri[0][0]).cross(tri[2][0] - tri[0][0]).dot(tri[0][1] + tri[1][1] + tri[2][1]) > 0.0:
			tri.reverse()
		for point: Array in tri:
			builder.set_normal(point[1])
			builder.add_vertex(point[0])

## Rimuove solo il centro della faccia posteriore; restano montanti, cerniere e paraurti.
static func rear_fragments(poly: Array) -> Array:
	var result: Array = [clip(poly, 2, 2.48, false)]
	var remaining := clip(poly, 2, 2.48, true)
	for plane in [[0, -0.905, true], [0, 0.905, false], [1, 0.53, true], [1, 2.412, false]]:
		result.append(clip(remaining, plane[0], plane[1], not plane[2]))
		remaining = clip(remaining, plane[0], plane[1], plane[2])
	return result

static func prepare() -> void:
	if not parts.is_empty():
		return
	# ResourceLoader segue anche il remapping dell'importatore nelle build esportate.
	var packed := load("res://assets/vehicles/ducato_base.glb") as PackedScene
	assert(packed != null, "Impossibile leggere la base Ducato")
	var scene := packed.instantiate() as Node3D
	var stack: Array = [[scene, scene.transform]]
	while not stack.is_empty():
		var entry: Array = stack.pop_back()
		var node: Node = entry[0]
		var transform: Transform3D = entry[1]
		for child in node.get_children():
			if child is Node3D:
				stack.append([child, transform * child.transform])
		var item := node as MeshInstance3D
		if item == null or str(item.name).contains("frontlight") or str(item.name).contains("frontlamp"):
			continue
		# Ottiche posteriori ricostruite con sezioni e riflettori X250.
		if str(item.name).contains("backlights") or str(item.name).contains("rearlamps"):
			continue
		var group := "body"
		var wheel_center := Vector3.ZERO
		for key in ["FL", "FR", "BL", "BR"]:
			if str(item.name).contains("_" + key + "_wheel_"):
				group = key
				wheel_center = Vector3(89.8094 if key.ends_with("L") else -89.8094, 34.87698, FRONT_AXLE if key.begins_with("F") else REAR_AXLE)
		var role: String = item.mesh.surface_get_material(0).resource_name
		if role == "brakelights_red":
			role = "rear_reflectors"
		var arrays := item.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in vertices.size():
				indices.append(i)
		var main := SurfaceTool.new()
		main.begin(Mesh.PRIMITIVE_TRIANGLES)
		var roof := SurfaceTool.new()
		roof.begin(Mesh.PRIMITIVE_TRIANGLES)
		var main_count := 0
		var roof_count := 0
		for i in range(0, indices.size(), 3):
			var poly: Array = []
			for j in 3:
				var index := indices[i + j]
				var p := transform * vertices[index]
				var n := (transform.basis.inverse().transposed() * normals[index]).normalized()
				if group != "body":
					var local := (p - wheel_center) * (0.38 / 35.04474)
					poly.append([Vector3(-local.x, local.y, -local.z), Vector3(-n.x, n.y, -n.z)])
				else:
					poly.append([map_body(p), map_normal(p, n)])
			if role == "rear_reflectors":
				poly = clip(poly, 1, 0.85, false)
				if poly.size() < 3:
					continue
			if group == "body" and str(item.name).contains("_exterior_"):
				if role in ["glass", "chrome"]:
					poly = clip(poly, 2, 2.48, false)
				# Elimina il muso 2014 conservando cowl, vetri, fianchi e passaruota.
				var above := clip(poly, 1, 1.66, true)
				var behind := clip(clip(poly, 1, 1.66, false), 2, -2.115, true)
				for fragment: Array in [above, behind]:
					for rear_fragment: Array in rear_fragments(fragment):
						if rear_fragment.size() < 3:
							continue
						var is_roof: bool = role == "varnish" and rear_fragment.all(func(v: Array) -> bool: return v[0].y > 2.4 and v[1].y > 0.3)
						emit(roof if is_roof else main, rear_fragment)
						if is_roof:
							roof_count += 1
						else:
							main_count += 1
			else:
				emit(main, poly)
				main_count += 1
		if main_count > 0:
			parts.append({"name": str(item.name), "group": group, "role": role, "mesh": main.commit()})
		if roof_count > 0:
			parts.append({"name": "TettoH2", "group": "body", "role": role, "mesh": roof.commit()})
	scene.free()

static func material(role: String) -> Material:
	if material_cache.has(role):
		return material_cache[role]
	var result: Material
	match role:
		"varnish": result = Materials.shader("vehicle_paint.gdshader")
		"black_plastic", "panel", "interior": result = Materials.shader("vehicle_plastic.gdshader")
		"bumper":
			var bumper := Materials.shader("vehicle_plastic.gdshader").duplicate() as ShaderMaterial
			bumper.set_shader_parameter("tint", Color("4e5356"))
			result = bumper
		"wheel_rubber": result = Materials.shader("vehicle_rubber.gdshader")
		"sits_leather": result = Materials.plastic(Color("303638"), 0.93)
		"chrome", "mirror_left", "mirror_right": result = Materials.metal(Color("c4cbd0"), 0.11)
		"metal": result = Materials.metal(Color("b2b7b9"), 0.35)
		"metal_dark", "brakes": result = Materials.metal(Color("62696c"), 0.55)
		"glass":
			var glass := StandardMaterial3D.new()
			glass.albedo_color = Color(0.12, 0.18, 0.20, 0.68)
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.roughness = 0.055
			glass.metallic = 0.0
			glass.metallic_specular = 0.5
			glass.cull_mode = BaseMaterial3D.CULL_DISABLED
			result = glass
		"back_blinkers", "blinker_lamps": result = Materials.plastic(Color("d28b19"), 0.22)
		"rearlights_white": result = Materials.plastic(Color("c8d1ce"), 0.19)
		"rear_reflectors": result = Materials.plastic(Color("991c26"), 0.24)
		_: result = Materials.plastic(Color("242b30"), 0.7)
	material_cache[role] = result
	return result

static func build(visual: Node3D) -> void:
	prepare()
	var parents: Dictionary = {"body": visual}
	for side in [-1.0, 1.0]:
		for front in [true, false]:
			var key: String = ("F" if front else "B") + ("L" if side < 0.0 else "R")
			var pivot := Node3D.new()
			pivot.position = Vector3(side * 0.905, 0.4, -1.756 if front else 1.694)
			visual.add_child(pivot)
			if front:
				visual.front_pivots.append(pivot)
			var spin := Node3D.new()
			pivot.add_child(spin)
			visual.wheels.append(spin)
			parents[key] = spin
	for part: Dictionary in parts:
		var mesh := MeshInstance3D.new()
		mesh.mesh = part.mesh
		mesh.name = part.name
		mesh.material_override = visual.brake_material if part.role == "brakelights_red" else material(part.role)
		mesh.set_meta("realistic_material", true)
		parents[part.group].add_child(mesh)
