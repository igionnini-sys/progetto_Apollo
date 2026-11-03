extends RefCounted
## Plesso di Via Trieste dalle foto dell'utente (giugno 2026): corpo basso in mattoni rossi con portico
## a pilastri e ampia gronda, copertura in lamiera chiara, corpo alto con finestre a nastro,
## ala verde in fondo e ingresso con arco verde. Dimensioni stimate; nessuna foto usata come texture.
const BRICK := Color("b4543b")
const GREEN := Color("bfd07c")
const CONCRETE := Color("cfd1cc")
const METAL := Color("c9cdcc")
const HEIGHT := 4.0
var stats := {"edges": 0, "columns": 0, "windows": 0}

func area(outline: PackedVector2Array) -> float:
	var total := 0.0
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5

func facade(town: RefCounted, outline: PackedVector2Array, h: float) -> void:
	var orientation := 1.0 if area(outline) > 0.0 else -1.0
	var center := Vector2.ZERO
	for p in outline:
		center += p
	center /= outline.size()
	var sxx := 0.0
	var syy := 0.0
	var sxy := 0.0
	for p in outline:
		var d := p - center
		sxx += d.x * d.x
		syy += d.y * d.y
		sxy += d.x * d.y
	var angle := 0.5 * atan2(2.0 * sxy, sxx - syy)
	var u := Vector2(cos(angle), sin(angle))
	var v := Vector2(-u.y, u.x)
	var min_u := INF
	var max_u := -INF
	for p in outline:
		min_u = minf(min_u, (p - center).dot(u))
		max_u = maxf(max_u, (p - center).dot(u))
	var entrance_edge := -1
	var entrance_distance := INF
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		var length := a.distance_to(b)
		if length < 2.4:
			continue
		var tangent := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
		var normal := Vector3(tangent.z, 0, -tangent.x) * orientation
		var yaw := atan2(-tangent.z, tangent.x)
		var middle := Vector3((a.x + b.x) * 0.5, 0, (a.y + b.y) * 0.5)
		var along := ((Vector2(middle.x, middle.z) - center).dot(u) - (min_u + max_u) * 0.5) / ((max_u - min_u) * 0.5)
		var annex: bool = along > 0.62
		var wall := GREEN if annex else BRICK
		town.box(middle + Vector3.UP * (h * 0.5 - 0.05) + normal * 0.06, Vector3(length, h + 0.1, 0.12), wall, yaw, "plain" if annex else "stone")
		if annex:
			# Riquadri rossi e verdi sulla facciata dell'ala in fondo.
			for k in floori(length / 2.4):
				town.box(middle + tangent * (-length * 0.5 + (k + 0.5) * 2.4) + Vector3.UP * 1.2 + normal * 0.13, Vector3(0.7, 2.4, 0.06), Color("c0463a"), yaw)
		# Zoccolo in cemento e cornice della gronda.
		town.box(middle + Vector3.UP * 0.3 + normal * 0.1, Vector3(length, 0.6, 0.16), Color("a9aaa3"), yaw)
		town.box(middle + Vector3.UP * (h - 0.05) + normal * 0.2, Vector3(length + 0.2, 0.18, 0.3), CONCRETE, yaw)
		# Finestre a nastro con montanti chiari.
		var count := floori((length - 1.6) / 2.6)
		for k in count:
			var pos: Vector3 = middle + tangent * (-(count - 1) * 1.3 + k * 2.6) + Vector3.UP * 1.95 + normal * 0.16
			town.box(pos, Vector3(2.2, 1.55, 0.1), Color("e4e3dc"), yaw)
			town.box(pos + normal * 0.05, Vector3(2.0, 1.4, 0.08), Color("52646a"), yaw, "window")
			town.box(pos + normal * 0.1, Vector3(0.05, 1.4, 0.04), Color("e4e3dc"), yaw)
			stats.windows += 1
		# Portico: ampia gronda in lamiera su pilastri di cemento lungo i fronti lunghi.
		if length > 10.0:
			town.box(middle + Vector3.UP * (h + 0.1) + normal * 1.35, Vector3(length + 0.4, 0.22, 2.9), METAL, yaw, "metal")
			var posts := floori(length / 5.5)
			for k in posts + 1:
				var post: Vector3 = middle + tangent * (-length * 0.5 + length * k / maxf(posts, 1)) + normal * 2.55 + Vector3.UP * (h * 0.5)
				town.box(post, Vector3(0.5, h, 0.5), CONCRETE, yaw)
				stats.columns += 1
		stats.edges += 1
		if length > 8.0 and not annex:
			var nearest := INF
			for road: Array in town.road_segments:
				var closest: Vector2 = Geometry2D.get_closest_point_to_segment(Vector2(middle.x, middle.z), road[0], road[1])
				nearest = minf(nearest, closest.distance_to(Vector2(middle.x, middle.z)))
			if nearest < entrance_distance:
				entrance_distance = nearest
				entrance_edge = i
	# Corpo alto centrale: mattoni, finestre a nastro e copertura chiara.
	var lu := (max_u - min_u) * 0.2
	var main := Vector3(center.x, 0, center.y) + Vector3(u.x, 0, u.y) * (min_u + max_u) * 0.5
	var yaw_u := atan2(-u.y, u.x)
	var top := Vector3(u.x, 0, u.y)
	var across := Vector3(v.x, 0, v.y)
	town.box(main + Vector3.UP * (h + 1.5), Vector3(lu, 3.0, 9.0), BRICK, yaw_u, "stone")
	town.box(main + Vector3.UP * (h + 3.1), Vector3(lu + 1.0, 0.24, 10.0), METAL, yaw_u, "metal")
	for side in [-1.0, 1.0]:
		for k in 8:
			var pos: Vector3 = main + top * (-lu * 0.5 + (k + 0.5) * lu / 8.0) + across * side * 4.55 + Vector3.UP * (h + 1.6)
			town.box(pos, Vector3(lu / 8.0 - 0.5, 0.9, 0.1), Color("e4e3dc"), yaw_u)
			town.box(pos + across * side * 0.04, Vector3(lu / 8.0 - 0.7, 0.75, 0.08), Color("52646a"), yaw_u, "window")
	if entrance_edge < 0:
		return
	var a := outline[entrance_edge]
	var b := outline[(entrance_edge + 1) % outline.size()]
	var tangent := Vector3(b.x - a.x, 0, b.y - a.y).normalized()
	var normal := Vector3(tangent.z, 0, -tangent.x) * orientation
	var yaw := atan2(-tangent.z, tangent.x)
	var door := Vector3((a.x + b.x) * 0.5, 0, (a.y + b.y) * 0.5)
	# Ingresso con arco verde e porte a vetri.
	town.box(door + Vector3.UP * 1.2 + normal * 0.22, Vector3(3.6, 2.4, 0.1), Color("3f5961"), yaw, "window")
	town.batch.add("arch_frame", door + Vector3.UP * 1.9 + normal * 0.35, Vector3(3.6, 3.4, 0.16), Color("6faa3f"), yaw)
	# Pilastrini neri con rastrelliere e dissuasori verdi davanti all'ingresso.
	for k in 9:
		var post: Vector3 = door + tangent * (-8.0 + k * 2.0) + normal * 4.4
		town.cylinder(post + Vector3.UP * 0.55, 0.14, 1.1, Color("2b2d2e"), "metal")
		town.box(post + Vector3.UP * 0.9, Vector3(2.0, 0.05, 0.05), Color("d8dbd8"), yaw, "metal")
	for k in 4:
		town.box(door + tangent * (-7.0 + k * 4.6) + normal * 4.3 + Vector3.UP * 0.5, Vector3(0.6, 1.0, 0.6), Color("7cb043"), yaw)
	town.box(door + normal * 7.0 + Vector3.DOWN * 0.07, Vector3(20.0, 0.03, 8.0), Color("626364"), yaw)
