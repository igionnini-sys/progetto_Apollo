extends RefCounted
## Portelloni lastrati H2 e ottiche X250, ricostruiti da riferimenti posteriori 2010.
const G = preload("res://scripts/utilities/geometry.gd")
const M = preload("res://scripts/vehicles/vehicle_mesh.gd")
const R = preload("res://scripts/vehicles/realistic_ducato.gd")
const F = preload("res://scripts/vehicles/ducato_x250_front.gd")
const Materials = preload("res://scripts/utilities/materials.gd")

static func assign(item: MeshInstance3D, material: Material) -> MeshInstance3D:
	return F.assign(item, material)

static func door_width(y: float) -> float:
	return 0.873 - 0.049 * smoothstep(1.80, 2.405, y)

static func depth(x: float, y: float) -> float:
	var z := 2.611 - 0.012 * pow(x / 0.89, 2.0)
	z -= 0.067 * smoothstep(2.30, 2.43, y)
	# Nervature orizzontali del pannello H2 e cintura stampata sotto la maniglia.
	z -= 0.007 * exp(-pow((y - 2.105) / 0.006, 2.0))
	z += 0.005 * (smoothstep(2.045, 2.055, y) - smoothstep(2.095, 2.105, y))
	z += 0.012 * (smoothstep(1.075, 1.12, y) - smoothstep(1.335, 1.36, y))
	# La targa appartiene alla porta sinistra: incavo nella lamiera, non una seconda piastra.
	var q := Vector2(x + 0.435, y - 0.895)
	var d := F.rounded_distance(q, Vector2(0.32, 0.112), 0.025)
	z -= 0.030 * (1.0 - smoothstep(-0.012, 0.008, d))
	return z

static func point(p: Vector2, offset: float = 0.0) -> Vector3:
	return Vector3(p.x, p.y, depth(p.x, p.y) + offset)

static func normal(p: Vector2) -> Vector3:
	var dx := point(p + Vector2(0.0001, 0)) - point(p - Vector2(0.0001, 0))
	var dy := point(p + Vector2(0, 0.0001)) - point(p - Vector2(0, 0.0001))
	return dx.cross(dy).normalized()

static func face(parent: Node3D, contour: PackedVector2Array, offset: float, material: Material, name: String) -> MeshInstance3D:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var indices := Geometry2D.triangulate_polygon(contour)
	for i in range(0, indices.size(), 3):
		var poly: Array = []
		for j in 3:
			var p := contour[indices[i + j]]
			poly.append([point(p, offset), normal(p)])
		R.emit(builder, poly)
	var item := G.mesh(parent, builder.commit(), Vector3.ZERO, Color.WHITE)
	item.name = name
	return assign(item, material)

