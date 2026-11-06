extends Node3D
## Passante di Volpiano: cammina avanti e indietro a bordo strada e saluta Apollo.
const G = preload("res://scripts/utilities/geometry.gd")
var axis: Vector3 = Vector3.FORWARD
var span: float = 7.0
var speed: float = 1.1
var phase: float = 0.0
var origin: Vector3
var body: Node3D

func setup(shirt: Color, trousers: Color, child: bool) -> void:
	body = Node3D.new()
	add_child(body)
	var scale_factor := 0.72 if child else 1.0
	body.scale = Vector3.ONE * scale_factor
	G.cylinder(body, Vector3(0, 0.45, 0), 0.16, 0.9, trousers)
	G.cylinder(body, Vector3(0, 1.15, 0), 0.22, 0.6, shirt)
	G.sphere(body, Vector3(0, 1.62, 0), 0.19, Color("e8b894"))
	origin = position
	phase = position.x * 0.37

func _process(delta: float) -> void:
	phase += delta * speed / span * PI
	var offset := sin(phase)
	position = origin + axis * offset * span * 0.5
	rotation.y = atan2(axis.x, axis.z) + (0.0 if cos(phase) > 0.0 else PI)
	body.position.y = absf(sin(phase * 9.0)) * 0.05
