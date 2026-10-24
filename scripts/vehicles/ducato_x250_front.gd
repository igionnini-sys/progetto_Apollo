extends RefCounted
## X250: lamiera aperta sulle ottiche, fascia verniciata, calandra e paraurti scolpiti.
const G = preload("res://scripts/utilities/geometry.gd")
const M = preload("res://scripts/vehicles/vehicle_mesh.gd")
const R = preload("res://scripts/vehicles/realistic_ducato.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
# Sezioni (quota Y, semilarghezza X, profondita Z), in metri.
const PROFILE = [Vector3(0.28, 0.91, -2.55), Vector3(0.34, 0.985, -2.66), Vector3(0.45, 1.015, -2.70), Vector3(0.60, 1.025, -2.70), Vector3(0.78, 1.025, -2.65), Vector3(1.0, 1.02, -2.61), Vector3(1.205, 1.008, -2.595)]
static var hood_mesh: ArrayMesh

static func assign(item: MeshInstance3D, material: Material) -> MeshInstance3D:
	item.material_override = material
	item.set_meta("realistic_material", true)
	return item

static func outline(corners: PackedVector2Array, rounding: float = 0.14) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in corners.size():
		var p := corners[i]
		var a := p.lerp(corners[posmod(i - 1, corners.size())], rounding)
		var b := p.lerp(corners[(i + 1) % corners.size()], rounding)
		for j in 9:
			var t := float(j) / 8.0
			result.append(a.lerp(p, t).lerp(p.lerp(b, t), t))
	return result

static func rect(center: Vector2, size: Vector2, rounding: float = 0.14) -> PackedVector2Array:
	var h := size * 0.5
	return outline(PackedVector2Array([center - h, center + Vector2(h.x, -h.y), center + h, center + Vector2(-h.x, h.y)]), rounding)

static func turn_at(u: float) -> float:
	return pow(1.0 - sqrt(maxf(0.0, 1.0 - u * u)), 3.0)

static func hood_point(uv: Vector2) -> Vector3:
	var u := uv.x
	var t := uv.y
	var front_y := 1.205 + (1.0 - u * u) * 0.006 - pow(turn_at(u), 1.5) * 0.29
	var y := lerpf(front_y, 1.555 + (1.0 - u * u) * 0.015, t) + sin(t * PI) * 0.025
	y += exp(-pow((absf(u) - lerpf(0.59, 0.81, t)) / 0.09, 2.0)) * sin(t * PI) * 0.010
	return Vector3(u * 1.008, y, lerpf(-2.595 + 0.48 * turn_at(u), -2.115, t))

static func hood_normal(uv: Vector2) -> Vector3:
	var dx := hood_point(uv + Vector2(0.0002, 0)) - hood_point(uv - Vector2(0.0002, 0))
	var dy := hood_point(uv + Vector2(0, 0.0002)) - hood_point(uv - Vector2(0, 0.0002))
	var normal := dx.cross(dy).normalized()
	return normal if normal.y > 0.0 else -normal

static func optic_uv(p: Vector2, side: float) -> Vector2:
	return Vector2(side * (lerpf(0.83, 0.79, p.y) + p.x), p.y)

static func optic_point(p: Vector2, side: float, depth: float) -> Vector3:
	var uv := optic_uv(p, side)
	return hood_point(uv) + hood_normal(uv) * depth

static func lamp_outline() -> PackedVector2Array:
	return outline(PackedVector2Array([Vector2(-0.17, 0.02), Vector2(0.169, 0.12), Vector2(0.13, 0.965), Vector2(-0.125, 0.98)]), 0.17)

static func half_plane(poly: PackedVector2Array, a: Vector2, b: Vector2, inside: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var dp := (b - a).cross(p - a)
		var dq := (b - a).cross(q - a)
		var ip := dp >= -0.0000001 if inside else dp <= 0.0000001
		var iq := dq >= -0.0000001 if inside else dq <= 0.0000001
		if ip:
			result.append(p)
		if ip != iq and absf(dp - dq) > 0.00000001:
			result.append(p.lerp(q, clampf(dp / (dp - dq), 0.0, 1.0)))
	return result

# Complemento disgiunto di un contorno convesso: i riflettori sono dentro la carrozzeria.
static func subtract(poly: PackedVector2Array, hole: PackedVector2Array) -> Array:
	var result: Array = []
	var remaining := poly
	for i in hole.size():
		var a := hole[i]
		var b := hole[(i + 1) % hole.size()]
		var outside := half_plane(remaining, a, b, false)
		if outside.size() >= 3:
			result.append(outside)
		remaining = half_plane(remaining, a, b, true)
		if remaining.size() < 3:
			break
	return result

static func build_hood(visual: Node3D) -> void:
	if hood_mesh == null:
		var holes: Array = []
		for side: float in [-1.0, 1.0]:
			var hole := PackedVector2Array()
			for p in lamp_outline():
				hole.append(optic_uv(p, side))
			if side < 0.0:
				hole.reverse()
			holes.append(hole)
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in 48:
			for i in 96:
				var uv := Vector2(float(i) / 48.0 - 1.0, float(j) / 48.0)
				var d := Vector2(1.0 / 48.0, 1.0 / 48.0)
				var fragments: Array = [PackedVector2Array([uv, uv + Vector2(d.x, 0), uv + d, uv + Vector2(0, d.y)])]
				for hole: PackedVector2Array in holes:
					if (uv.x < -0.55 and hole[0].x < 0.0) or (uv.x > 0.53 and hole[0].x > 0.0):
						var clipped: Array = []
						for fragment: PackedVector2Array in fragments:
							clipped.append_array(subtract(fragment, hole))
						fragments = clipped
				for fragment: PackedVector2Array in fragments:
					var poly: Array = []
					for p in fragment:
						poly.append([hood_point(p), hood_normal(p)])
					R.emit(builder, poly)
		hood_mesh = builder.commit()
	var item := G.mesh(visual, hood_mesh, Vector3.ZERO, visual.white)
	item.name = "CofanoX250"
	assign(item, R.material("varnish"))

static func profile(v: float) -> Vector3:
	var t := clampf(v, 0.0, 1.0) * (PROFILE.size() - 1)
	var k := mini(int(t), PROFILE.size() - 2)
	var p: Vector3 = PROFILE[k]
	var result := p.cubic_interpolate(PROFILE[k + 1], PROFILE[maxi(0, k - 1)], PROFILE[mini(PROFILE.size() - 1, k + 2)], t - k)
	result.y = minf(result.y, 1.025)
	result.z = maxf(result.z, -2.7065)
	return result

static func base_depth(x: float, y: float) -> float:
	var index := PROFILE.size() - 2
	for i in PROFILE.size() - 1:
		if y <= PROFILE[i + 1].x:
			index = i
			break
	var a: Vector3 = PROFILE[index]
	var b: Vector3 = PROFILE[index + 1]
	var t := clampf((y - a.x) / (b.x - a.x), 0.0, 1.0)
	return lerpf(lerpf(a.z, b.z, t), -2.115, turn_at(x / lerpf(a.y, b.y, t)))

static func rounded_distance(p: Vector2, half_size: Vector2, radius: float) -> float:
	var q := p.abs() - half_size + Vector2.ONE * radius
	return q.max(Vector2.ZERO).length() + minf(maxf(q.x, q.y), 0.0) - radius

static func cavities(p: Vector2) -> float:
	var grille := rounded_distance(Vector2(p.x, p.y - 0.878), Vector2(lerpf(0.555, 0.585, clampf((p.y - 0.71) / 0.345, 0, 1)), 0.173), 0.038)
	var fog := rounded_distance(Vector2(absf(p.x) - 0.82, p.y - 0.435), Vector2(0.14, 0.080), 0.03)
	var vent := rounded_distance(Vector2(absf(p.x) - 0.80, p.y - 0.735), Vector2(0.115, 0.038), 0.012)
	return (1.0 - smoothstep(-0.015, 0.025, grille)) * 0.080 + (1.0 - smoothstep(0.0, 0.02, fog)) * 0.035 + (1.0 - smoothstep(0.0, 0.015, vent)) * 0.022

static func bumper(visual: Node3D) -> void:
	var rows: Array = []
	for j in 73:
		var p := profile(float(j) / 72.0)
		var row := PackedVector3Array()
		for i in 129:
			var u := sin((float(i) / 64.0 - 1.0) * PI * 0.5)
			var turn := turn_at(u)
			var x := u * p.y
			var y := p.x + ((1.0 - u * u) * 0.006 - pow(turn, 1.5) * 0.29) * smoothstep(0.65, 1.205, p.x)
			var z := lerpf(p.z, -2.115, turn) + cavities(Vector2(x, y))
			z -= exp(-pow((y - 0.57) / 0.055, 2.0)) * smoothstep(0.70, 0.82, absf(x)) * 0.012
			row.append(Vector3(x, y, z))
		rows.append(row)
	var shell := M.panel(visual, rows, visual.trim, "ParaurtiAnteriore", Vector3.FORWARD)
	cut_fascia(shell)
	assign(shell, R.material("bumper"))
	for side: float in [-1.0, 1.0]:
		for i in 40:
			var y := lerpf(0.30, 1.20, float(i) / 40.0)
			var yy := lerpf(0.30, 1.20, float(i + 1) / 40.0)
			var x := side * lerpf(0.64, 0.70, smoothstep(0.30, 0.66, y))
			var xx := side * lerpf(0.64, 0.70, smoothstep(0.30, 0.66, yy))
			M.beam(visual, Vector3(x, y, base_depth(x, y) - 0.001), Vector3(xx, yy, base_depth(xx, yy) - 0.001), 0.0014, Color("2b2e30"))

static func face_frame(visual: Node3D, inner: PackedVector2Array, outer: PackedVector2Array, material: Material, name: String, recess: float) -> void:
	var rows: Array = []
	for j in 13:
		var t := float(j) / 12.0
		var row := PackedVector3Array()
		for i in inner.size() + 1:
			var p := inner[i % inner.size()].lerp(outer[i % outer.size()], t)
			var bevel := lerpf(recess, -0.004, smoothstep(0.0, 0.33, t)) - sin(t * PI) * 0.002
			row.append(Vector3(p.x, p.y, base_depth(p.x, p.y) + bevel))
		rows.append(row)
	assign(M.panel(visual, rows, Color.WHITE, name, Vector3.FORWARD), material)

static func fascia_outline() -> PackedVector2Array:
	return outline(PackedVector2Array([Vector2(-0.70, 0.657), Vector2(0.70, 0.657), Vector2(0.675, 1.207), Vector2(-0.675, 1.207)]), 0.035)

static func clip_surface(poly: Array, a: Vector2, b: Vector2, inside: bool) -> Array:
	var result: Array = []
	for i in poly.size():
		var p: Array = poly[i]
		var q: Array = poly[(i + 1) % poly.size()]
		var dp: float = (b - a).cross(Vector2(p[0].x, p[0].y) - a)
		var dq: float = (b - a).cross(Vector2(q[0].x, q[0].y) - a)
		var ip := dp >= -0.0000001 if inside else dp <= 0.0000001
		var iq := dq >= -0.0000001 if inside else dq <= 0.0000001
		if ip:
			result.append(p)
		if ip != iq and absf(dp - dq) > 0.00000001:
			var t := clampf(dp / (dp - dq), 0.0, 1.0)
			result.append([p[0].lerp(q[0], t), p[1].lerp(q[1], t).normalized()])
	return result

static func cut_fascia(shell: MeshInstance3D) -> void:
	var data := shell.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = data[Mesh.ARRAY_NORMAL]
	var hole := fascia_outline()
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, vertices.size(), 3):
		var remaining: Array = [[vertices[i], normals[i]], [vertices[i + 1], normals[i + 1]], [vertices[i + 2], normals[i + 2]]]
		if remaining.all(func(p: Array) -> bool: return absf(p[0].x) > 0.71 or p[0].y < 0.65):
			R.emit(builder, remaining)
			continue
		for j in hole.size():
			var a := hole[j]
			var b := hole[(j + 1) % hole.size()]
			var outside := clip_surface(remaining, a, b, false)
			if outside.size() >= 3:
				R.emit(builder, outside)
			remaining = clip_surface(remaining, a, b, true)
			if remaining.size() < 3:
				break
	shell.mesh = builder.commit()

static func face_fill(visual: Node3D, contour: PackedVector2Array, center: Vector2, depth: float, material: Material, name: String) -> void:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in contour.size():
		var poly: Array = []
		for p: Vector2 in [center, contour[i], contour[(i + 1) % contour.size()]]:
			poly.append([Vector3(p.x, p.y, base_depth(p.x, p.y) + depth), Vector3.FORWARD])
		R.emit(builder, poly)
	var mesh := G.mesh(visual, builder.commit(), Vector3.ZERO, Color.WHITE)
	mesh.name = name
	assign(mesh, material)

static func grille(visual: Node3D) -> void:
	var inner := outline(PackedVector2Array([Vector2(-0.555, 0.710), Vector2(0.555, 0.710), Vector2(0.585, 1.055), Vector2(-0.585, 1.055)]), 0.14)
	var outer := fascia_outline()
	face_frame(visual, inner, outer, R.material("varnish"), "CorniceVerniciataX250", 0.034)
	face_fill(visual, inner, Vector2(0, 0.878), 0.073, Materials.plastic(Color("101418"), 0.82), "CalandraX250")
	var slat_material := Materials.plastic(Color("353b3f"), 0.47)
	for j in 4:
		var y := 0.744 + j * 0.081
		var width := lerpf(1.062, 1.13, float(j) / 3.0)
		assign(M.rounded_box(visual, Vector3(0, y, base_depth(0, y) + 0.041), Vector3(width, 0.029, 0.045), 0.010, Color.WHITE, "LamellaCalandra"), slat_material)
	for i in 11:
		var x := -0.50 + i * 0.10
		var rows: Array = []
		for y in [0.725, 1.025]:
			rows.append(PackedVector3Array([Vector3(x - 0.003, y, base_depth(x, y) + 0.050), Vector3(x + 0.003, y, base_depth(x, y) + 0.050)]))
		assign(M.panel(visual, rows, Color.WHITE, "SupportoRadiatore", Vector3.FORWARD), Materials.plastic(Color("202629"), 0.7))
	face_fill(visual, rect(Vector2(0, 0.625), Vector2(1.06, 0.053), 0.12), Vector2(0, 0.625), -0.003, Materials.plastic(Color("101517"), 0.8), "PresaAriaInferiore")
	for i in 13:
		var x := -0.48 + i * 0.08
		assign(M.rounded_box(visual, Vector3(x, 0.625, base_depth(x, 0.625) - 0.008), Vector3(0.008, 0.045, 0.016), 0.003, Color.WHITE), slat_material)
	var p := Vector3(0, 0.868, base_depth(0, 0.868) - 0.012)
	var rim := G.cylinder(visual, p, 0.070, 0.012, Color.WHITE)
	rim.rotation.x = PI / 2.0
	(rim.mesh as CylinderMesh).radial_segments = 64
	assign(rim, Materials.metal(Color("c7ced0"), 0.18))
	var enamel := G.cylinder(visual, p + Vector3.FORWARD * 0.008, 0.061, 0.009, Color.WHITE)
	enamel.rotation.x = PI / 2.0
	(enamel.mesh as CylinderMesh).radial_segments = 64
	assign(enamel, Materials.paint(Color("8e1825"), 0.24))
	var text := G.label(visual, "FIAT", p + Vector3.FORWARD * 0.015, 36)
	text.pixel_size = 0.0010
	text.outline_size = 0
	text.rotation.y = PI

static func optic_surface(visual: Node3D, contour: PackedVector2Array, side: float, depth: float, material: Material, name: String, bow: float = 0.0) -> void:
	var center := Vector2(-0.005, 0.51)
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 10:
		var r0 := float(ring) / 10.0
		var r1 := float(ring + 1) / 10.0
		for i in contour.size():
			var a := contour[i]
			var b := contour[(i + 1) % contour.size()]
			for triangle in [[Vector2(0, r0), Vector2(0, r1), Vector2(1, r1)], [Vector2(0, r0), Vector2(1, r1), Vector2(1, r0)]]:
				var poly: Array = []
				for vertex: Vector2 in triangle:
					var p := center.lerp(a.lerp(b, vertex.x), vertex.y)
					poly.append([optic_point(p, side, depth + bow * (1.0 - vertex.y * vertex.y)), hood_normal(optic_uv(p, side))])
				R.emit(builder, poly)
	var mesh := G.mesh(visual, builder.commit(), Vector3.ZERO, Color.WHITE)
	mesh.name = name
	assign(mesh, material)

static func reflector(visual: Node3D, parameter: Vector2, radius: float, side: float, primary: bool) -> Vector3:
	var location := hood_point(optic_uv(parameter, side)) + Vector3.BACK * (0.145 if primary else 0.105)
	var normal := Vector3(side * 0.10, 0.025, -1.0).normalized()
	var profile_points := PackedVector2Array([Vector2(0, radius), Vector2(-0.003, radius * 0.97), Vector2(-0.010, radius * 0.84), Vector2(-0.023, radius * 0.62), Vector2(-0.036, radius * 0.34), Vector2(-0.043, 0.005)])
	var bowl := M.lathe(visual, profile_points, Color.WHITE, "RiflettoreParabolico", 64)
	bowl.position = location
	bowl.quaternion = Quaternion(Vector3.RIGHT, normal)
	assign(bowl, visual.reflector_material if primary else Materials.metal(Color("b4bdc2"), 0.18))
	var flange_profile := PackedVector2Array([Vector2(-0.045, radius + 0.022), Vector2(-0.030, radius + 0.021), Vector2(-0.009, radius + 0.012), Vector2(0.001, radius + 0.002)])
	var flange := M.lathe(visual, flange_profile, Color.WHITE, "FlangiaRiflettore", 64)
	flange.position = location
	flange.quaternion = bowl.quaternion
	assign(flange, Materials.metal(Color("909ba2"), 0.29))
	return location - normal * 0.014

static func headlamp(visual: Node3D, side: float, glass: Material) -> void:
	var contour := lamp_outline()
	var housing := Materials.plastic(Color("252d32"), 0.42)
	optic_surface(visual, contour, side, -0.19, housing, "VascaOtticaX250")
	var tray := PackedVector2Array()
	for p in contour:
		tray.append(Vector2(0, 0.51).lerp(p, 0.965))
	optic_surface(visual, tray, side, -0.18, Materials.metal(Color("727f87"), 0.32), "MascheraCromataOttica")
	var walls: Array = []
	for j in 5:
		var t := float(j) / 4.0
		var row := PackedVector3Array()
		for i in contour.size() + 1:
			row.append(optic_point(Vector2(0, 0.51).lerp(contour[i % contour.size()], lerpf(1.0, 0.97, t)), side, lerpf(0.001, -0.19, t)))
		walls.append(row)
	assign(M.panel(visual, walls, Color.WHITE, "BordoIncassoOttica", Vector3.UP), housing)
	for index in 2:
		var parameter := Vector2(0.04, 0.30) if index == 0 else Vector2(-0.055, 0.56)
		var location := reflector(visual, parameter, 0.079 if index == 0 else 0.056, side, index == 0)
		assign(G.sphere(visual, location, 0.006, Color.WHITE), visual.headlight_material if index == 0 else Materials.metal(Color("a4adb1"), 0.20))
	assign(G.sphere(visual, optic_point(Vector2(0.0, 0.84), side, -0.010), 0.009, Color.WHITE), Materials.plastic(Color("d9a04d"), 0.24))
	optic_surface(visual, contour, side, 0.002, glass, "FaroObliquoX250" if side < 0.0 else "FaroObliquoX250R", 0.005)

static func details(visual: Node3D) -> void:
	var black := Materials.plastic(Color("1b2226"), 0.72)
	for side: float in [-1.0, 1.0]:
		for i in 13:
			var u := side * (0.085 + i * 0.034)
			var contour := rect(Vector2(u, 0.91), Vector2(0.010, 0.075), 0.25)
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			for j in contour.size():
				var poly: Array = []
				for uv: Vector2 in [Vector2(u, 0.91), contour[j], contour[(j + 1) % contour.size()]]:
					poly.append([hood_point(uv) + hood_normal(uv) * 0.0008, hood_normal(uv)])
				R.emit(builder, poly)
			assign(G.mesh(visual, builder.commit(), Vector3.ZERO, Color.WHITE), black)
		for i in 30:
			var t := float(i) / 30.0
			var tt := float(i + 1) / 30.0
			var a := Vector2(side * 0.66, t)
			var b := Vector2(side * 0.66, tt)
			M.beam(visual, hood_point(a) + hood_normal(a) * 0.0004, hood_point(b) + hood_normal(b) * 0.0004, 0.0012, Color("657077"))
		M.beam(visual, Vector3(side * 0.48, 1.575, -2.09), Vector3(side * 0.30, 1.63, -2.01), 0.009, visual.trim)
		M.beam(visual, Vector3(side * 0.04, 1.642, -1.995), Vector3(side * 0.61, 1.642, -1.995), 0.013, visual.trim)
		var vc := Vector2(side * 0.80, 0.735)
		var vi := rect(vc, Vector2(0.195, 0.052), 0.20)
		face_frame(visual, vi, rect(vc, Vector2(0.235, 0.085), 0.20), R.material("bumper"), "LabbroPresaLaterale", 0.016)
		face_fill(visual, vi, vc, 0.018, black, "PresaLateraleIncassata")
		for j in 3:
			var y := vc.y - 0.018 + j * 0.018
			var rows: Array = []
			for yy in [y - 0.003, y + 0.003]:
				var row := PackedVector3Array()
				for i in 13:
					var x := vc.x + lerpf(-0.095, 0.095, float(i) / 12.0)
					row.append(Vector3(x, yy, base_depth(x, yy) + 0.007))
				rows.append(row)
			assign(M.panel(visual, rows, Color.WHITE, "LamellaPresaLaterale", Vector3.FORWARD), Materials.plastic(Color("343b40"), 0.65))
		var fc := Vector2(side * 0.82, 0.435)
		var fi := rect(fc, Vector2(0.23, 0.112), 0.27)
		face_frame(visual, fi, rect(fc, Vector2(0.29, 0.17), 0.27), R.material("bumper"), "ScassoFendinebbia", 0.026)
		face_fill(visual, fi, fc, 0.032, black, "FondoFendinebbia")
		var p := Vector3(fc.x, fc.y, base_depth(fc.x, fc.y) + 0.015)
		var normal := Vector3(side * 0.30, 0, -1).normalized()
		var reflector_mesh := G.cylinder(visual, p, 0.045, 0.008, Color.WHITE)
		reflector_mesh.quaternion = Quaternion(Vector3.UP, normal)
		assign(reflector_mesh, Materials.metal(Color("b3bfc2"), 0.22))
		var cover := G.sphere(visual, p + normal * 0.006, 0.044, Color.WHITE)
		cover.scale = Vector3(1, 1, 0.20)
		cover.quaternion = Quaternion(Vector3.FORWARD, normal)
		assign(cover, Materials.metal(Color("71848a"), 0.16))
		var lamp := SpotLight3D.new()
		lamp.position = Vector3(side * 0.79, 1.30, -2.65)
		lamp.rotation.x = -0.035
		lamp.light_color = Color("ffe6bd")
		lamp.spot_range = 26.0
		lamp.spot_angle = 34.0
		lamp.light_energy = 2.0
		lamp.visible = false
		visual.add_child(lamp)
		visual.lamps.append(lamp)

static func plate(visual: Node3D) -> void:
	var p := Vector3(0, 0.49, base_depth(0, 0.49) - 0.012)
	assign(M.rounded_box(visual, p, Vector3(0.55, 0.135, 0.018), 0.009, Color.WHITE, "PortatargaAnteriore"), Materials.plastic(Color("202528"), 0.72))
	assign(M.rounded_box(visual, p + Vector3.FORWARD * 0.012, Vector3(0.52, 0.11, 0.006), 0.005, Color.WHITE, "TargaAnteriore"), Materials.plastic(Color("e5e8e5"), 0.35))
	for side: float in [-1.0, 1.0]:
		assign(G.box(visual, p + Vector3(side * 0.241, 0, -0.016), Vector3(0.030, 0.103, 0.002), Color.WHITE), Materials.plastic(Color("184b86"), 0.45))
		assign(G.sphere(visual, p + Vector3(side * 0.218, 0.036, -0.018), 0.0025, Color.WHITE), Materials.metal(Color("a5adb1"), 0.32))
	var text := G.label(visual, "APOLLO", p + Vector3.FORWARD * 0.018, 30)
	text.modulate = Color("1e2428")
	text.pixel_size = 0.0020
	text.outline_size = 0
	text.rotation.y = PI

static func build(visual: Node3D) -> void:
	build_hood(visual)
	bumper(visual)
	grille(visual)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.96, 0.98, 1.0, 0.085)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.055
	glass.metallic_specular = 0.50
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side: float in [-1.0, 1.0]:
		headlamp(visual, side, glass)
	details(visual)
	plate(visual)
