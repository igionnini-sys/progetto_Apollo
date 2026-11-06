extends Node3D
## Striscia turbo sulla strada: pannello scuro con tre frecce luminose nel senso di marcia (-Z).
const Materials = preload("res://scripts/utilities/materials.gd")
const G = preload("res://scripts/utilities/geometry.gd")
const WIDTH := 4.0
const LENGTH := 6.0
var arrows: Array[MeshInstance3D] = []

func _ready() -> void:
	name = "StrisciaTurbo"
	var base := G.box(self, Vector3(0, 0.07, 0), Vector3(WIDTH, 0.02, LENGTH), Color("142a3a"))
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for i in 3:
		var arrow := MeshInstance3D.new()
		arrow.mesh = chevron(WIDTH * 0.78, 1.25, 0.5)
		arrow.position = Vector3(0, 0.09, 1.6 - i * 1.6)
		arrow.material_override = Materials.glow(Color("3fe6ff"), 1.7)
		arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(arrow)
		arrows.append(arrow)

## Freccia a V rivolta verso -Z: larghezza, profondità e spessore del braccio.
func chevron(width: float, depth: float, arm: float) -> ArrayMesh:
	var half := width * 0.5
	var tip := Vector3(0, 0, -depth * 0.5)
	var outer_l := Vector3(-half, 0, depth * 0.5)
	var outer_r := Vector3(half, 0, depth * 0.5)
	var inner_l := Vector3(-half + arm, 0, depth * 0.5)
	var inner_r := Vector3(half - arm, 0, depth * 0.5)
	var notch := Vector3(0, 0, -depth * 0.5 + arm * 1.1)
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tri in [[tip, outer_r, inner_r], [tip, inner_r, notch], [tip, notch, inner_l], [tip, inner_l, outer_l]]:
		var a: Vector3 = tri[0]
		var b: Vector3 = tri[1]
		var c: Vector3 = tri[2]
		# Visibili dall'alto: normale verso +Y, avvolgimento orario.
		if (b - a).cross(c - a).y > 0.0:
			builder.add_vertex(a)
			builder.add_vertex(c)
			builder.add_vertex(b)
		else:
			builder.add_vertex(a)
			builder.add_vertex(b)
			builder.add_vertex(c)
	builder.generate_normals()
	return builder.commit()

## Le frecce lampeggiano in sequenza, tranne con "Movimenti ridotti".
func _process(_delta: float) -> void:
	if get_tree().get_meta("apollo_reduced_motion", false):
		return
	var phase := Time.get_ticks_msec() / 1000.0 * 5.0
	for i in arrows.size():
		arrows[i].visible = fmod(phase - i * 0.7, 3.0) < 2.2
