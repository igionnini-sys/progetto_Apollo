extends RefCounted
## Primitive ripetute raggruppate per forma e materiale; colore per istanza.
const Materials = preload("res://scripts/utilities/materials.gd")
const Meshes = preload("res://scripts/utilities/meshes.gd")
const FacadeMeshes = preload("res://scripts/environment/facade_meshes.gd")
var groups: Dictionary = {}
var instance_count: int = 0

## `kind`: box, cylinder, sphere, blob, cone, car_body, car_glass, arch_frame, arch_fill.
## `look`: plain, foliage, glass, metal, paint, glow, marker, shutter, window, paving.
func add(kind: String, pos: Vector3, size: Vector3, color: Color, yaw: float = 0.0, look: String = "plain") -> void:
	var key := kind + "_" + look
	if not groups.has(key):
		groups[key] = {"kind": kind, "look": look, "transforms": [], "colors": []}
	var basis := Basis(Vector3.UP, yaw).scaled_local(size)
	groups[key].transforms.append(Transform3D(basis, pos))
	groups[key].colors.append(color)
	instance_count += 1

func add_transform(kind: String, transform: Transform3D, color: Color, look: String = "plain") -> void:
	var key := kind + "_" + look
	if not groups.has(key):
		groups[key] = {"kind": kind, "look": look, "transforms": [], "colors": []}
	groups[key].transforms.append(transform)
	groups[key].colors.append(color)
	instance_count += 1

func shape(kind: String) -> Mesh:
	match kind:
		"arch_frame":
			return FacadeMeshes.arch_frame()
		"arch_fill":
			return FacadeMeshes.arch_fill()
		"sphere":
			var sphere := SphereMesh.new()
			sphere.radius = 0.5
			sphere.height = 1.0
			sphere.radial_segments = 14
			sphere.rings = 7
			return sphere
		"cylinder":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.5
			cylinder.bottom_radius = 0.5
			cylinder.height = 1.0
			cylinder.radial_segments = 12
			return cylinder
		"trunk":
			var trunk := CylinderMesh.new()
			trunk.top_radius = 0.32
			trunk.bottom_radius = 0.5
			trunk.height = 1.0
			trunk.radial_segments = 7
			return trunk
		"blob":
			return Meshes.blob()
		"cone":
			return Meshes.cone()
		"car_body":
			return Meshes.car_body()
		"car_glass":
			return Meshes.car_glass()
	return BoxMesh.new()

func flush(parent: Node3D) -> void:
	for key: String in groups:
		var group: Dictionary = groups[key]
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.mesh = shape(group.kind)
		instances.instance_count = group.transforms.size()
		for i in instances.instance_count:
			instances.set_instance_transform(i, group.transforms[i])
			instances.set_instance_color(i, group.colors[i])
		var node := MultiMeshInstance3D.new()
		node.multimesh = instances
		node.material_override = Materials.instanced(group.look)
		node.name = "Town_" + key
		if group.look in ["marker", "glow", "paving"] or group.kind == "car_glass":
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
	groups.clear()
