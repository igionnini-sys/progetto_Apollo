extends Node3D
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
var red: MeshInstance3D
var green: MeshInstance3D
var released: bool = false

func _ready() -> void:
	G.cylinder(self, Vector3(0, 1.8, 0), 0.08, 3.6, Color("38524f")).material_override = Materials.metal(Color("38524f"), 0.4)
	G.box(self, Vector3(0, 3.4, 0), Vector3(0.65, 1.5, 0.4), Color("2b3b3c"))
	for y in [3.85, 3.4, 2.95]:
		G.box(self, Vector3(0, y + 0.14, 0.27), Vector3(0.5, 0.06, 0.18), Color("2b3b3c"))
	red = G.sphere(self, Vector3(0, 3.85, 0.25), 0.19, Color("da766b"))
	G.sphere(self, Vector3(0, 3.4, 0.25), 0.19, Color("6e6a55"))
	green = G.sphere(self, Vector3(0, 2.95, 0.25), 0.19, Color("526d64"))
	reset()

func reset() -> void:
	released = false
	red.material_override = Materials.glow(Color("ff5747"), 3.0)
	green.material_override = G.material(Color("3f5149"))

func release() -> void:
	released = true
	red.material_override = G.material(Color("5a3f3b"))
	green.material_override = Materials.glow(Color("5cf08a"), 3.0)
