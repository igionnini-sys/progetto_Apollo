extends Node3D
const G = preload("res://scripts/utilities/geometry.gd")
var profile: Dictionary
var child_passenger: bool = false
var belt: Node3D
var head: Node3D

func _ready() -> void:
	name = "Nipotina" if child_passenger else "Nonno"
	var skin := Color.from_string(str(profile.skin), Color("efd0ad"))
	var hair := Color.from_string(str(profile.hair), Color("795b48"))
	var shirt := Color.from_string(str(profile.shirt), Color("688c9d"))
	var dark := Color("3b4b51")
	G.box(self, Vector3(0, 0.35, -0.04), Vector3(0.44, 0.62, 0.36), shirt)
	for x in [-0.13, 0.13]:
		G.box(self, Vector3(x, 0.08, -0.24), Vector3(0.18, 0.18, 0.55), Color("657987"))
		G.sphere(self, Vector3(x, -0.02, -0.46), 0.1, dark)
	for x in [-0.24, 0.24]:
		var arm := G.box(self, Vector3(x, 0.46, -0.2), Vector3(0.12, 0.4, 0.12), shirt)
		arm.rotation.x = -0.8
		G.sphere(self, Vector3(x, 0.34, -0.36), 0.075, skin)
	head = Node3D.new()
	head.position = Vector3(0, 0.91 if child_passenger else 1.03, -0.07)
	add_child(head)
	var radius := 0.23 if child_passenger else 0.26
	G.sphere(head, Vector3.ZERO, radius, skin)
	var cap := G.sphere(head, Vector3(0, 0.12, 0.05), radius*0.92, hair)
	cap.scale.y = 0.72
	for x in [-0.09, 0.09]:
		G.sphere(head, Vector3(x, 0.015, -radius*0.92), 0.032, dark)
		G.sphere(head, Vector3(x-0.008, 0.024, -radius), 0.01, Color("fff6de"))
	G.sphere(head, Vector3(0, -0.025, -radius), 0.042, skin)
	G.box(head, Vector3(0, -0.10, -radius*0.88), Vector3(0.10, 0.016, 0.025), Color("ad786b"))
	if child_passenger:
		G.sphere(head, Vector3(0.22, 0.03, 0.17), 0.14, hair)
		for side in [-1, 1]:
			G.sphere(head, Vector3(0.22+side*0.055, 0.16, 0.09), 0.055, Color("dfb779"))
	else:
		for x in [-0.1, 0.1]:
			G.box(head, Vector3(x, 0.03, -0.25), Vector3(0.15, 0.012, 0.02), dark)
			G.box(head, Vector3(x, -0.055, -0.25), Vector3(0.15, 0.012, 0.02), dark)
			for side in [-1, 1]:
				G.box(head, Vector3(x+side*0.075, -0.012, -0.25), Vector3(0.012, 0.09, 0.02), dark)
		G.box(head, Vector3(0, 0.015, -0.26), Vector3(0.06, 0.012, 0.02), dark)
		G.box(head, Vector3(0, -0.075, -0.25), Vector3(0.14, 0.035, 0.025), hair)
	# Cintura diagonale e fascia addominale, parte fissa del modello seduto.
	belt = G.box(self, Vector3(0, 0.39, -0.255), Vector3(0.065, 0.71, 0.045), dark)
	belt.name = "CinturaDiagonale"
	belt.rotation.z = 0.5
	G.box(self, Vector3(0, 0.15, -0.32), Vector3(0.46, 0.065, 0.04), dark).name = "CinturaAddominale"
	G.box(self, Vector3(0.12, 0.16, -0.35), Vector3(0.085, 0.075, 0.04), Color("e0b373"))
	# Teste e mani più morbide: le sfere dei volti usano più segmenti.
	for node in find_children("*", "MeshInstance3D", true, false):
		var item := node as MeshInstance3D
		if item.mesh is SphereMesh:
			(item.mesh as SphereMesh).radial_segments = 24
			(item.mesh as SphereMesh).rings = 12
