extends RefCounted
## Pannelli originali in metri; nelle sagome laterali Vector2 rappresenta (z, y).
const G = preload("res://scripts/utilities/geometry.gd")
const Meshes = preload("res://scripts/utilities/meshes.gd")
static var cache: Dictionary = {}

## Griglia di pannello con normali continue; l'orientamento è esplicito anche per la cabina.
static func panel(parent: Node3D, rows: Array, color: Color, panel_name: String, outward: Vector3) -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = rows[0].size()
	var normals: Array = []
	for y in rows.size():
		var line := PackedVector3Array()
		for x in count:
			var u: Vector3 = rows[y][mini(x + 1, count - 1)] - rows[y][maxi(x - 1, 0)]
			var v: Vector3 = rows[mini(y + 1, rows.size() - 1)][x] - rows[maxi(y - 1, 0)][x]
			var n := u.cross(v).normalized()
			line.append(n if n.dot(outward) >= 0.0 else -n)
		normals.append(line)
	for y in range(rows.size() - 1):
		for x in range(count - 1):
			for tri in [[Vector2i(x, y), Vector2i(x + 1, y), Vector2i(x + 1, y + 1)], [Vector2i(x, y), Vector2i(x + 1, y + 1), Vector2i(x, y + 1)]]:
				var a: Vector3 = rows[tri[0].y][tri[0].x]
				var b: Vector3 = rows[tri[1].y][tri[1].x]
				var c: Vector3 = rows[tri[2].y][tri[2].x]
				var face_normal: Vector3 = normals[tri[0].y][tri[0].x] + normals[tri[1].y][tri[1].x] + normals[tri[2].y][tri[2].x]
				if (b - a).cross(c - a).dot(face_normal) > 0.0:
					tri.reverse()
				for p: Vector2i in tri:
					builder.set_normal(normals[p.y][p.x])
					builder.set_uv(Vector2(float(p.x) / (count - 1), float(p.y) / (rows.size() - 1)))
					builder.add_vertex(rows[p.y][p.x])
	var result := G.mesh(parent, builder.commit(), Vector3.ZERO, color)
	result.name = panel_name
	return result

## Solido raccordato: normali analitiche sui bordi, nessuna suddivisione delle facce piane.
static func rounded_box(parent: Node3D, pos: Vector3, size: Vector3, radius: float, color: Color, panel_name: String = "Raccordo") -> MeshInstance3D:
	var key := str(size) + str(radius)
	if not cache.has(key):
		var half := size * 0.5
		var r := minf(radius, minf(half.x, minf(half.y, half.z)) * 0.99)
		var inner := half - Vector3.ONE * r
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for axis in 3:
			var u := (axis + 1) % 3
			var v := (axis + 2) % 3
			for sign_side in [-1.0, 1.0]:
				var points: Array[Vector3] = []
				var norms: Array[Vector3] = []
				for y in 10:
					for x in 10:
						var p := Vector3.ZERO
						p[axis] = half[axis] * sign_side
						for coord in [[u, x], [v, y]]:
							var i: int = coord[1]
							var h: float = half[coord[0]]
							p[coord[0]] = -h + r * float(i) / 4.0 if i <= 4 else h - r + r * float(i - 5) / 4.0
						var core := p.clamp(-inner, inner)
						var n := (p - core).normalized()
						points.append(core + n * r)
						norms.append(n)
				for y in 9:
					for x in 9:
						var a := y * 10 + x
						for tri in [[a, a + 1, a + 11], [a, a + 11, a + 10]]:
							if (points[tri[1]] - points[tri[0]]).cross(points[tri[2]] - points[tri[0]]).dot(norms[tri[0]]) > 0.0:
								tri.reverse()
							for i: int in tri:
								builder.set_normal(norms[i])
								builder.add_vertex(points[i])
		cache[key] = builder.commit()
	var result := G.mesh(parent, cache[key], pos, color)
	result.name = panel_name
	return result

## Tornitura attorno a X: profilo (x, raggio), pneumatici e cerchi con normali continue.
static func lathe(parent: Node3D, profile: PackedVector2Array, color: Color, panel_name: String, segments: int = 64) -> MeshInstance3D:
	var rows: Array = []
	for p in profile:
		var ring := PackedVector3Array()
		for i in range(segments + 1):
			var angle := TAU * i / segments
			ring.append(Vector3(p.x, cos(angle) * p.y, sin(angle) * p.y))
		rows.append(ring)
	# Normali della tornitura calcolate nel piano del profilo, senza cucitura angolare.
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in range(profile.size() - 1):
		for i in segments:
			for tri in [[Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i + 1, j + 1)], [Vector2i(i, j), Vector2i(i + 1, j + 1), Vector2i(i, j + 1)]]:
				var a: Vector3 = rows[tri[0].y][tri[0].x]
				var b: Vector3 = rows[tri[1].y][tri[1].x]
				var c: Vector3 = rows[tri[2].y][tri[2].x]
				var edge := profile[j + 1] - profile[j]
				var hint := Vector3(-edge.y, edge.x * cos(TAU * (i + 0.5) / segments), edge.x * sin(TAU * (i + 0.5) / segments))
				if (b - a).cross(c - a).dot(hint) > 0.0:
					tri.reverse()
				for p: Vector2i in tri:
					var tangent := profile[mini(p.y + 1, profile.size() - 1)] - profile[maxi(p.y - 1, 0)]
					var angle := TAU * p.x / segments
					builder.set_normal(Vector3(-tangent.y, tangent.x * cos(angle), tangent.x * sin(angle)).normalized())
					builder.set_uv(Vector2(float(p.x) / segments, float(p.y) / (profile.size() - 1)))
					builder.add_vertex(rows[p.y][p.x])
	var result := G.mesh(parent, builder.commit(), Vector3.ZERO, color)
	result.name = panel_name
	return result

