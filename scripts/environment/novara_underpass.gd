extends RefCounted
## Sottopasso ferroviario di Via Novara e imbocco da Via Pasubio, dalle foto dell'utente (giugno 2026).
## Il mondo resta piatto: la "trincea" è resa con muri di contenimento solidi ai due lati della strada.
## Posizione del ponte e del parcheggio stimate dalle viste aeree; nessuna foto usata come texture.
const G = preload("res://scripts/utilities/geometry.gd")
const UNDERPASS_ID := 125508945
const NOVARA_ID := 91031160
const GROUND := -0.1
const WALL_HEIGHT := 4.4
const ROAD_WIDTH := 6.4
const WALL_OFFSET := 3.45
const RAMP := 40.0
const BRIDGE_AT := Vector2(339.0, 256.0)
const BRIDGE_DIRECTION := Vector2(-0.42, 0.91)
const CONCRETE := [Color("b2afa5"), Color("a9a69c"), Color("bcb9ae")]
const PAINT := -0.062
var path: Array[Vector2] = []
var novara: Array[Vector2] = []
var length := 0.0
var stats := {"wall_spans": 0, "bridge": 0, "markings": 0, "lot_cars": 0}

func prepare(roads: Array) -> void:
	for road: Dictionary in roads:
		if int(road.id) == UNDERPASS_ID:
			road.width = ROAD_WIDTH
			road.sidewalk = "no"
			for p: Array in road.points:
				path.push_front(Vector2(p[0], p[1]))
		elif int(road.id) == NOVARA_ID:
			for p: Array in road.points:
				novara.append(Vector2(p[0], p[1]))
	for i in range(path.size() - 1):
		length += path[i].distance_to(path[i + 1])

## Punto e direzione alla distanza `s` lungo una polilinea.
func along(line: Array[Vector2], s: float) -> Array:
	var remaining := maxf(s, 0.0)
	for i in range(line.size() - 1):
		var d := line[i].distance_to(line[i + 1])
		if remaining <= d or i == line.size() - 2:
			var t := clampf(remaining / maxf(d, 0.001), 0.0, 1.0)
			return [line[i].lerp(line[i + 1], t), (line[i + 1] - line[i]).normalized()]
		remaining -= d
	return [line[-1], Vector2.RIGHT]

func v3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)

## Vero se la posizione è dentro la trincea (tra le rampe), dove la camera deve restare bassa sotto il ponte.
func contains(pos: Vector3) -> bool:
	if path.size() < 2:
		return false
	var xy := Vector2(pos.x, pos.z)
	var s := 0.0
	var best := INF
	var best_s := 0.0
	while s <= length:
		var d: float = (along(path, s)[0] as Vector2).distance_to(xy)
		if d < best:
			best = d
			best_s = s
		s += 2.0
	return best < 6.0 and best_s > 40.0 and best_s < length - 50.0

func wall_height(s: float) -> float:
	var ramp := minf(s - 30.0, length - 40.0 - s) / RAMP
	return WALL_HEIGHT * clampf(ramp, 0.0, 1.0)

