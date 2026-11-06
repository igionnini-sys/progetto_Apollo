extends Node3D
## Banconota del nonno caduta lungo la strada: svolazza e si raccoglie passandoci vicino.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const COLORS := {500: Color("9aa3a8"), 1000: Color("d0524a"), 2000: Color("4a7fc8"), 5000: Color("e08a3a")}
var value: int = 500
var collected: bool = false
var shape: MeshInstance3D
var elapsed: float = 0.0

func _ready() -> void:
	shape = MeshInstance3D.new()
	var note := BoxMesh.new()
	note.size = Vector3(1.0, 0.03, 0.52)
	shape.mesh = note
	shape.material_override = Materials.glow(COLORS.get(value, Color("9aa3a8")), 0.7)
	add_child(shape)
	G.box(shape, Vector3(0, 0.02, 0), Vector3(0.62, 0.02, 0.32), Color("f4efd8"))
	elapsed = position.x * 0.4

func _process(delta: float) -> void:
	elapsed += delta
	rotation.y += delta * 1.6
	shape.rotation.z = sin(elapsed * 3.0) * 0.35
	shape.position.y = sin(elapsed * 2.0) * 0.15

func collect() -> void:
	collected = true
	hide()