static func doors(visual: Node3D) -> void:
	var paint := R.material("varnish")
	var black := Materials.plastic(Color("171c20"), 0.85)
	# Fondo dei giochi porta, dietro entrambe le ante: nessun giunto dipinto sulla lamiera.
	var opening: Array = []
	for j in 81:
		var y := lerpf(0.533, 2.400, float(j) / 80.0)
		opening.append(PackedVector3Array([point(Vector2(-door_width(y) - 0.004, y), -0.060), point(Vector2(door_width(y) + 0.004, y), -0.060)]))
	assign(M.panel(visual, opening, Color.WHITE, "FondoVanoPortelloni", Vector3.BACK), black)
	for side: float in [-1.0, 1.0]:
		var rows: Array = []
		# Campionatura fitta per nervature e invaso targa; raccordo continuo sul tetto.
		for j in 381:
			var y := lerpf(0.537, 2.396, float(j) / 380.0)
			var row := PackedVector3Array()
			for i in 121:
				var x := side * lerpf(0.003, door_width(y), float(i) / 120.0)
				row.append(point(Vector2(x, y)))
			rows.append(row)
		assign(M.panel(visual, rows, visual.white, "PortelloneSinistroX250" if side < 0 else "PortelloneDestroX250", Vector3.BACK), paint)
		# Risvolti sui bordi, spessore reale dei portelloni.
		var edges: Array = []
		for offset in [-0.035, 0.0]:
			var row := PackedVector3Array()
			for i in 121:
				var y := lerpf(0.537, 2.396, float(i) / 120.0)
				row.append(point(Vector2(side * door_width(y), y), offset))
			edges.append(row)
		assign(M.panel(visual, edges, visual.white, "RisvoltoPortellone", Vector3.RIGHT * side), paint)
		var center_edge: Array = []
		for offset in [-0.035, 0.0]:
			var row := PackedVector3Array()
			for i in 121:
				row.append(point(Vector2(side * 0.003, lerpf(0.537, 2.396, float(i) / 120.0)), offset))
			center_edge.append(row)
		assign(M.panel(visual, center_edge, visual.white, "BattutaCentralePortellone", Vector3.LEFT * side), paint)
		# Fasce nere inferiori indipendenti, separate dal gioco centrale.
		var lower_rows: Array = []
		for y in [0.538, 0.544, 0.754, 0.760]:
			var row := PackedVector3Array()
			for i in 49:
				var x := side * lerpf(0.007, door_width(y) - 0.005, float(i) / 48.0)
				row.append(point(Vector2(x, y), 0.002))
			lower_rows.append(row)
		assign(M.panel(visual, lower_rows, Color.WHITE, "ProtezioneInferiorePortellone", Vector3.BACK), R.material("black_plastic"))
		# Il montante rastremato chiude il taglio della base H1 senza coprire il gioco porta.
		for limits: Vector2 in [Vector2(0.535, 0.86), Vector2(0.86, 2.412)]:
			var surround_rows: Array = []
			for j in 81:
				var y := lerpf(limits.x, limits.y, float(j) / 80.0)
				var outer_z := 2.572 - 0.068 * smoothstep(2.05, 2.32, y)
				surround_rows.append(PackedVector3Array([point(Vector2(side * (door_width(y) + 0.005), y), -0.012), Vector3(side * 0.907, y, outer_z)]))
			assign(M.panel(visual, surround_rows, visual.white, "MontantePosterioreH2", Vector3.BACK), R.material("black_plastic") if limits.x < 0.8 else paint)
	var lintel: Array = []
	for y in [2.400, 2.412]:
		var row := PackedVector3Array()
		for i in 81:
			row.append(point(Vector2(lerpf(-0.88, 0.88, float(i) / 80.0), y), -0.006))
		lintel.append(row)
	assign(M.panel(visual, lintel, visual.white, "CorniceSuperiorePortelloni", Vector3.BACK), paint)
	var seal: Array = []
	for y in [2.396, 2.400]:
		var row := PackedVector3Array()
		for i in 81:
			row.append(point(Vector2(lerpf(-0.825, 0.825, float(i) / 80.0), y), 0.001))
		seal.append(row)
	assign(M.panel(visual, seal, Color.WHITE, "GuarnizioneSuperiorePortelloni", Vector3.BACK), black)

static func raised(visual: Node3D, center: Vector2, size: Vector2, height: float, material: Material, name: String) -> void:
	var contour := F.rect(center, size, 0.40)
	var rows: Array = []
	for j in 9:
		var t := float(j) / 8.0
		var row := PackedVector3Array()
		for i in contour.size() + 1:
			var p := center.lerp(contour[i % contour.size()], lerpf(1.0, 0.76, sin(t * PI * 0.5)))
			row.append(point(p, 0.003 + height * sin(t * PI * 0.5)))
		rows.append(row)
	assign(M.panel(visual, rows, Color.WHITE, name, Vector3.BACK), material)
	var inner := PackedVector2Array()
	for p in contour:
		inner.append(center.lerp(p, 0.76))
	face(visual, inner, height + 0.003, material, name + "Centro")