func add(world: Node3D, bounds: AABB) -> void:
	if path.size() < 2:
		return
	var town: RefCounted = world.town
	var body := StaticBody3D.new()
	body.name = "MuriSottopasso"
	body.collision_layer = 2
	body.collision_mask = 0
	world.add_child(body)
	var step := 4.0
	var spans := floori(length / step)
	var bridge_s := bridge_distance()
	for i in spans:
		var s := i * step
		var mid: Array = along(path, s + step * 0.5)
		var c: Vector2 = mid[0]
		var tangent: Vector2 = mid[1]
		var t3 := Vector3(tangent.x, 0, tangent.y)
		var n3 := Vector3(tangent.y, 0, -tangent.x)
		var yaw := atan2(-t3.z, t3.x)
		var center := v3(c)
		if not bounds.has_point(center):
			continue
		paint_span(town, center, t3, n3, yaw, i)
		var h := wall_height(s + step * 0.5)
		if h < 0.4:
			continue
		for side in [-1.0, 1.0]:
			var pos: Vector3 = center + n3 * side * WALL_OFFSET
			var wall_center := pos + Vector3.UP * (GROUND + h * 0.5)
			town.box(wall_center, Vector3(step + 0.08, h, 0.5), CONCRETE[posmod(i + int(side), 3)], yaw)
			for k in 2:
				town.box(pos - n3 * side * 0.27 + Vector3.UP * (GROUND + h * (0.34 + k * 0.33)), Vector3(step + 0.08, 0.05, 0.04), Color("8d8a80"), yaw)
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(step + 0.08, h, 0.5)
			shape.shape = box
			shape.transform = Transform3D(Basis(Vector3.UP, yaw), wall_center)
			body.add_child(shape)
			var quad := PackedVector2Array()
			for corner in [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]:
				quad.append(c + tangent * corner[0] * (step * 0.5 + 0.3) + Vector2(n3.x, n3.z) * (side * WALL_OFFSET + corner[1] * 0.6))
			town.footprints.append(quad)
			stats.wall_spans += 1
			# Lato ringhiera: balaustra metallica e lampioni sul ciglio superiore.
			if side > 0.0:
				rail_span(town, pos + Vector3.UP * (GROUND + h), t3, yaw, step)
				if i % 9 == 4:
					town.cylinder(pos + n3 * 0.5 + Vector3.UP * (GROUND + h + 3.0), 0.12, 6.0, Color("8c918c"), "metal")
					town.box(pos + Vector3.UP * (GROUND + h + 6.0), Vector3(0.06, 0.06, 1.0), Color("8c918c"), yaw, "metal")
			else:
				# Lato opposto: scarpata secca e steccato della ferrovia in cima al muro.
				for k in 3:
					var p: Vector3 = pos - n3 * 0.9 + t3 * (-step * 0.5 + (k + 0.5) * step / 3.0) + Vector3.UP * (GROUND + h + 0.25)
					town.batch.add("blob", p, Vector3(1.9, 0.9, 1.6), Color("8c8a52") if (i + k) % 2 == 0 else Color("5f7a3e"), yaw + k, "foliage")
				town.box(pos - n3 * 0.15 + Vector3.UP * (GROUND + h + 0.65), Vector3(step, 0.06, 0.05), Color("7b7767"), yaw, "metal")
				for k in 8:
					town.box(pos - n3 * 0.15 + t3 * (-step * 0.5 + (k + 0.5) * step / 8.0) + Vector3.UP * (GROUND + h + 0.65), Vector3(0.07, 1.2, 0.03), Color("7b7767"), yaw)
	# Scritte sui muri.
	for item in [["ZERO!", 90.0, 1.0, "5cc8d8"], ["SUB", 175.0, -1.0, "e8e6dc"], ["ZERO!", 235.0, -1.0, "5cc8d8"]]:
		var info: Array = along(path, item[1])
		var tangent: Vector2 = info[1]
		var side: float = item[2]
		var normal := Vector3(tangent.y, 0, -tangent.x)
		if wall_height(item[1]) < 3.0:
			continue
		var label := G.label(world, item[0], v3(info[0]) + normal * side * (WALL_OFFSET - 0.27) + Vector3.UP * 1.6, 96)
		var inward: Vector3 = -normal * side
		label.rotation.y = atan2(inward.x, inward.z)
		label.pixel_size = 0.014
		label.modulate = Color(item[3])
		label.outline_size = 10
	add_bridge(world, bridge_s)
	add_junction(world, bounds)

func bridge_distance() -> float:
	var best := 0.0
	var nearest := INF
	var s := 0.0
	while s < length:
		var d: float = (along(path, s)[0] as Vector2).distance_to(BRIDGE_AT)
		if d < nearest:
			nearest = d
			best = s
		s += 1.0
	return best

func paint_span(town: RefCounted, center: Vector3, t3: Vector3, n3: Vector3, yaw: float, index: int) -> void:
	# Linea di mezzeria continua, bordi bianchi e croci ogni tanto, come nelle foto.
	town.box(center + Vector3.UP * PAINT, Vector3(4.0, 0.012, 0.12), Color("f1eee2"), yaw)
	for side in [-1.0, 1.0]:
		town.box(center + n3 * side * 2.95 + Vector3.UP * PAINT, Vector3(4.0, 0.012, 0.12), Color("f1eee2"), yaw)
	if index % 16 == 7:
		for sign_side in [-1.0, 1.0]:
			town.box(center + n3 * 1.5 + Vector3.UP * PAINT, Vector3(2.0, 0.012, 0.22), Color("e6e3d8"), yaw + sign_side * 0.6)
		stats.markings += 1

