extends Node3D
## Gino: furgoncino rosso a tetto alto, ispirato alle sagome dei piccoli furgoni anni '90.
## Geometria originale (nessun marchio, livrea o targa reale). Fronte -Z, lunghezza circa 3,75 m, origine a terra.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const VehicleMesh = preload("res://scripts/vehicles/vehicle_mesh.gd")
const WHEEL_RADIUS := 0.31
const AXLES := [-1.17, 1.13]
const BODY_HALF := 0.76
var red := Color("c8301b")
var dark_red := Color("a02312")
var black := Color("1f2326")
var wheels: Array[Node3D] = []
var headlight_material := Materials.glow(Color("f7f1da"), 0.0)
var brake_material := Materials.glow(Color("b01616"), 0.15)
var window := Materials.glass(Color(0.04, 0.07, 0.09, 0.94))

func _ready() -> void:
	body()
	greenhouse()
	cargo_box()
	trim()
	lights()
	underbody()
	cab_interior()
	for axle in AXLES:
		for side in [-1.0, 1.0]:
			wheel(Vector3(side * (BODY_HALF - 0.1), WHEEL_RADIUS, axle), side)
	fruit_crates()

## Solido a sezioni: ogni stazione è (z, semilarghezza, y basso, y alto, raggio spigolo, rastremazione del tetto).
func loft(stations: Array, color: Color, part_name: String) -> MeshInstance3D:
	var rings: Array = []
	for s: Array in stations:
		var ring: Array[Vector3] = []
		var z: float = s[0]
		var hw: float = s[1]
		var y0: float = s[2]
		var y1: float = s[3]
		var r: float = s[4]
		var ht: float = hw * (1.0 - float(s[5]))
		ring.append(Vector3(-hw, y0, z))
		for i in 7:
			var a := PI - (PI / 2.0) * float(i) / 6.0
			ring.append(Vector3(-ht + r + cos(a) * r, y1 - r + sin(a) * r, z))
		for i in 7:
			var a := PI / 2.0 - (PI / 2.0) * float(i) / 6.0
			ring.append(Vector3(ht - r + cos(a) * r, y1 - r + sin(a) * r, z))
		ring.append(Vector3(hw, y0, z))
		rings.append(ring)
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = rings[0].size()
	for j in rings.size() - 1:
		var centre := Vector3(0, (float(stations[j][2]) + float(stations[j][3])) * 0.5, (float(stations[j][0]) + float(stations[j + 1][0])) * 0.5)
		for i in count - 1:
			add_triangle(builder, rings[j][i], rings[j + 1][i], rings[j + 1][i + 1], centre)
			add_triangle(builder, rings[j][i], rings[j + 1][i + 1], rings[j][i + 1], centre)
	# Tappi di testa e di coda.
	for end in [0, rings.size() - 1]:
		var outline := PackedVector2Array()
		for p: Vector3 in rings[end]:
			outline.append(Vector2(p.x, p.y))
		var tri_indices := Geometry2D.triangulate_polygon(outline)
		var beyond := Vector3(0, 0, -5.0 if end == 0 else 5.0)
		for k in range(0, tri_indices.size(), 3):
			var a: Vector3 = rings[end][tri_indices[k]]
			var b: Vector3 = rings[end][tri_indices[k + 1]]
			var c: Vector3 = rings[end][tri_indices[k + 2]]
			add_triangle(builder, a, b, c, (a + b + c) / 3.0 - beyond)
	builder.index()
	builder.generate_normals()
	var item := G.mesh(self, builder.commit(), Vector3.ZERO, color)
	item.material_override = Materials.paint(color, 0.3)
	item.name = part_name
	return item

func add_triangle(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, centre: Vector3) -> void:
	var outward := (a + b + c) / 3.0 - centre
	if (b - a).cross(c - a).dot(outward) > 0.0:
		var swap := b
		b = c
		c = swap
	builder.add_vertex(a)
	builder.add_vertex(b)
	builder.add_vertex(c)