static func plate_and_handle(visual: Node3D) -> void:
	var black := R.material("black_plastic")
	var c := Vector2(-0.435, 0.895)
	var plate_center := point(c)
	assign(M.rounded_box(visual, point(c, 0.006), Vector3(0.537, 0.125, 0.009), 0.006, Color.WHITE, "PortatargaPosterioreIncassato"), black)
	assign(M.rounded_box(visual, point(c, 0.012), Vector3(0.520, 0.110, 0.004), 0.003, Color.WHITE, "TargaPosteriore"), Materials.plastic(Color("e7e9e3"), 0.38))
	for side: float in [-1.0, 1.0]:
		assign(G.box(visual, plate_center + Vector3(side * 0.244, 0, 0.015), Vector3(0.029, 0.103, 0.002), Color.WHITE), Materials.plastic(Color("174b8c"), 0.45))
		assign(G.sphere(visual, plate_center + Vector3(side * 0.212, 0.039, 0.018), 0.0026, Color.WHITE), Materials.metal(Color("aab1b5"), 0.35))
	var lettering := G.label(visual, "APOLLO", point(c, 0.018), 40)
	lettering.pixel_size = 0.0014
	lettering.outline_size = 0
	lettering.modulate = Color("20252a")
	# Modanatura luci targa sopra la sede, larga come nell'originale.
	assign(M.rounded_box(visual, point(Vector2(-0.435, 1.015), 0.020), Vector3(0.69, 0.045, 0.048), 0.009, Color.WHITE, "ModanaturaLuciTarga"), black)
	for x in [-0.66, -0.21]:
		assign(M.rounded_box(visual, point(Vector2(x, 0.994), 0.022), Vector3(0.062, 0.008, 0.022), 0.002, Color.WHITE, "LuceTarga"), Materials.plastic(Color("cad0c9"), 0.35))
	var h := Vector2(0.195, 1.245)
	raised(visual, h, Vector2(0.129, 0.207), 0.024, Materials.plastic(Color("10171b"), 0.77), "GuarnizioneManigliaPosteriore")
	raised(visual, h + Vector2(0.008, 0), Vector2(0.091, 0.167), 0.047, Materials.plastic(Color("232b30"), 0.57), "ManigliaPosterioreX250")
	assign(M.rounded_box(visual, point(h + Vector2(-0.023, 0.005), 0.051), Vector3(0.017, 0.105, 0.010), 0.004, Color.WHITE, "IncavoPresaManiglia"), Materials.plastic(Color("0c1216"), 0.8))
	var lock := G.cylinder(visual, point(h + Vector2(0.010, -0.066), 0.057), 0.008, 0.003, Color.WHITE)
	lock.rotation.x = PI / 2.0
	assign(lock, Materials.metal(Color("767f85"), 0.34))

static func badges(visual: Node3D) -> void:
	var p := point(Vector2(-0.435, 1.245), 0.010)
	var chrome := Materials.metal(Color("c6cccd"), 0.20)
	var rim := G.cylinder(visual, p, 0.047, 0.008, Color.WHITE)
	rim.rotation.x = PI / 2.0
	(rim.mesh as CylinderMesh).radial_segments = 64
	assign(rim, chrome)
	var enamel := G.cylinder(visual, p + Vector3.BACK * 0.006, 0.040, 0.006, Color.WHITE)
	enamel.rotation.x = PI / 2.0
	(enamel.mesh as CylinderMesh).radial_segments = 64
	assign(enamel, Materials.paint(Color("8f1627"), 0.22))
	var fiat := G.label(visual, "FIAT", p + Vector3.BACK * 0.011, 42)
	fiat.pixel_size = 0.00065
	fiat.outline_size = 0
	# Lettere metalliche sul portellone destro, senza fondino o adesivo.
	var badge := G.label(visual, "DUCATO", point(Vector2(0.59, 1.245), 0.012), 48)
	badge.name = "ScrittaDucatoPosteriore"
	badge.pixel_size = 0.0015
	badge.outline_size = 0
	badge.no_depth_test = false
	badge.modulate = Color("a7b0b3")
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Arial"])
	font.font_italic = true
	font.font_weight = 700
	badge.font = font
	# Perno e viti delle due cerniere superiori mantenute dalla base.
	for side: float in [-1.0, 1.0]:
		assign(M.rounded_box(visual, Vector3(side * 0.884, 2.003, 2.583), Vector3(0.052, 0.091, 0.024), 0.008, Color.WHITE, "PiastraCernieraPosteriore"), R.material("varnish"))
		var pin := G.cylinder(visual, Vector3(side * 0.907, 2.003, 2.588), 0.009, 0.082, Color.WHITE)
		assign(pin, R.material("varnish"))
		for y in [1.976, 2.031]:
			var bolt := G.cylinder(visual, Vector3(side * 0.902, y, 2.584), 0.007, 0.004, Color.WHITE)
			bolt.rotation.x = PI / 2.0
			assign(bolt, Materials.metal(Color("9aa5a7"), 0.43))

static func lamp_z(x: float) -> float:
	return 2.613 - 0.085 * smoothstep(0.885, 1.025, absf(x))

static func lens_surface(visual: Node3D, contour: PackedVector2Array, material: Material, name: String, offset: float = 0.0) -> void:
	var center := Vector2.ZERO
	for p in contour:
		center += p
	center /= contour.size()
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in contour.size():
		var poly: Array = []
		for p: Vector2 in [center, contour[i], contour[(i + 1) % contour.size()]]:
			var z := lamp_z(p.x) + offset
			var slope := (lamp_z(p.x + 0.0001) - lamp_z(p.x - 0.0001)) / 0.0002
			poly.append([Vector3(p.x, p.y, z), Vector3(-slope, 0, 1).normalized()])
		R.emit(builder, poly)
	var item := G.mesh(visual, builder.commit(), Vector3.ZERO, Color.WHITE)
	item.name = name
	assign(item, material)