func rail_span(town: RefCounted, base: Vector3, t3: Vector3, yaw: float, step: float) -> void:
	var metal := Color("6d767a")
	for y in [0.45, 0.8, 1.15]:
		town.box(base + Vector3.UP * y, Vector3(step + 0.05, 0.07, 0.07), metal, yaw, "metal")
	for k in 3:
		town.box(base + t3 * (-step * 0.5 + (k + 0.5) * step / 3.0) + Vector3.UP * 0.6, Vector3(0.11, 1.25, 0.11), Color("4f5b60"), yaw, "metal")

func add_bridge(world: Node3D, s: float) -> void:
	var town: RefCounted = world.town
	var info: Array = along(path, s)
	var c: Vector2 = info[0]
	var tangent: Vector2 = info[1]
	var rail_dir := BRIDGE_DIRECTION.normalized()
	var yaw := atan2(-rail_dir.y, rail_dir.x)
	var across := Vector2(rail_dir.y, -rail_dir.x)
	var deck_bottom := 3.85
	var center := v3(c)
	# Impalcato in cemento con ballast, rotaie e parapetto verde-grigio.
	town.box(center + Vector3.UP * (GROUND + deck_bottom + 0.5), Vector3(22.0, 1.0, 7.0), Color("a5a298"), yaw)
	town.box(center + Vector3.UP * (GROUND + deck_bottom + 1.08), Vector3(22.0, 0.16, 4.6), Color("8a857c"), yaw)
	for offset in [-0.72, 0.72]:
		var p: Vector3 = center + Vector3(across.x, 0, across.y) * offset
		town.box(p + Vector3.UP * (GROUND + deck_bottom + 1.22), Vector3(22.0, 0.12, 0.08), Color("5b5b5a"), yaw, "metal")
	var tangent3 := Vector3(rail_dir.x, 0, rail_dir.y)
	for side in [-1.0, 1.0]:
		var edge: Vector3 = center + Vector3(across.x, 0, across.y) * side * 3.35
		for y in [0.4, 0.75, 1.1]:
			town.box(edge + Vector3.UP * (GROUND + deck_bottom + 1.0 + y), Vector3(22.0, 0.06, 0.06), Color("69736f"), yaw, "metal")
		for k in 8:
			town.box(edge + tangent3 * (-10.0 + k * 20.0 / 7.0) + Vector3.UP * (GROUND + deck_bottom + 1.55), Vector3(0.1, 1.1, 0.1), Color("4f5b60"), yaw, "metal")
	for end in [-1.0, 1.0]:
		var pole: Vector3 = center + tangent3 * end * 10.5 + Vector3(across.x, 0, across.y) * 3.0
		town.cylinder(pole + Vector3.UP * (GROUND + deck_bottom + 4.0), 0.22, 6.0, Color("7f8581"), "metal")
	town.box(center + Vector3.UP * (GROUND + deck_bottom + 6.2), Vector3(22.0, 0.04, 0.04), Color("2e2e30"), yaw, "metal")
	# Limite di altezza 3,60 m e semaforo sotto l'impalcato, sul lato da cui si arriva.
	var face := Vector3(across.x, 0, across.y)
	var approach := Vector3(tangent.x, 0, tangent.y)
	if face.dot(approach) > 0.0:
		face = -face
	var distance := 3.5 / maxf(absf(face.dot(approach)), 0.2)
	var sign_pos := center + face * 3.55 + Vector3.UP * (GROUND + 3.35)
	var sign_yaw := atan2(face.x, face.z)
	town.sphere(sign_pos, Vector3(0.7, 0.7, 0.06), Color("c8372d"))
	town.sphere(sign_pos + face * 0.03, Vector3(0.5, 0.5, 0.03), Color("eeeae0"))
	var label := G.label(world, "3,60", sign_pos + face * 0.07, 40)
	label.rotation.y = sign_yaw
	label.pixel_size = 0.0045
	label.modulate = Color("202020")
	label.outline_size = 0
	var lamp := sign_pos + Vector3(across.x, 0, across.y) * 1.2 + face * 0.1
	town.box(lamp, Vector3(0.34, 0.95, 0.3), Color("262a2a"), yaw)
	for k in 3:
		var tone: Color = [Color("6b2a26"), Color("6f5a24"), Color("3fc46c")][k]
		town.sphere(lamp + face * 0.18 + Vector3.UP * (0.3 - k * 0.3), Vector3.ONE * 0.2, tone, "glow" if k == 2 else "plain")
	stats.bridge = 1
	if distance > 0.0:
		stats["bridge_face_distance"] = distance

