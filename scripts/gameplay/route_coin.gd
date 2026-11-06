extends Node3D
## Moneta dorata lungo il percorso: gira su se stessa e si raccoglie passandoci vicino.
const Materials = preload("res://scripts/utilities/materials.gd")
var collected: bool = false
var shape: MeshInstance3D

func _ready() -> void:
	shape = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.42
	disc.bottom_radius = 0.42
	disc.height = 0.09
	disc.radial_segments = 14
	shape.mesh = disc
	shape.rotation.x = PI / 2.0
	shape.material_override = Materials.glow(Color("ffc83d"), 1.1)
	add_child(shape)
	rotation.y = position.x * 0.7

func _process(delta: float) -> void:
	rotation.y += delta * 2.6

func collect() -> void:
	collected = true
	hide()