static func surface(parent: Node3D, vertices: Array[Vector3], indices: Array[int], color: Color, panel_name: String = "Pannello") -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in range(0, indices.size(), 3):
		var a := vertices[indices[triangle]]
		var b := vertices[indices[triangle + 1]]
		var c := vertices[indices[triangle + 2]]
		var outward := (a + b + c) / 3.0 - Vector3(0, 1.1, 0)
		builder.add_vertex(a)
		# Godot considera frontali i triangoli con avvolgimento orario.
		if (b - a).cross(c - a).dot(outward) > 0:
			builder.add_vertex(c)
			builder.add_vertex(b)
		else:
			builder.add_vertex(b)
			builder.add_vertex(c)
	builder.generate_normals()
	var result := MeshInstance3D.new()
	result.name = panel_name
	result.mesh = builder.commit()
	var material := G.material(color).duplicate() as StandardMaterial3D
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	result.material_override = material
	parent.add_child(result)
	return result

static func quad(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, panel_name: String = "Pannello") -> MeshInstance3D:
	return surface(parent, [a, b, c, d], [0, 1, 2, 0, 2, 3], color, panel_name)

static func side(parent: Node3D, outline: PackedVector2Array, x: float, color: Color, panel_name: String) -> MeshInstance3D:
	var vertices: Array[Vector3] = []
	var indices: Array[int] = []
	for point in outline:
		vertices.append(Vector3(x, point.y, point.x))
	for index in Geometry2D.triangulate_polygon(outline):
		indices.append(index)
	return surface(parent, vertices, indices, color, panel_name)

## Fianco inferiore rastremato al muso e al sottoporta, con gli archi ruota aperti.
static func body_width(z: float, y: float) -> float:
	return 1.025 - (1.0 - smoothstep(0.34, 0.7, y)) * 0.075 - smoothstep(2.15, 2.69, -z) * 0.14 - smoothstep(2.45, 2.69, z) * 0.07

static func lower_side(parent: Node3D, side_sign: float, color: Color) -> MeshInstance3D:
	var samples: Array[float] = []
	for i in 81:
		samples.append(lerpf(-2.69, 2.69, float(i) / 80.0))
	for axle in [-1.756, 1.694]:
		for i in 25:
			samples.append(axle - cos(PI * i / 24.0) * 0.47)
	samples.sort()
	var rows: Array = []
	for j in 9:
		var row := PackedVector3Array()
		for z in samples:
			var bottom := 0.34
			for axle in [-1.756, 1.694]:
				var delta: float = absf(z - axle)
				if delta <= 0.470001:
					bottom = 0.4 + sqrt(maxf(0.0, 0.47 * 0.47 - delta * delta))
			var top := 1.48 - smoothstep(2.2, 2.69, -z) * 0.45
			var y := lerpf(bottom, top, float(j) / 8.0)
			row.append(Vector3(side_sign * body_width(z, y), y, z))
		rows.append(row)
	return panel(parent, rows, color, "FiancataConPassaruota", Vector3.RIGHT * side_sign)

static func beam(parent: Node3D, a: Vector3, b: Vector3, width: float, color: Color) -> MeshInstance3D:
	var result := G.box(parent, (a + b) * 0.5, Vector3(width, a.distance_to(b), width), color)
	result.basis = Basis(Quaternion(Vector3.UP, (b - a).normalized()))
	return result

static func arch(parent: Node3D, x: float, z: float, inner: float, outer: float, color: Color) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var side_sign := signf(x)
	for i in 24:
		var points: Array[Vector3] = []
		for p in [Vector2(PI * i / 24.0, inner), Vector2(PI * (i + 1) / 24.0, inner), Vector2(PI * (i + 1) / 24.0, outer), Vector2(PI * i / 24.0, outer)]:
			var y: float = 0.4 + sin(p.x) * p.y
			var along: float = z - cos(p.x) * p.y
			points.append(Vector3(side_sign * (body_width(along, y) + 0.007), y, along))
		Meshes.triangle(builder, points[0], points[1], points[2], Vector3.RIGHT * side_sign)
		Meshes.triangle(builder, points[0], points[2], points[3], Vector3.RIGHT * side_sign)
	G.mesh(parent, builder.commit(), Vector3.ZERO, color).name = "BordoPassaruota"
