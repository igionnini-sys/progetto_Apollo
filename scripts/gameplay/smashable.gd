extends Node3D
## Cassa o cassetta di frutta da sfondare: nessuna collisione fisica, nessun danno per Apollo.
const G = preload("res://scripts/utilities/geometry.gd")
var fruit: bool = false
var smashed: bool = false
var pieces: Array[Dictionary] = []
var age: float = 0.0

func _ready() -> void:
	var wood := Color("b57a3d") if not fruit else Color("c9a064")
	for level in (2 if fruit else 3):
		G.box(self, Vector3(0, 0.3 + level * 0.6, 0), Vector3(0.9, 0.55, 0.9), wood.darkened(level * 0.06))
	if fruit:
		var colors := [Color("d9422f"), Color("f0902a"), Color("8cc152")]
		for i in 6:
			G.sphere(self, Vector3(-0.28 + (i % 3) * 0.28, 1.28, -0.14 + (i / 3) * 0.28), 0.16, colors[i % 3])

func smash(direction: Vector3) -> void:
	smashed = true
	var rng := RandomNumberGenerator.new()
	rng.seed = int(position.x * 10.0) + int(position.z)
	var holder := Node3D.new()
	for child in get_children():
		var piece := child as Node3D
		remove_child(piece)
		holder.add_child(piece)
		pieces.append({
			"node": piece,
			"velocity": direction * rng.randf_range(3.0, 7.0) + Vector3(rng.randf_range(-2, 2), rng.randf_range(3.0, 6.5), rng.randf_range(-2, 2)),
			"spin": Vector3(rng.randf_range(-6, 6), rng.randf_range(-6, 6), rng.randf_range(-6, 6)),
		})
	add_child(holder)

func _process(delta: float) -> void:
	if not smashed:
		return
	age += delta
	for piece in pieces:
		var node: Node3D = piece.node
		piece.velocity.y -= 14.0 * delta
		node.position += piece.velocity * delta
		node.rotation += piece.spin * delta
		if node.position.y < 0.15:
			node.position.y = 0.15
			piece.velocity = Vector3(piece.velocity.x * 0.5, absf(piece.velocity.y) * 0.3, piece.velocity.z * 0.5)
			piece.spin *= 0.5
	if age > 3.0:
		queue_free()
