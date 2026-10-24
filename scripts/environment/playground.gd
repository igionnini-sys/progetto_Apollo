extends Node3D
## Allestimento cartoon riutilizzabile; ingombri e disposizione illustrativi.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const Meshes = preload("res://scripts/utilities/meshes.gd")
var park_data: Dictionary
var swing: Node3D
var seesaw: Node3D
var star: Node3D
var elapsed: float = 0
var hiding_place: int = 0

func _ready() -> void:
	name = "Parco_" + str(park_data.id)
	process_mode = Node.PROCESS_MODE_ALWAYS
	scale = Vector3(float(park_data.size[0])/14, 1, float(park_data.size[1])/18)
	rotation.y = float(park_data.yaw)
	G.box(self, Vector3(0, 0.02, 0), Vector3(14, 0.08, 18), Color("6fc2b0"))
	G.box(self, Vector3(-3, 0.08, -4), Vector3(6, 0.05, 6), Color("f0a868"))
	G.box(self, Vector3(3, 0.08, 3), Vector3(5, 0.05, 6), Color("8fb4ea"))
	# Altalena: telaio, sospensioni e seduta oscillante.
	for x in [-5, -1]:
		G.cylinder(self, Vector3(x, 1.5, -4), 0.10, 3.0, Color("3f8fd0"))
	G.box(self, Vector3(-3, 3, -4), Vector3(4.5, 0.16, 0.18), Color("3f8fd0"))
	swing = Node3D.new()
	swing.position = Vector3(-3, 2.9, -4)
	add_child(swing)
	for x in [-0.6, 0.6]:
		G.cylinder(swing, Vector3(x, -1.1, 0), 0.025, 2.2, Color("cfd3d2"))
	G.box(swing, Vector3(0, -2.2, 0), Vector3(1.5, 0.15, 0.7), Color("f05a4f"))
	# Castello con scivolo e scala.
	for x in [2, 4]:
		for z in [-5, -3]:
			G.cylinder(self, Vector3(x, 1.3, z), 0.12, 2.6, Color("c99256"))
	G.box(self, Vector3(3, 1.9, -4), Vector3(2.3, 0.2, 2.3), Color("ffc93c"))
	var slide := G.box(self, Vector3(3, 1.0, -1.6), Vector3(1.3, 0.12, 3.5), Color("f05a4f"))
	slide.rotation.x = 0.55
	for rung in 5:
		G.box(self, Vector3(3, 0.35+rung*0.34, -5.25), Vector3(1.3, 0.1, 0.15), Color("3f8fd0"))
	var roof := CylinderMesh.new()
	roof.top_radius = 0
	roof.bottom_radius = 1.7
	roof.height = 1.1
	roof.radial_segments = 4
	G.mesh(self, roof, Vector3(3, 3.3, -4), Color("f05a4f"))
	# Dondolo e piccola struttura per arrampicarsi.
	G.cylinder(self, Vector3(-3, 0.45, 3), 0.35, 0.9, Color("3f8fd0"))
	seesaw = Node3D.new()
	seesaw.position = Vector3(-3, 0.85, 3)
	add_child(seesaw)
	G.box(seesaw, Vector3.ZERO, Vector3(3.8, 0.18, 0.5), Color("ffc93c"))
	for x in [-1.5, 1.5]:
		G.box(seesaw, Vector3(x, 0.12, 0), Vector3(0.65, 0.16, 0.7), Color("f05a4f"))
	for x in [1.5, 4.5]:
		for z in [2, 5]:
			G.cylinder(self, Vector3(x, 1.25, z), 0.09, 2.5, Color("4fb87a"))
	for rung in 5:
		G.box(self, Vector3(3, 0.4+rung*0.45, 2), Vector3(3, 0.08, 0.08), Color("ffc93c"))
		G.box(self, Vector3(3, 2.5, 2+rung*0.75), Vector3(3, 0.08, 0.08), Color("8f74d1"))
	G.box(self, Vector3(0, 0.55, 7), Vector3(3.4, 0.18, 0.65), Color("b18c69"))
	G.box(self, Vector3(0, 1.0, 7.3), Vector3(3.4, 0.7, 0.12), Color("b18c69"))
	for x in [-1.2, 1.2]:
		G.box(self, Vector3(x, 0.25, 7), Vector3(0.12, 0.5, 0.5), Color("5b7f78"))
	for x in [-5.5, 5.5]:
		G.cylinder(self, Vector3(x, 1, 7), 0.17, 2, Color("9c7c5a"))
		G.sphere(self, Vector3(x, 2.8, 7), 1.1, Color("7fb35a"))
	# Recinto continuo per i veicoli; la visita dei giochi usa una camera dedicata.
	for x in [-6.9, 6.9]:
		G.box(self, Vector3(x, 0.5, 0), Vector3(0.12, 1, 17.8), Color("5a8f6e"), true)
	for z in [-8.9, 8.9]:
		G.box(self, Vector3(0, 0.5, z), Vector3(13.8, 1, 0.12), Color("5a8f6e"), true)
	# Plastiche lucide per i giochi colorati.
	for node in find_children("*", "MeshInstance3D", true, false):
		var item := node as MeshInstance3D
		var material := item.material_override as StandardMaterial3D
		if material != null and material.albedo_color in [Color("f05a4f"), Color("ffc93c"), Color("3f8fd0"), Color("4fb87a"), Color("8f74d1")]:
			item.material_override = Materials.plastic(material.albedo_color, 0.35)
	var title := G.label(self, str(park_data.name), Vector3(0, 4.5, 0), 28)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hiding_place = ["madonna", "riviera", "san_grato"].find(str(park_data.id))
	star = Node3D.new()
	star.position = [Vector3(3, 2.8, -3), Vector3(-3, 1.5, -4), Vector3(0, 1.5, 7)][hiding_place]
	add_child(star)
	var shape := MeshInstance3D.new()
	shape.mesh = Meshes.star()
	shape.scale = Vector3.ONE * 1.6
	shape.material_override = Materials.glow(Color("ffcf4a"), 1.6)
	star.add_child(shape)
	star.hide()

func _process(delta: float) -> void:
	if get_tree().get_meta("apollo_reduced_motion", false):
		swing.rotation.x = 0.0
		seesaw.rotation.z = 0.0
		return
	elapsed += delta
	swing.rotation.x = sin(elapsed*1.5)*0.12
	seesaw.rotation.z = sin(elapsed)*0.08
	if star.visible:
		star.rotation.y += delta