static func lamps(visual: Node3D) -> void:
	var clear := StandardMaterial3D.new()
	clear.albedo_color = Color(0.90, 0.95, 0.96, 0.18)
	clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	clear.roughness = 0.13
	clear.cull_mode = BaseMaterial3D.CULL_DISABLED
	var red := Materials.plastic(Color("9e1823"), 0.23)
	var reflector := Materials.metal(Color("c2c9cb"), 0.22)
	for side: float in [-1.0, 1.0]:
		var outer := F.outline(PackedVector2Array([Vector2(0.881, 0.876), Vector2(1.009, 0.884), Vector2(1.007, 1.428), Vector2(0.885, 1.451)]), 0.06)
		var contour := PackedVector2Array()
		for p in outer:
			contour.append(Vector2(side * p.x, p.y))
		lens_surface(visual, contour, Materials.plastic(Color("22272a"), 0.65), "GuarnizioneFanalePosteriore", -0.008)
		lens_surface(visual, contour, red, "CorpoRossoFanaleX250")
		var wall_rows: Array = []
		for offset in [-0.035, 0.0]:
			var row := PackedVector3Array()
			for i in contour.size() + 1:
				var p := contour[i % contour.size()]
				row.append(Vector3(p.x, p.y, lamp_z(p.x) + offset))
			wall_rows.append(row)
		assign(M.panel(visual, wall_rows, Color.WHITE, "RaccordoLateraleFanale", Vector3.BACK), red)
		# Tre settori: rosso superiore, zona trasparente centrale con due riflettori, rosso basso.
		for spec: Vector3 in [Vector3(1.370, 0.133, 1), Vector3(0.935, 0.096, 0)]:
			var segment := F.rect(Vector2(side * 0.944, spec.x), Vector2(0.112, spec.y), 0.08)
			lens_surface(visual, segment, visual.brake_material if spec.z > 0 else red, "StopPosterioreX250" if spec.z > 0 else "CatadiottroFanale", 0.004)
		var window := F.rect(Vector2(side * 0.944, 1.140), Vector2(0.113, 0.292), 0.08)
		lens_surface(visual, window, Materials.plastic(Color("414b50"), 0.4), "FondoOtticaTrasparente", 0.002)
		for y in [1.074, 1.217]:
			var p := Vector3(side * 0.944, y, lamp_z(side * 0.944) + 0.005)
			var normal_out := Vector3(side * 0.55, 0, 1).normalized()
			var bowl := M.lathe(visual, PackedVector2Array([Vector2(0.0, 0.048), Vector2(-0.004, 0.044), Vector2(-0.014, 0.030), Vector2(-0.022, 0.010)]), Color.WHITE, "RiflettorePosteriore", 48)
			bowl.position = p
			bowl.quaternion = Quaternion(Vector3.RIGHT, normal_out)
			assign(bowl, reflector)
			assign(G.sphere(visual, p - normal_out * 0.010, 0.007, Color.WHITE), Materials.plastic(Color("d5a15c"), 0.26) if y > 1.15 else reflector)
		lens_surface(visual, window, clear, "LenteTrasparenteFanaleX250", 0.016)
		# Prismi sottili sulla lente: rifrazione leggibile anche con le luci spente.
		for j in 25:
			var y := 0.894 + j * 0.022
			var in_window := y > 0.995 and y < 1.29
			var prism := F.rect(Vector2(side * 0.944, y), Vector2(0.107, 0.0010), 0.04)
			lens_surface(visual, prism, Materials.plastic(Color("66777e"), 0.23) if in_window else Materials.plastic(Color("ad2933"), 0.23), "PrismaFanalePosteriore", 0.018)
	# Terzo stop alla sommità, rosso anche da spento.
	assign(M.rounded_box(visual, Vector3(0, 2.437, 2.548), Vector3(0.226, 0.043, 0.019), 0.009, Color.WHITE, "TerzoStopX250"), visual.brake_material)
	for i in 11:
		assign(G.box(visual, Vector3(-0.096 + i * 0.0192, 2.437, 2.559), Vector3(0.002, 0.031, 0.002), Color.WHITE), red)

static func build(visual: Node3D) -> void:
	doors(visual)
	plate_and_handle(visual)
	badges(visual)
	lamps(visual)