func body() -> void:
	# Cofano basso e fiancate fino alla linea di cintura; il muso scende e si arrotonda.
	loft([
		[-1.86, 0.66, 0.40, 0.60, 0.10, 0.0],
		[-1.80, 0.72, 0.38, 0.69, 0.12, 0.0],
		[-1.45, 0.76, 0.36, 0.78, 0.13, 0.0],
		[-0.95, 0.76, 0.36, 0.93, 0.12, 0.0],
		[0.15, 0.76, 0.36, 0.95, 0.09, 0.0]], red, "Carrozzeria")

func greenhouse() -> void:
	loft([
		[-0.92, 0.69, 0.90, 0.95, 0.05, 0.04],
		[-0.68, 0.69, 0.90, 1.22, 0.07, 0.05],
		[-0.40, 0.69, 0.90, 1.47, 0.09, 0.06],
		[0.14, 0.69, 0.90, 1.50, 0.10, 0.06]], red, "Abitacolo")
	var tilt := Vector3(0, 0.84, -0.54) * 0.03
	var screen := VehicleMesh.quad(self, Vector3(-0.62, 0.98, -0.88), Vector3(0.62, 0.98, -0.88), Vector3(0.58, 1.43, -0.38), Vector3(-0.58, 1.43, -0.38), Color("26373d"), "Parabrezza")
	screen.position = tilt
	screen.material_override = window
	# Fascia nera in cima al parabrezza e tergicristalli.
	var cowl := G.box(self, Vector3(0, 1.485, -0.36), Vector3(1.2, 0.045, 0.1), black)
	cowl.name = "FasciaParabrezza"
	cowl.rotation.x = 0.12
	for x in [-0.3, 0.2]:
		var wiper := G.box(self, Vector3(x, 1.04, -0.8), Vector3(0.012, 0.012, 0.5), black)
		wiper.name = "Tergicristallo"
		wiper.rotation = Vector3(-0.8, 0.0, 0.0)
		wiper.position = Vector3(x, 1.09, -0.73) + tilt * 1.2
	for side in [-1.0, 1.0]:
		var glass := VehicleMesh.side(self, PackedVector2Array([Vector2(-0.82, 1.02), Vector2(-0.46, 1.42), Vector2(0.06, 1.46), Vector2(0.06, 1.02)]), side * 0.699, Color("26373d"), "FinestrinoPorta")
		glass.material_override = window
		G.box(self, Vector3(side * 0.70, 1.24, 0.065), Vector3(0.02, 0.5, 0.05), black).name = "MontanteCentrale"
		G.box(self, Vector3(side * 0.70, 1.01, -0.38), Vector3(0.02, 0.025, 0.9), black).name = "GuarnizioneFinestrino"
		G.box(self, Vector3(side * 0.84, 1.14, -0.80), Vector3(0.09, 0.13, 0.15), black).name = "Specchietto"
		G.box(self, Vector3(side * 0.77, 1.07, -0.78), Vector3(0.14, 0.03, 0.03), black).name = "BraccioSpecchietto"

func cargo_box() -> void:
	var box := VehicleMesh.rounded_box(self, Vector3(0, 1.08, 0.99), Vector3(1.54, 1.36, 1.84), 0.15, red, "Cassa")
	box.material_override = Materials.paint(red, 0.3)
	for z in [0.55, 1.4]:
		for side in [-1.0, 1.0]:
			G.box(self, Vector3(side * 0.775, 0.98, z), Vector3(0.012, 0.42, 0.66), dark_red).name = "PannelloLaterale"
	for z in [0.5, 1.0, 1.5]:
		G.box(self, Vector3(0, 1.762, z), Vector3(1.0, 0.014, 0.34), dark_red).name = "RilievoTetto"
	for side in [-1.0, 1.0]:
		var glass := VehicleMesh.side(self, PackedVector2Array([Vector2(0.45, 1.38), Vector2(1.05, 1.38), Vector2(1.05, 1.64), Vector2(0.45, 1.64)]), side * 0.775, Color("26373d"), "FinestrinoCassa")
		glass.material_override = window
		G.box(self, Vector3(side * 0.77, 1.51, 0.75), Vector3(0.02, 0.3, 0.64), black).name = "CornicineFinestrino"
	for x in [-0.36, 0.36]:
		G.box(self, Vector3(x, 1.38, 1.912), Vector3(0.6, 0.58, 0.01), black).name = "CornicePosteriore"
		var rear_glass := VehicleMesh.quad(self, Vector3(x - 0.27, 1.12, 1.92), Vector3(x + 0.27, 1.12, 1.92), Vector3(x + 0.27, 1.64, 1.92), Vector3(x - 0.27, 1.64, 1.92), Color("26373d"), "LunottoPosteriore")
		rear_glass.material_override = window
	G.box(self, Vector3(0, 1.08, 1.915), Vector3(0.012, 1.1, 0.02), black).name = "FessuraPorte"
	G.box(self, Vector3(0.06, 0.86, 1.925), Vector3(0.12, 0.03, 0.03), black).name = "Maniglia"
	for side in [-1.0, 1.0]:
		var text := G.label(self, "GINO · FRUTTA", Vector3(side * 0.782, 0.9, 1.05), 28)
		text.rotation.y = side * PI / 2.0
		text.pixel_size = 0.0034
		text.modulate = Color("f6efd8")
		text.outline_size = 0