## Imbocco da Via Pasubio: parcheggio in autobloccanti con strisce d'erba, auto, steccato e segnali.
func add_junction(world: Node3D, bounds: AABB) -> void:
	if novara.size() < 3:
		return
	var town: RefCounted = world.town
	var start := 14.0
	for i in 20:
		var s := start + i * 4.0
		var info: Array = along(novara, s)
		var c: Vector2 = info[0]
		var tangent: Vector2 = info[1]
		var t3 := Vector3(tangent.x, 0, tangent.y)
		var n3 := Vector3(tangent.y, 0, -tangent.x)
		if n3.x < 0.0:
			n3 = -n3  # verso est, dove sta il parcheggio
		var yaw := atan2(-t3.z, t3.x)
		var center := v3(c)
		if not bounds.has_point(center):
			continue
		var edge: Vector3 = center + n3 * 3.5
		var clear := true
		for fraction in [0.0, 0.5, 1.0]:
			clear = clear and town.clear_position(edge + n3 * (2.0 + fraction * 11.0), 0.2)
		if not clear:
			continue
		town.box(edge + n3 * 8.0 + Vector3.DOWN * 0.075, Vector3(4.05, 0.03, 12.0), Color.WHITE, yaw, "trento_paving")
		town.box(edge + n3 * 1.0 + Vector3.DOWN * 0.045, Vector3(4.05, 0.05, 2.0), Color("86a04f"), yaw)
		if i % 5 == 2:
			# Isole d'erba nel selciato, come nelle foto.
			town.box(edge + n3 * 7.0 + Vector3.DOWN * 0.045, Vector3(0.9, 0.06, 3.0), Color("7f9a52"), yaw)
		if i % 4 == 1:
			var car := center + n3 * 5.1
			if town.clear_position(car, 1.2):
				town.parked_car(car, yaw)
				stats.lot_cars += 1
		# Steccato di legno della ferrovia sul lato lontano.
		var fence: Vector3 = edge + n3 * 14.5
		town.box(fence + Vector3.UP * 0.62, Vector3(4.05, 0.07, 0.05), Color("8a8372"), yaw)
		for k in 8:
			town.box(fence + t3 * (-2.0 + (k + 0.5) * 0.5) + Vector3.UP * 0.6, Vector3(0.08, 1.15, 0.03), Color("8a8372"), yaw)
	var sign_info: Array = along(novara, 18.0)
	var sign_dir: Vector2 = sign_info[1]
	var side := Vector3(sign_dir.y, 0, -sign_dir.x)
	if side.x < 0.0:
		side = -side
	var pole: Vector3 = v3(sign_info[0]) + side * 4.1
	if town.clear_position(pole, 0.1):
		town.cylinder(pole + Vector3.UP * 1.3, 0.07, 2.6, Color("858a82"), "metal")
		town.box(pole + Vector3(0, 2.7, 0), Vector3(0.62, 0.62, 0.05), Color("1f5fb0"), 0.0)
		var p_label := G.label(world, "P", pole + Vector3(0, 2.7, 0.04), 56)
		p_label.pixel_size = 0.006
		p_label.modulate = Color("f4f4f0")
		p_label.outline_size = 0
		town.sphere(pole + Vector3(0, 2.05, 0), Vector3(0.6, 0.6, 0.05), Color("c8372d"))
		town.box(pole + Vector3(0, 2.05, 0.03), Vector3(0.46, 0.1, 0.03), Color("f1eee2"))
