extends Node3D
const Meshes = preload("res://scripts/utilities/meshes.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
var collected: bool = false
var elapsed: float = 0.0
var shape: MeshInstance3D

func _ready() -> void:
	shape = MeshInstance3D.new()
	shape.mesh = Meshes.star()
	shape.scale = Vector3.ONE * 1.25
	shape.material_override = Materials.glow(Color("ffcf4a"), 1.4)
	add_child(shape)
	elapsed = position.x * 0.3

func _process(delta: float) -> void:
	elapsed += delta
	rotation.y += delta * 1.2
	if not get_tree().get_meta("apollo_reduced_motion", false):
		shape.position.y = sin(elapsed * 2.2) * 0.18

func collect() -> void:
	collected = true
	hide()
