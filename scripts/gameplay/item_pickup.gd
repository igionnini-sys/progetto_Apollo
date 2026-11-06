extends Node3D
## Oggetto a terra: cassetta degli attrezzi (per Apollo) o cassa di frutta (per Gino). Si rigenera dopo alcuni secondi.
## Contiene anche le forme dei proiettili, condivise dal sistema degli oggetti.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const RESPAWN_SECONDS := 8.0
var kind: String = "tool"      # "tool" (Apollo) o "fruit" (Gino)
var distance: float = 0.0      # distanza lungo il percorso
var lane: float = 0.0
var respawn: float = 0.0
var shape: Node3D

func _ready() -> void:
	name = "CassettaAttrezzi" if kind == "tool" else "CassaFrutta"
	shape = Node3D.new()
	add_child(shape)
	if kind == "tool":
		G.box(shape, Vector3(0, 0.55, 0), Vector3(0.95, 0.55, 0.6), Color("c8301b")).material_override = Materials.paint(Color("c8301b"), 0.3)
		G.box(shape, Vector3(0, 0.88, 0), Vector3(0.5, 0.08, 0.1), Color("2a2f33"))
		var bolt := G.box(shape, Vector3(0, 0.55, 0.31), Vector3(0.18, 0.4, 0.02), Color("ffd23d"))
		bolt.rotation.z = 0.35
		bolt.material_override = Materials.glow(Color("ffd23d"), 0.8)
	else:
		G.box(shape, Vector3(0, 0.4, 0), Vector3(0.95, 0.4, 0.65), Color("b58a55"))
		for i in 4:
			G.sphere(shape, Vector3(-0.3 + i * 0.2, 0.68, (i % 2) * 0.12 - 0.06), 0.14, [Color("d8402a"), Color("f08a1c"), Color("7cb342"), Color("f2c230")][i])
	var ring := G.cylinder(self, Vector3(0, 0.06, 0), 1.2, 0.03, Color("3fe6ff") if kind == "tool" else Color("ffb23d"))
	ring.material_override = Materials.glow(Color("3fe6ff") if kind == "tool" else Color("ffb23d"), 0.9)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if respawn > 0.0:
		respawn -= delta
		if respawn <= 0.0:
			shape.show()
	if shape.visible and not get_tree().get_meta("apollo_reduced_motion", false):
		shape.rotation.y += delta * 1.8
		shape.position.y = 0.12 + sin(Time.get_ticks_msec() / 400.0) * 0.08

func is_ready() -> bool:
	return respawn <= 0.0

func take() -> void:
	respawn = RESPAWN_SECONDS
	shape.hide()

## Forma di un proiettile o di un oggetto lanciato.
static func projectile_visual(item: String) -> Node3D:
	var root := Node3D.new()
	match item:
		"forbici":
			for angle in [0.35, -0.35]:
				var blade := G.box(root, Vector3.ZERO, Vector3(0.05, 0.03, 0.9), Color("c9ced1"))
				blade.rotation.y = angle
				blade.material_override = Materials.metal(Color("c9ced1"), 0.2)
			G.box(root, Vector3(0.18, 0, 0.5), Vector3(0.12, 0.05, 0.14), Color("e8921b"))
			G.box(root, Vector3(-0.18, 0, 0.5), Vector3(0.12, 0.05, 0.14), Color("e8921b"))
		"multimetro":
			G.box(root, Vector3.ZERO, Vector3(0.4, 0.2, 0.55), Color("f2c230")).material_override = Materials.paint(Color("f2c230"), 0.3)
			G.box(root, Vector3(0, 0.11, -0.05), Vector3(0.28, 0.02, 0.2), Color("7fd4a0")).material_override = Materials.glow(Color("7fd4a0"), 0.7)
		"pomodoro":
			G.sphere(root, Vector3.ZERO, 0.22, Color("d8402a"))
		"arancia":
			G.sphere(root, Vector3.ZERO, 0.24, Color("f08a1c"))
		"anguria":
			var melon := G.sphere(root, Vector3.ZERO, 0.38, Color("4f9a4a"))
			melon.scale = Vector3(1.0, 0.9, 1.25)
			G.box(root, Vector3(0, 0.34, 0), Vector3(0.05, 0.05, 0.5), Color("2f6a30"))
	return root