func trim() -> void:
	for side in [-1.0, 1.0]:
		var sill := VehicleMesh.rounded_box(self, Vector3(side * 0.765, 0.46, -0.4), Vector3(0.03, 0.1, 0.95), 0.012, black, "Sottoporta")
		sill.material_override = Materials.plastic(black, 0.7)
		for axle in AXLES:
			var arch := G.cylinder(self, Vector3(side * 0.752, WHEEL_RADIUS, axle), 0.385, 0.03, black)
			arch.rotation.z = PI / 2.0
			(arch.mesh as CylinderMesh).radial_segments = 36
			arch.material_override = Materials.plastic(Color("141719"), 0.9)
		for z in [-0.86, 0.04]:
			G.box(self, Vector3(side * 0.763, 0.66, z), Vector3(0.008, 0.5, 0.012), black).name = "LineaPorta"
		G.box(self, Vector3(side * 0.77, 0.9, -0.12), Vector3(0.02, 0.025, 0.12), black).name = "ManigliaPorta"
	var front := VehicleMesh.rounded_box(self, Vector3(0, 0.45, -1.84), Vector3(1.56, 0.2, 0.16), 0.06, black, "ParaurtiAnteriore")
	front.material_override = Materials.plastic(black, 0.65)
	var rear := VehicleMesh.rounded_box(self, Vector3(0, 0.5, 1.9), Vector3(1.58, 0.24, 0.16), 0.06, black, "ParaurtiPosteriore")
	rear.material_override = Materials.plastic(black, 0.65)
	G.box(self, Vector3(0, 0.45, -1.925), Vector3(0.5, 0.11, 0.015), Color("f1efdb")).name = "TargaAnteriore"
	var plate := G.box(self, Vector3(0, 0.55, 1.985), Vector3(0.5, 0.11, 0.015), Color("f1efdb"))
	plate.name = "Targa"
	var text := G.label(self, "GINO", Vector3(0, 0.55, 1.995), 22)
	text.pixel_size = 0.0028
	text.modulate = black
	text.outline_size = 0

func underbody() -> void:
	G.box(self, Vector3(0, 0.33, 0.0), Vector3(1.3, 0.12, 3.5), Color("15181a")).name = "Sottoscocca"
	var exhaust := G.cylinder(self, Vector3(-0.5, 0.29, 1.9), 0.04, 0.16, Color("737a7d"))
	exhaust.rotation.x = PI / 2.0
	exhaust.name = "Scarico"

func lights() -> void:
	G.box(self, Vector3(0, 0.66, -1.835), Vector3(0.84, 0.15, 0.04), Color("141719")).name = "Calandra"
	for i in 5:
		G.box(self, Vector3(-0.08 + i * 0.04, 0.66, -1.858), Vector3(0.012, 0.13, 0.012), Color("c9ccc8"))
	for side in [-1.0, 1.0]:
		G.box(self, Vector3(side * 0.58, 0.675, -1.83), Vector3(0.34, 0.17, 0.05), black).name = "CorniceFaro"
		var lamp := G.box(self, Vector3(side * 0.575, 0.675, -1.856), Vector3(0.3, 0.13, 0.02), Color("f7f1da"))
		lamp.name = "Faro"
		lamp.material_override = headlight_material
		var indicator := G.box(self, Vector3(side * 0.735, 0.67, -1.82), Vector3(0.08, 0.13, 0.06), Color("e8921b"))
		indicator.material_override = Materials.glow(Color("e8921b"), 0.25)
		var tail := G.box(self, Vector3(side * 0.74, 0.88, 1.915), Vector3(0.1, 0.34, 0.04), Color("a31212"))
		tail.name = "FanaleRosso"
		tail.material_override = brake_material
		G.box(self, Vector3(side * 0.74, 0.7, 1.915), Vector3(0.1, 0.08, 0.04), Color("e8e4d4")).name = "Retromarcia"

