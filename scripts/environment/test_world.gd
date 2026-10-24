extends Node3D
## Circuito fittizio di collaudo. Non contiene dati geografici o indirizzi.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const TownStyle = preload("res://scripts/environment/town_style.gd")
const Meshes = preload("res://scripts/utilities/meshes.gd")
var town = TownStyle.new()
var checkpoints: Array[Vector3] = [Vector3(-54, 0, 0), Vector3(0, 0, -36), Vector3(54, 0, 0), Vector3(0, 0, 36)]
var gates: Array[Node3D] = []

func _ready() -> void:
	name = "CircuitoProva"
	G.box(self, Vector3(0, -0.6, 0), Vector3(330, 1, 330), Color("9cbe79"), true).material_override = Materials.grass()
	var countryside := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(9000, 9000)
	countryside.mesh = plane
	countryside.position.y = -0.3
	countryside.material_override = Materials.grass(true)
	countryside.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(countryside)
	road_ring(7.7, 0.012, Materials.paving())
	road_ring(5.8, 0.025, Materials.asphalt())
	for i in 96:
		var angle := TAU * float(i) / 96.0
		var p := Vector3(54 * cos(angle), 0.04, 36 * sin(angle))
		var dash := G.box(self, p, Vector3(0.13, 0.018, 1.35), Color("f9eac3"))
		dash.rotation.y = atan2(-54 * sin(angle), 36 * cos(angle))
	for i in 4:
		var gate := Node3D.new()
		gate.position = checkpoints[i]
		gate.rotation.y = [0.0, PI / 2, 0.0, PI / 2][i]
		add_child(gate)
		gates.append(gate)
		for x in [-4.7, 4.7]:
			G.cylinder(gate, Vector3(x, 2.8, 0), 0.16, 5.6, Color("f0ba61"))
		G.box(gate, Vector3(0, 5.4, 0), Vector3(9.8, 0.6, 0.4), Color("367c80"))
		var label := G.label(gate, "TAPPA %d" % (i + 1), Vector3(0, 5.43, 0.24), 42)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var random := RandomNumberGenerator.new()
	random.seed = 20261017
	for i in 40:
		var angle := TAU * float(i) / 40.0
		var p := Vector3(77 * cos(angle), 0, 58 * sin(angle))
		if i % 3 == 0:
			building(p, town.palette[i % town.palette.size()], random.randf_range(5, 8))
		else:
			town.tree(p, i * 7 + 3)
	for i in 14:
		var angle := TAU * float(i) / 14.0
		town.tree(Vector3(33 * cos(angle), 0, 19 * sin(angle)), i * 5 + 1)
	# Prato vivo: ciuffi, fiori e cespugli lontano dalla pista e dalla fontana.
	for i in 1800:
		var p := Vector3(random.randf_range(-150, 150), -0.1, random.randf_range(-150, 150))
		var ring := sqrt(pow(p.x / 54.0, 2) + pow(p.z / 36.0, 2))
		if absf(ring - 1.0) < 0.24 or p.length() < 13.0 or Vector2(p.x - 110, p.z).length() < 6.0:
			continue
		if i % 19 == 0:
			town.bush(p, i, random.randf_range(0.8, 1.3))
		else:
			town.grass_tuft(p, i)
	var greenery := Node3D.new()
	greenery.name = "Verde"
	add_child(greenery)
	town.batch.flush(greenery)
	G.cylinder(self, Vector3(0, 0.16, 0), 9, 0.3, Color("d9c5a4"))
	G.cylinder(self, Vector3(0, 0.42, 0), 5, 0.45, Color("f2e3c5"))
	G.cylinder(self, Vector3(0, 0.67, 0), 4.5, 0.08, Color("69b9c9"))
	G.cylinder(self, Vector3(0, 1.3, 0), 0.5, 1.4, Color("eae1c8"))
	G.sphere(self, Vector3(0, 2.2, 0), 0.9, Color("efd074"))
	for x in [-12, 12]:
		G.box(self, Vector3(x, 0.65, 0), Vector3(3, 0.18, 0.9), Color("b27b52"))
		G.box(self, Vector3(x, 1.15, 0.5), Vector3(3, 0.7, 0.15), Color("b27b52"))
		for offset in [-1, 1]:
			G.box(self, Vector3(x + offset, 0.3, 0), Vector3(0.15, 0.6, 0.7), Color("485459"))
	G.label(self, "IL PRIMO GIRO DI APOLLO", Vector3(0, 4.0, 5), 60)
	for z in [-1, 1]:
		G.box(self, Vector3(0, 1.5, z * 154), Vector3(310, 3, 1.4), Color("6a9274"), true).material_override = Materials.hedge()
		G.box(self, Vector3(z * 154, 1.5, 0), Vector3(1.4, 3, 310), Color("6a9274"), true).material_override = Materials.hedge()
	# Ostacolo dedicato al collaudo delle collisioni, lontano dal circuito.
	G.box(self, Vector3(110, 1, 0), Vector3(5, 2, 5), Color("df9972"), true)

func road_ring(half_width: float, height: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 128:
		var a := TAU * float(i) / 128.0
		var b := TAU * float(i + 1) / 128.0
		var points: Array[Vector3] = []
		for t in [a, b]:
			var center := Vector3(54 * cos(t), height, 36 * sin(t))
			var outward := Vector3(36 * cos(t), 0, 54 * sin(t)).normalized()
			points.append(center - outward * half_width)
			points.append(center + outward * half_width)
		# Avvolgimento frontale Godot: la pista deve essere visibile dall'alto.
		Meshes.triangle(surface, points[0], points[2], points[1], Vector3.UP)
		Meshes.triangle(surface, points[1], points[2], points[3], Vector3.UP)
	var result := MeshInstance3D.new()
	result.mesh = surface.commit()
	result.material_override = material
	result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(result)

func building(pos: Vector3, color: Color, height: float) -> void:
	var root := Node3D.new()
	root.position = pos
	root.look_at_from_position(pos, Vector3(0, 0, 0))
	add_child(root)
	G.box(root, Vector3(0, height / 2, 0), Vector3(7, height, 5), color, true)
	G.box(root, Vector3(0, height + 0.1, 0), Vector3(7.5, 0.24, 5.5), Color("f4e3c4"))
	var roof := PrismMesh.new()
	roof.size = Vector3(5.9, 1.9, 7.9)
	var tiles := G.mesh(root, roof, Vector3(0, height + 1.17, 0), Color("c8674a"))
	tiles.rotation.y = PI / 2.0
	G.box(root, Vector3(1.8, height + 1.6, 0.8), Vector3(0.5, 1.4, 0.5), Color("b56a50"))
	G.box(root, Vector3(0, 1.2, -2.53), Vector3(1.2, 2.4, 0.1), Color("547f7b"))
	for x in [-2.0, 2.0]:
		for y in [1.8, 4.2]:
			G.box(root, Vector3(x, y, -2.54), Vector3(1.1, 1.35, 0.1), Color("f6e8c8"))
			G.box(root, Vector3(x, y, -2.6), Vector3(0.86, 1.1, 0.06), Color("3d5f70")).material_override = Materials.glass(Color(0.24, 0.37, 0.44, 0.92))
			for side in [-1, 1]:
				G.box(root, Vector3(x + side * 0.72, y, -2.58), Vector3(0.34, 1.35, 0.08), Color("4f8a63"))
			G.box(root, Vector3(x, y - 0.72, -2.65), Vector3(1.4, 0.12, 0.4), Color("f6e3bc"))
