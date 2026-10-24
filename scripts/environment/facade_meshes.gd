extends RefCounted
## Portali normalizzati, estrusi e riutilizzati dai MultiMesh della città.
const Meshes = preload("res://scripts/utilities/meshes.gd")
static var cache: Dictionary = {}

static func face(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	Meshes.triangle(builder, a, b, c, normal)
	Meshes.triangle(builder, a, c, d, normal)

static func arch_frame() -> ArrayMesh:
	if cache.has("arch_frame"):
		return cache.arch_frame
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 20:
		var a := PI * i / 20.0
		var b := PI * (i + 1) / 20.0
		var outer_a := Vector2(cos(a) * 0.5, 0.16 + sin(a) * 0.34)
		var outer_b := Vector2(cos(b) * 0.5, 0.16 + sin(b) * 0.34)
		var inner_a := Vector2(cos(a) * 0.39, 0.16 + sin(a) * 0.23)
		var inner_b := Vector2(cos(b) * 0.39, 0.16 + sin(b) * 0.23)
		for z in [-0.5, 0.5]:
			face(builder, Vector3(outer_a.x, outer_a.y, z), Vector3(outer_b.x, outer_b.y, z), Vector3(inner_b.x, inner_b.y, z), Vector3(inner_a.x, inner_a.y, z), Vector3.BACK * z)
		var radial := Vector3(cos((a + b) * 0.5), sin((a + b) * 0.5), 0)
		face(builder, Vector3(outer_a.x, outer_a.y, -0.5), Vector3(outer_b.x, outer_b.y, -0.5), Vector3(outer_b.x, outer_b.y, 0.5), Vector3(outer_a.x, outer_a.y, 0.5), radial)
		face(builder, Vector3(inner_a.x, inner_a.y, -0.5), Vector3(inner_b.x, inner_b.y, -0.5), Vector3(inner_b.x, inner_b.y, 0.5), Vector3(inner_a.x, inner_a.y, 0.5), -radial)
	for side in [-1.0, 1.0]:
		var x0: float = side * 0.39
		var x1: float = side * 0.5
		for z in [-0.5, 0.5]:
			face(builder, Vector3(x0, -0.5, z), Vector3(x1, -0.5, z), Vector3(x1, 0.16, z), Vector3(x0, 0.16, z), Vector3.BACK * z)
		for x in [x0, x1]:
			face(builder, Vector3(x, -0.5, -0.5), Vector3(x, 0.16, -0.5), Vector3(x, 0.16, 0.5), Vector3(x, -0.5, 0.5), Vector3.RIGHT * side * (-1.0 if x == x0 else 1.0))
		face(builder, Vector3(x0, -0.5, -0.5), Vector3(x1, -0.5, -0.5), Vector3(x1, -0.5, 0.5), Vector3(x0, -0.5, 0.5), Vector3.DOWN)
	cache.arch_frame = builder.commit()
	return cache.arch_frame

static func arch_fill() -> ArrayMesh:
	if cache.has("arch_fill"):
		return cache.arch_fill
	var outline := PackedVector2Array([Vector2(-0.5, -0.5), Vector2(0.5, -0.5)])
	for i in 21:
		var angle := PI * i / 20.0
		outline.append(Vector2(cos(angle) * 0.5, 0.16 + sin(angle) * 0.34))
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(outline)
	for z in [-0.5, 0.5]:
		for i in range(0, indices.size(), 3):
			var a := outline[indices[i]]
			var b := outline[indices[i + 1]]
			var c := outline[indices[i + 2]]
			Meshes.triangle(builder, Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), Vector3.BACK * z)
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var edge := b - a
		face(builder, Vector3(a.x, a.y, -0.5), Vector3(b.x, b.y, -0.5), Vector3(b.x, b.y, 0.5), Vector3(a.x, a.y, 0.5), Vector3(edge.y, -edge.x, 0))
	cache.arch_fill = builder.commit()
	return cache.arch_fill
