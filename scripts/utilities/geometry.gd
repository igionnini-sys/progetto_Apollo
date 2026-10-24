extends RefCounted
## Primitive originali condivise. Nessun asset esterno richiesto.

static var materials: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = 0.85
		materials[color] = result
	return materials[color]

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var result := MeshInstance3D.new()
	result.mesh = shape
	result.material_override = material(color)
	result.position = pos
	parent.add_child(result)
	return result

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, solid: bool = false) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	var result := mesh(parent, shape, pos, color)
	if solid:
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
		result.add_child(body)
	return result

static func sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	return mesh(parent, shape, pos, color)

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 12
	return mesh(parent, shape, pos, color)

static func label(parent: Node3D, text: String, pos: Vector3, size: int = 40) -> Label3D:
	var result := Label3D.new()
	result.text = text
	result.position = pos
	result.font_size = size
	result.pixel_size = 0.012
	result.outline_size = 6
	result.modulate = Color("fff4d9")
	parent.add_child(result)
	return result
