extends RefCounted
## Mesh procedurali originali in stile low-poly, con normali piatte. Unità: metri.
static var cache: Dictionary = {}

## Aggiunge un triangolo frontale verso `outward` (Godot: avvolgimento orario frontale).
static func triangle(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3, uv: Array = []) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 1e-10:
		return
	var order := [0, 1, 2]
	var points := [a, b, c]
	if normal.dot(outward) > 0.0:
		order = [0, 2, 1]
	else:
		normal = -normal
	builder.set_normal(normal.normalized())
	for index: int in order:
		if not uv.is_empty():
			builder.set_uv(uv[index])
		builder.add_vertex(points[index])

## Chioma irregolare: icosaedro suddiviso, raggio 0,5 con piccole deformazioni.
static func blob() -> ArrayMesh:
	if cache.has("blob"):
		return cache.blob
	var t := (1.0 + sqrt(5.0)) / 2.0
	var vertices: Array[Vector3] = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var faces := [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	var lumpy := func(v: Vector3) -> Vector3:
		var n := v.normalized()
		var wobble := sin(n.x * 7.1 + n.y * 3.3) * cos(n.z * 5.7 - n.y * 2.1)
		return n * (0.5 + wobble * 0.045)
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face: Array in faces:
		var a: Vector3 = vertices[face[0]]
		var b: Vector3 = vertices[face[1]]
		var c: Vector3 = vertices[face[2]]
		var ab := (a + b) / 2.0
		var bc := (b + c) / 2.0
		var ca := (c + a) / 2.0
		for tri in [[a, ab, ca], [b, bc, ab], [c, ca, bc], [ab, bc, ca]]:
			var p0: Vector3 = lumpy.call(tri[0])
			var p1: Vector3 = lumpy.call(tri[1])
			var p2: Vector3 = lumpy.call(tri[2])
			triangle(builder, p0, p1, p2, (p0 + p1 + p2) / 3.0)
	cache.blob = builder.commit()
	return cache.blob

## Cono sfaccettato con base a y = -0,5 e punta a y = 0,5: cipressi e abeti.
static func cone(sides: int = 7) -> ArrayMesh:
	var key := "cone%d" % sides
	if cache.has(key):
		return cache[key]
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip := Vector3(0, 0.5, 0)
	for i in sides:
		var a := Vector3(cos(TAU * i / sides) * 0.5, -0.5, sin(TAU * i / sides) * 0.5)
		var b := Vector3(cos(TAU * (i + 1) / sides) * 0.5, -0.5, sin(TAU * (i + 1) / sides) * 0.5)
		triangle(builder, a, b, tip, (a + b) / 2.0)
		triangle(builder, a, b, Vector3(0, -0.5, 0), Vector3.DOWN)
	cache[key] = builder.commit()
	return cache[key]

## Estrusione laterale di un profilo (z, y) fra -half e +half su X.
static func extrude(builder: SurfaceTool, profile: PackedVector2Array, half: float) -> void:
	var indices := Geometry2D.triangulate_polygon(profile)
	for side in [-1.0, 1.0]:
		for i in range(0, indices.size(), 3):
			var points: Array[Vector3] = []
			for k in 3:
				var p := profile[indices[i + k]]
				points.append(Vector3(side * half, p.y, p.x))
			triangle(builder, points[0], points[1], points[2], Vector3(side, 0, 0))
	var center := Vector2.ZERO
	for p in profile:
		center += p
	center /= profile.size()
	for i in profile.size():
		var p := profile[i]
		var q := profile[(i + 1) % profile.size()]
		var edge := q - p
		var outward2 := Vector2(edge.y, -edge.x)
		if outward2.dot((p + q) / 2.0 - center) < 0.0:
			outward2 = -outward2
		var outward := Vector3(0, outward2.y, outward2.x)
		var a := Vector3(-half, p.y, p.x)
		var b := Vector3(half, p.y, p.x)
		var c := Vector3(half, q.y, q.x)
		var d := Vector3(-half, q.y, q.x)
		triangle(builder, a, b, c, outward)
		triangle(builder, a, c, d, outward)

## Utilitaria cartoon lunga 3,6 m, fronte verso +Z, ruote escluse.
static func car_body() -> ArrayMesh:
	if cache.has("car_body"):
		return cache.car_body
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	extrude(builder, PackedVector2Array([Vector2(-1.78, 0.3), Vector2(1.78, 0.3), Vector2(1.84, 0.62), Vector2(1.66, 0.86),
		Vector2(0.78, 0.96), Vector2(0.3, 1.44), Vector2(-0.95, 1.48), Vector2(-1.62, 1.02), Vector2(-1.8, 0.72)]), 0.82)
	cache.car_body = builder.commit()
	return cache.car_body

## Vetratura leggermente sporgente rispetto alla carrozzeria.
static func car_glass() -> ArrayMesh:
	if cache.has("car_glass"):
		return cache.car_glass
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	extrude(builder, PackedVector2Array([Vector2(0.74, 1.0), Vector2(0.36, 1.42), Vector2(-0.9, 1.45),
		Vector2(-1.56, 1.04), Vector2(-1.2, 0.98), Vector2(0.4, 0.98)]), 0.835)
	cache.car_glass = builder.commit()
	return cache.car_glass

## Stella a cinque punte con bisello, raggio esterno 0,5 e spessore 0,16.
static func star() -> ArrayMesh:
	if cache.has("star"):
		return cache.star
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: Array[Vector3] = []
	for i in 10:
		var angle := PI / 2.0 + float(i) * PI / 5.0
		var radius := 0.5 if i % 2 == 0 else 0.22
		rim.append(Vector3(cos(angle) * radius, sin(angle) * radius, 0))
	for side in [-1.0, 1.0]:
		var apex := Vector3(0, 0, side * 0.12)
		for i in 10:
			triangle(builder, rim[i], rim[(i + 1) % 10], apex, (rim[i] + rim[(i + 1) % 10]) / 2.0 + Vector3(0, 0, side * 0.5))
	cache.star = builder.commit()
	return cache.star