func cab_interior() -> void:
	G.box(self, Vector3(0, 1.02, -0.55), Vector3(1.3, 0.1, 0.35), Color("2a2f33")).name = "Cruscotto"
	var steering := G.cylinder(self, Vector3(-0.35, 1.08, -0.42), 0.17, 0.02, Color("15181a"))
	steering.rotation.x = 1.0
	for x in [-0.35, 0.35]:
		G.box(self, Vector3(x, 0.92, -0.05), Vector3(0.42, 0.14, 0.4), Color("353b40")).name = "Sedile"
		G.box(self, Vector3(x, 1.12, 0.04), Vector3(0.42, 0.42, 0.1), Color("353b40")).name = "Schienale"

func wheel(pos: Vector3, side: float) -> void:
	var pivot := Node3D.new()
	pivot.position = pos
	add_child(pivot)
	var tyre := G.cylinder(pivot, Vector3.ZERO, WHEEL_RADIUS, 0.21, Color("1b1d1f"))
	tyre.rotation.z = PI / 2.0
	tyre.material_override = Materials.plastic(Color("1b1d1f"), 0.85)
	(tyre.mesh as CylinderMesh).radial_segments = 32
	var rim := G.cylinder(pivot, Vector3(side * 0.1, 0, 0), 0.205, 0.03, Color("c3c9c9"))
	rim.rotation.z = PI / 2.0
	rim.material_override = Materials.metal(Color("c3c9c9"), 0.3)
	(rim.mesh as CylinderMesh).radial_segments = 28
	var cap := G.cylinder(pivot, Vector3(side * 0.12, 0, 0), 0.075, 0.02, Color("e4e8e8"))
	cap.rotation.z = PI / 2.0
	cap.material_override = Materials.metal(Color("e4e8e8"), 0.2)
	for i in 6:
		var angle := TAU * i / 6.0
		var spoke := G.box(pivot, Vector3(side * 0.118, cos(angle) * 0.13, sin(angle) * 0.13), Vector3(0.012, 0.04, 0.04), Color("8d9597"))
		spoke.rotation.x = angle
	wheels.append(pivot)

## Cassette di frutta sul tetto: Gino è un fruttivendolo.
func fruit_crates() -> void:
	var colors := [Color("d8402a"), Color("f08a1c"), Color("7cb342"), Color("f2c230")]
	var wood := Materials.plastic(Color("b58a55"), 0.8)
	for i in 3:
		var crate := Node3D.new()
		crate.position = Vector3(0, 1.77, 0.45 + i * 0.52)
		add_child(crate)
		G.box(crate, Vector3(0, 0.03, 0), Vector3(0.96, 0.06, 0.44), Color("b58a55")).material_override = wood
		for side_x in [-0.47, 0.47]:
			G.box(crate, Vector3(side_x, 0.11, 0), Vector3(0.03, 0.16, 0.44), Color("b58a55")).material_override = wood
		for side_z in [-0.21, 0.21]:
			G.box(crate, Vector3(0, 0.11, side_z), Vector3(0.96, 0.16, 0.03), Color("b58a55")).material_override = wood
		for j in 8:
			G.sphere(crate, Vector3(-0.33 + (j % 4) * 0.22, 0.2, -0.1 + (j / 4) * 0.2), 0.1, colors[(i + j) % 4])

## Giro delle ruote. La capriola (stordimento) la applica il nodo che contiene Gino, ruotandolo su X.
func animate(speed: float, delta: float) -> void:
	for pivot in wheels:
		pivot.rotation.x -= speed / WHEEL_RADIUS * delta
