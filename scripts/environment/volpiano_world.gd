extends Node3D
## Volpiano offline su impronte OSM; quote e facciate non censite restano stimate.
## Strade, muri e tetti sono unificati in poche mesh per lasciare margine agli effetti grafici.
const G = preload("res://scripts/utilities/geometry.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const Meshes = preload("res://scripts/utilities/meshes.gd")
const TownStyle = preload("res://scripts/environment/town_style.gd")
const Playground = preload("res://scripts/environment/playground.gd")
const StoryTraffic = preload("res://scripts/environment/story_traffic_light.gd")
const TrentoReference = preload("res://scripts/environment/trento_reference.gd")
const NovaraUnderpass = preload("res://scripts/environment/novara_underpass.gd")
const TriesteStreet = preload("res://scripts/environment/trieste_street.gd")
const HomeDeparture = preload("res://scripts/environment/home_departure.gd")
## Quote delle superfici rispetto al terreno (sommità a -0,1 m).
const SIDEWALK_Y = -0.085
const ROAD_Y = -0.07
const PAINT_Y = -0.064
var story_id: String = ""
var story_data: Dictionary = {}
var story_traffic: Node3D
var park_id: String = ""
var park_data: Dictionary = {}
var playground: Node3D
var town = TownStyle.new()
var trento = TrentoReference.new()
var underpass = NovaraUnderpass.new()
var trieste = TriesteStreet.new()
var home: Node3D
var home_config: Dictionary = {}
var town_stats: Dictionary = {}
var checkpoints: Array[Vector3] = []
var spawn: Vector3
var heading: float
var data: Dictionary
var map_bounds: AABB
var rendered_segments: Dictionary = {}

func point(value: Array, height: float = 0.0) -> Vector3:
	return Vector3(float(value[0]), height, float(value[1]))

func _ready() -> void:
	name = "VolpianoOSM"
	var map_path := "res://data/map/volpiano.json"
	if FileAccess.file_exists("res://local/volpiano.private.json"):
		map_path = "res://local/volpiano.private.json"
	data = JSON.parse_string(FileAccess.get_file_as_string(map_path))
	if story_id != "":
		story_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/map/story_route.json"))
		data.route = story_data.route
		# Il semaforo della storia è una regola di gioco: senza impianto OSM sul nodo lo aggiungiamo qui.
		var signal_id := int(story_data.traffic_node)
		var has_signal := false
		for feature: Dictionary in data.get("features", []):
			has_signal = has_signal or (int(feature.id) == signal_id and feature.kind == "traffic_signals")
		if not has_signal:
			data.features.append({"id": signal_id, "kind": "traffic_signals", "point": data.nodes[str(story_data.traffic_node)]})
	if park_id != "":
		var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map/parks.json"))
		for park: Dictionary in catalog.parks:
			if park.id == park_id:
				park_data = park
		data.route = park_data.route
	if park_id == "":
		home_config = HomeDeparture.resolve(data, HomeDeparture.load_settings(get_tree()))
		if not home_config.is_empty() and HomeDeparture.attach_route(data, home_config):
			home = HomeDeparture.new()
			home.settings = home_config
			home.position = point(home_config.origin)
			home.rotation.y = deg_to_rad(float(home_config.get("yaw_degrees", 0.0)))
			add_child(home)
			town.footprints.append(home.world_outline())
			town.footprints.append(home.lane_world_outline())
	trento.prepare(data.roads)
	underpass.prepare(data.roads)
	trieste.prepare(data.roads)
	town.reference = trento
	town.register_roads(data.roads)
	var route: Array = data.route
	for id in route:
		checkpoints.append(point(data.nodes[id]))
		town.detail_route.append(Vector2(data.nodes[id][0], data.nodes[id][1]))
	spawn = checkpoints[0] + Vector3.UP * 0.15
	var forward := checkpoints[1] - checkpoints[0]
	heading = atan2(-forward.x, -forward.z)
	checkpoints.remove_at(0)
	var bounds := AABB(spawn, Vector3.ZERO)
	for target in checkpoints:
		bounds = bounds.expand(target)
	bounds = bounds.grow(160.0)
	# Via Trento attraversa il margine meridionale della vecchia finestra sulla rotta.
	# Comprendere TUTTI i suoi tratti, con spazio per edifici e camera alle estremità.
	if park_id == "":
		for road: Dictionary in data.roads:
			if road.name == "Via Trento":
				for xy: Array in road.points:
					var p := point(xy)
					bounds = bounds.expand(p - Vector3(65, 0, 65))
					bounds = bounds.expand(p + Vector3(65, 0, 65))
	# Include l'intera impronta del plesso pubblico, che ricade al margine del diorama.
	for building: Dictionary in data.buildings:
		if park_id == "" and int(building.id) == 215468999:
			for xy: Array in building.outline:
				bounds = bounds.expand(point(xy) + Vector3(12, 0, 12))
	if park_id != "":
		var center := geo(park_data.lat, park_data.lon)
		bounds = AABB(center - Vector3(100, 100, 100), Vector3(200, 200, 200))
	map_bounds = bounds
	var ground := G.box(self, bounds.get_center() * Vector3(1, 0, 1) - Vector3.UP * 0.6,
		Vector3(bounds.size.x, 1, bounds.size.z), Color("90ab78"), true)
	ground.name = "Prato"
	ground.material_override = Materials.shader("ground.gdshader", {"grass_light": Color("8d9878"), "grass_dark": Color("69785e"), "grass_dry": Color("aaa18a"), "flowers": 0.12})
	# Campagna canavesana fuori dal diorama: solo visiva, senza collisioni.
	var countryside := MeshInstance3D.new()
	countryside.name = "Campagna"
	var plane := PlaneMesh.new()
	plane.size = Vector2(9000, 9000)
	countryside.mesh = plane
	countryside.position = bounds.get_center() * Vector3(1, 0, 1) - Vector3.UP * 0.3
	countryside.material_override = Materials.grass(true)
	countryside.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(countryside)
	# Limiti del diorama come siepi: recupero prevedibile senza cadute infinite.
	for side in [-1, 1]:
		G.box(self, Vector3(bounds.get_center().x + side * bounds.size.x / 2, 1, bounds.get_center().z), Vector3(1.4, 2.2, bounds.size.z), Color("698f73"), true).material_override = Materials.hedge()
		G.box(self, Vector3(bounds.get_center().x, 1, bounds.get_center().z + side * bounds.size.z / 2), Vector3(bounds.size.x, 2.2, 1.4), Color("698f73"), true).material_override = Materials.hedge()
	var signs := build_roads(bounds)
	var landmark_ids := build_buildings(bounds)
	town.landmarks(self, landmark_ids)
	street_signs(signs, bounds)
	decorate(bounds)
	trento.add_boundaries(self, bounds)
	trento.add_pasubio(self, bounds)
	underpass.add(self, bounds)
	trieste.add(self, bounds)
	scatter_greenery(bounds)
	var decorations := Node3D.new()
	decorations.name = "ArrediCittadini"
	add_child(decorations)
	town.batch.flush(decorations)
	town.add_collisions(self)
	town_stats = town.stats
	town_stats["instances"] = town.batch.instance_count
	town_stats["batches"] = decorations.get_child_count()
	town_stats["trento_reference"] = trento.stats
	route_markers(route)
	arrival_marker()
	if story_id != "":
		$Arrivo/Etichetta.text = "SOSTA FINALE · POI A PIEDI"
	if park_id != "":
		$Arrivo/Etichetta.text = "SOSTA PER IL PARCO"
		playground = Node3D.new()
		playground.set_script(Playground)
		playground.park_data = park_data
		playground.position = geo(park_data.lat, park_data.lon)
		add_child(playground)

func geo(lat: float, lon: float) -> Vector3:
	var origin: Array = data.metadata.origin
	var scale_factor: float = data.metadata.scale
	return Vector3(deg_to_rad(lon - float(origin[1])) * 6371000.0 * cos(deg_to_rad(origin[0])), 0,
		-deg_to_rad(lat - float(origin[0])) * 6371000.0) * scale_factor

func surface_node(builder: SurfaceTool, node_name: String, material: Material, shadows: bool = false) -> MeshInstance3D:
	var arrays := builder.commit_to_arrays()
	var vertices: Variant = arrays[Mesh.ARRAY_VERTEX] if arrays.size() > Mesh.ARRAY_VERTEX else null
	if not vertices is PackedVector3Array or (vertices as PackedVector3Array).is_empty():
		return null
	var result := MeshInstance3D.new()
	result.name = node_name
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	result.mesh = mesh
	result.material_override = material
	if not shadows:
		result.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(result)
	return result

func ribbon(builder: SurfaceTool, a: Vector3, b: Vector3, half_width: float, y: float) -> void:
	var direction := Vector3(b.x - a.x, 0, b.z - a.z)
	if direction.length() < 0.01:
		return
	var side := Vector3(direction.z, 0, -direction.x).normalized() * half_width
	var start := Vector3(a.x, y, a.z)
	var finish := Vector3(b.x, y, b.z)
	Meshes.triangle(builder, start + side, finish + side, finish - side, Vector3.UP)
	Meshes.triangle(builder, start + side, finish - side, start - side, Vector3.UP)

func disc(builder: SurfaceTool, center: Vector3, radius: float, y: float) -> void:
	var middle := Vector3(center.x, y, center.z)
	for i in 12:
		var a := middle + Vector3(cos(TAU * i / 12.0), 0, sin(TAU * i / 12.0)) * radius
		var b := middle + Vector3(cos(TAU * (i + 1) / 12.0), 0, sin(TAU * (i + 1) / 12.0)) * radius
		Meshes.triangle(builder, middle, a, b, Vector3.UP)

func junction_key(value: Array) -> Vector2i:
	return Vector2i(roundi(float(value[0]) * 2.0), roundi(float(value[1]) * 2.0))

## Clipping parametrico: conserva anche segmenti con entrambi gli estremi fuori mappa.
func clip_road(a: Vector3, b: Vector3, bounds: AABB) -> PackedVector3Array:
	var start := 0.0
	var finish := 1.0
	for axis in [0, 2]:
		var delta: float = b[axis] - a[axis]
		if absf(delta) < 0.00001:
			if a[axis] < bounds.position[axis] or a[axis] > bounds.end[axis]:
				return PackedVector3Array()
			continue
		var low: float = (bounds.position[axis] - a[axis]) / delta
		var high: float = (bounds.end[axis] - a[axis]) / delta
		start = maxf(start, minf(low, high))
		finish = minf(finish, maxf(low, high))
		if start >= finish:
			return PackedVector3Array()
	return PackedVector3Array([a.lerp(b, start), a.lerp(b, finish)])

func sidewalks(builder: SurfaceTool, a: Vector3, b: Vector3, width: float, profile: String, walk_width: float = 1.0) -> void:
	var direction := (b - a).normalized()
	var side := Vector3(direction.z, 0, -direction.x)
	for sign_side in [-1.0, 1.0]:
		if profile in ["no", "none", "separate"] or (profile == "left" and sign_side < 0) or (profile == "right" and sign_side > 0):
			continue
		var offset: Vector3 = side * sign_side * (width * 0.5 + walk_width * 0.5)
		ribbon(builder, a + offset, b + offset, walk_width * 0.5, SIDEWALK_Y)

func build_roads(bounds: AABB) -> Array:
	# Incroci: punti condivisi da più vie, dove la segnaletica orizzontale si interrompe.
	var usage: Dictionary = {}
	for road: Dictionary in data.roads:
		var count: int = road.points.size()
		for i in count:
			var key := junction_key(road.points[i])
			usage[key] = usage.get(key, 0) + (1 if i == 0 or i == count - 1 else 2)
	var asphalt := SurfaceTool.new()
	var walk := SurfaceTool.new()
	var trento_walk := SurfaceTool.new()
	var trento_asphalt := SurfaceTool.new()
	var footpath := SurfaceTool.new()
	var paint := SurfaceTool.new()
	var kerbs := SurfaceTool.new()
	for builder in [asphalt, walk, trento_walk, trento_asphalt, footpath, paint, kerbs]:
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var signs: Array = []
	for road: Dictionary in data.roads:
		var rendered := false
		var carriageway: bool = road.get("carriageway", road.drivable)
		var width: float = road.width if carriageway else 3.0
		var photo_street: bool = (road.name == "Via Trento" and road.get("highway", "") == "tertiary") or road.name == "Via Pasubio" or int(road.id) == 125508945 or road.name == "Via Trieste"
		var road_surface: SurfaceTool = trento_asphalt if photo_street else asphalt
		# Le due finiture si sovrappongono agli incroci: evitare superfici complanari.
		var road_y: float = ROAD_Y + 0.002 if photo_street else ROAD_Y
		for i in road.points.size():
			var a := point(road.points[i])
			if not bounds.has_point(a):
				continue
			if carriageway:
				disc(road_surface, a, width / 2.0, road_y)
			else:
				disc(footpath, a, width / 2.0, SIDEWALK_Y + 0.004)
		for i in range(road.points.size() - 1):
			var a := point(road.points[i])
			var b := point(road.points[i + 1])
			var clipped := clip_road(a, b, bounds)
			if clipped.is_empty():
				continue
			a = clipped[0]
			b = clipped[1]
			rendered_segments[str(road.id)] = int(rendered_segments.get(str(road.id), 0)) + 1
			rendered = true
			if not carriageway:
				ribbon(footpath, a, b, width / 2.0, SIDEWALK_Y + 0.004)
				continue
			sidewalks(trento_walk if photo_street else walk, a, b, width, road.get("sidewalk", "both"), (1.6 if road.name == "Via Trieste" else float(trento.catalog.sidewalk_width_estimate)) if photo_street else 1.0)
			ribbon(road_surface, a, b, width / 2.0, road_y)
			var kerb_clear_a: float = width / 2.0 + 2.0 if usage.get(junction_key(road.points[i]), 0) >= 3 else 0.0
			var kerb_clear_b: float = width / 2.0 + 2.0 if usage.get(junction_key(road.points[i + 1]), 0) >= 3 else 0.0
			kerb_edges(kerbs, a, b, width / 2.0, kerb_clear_a, kerb_clear_b, road.get("sidewalk", "both"))
			if int(road.get("oneway", 0)) == 0 and road.get("highway", "tertiary") in ["primary", "secondary", "tertiary"]:
				var clear_a: float = width / 2.0 + 3.0 if usage.get(junction_key(road.points[i]), 0) >= 3 else 0.0
				var clear_b: float = width / 2.0 + 3.0 if usage.get(junction_key(road.points[i + 1]), 0) >= 3 else 0.0
				center_dashes(paint, a, b, clear_a, clear_b)
				if photo_street and a.distance_to(b) > clear_a + clear_b + 0.2:
					var direction := (b - a).normalized()
					var side := Vector3(direction.z, 0, -direction.x)
					for sign_side in [-1.0, 1.0]:
						var offset: Vector3 = side * sign_side * (width * 0.5 - 0.15)
						ribbon(paint, a + direction * clear_a + offset, b - direction * clear_b + offset, 0.045, PAINT_Y)
		if rendered and road.name != "":
			signs.append(road)
	surface_node(walk, "Marciapiedi", Materials.paving())
	surface_node(footpath, "Percorsi", Materials.paving(Color("e6d3a8"), 0.45))
	surface_node(asphalt, "Asfalto", Materials.asphalt())
	surface_node(trento_walk, "AutobloccantiViaTrento", Materials.paving(Color("ba9d8c"), 0.24))
	surface_node(trento_asphalt, "AsfaltoViaTrento", Materials.shader("asphalt.gdshader", {"base_color": Color("646463"), "wear": 1.0}))
	surface_node(paint, "Segnaletica", G.material(Color("f4efe0")))
	surface_node(kerbs, "BordurePietra", Materials.instanced("plain"), true)
	return signs

## Piccole bordure visive fuori dalla carreggiata; gli incroci restano aperti.
func kerb_edges(builder: SurfaceTool, a: Vector3, b: Vector3, half_width: float, clear_a: float, clear_b: float, profile: String = "both") -> void:
	var length := a.distance_to(b)
	if length < clear_a + clear_b + 0.4:
		return
	var direction := (b - a).normalized()
	var side := Vector3(direction.z, 0, -direction.x)
	for sign_side in [-1.0, 1.0]:
		if profile in ["no", "none", "separate"] or (profile == "left" and sign_side < 0) or (profile == "right" and sign_side > 0):
			continue
		var offset: Vector3 = side * sign_side
		var t := clear_a
		while t < length - clear_b - 0.02:
			var stop := minf(t + 1.08, length - clear_b)
			var start := a + direction * (t + 0.012) + offset * (half_width + 0.025)
			var end := a + direction * stop + offset * (half_width + 0.025)
			var p := Vector3(start.x, -0.015, start.z)
			var q := Vector3(end.x, -0.015, end.z)
			var r := q + offset * 0.18
			var s := p + offset * 0.18
			builder.set_color(Color("c8c7ba").darkened(float(posmod(int(t * 10.0), 5)) * 0.015))
			Meshes.triangle(builder, p, q, r, Vector3.UP)
			Meshes.triangle(builder, p, r, s, Vector3.UP)
			var lower := Vector3.UP * (SIDEWALK_Y + 0.015)
			Meshes.triangle(builder, p, p + lower, q + lower, -offset)
			Meshes.triangle(builder, p, q + lower, q, -offset)
			Meshes.triangle(builder, s, r + lower, s + lower, offset)
			Meshes.triangle(builder, s, r, r + lower, offset)
			t += 1.1

func center_dashes(builder: SurfaceTool, a: Vector3, b: Vector3, clear_a: float, clear_b: float) -> void:
	var length := a.distance_to(b)
	var direction := (b - a) / maxf(length, 0.001)
	var t := 1.0
	while t + 2.5 < length:
		var start := t
		var finish := t + 2.5
		t += 5.5
		if start < clear_a or finish > length - clear_b:
			continue
		ribbon(builder, a + direction * start, a + direction * finish, 0.07, PAINT_Y)

func signed_area(outline: PackedVector2Array) -> float:
	var total := 0.0
	for i in outline.size():
		var p := outline[i]
		var q := outline[(i + 1) % outline.size()]
		total += p.x * q.y - q.x * p.y
	return total * 0.5

func build_buildings(bounds: AABB) -> Dictionary:
	var walls := SurfaceTool.new()
	walls.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roofs := SurfaceTool.new()
	roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var landmark_ids: Dictionary = {}
	var facade_entries: Array = []
	var scale_factor: float = data.metadata.scale
	for building: Dictionary in data.buildings:
		if home != null and home.replaces(int(building.id)):
			continue
		var outline := PackedVector2Array()
		var inside := true
		for xy: Array in building.outline:
			inside = inside and bounds.has_point(point(xy))
			outline.append(Vector2(xy[0], xy[1]))
		if not inside or outline.size() < 4:
			continue
		outline.remove_at(outline.size() - 1)
		if Geometry2D.triangulate_polygon(outline).is_empty():
			continue
		town.footprints.append(outline)
		var h: float = town.height(building)
		add_walls(walls, faces, outline, h, town.wall_color(building))
		add_roof(roofs, outline, h, building)
		facade_entries.append([outline, building, h])
		if int(building.id) == 417795500:
			landmark_ids[417795500] = {"origin": geo(45.201633, 7.775481), "scale": scale_factor}
		if int(building.id) == 897476177:
			landmark_ids[897476177] = {"origin": geo(45.201835, 7.775600), "scale": scale_factor}
		if int(building.id) == 215468999:
			landmark_ids[215468999] = {"origin": geo(45.1993144, 7.781281), "scale": scale_factor}
	# Tutte le impronte devono essere note prima di collocare i piccoli piazzali.
	for entry: Array in facade_entries:
		town.facade(entry[0], entry[1], entry[2])
	surface_node(walls, "Edifici", Materials.walls(), true)
	surface_node(roofs, "Tetti", Materials.roofs(), true)
	# Collider concavo generato dalle stesse impronte, senza rettangoli sopra le strade.
	var body := StaticBody3D.new()
	body.name = "EdificiCollisione"
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return landmark_ids

func add_walls(builder: SurfaceTool, faces: PackedVector3Array, outline: PackedVector2Array, h: float, color: Color) -> void:
	var orientation := 1.0 if signed_area(outline) > 0.0 else -1.0
	builder.set_color(color)
	var along := 0.0
	for i in outline.size():
		var p := outline[i]
		var q := outline[(i + 1) % outline.size()]
		var edge := q - p
		var outward := Vector3(edge.y, 0, -edge.x).normalized() * orientation
		var a := Vector3(p.x, -0.15, p.y)
		var b := Vector3(q.x, -0.15, q.y)
		var c := Vector3(q.x, h, q.y)
		var d := Vector3(p.x, h, p.y)
		var length := edge.length()
		Meshes.triangle(builder, a, b, c, outward, [Vector2(along, 0), Vector2(along + length, 0), Vector2(along + length, h)])
		Meshes.triangle(builder, a, c, d, outward, [Vector2(along, 0), Vector2(along + length, h), Vector2(along, h)])
		along += length
		faces.append_array([a, b, c, a, c, d])

func add_roof(builder: SurfaceTool, outline: PackedVector2Array, h: float, building: Dictionary) -> void:
	var id := int(building.id)
	var tones := [Color("89624e"), Color("986c53"), Color("a07760"), Color("806458"), Color("95705e")]
	var roof_color: Color = tones[posmod(id, tones.size())]
	if building.get("roof_shape", "") == "flat" or building.get("kind", "") in ["industrial", "warehouse"] or id == 215468999:
		builder.set_color(Color("c9cdcc") if id == 215468999 else Color("9b9a90"))
		var indices := Geometry2D.triangulate_polygon(outline)
		for i in range(0, indices.size(), 3):
			var a := outline[indices[i]]
			var b := outline[indices[i + 1]]
			var c := outline[indices[i + 2]]
			Meshes.triangle(builder, Vector3(a.x, h, a.y), Vector3(b.x, h, b.y), Vector3(c.x, h, c.y), Vector3.UP)
		return
	var area := absf(signed_area(outline))
	var hull := Geometry2D.convex_hull(outline)
	var hull_area := absf(signed_area(hull))
	var center := Vector2.ZERO
	for p in outline:
		center += p
	center /= outline.size()
	# Asse principale dell'impronta: la linea di colmo segue il lato lungo.
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
	var min_v := INF
	var max_v := -INF
	for p in outline:
		min_u = minf(min_u, (p - center).dot(u))
		max_u = maxf(max_u, (p - center).dot(u))
		min_v = minf(min_v, (p - center).dot(v))
		max_v = maxf(max_v, (p - center).dot(v))
	var half_length := (max_u - min_u) / 2.0
	var half_width := (max_v - min_v) / 2.0
	var middle := center + u * (min_u + max_u) / 2.0 + v * (min_v + max_v) / 2.0
	if half_width > half_length:
		var swap := half_width
		half_width = half_length
		half_length = swap
		var axis := u
		u = v
		v = -axis
	var hipped := hull_area > 0.0 and area / hull_area > 0.86 and half_width > 1.2 and half_width < 13.0
	if not hipped and id != 417795500:
		for inset in [2.2, 1.5, 1.0]:
			if terrace_roof(builder, outline, h, roof_color, inset, Color("cdbfa8") if id == 215468999 else roof_color.darkened(0.1)):
				return
	if not hipped or id == 417795500:
		builder.set_color(Color("c2b29b"))
		var indices := Geometry2D.triangulate_polygon(outline)
		for i in range(0, indices.size(), 3):
			var points: Array[Vector3] = []
			for k in 3:
				var p := outline[indices[i + k]]
				points.append(Vector3(p.x, h + 0.02, p.y))
			Meshes.triangle(builder, points[0], points[1], points[2], Vector3.UP, [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		return
	var rise := clampf(half_width * 0.55, 0.9, 3.4)
	var ridge_scale := maxf(0.0, (half_length - half_width) / half_length)
	var orientation := 1.0 if signed_area(outline) > 0.0 else -1.0
	var count := outline.size()
	var outer: Array[Vector3] = []
	var inner: Array[Vector3] = []
	for i in count:
		var p := outline[i]
		var previous := outline[(i - 1 + count) % count]
		var following := outline[(i + 1) % count]
		var n1 := Vector2(p.y - previous.y, -(p.x - previous.x)).normalized() * orientation
		var n2 := Vector2(following.y - p.y, -(following.x - p.x)).normalized() * orientation
		var bisector := (n1 + n2).normalized()
		var push := 0.4 / maxf(bisector.dot(n1), 0.5)
		var eave := p + bisector * push
		outer.append(Vector3(eave.x, h - 0.08, eave.y))
		var ridge := middle + u * (p - middle).dot(u) * ridge_scale
		inner.append(Vector3(ridge.x, h + rise, ridge.y))
	builder.set_color(roof_color)
	for i in count:
		var j := (i + 1) % count
		var edge3 := outer[j] - outer[i]
		if edge3.length() < 0.05:
			continue
		var edge_dir := edge3.normalized()
		var outward2 := Vector2(edge3.z, -edge3.x).normalized() * orientation
		var hint := Vector3(outward2.x, 1.2, outward2.y)
		var quad := [outer[i], outer[j], inner[j], inner[i]]
		var uv: Array[Vector2] = []
		for corner: Vector3 in quad:
			var offset := corner - outer[i]
			var along := offset.dot(edge_dir)
			uv.append(Vector2(along, (offset - edge_dir * along).length()))
		Meshes.triangle(builder, quad[0], quad[1], quad[2], hint, [uv[0], uv[1], uv[2]])
		Meshes.triangle(builder, quad[0], quad[2], quad[3], hint, [uv[0], uv[2], uv[3]])
	if posmod(id, 3) == 0 and half_length > 3.0 and id != 897476177:
		var spot := middle + u * half_length * 0.35 * (1.0 if posmod(id, 2) == 0 else -1.0) + v * half_width * 0.3
		town.chimney(Vector3(spot.x, h + rise * 0.7 - 0.3, spot.y), 1.3)

## Impronte irregolari: falde in coppi lungo il perimetro e terrazzo piano al centro.
func terrace_roof(builder: SurfaceTool, outline: PackedVector2Array, h: float, roof_color: Color, inset: float, top_color: Color) -> bool:
	var area := signed_area(outline)
	var orientation := 1.0 if area > 0.0 else -1.0
	var count := outline.size()
	var rise := inset * 0.55
	var eaves: Array[Vector3] = []
	var inner := PackedVector2Array()
	for i in count:
		var p := outline[i]
		var previous := outline[(i - 1 + count) % count]
		var following := outline[(i + 1) % count]
		var n1 := Vector2(p.y - previous.y, -(p.x - previous.x)).normalized() * orientation
		var n2 := Vector2(following.y - p.y, -(following.x - p.x)).normalized() * orientation
		var bisector := n1 + n2
		if bisector.length() < 0.05:
			return false
		bisector = bisector.normalized()
		var cosine := bisector.dot(n1)
		if cosine < 0.25:
			return false
		var eave := p + bisector * 0.4 / maxf(cosine, 0.5)
		eaves.append(Vector3(eave.x, h - 0.08, eave.y))
		var core := p - bisector * inset / cosine
		if not Geometry2D.is_point_in_polygon(core, outline):
			return false
		inner.append(core)
	var inner_area := signed_area(inner)
	if inner_area * area <= 0.0 or absf(inner_area) < absf(area) * 0.12:
		return false
	for i in count:
		for j in range(i + 2, count):
			if i == 0 and j == count - 1:
				continue
			if Geometry2D.segment_intersects_segment(inner[i], inner[(i + 1) % count], inner[j], inner[(j + 1) % count]) != null:
				return false
	var indices := Geometry2D.triangulate_polygon(inner)
	if indices.is_empty():
		return false
	builder.set_color(roof_color)
	for i in count:
		var j := (i + 1) % count
		var a := eaves[i]
		var b := eaves[j]
		var c := Vector3(inner[j].x, h + rise, inner[j].y)
		var d := Vector3(inner[i].x, h + rise, inner[i].y)
		var edge_dir := (b - a).normalized()
		var outward2 := Vector2(b.z - a.z, -(b.x - a.x)).normalized() * orientation
		var hint := Vector3(outward2.x, 1.2, outward2.y)
		var uv: Array[Vector2] = []
		for corner: Vector3 in [a, b, c, d]:
			var offset := corner - a
			var along := offset.dot(edge_dir)
			uv.append(Vector2(along, (offset - edge_dir * along).length()))
		Meshes.triangle(builder, a, b, c, hint, [uv[0], uv[1], uv[2]])
		Meshes.triangle(builder, a, c, d, hint, [uv[0], uv[2], uv[3]])
	builder.set_color(top_color)
	for i in range(0, indices.size(), 3):
		var points: Array[Vector3] = []
		for k in 3:
			var p := inner[indices[i + k]]
			points.append(Vector3(p.x, h + rise, p.y))
		Meshes.triangle(builder, points[0], points[1], points[2], Vector3.UP, [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	return true

func decorate(bounds: AABB) -> void:
	# I punti OSM mantengono la posizione reale; gli arredi nuovi sono illustrativi.
	for feature: Dictionary in data.get("features", []):
		var pos := point(feature.point)
		if not bounds.has_point(pos):
			continue
		if feature.kind == "tree":
			if town.clear_position(pos, 0.45):
				town.tree(pos, int(feature.id))
		elif feature.kind == "crossing" or feature.kind == "traffic_signals":
			var nearest: Array = []
			var distance := INF
			var xy := Vector2(pos.x, pos.z)
			for road: Array in town.road_segments:
				var d := Geometry2D.get_closest_point_to_segment(xy, road[0], road[1]).distance_to(xy)
				if d < distance:
					distance = d
					nearest = road
			if nearest.is_empty() or distance > 8:
				continue
			var direction: Vector2 = (nearest[1] - nearest[0]).normalized()
			var yaw := atan2(direction.x, direction.y)
			var side := Vector3(direction.y, 0, -direction.x)
			if feature.kind == "crossing":
				var stripes := maxi(2, floori(float(nearest[2]) * 2 / 0.8))
				for i in stripes:
					town.box(pos + side * ((i - float(stripes - 1) / 2) * 0.8) + Vector3.UP * (PAINT_Y - 0.004), Vector3(0.45, 0.02, 3), Color("f6f1e2"), yaw)
				town.stats.crossings += 1
			else:
				var pole := pos + side * (float(nearest[2]) + 0.8)
				if not town.clear_position(pole, 0.15):
					for attempt in 8:
						var angle := float(attempt) * TAU / 8
						var candidate := pos + Vector3(cos(angle), 0, sin(angle)) * 8
						if town.clear_position(candidate, 0.15):
							pole = candidate
							break
				if town.clear_position(pole, 0.15):
					if story_id != "" and int(feature.id) == int(story_data.traffic_node):
						story_traffic = Node3D.new()
						story_traffic.set_script(StoryTraffic)
						story_traffic.position = pole
						story_traffic.rotation.y = yaw + PI
						add_child(story_traffic)
						town.stats.signals += 1
						continue
					town.cylinder(pole + Vector3.UP * 1.8, 0.12, 3.6, Color("38524f"), "metal")
					town.box(pole + Vector3.UP * 3.3, Vector3(0.55, 1.35, 0.4), Color("2f4342"), yaw)
					for i in 3:
						town.sphere(pole + Vector3.UP * (3.7-i*0.4), Vector3.ONE*0.27, Color("f2b84b") if i == 1 else Color("4a5752"), "glow" if i == 1 else "plain")
					town.stats.signals += 1
	# Arredi lungo la rotta, con distanza minima da tutte le strade e impronte.
	var occupied: Array[Vector3] = []
	var route: Array = data.route
	var serial := 0
	for i in range(route.size() - 1):
		var a := point(data.nodes[route[i]])
		var b := point(data.nodes[route[i + 1]])
		var tangent := (b - a).normalized()
		var side := Vector3(tangent.z, 0, -tangent.x)
		var steps := maxi(1, floori(a.distance_to(b) / 36))
		for step in steps:
			serial += 1
			for sign_side in [-1, 1]:
				var pos: Vector3 = a.lerp(b, (float(step) + 0.5) / steps) + side * sign_side * 6.5
				var crowded := false
				for placed in occupied:
					crowded = crowded or placed.distance_to(pos) < 8.0
				if crowded or not town.clear_position(pos, 1.1):
					continue
				occupied.append(pos)
				var yaw := atan2(-tangent.z, tangent.x)
				match serial % 5:
					0:
						town.tree(pos, serial)
					1:
						town.lamp(pos, yaw - sign_side * PI / 2.0)
					2:
						town.bench(pos, yaw)
						if town.clear_position(pos + tangent * 2.5, 1.0):
							town.planter(pos + tangent * 2.5)
					3:
						town.planter(pos)
						if town.clear_position(pos + tangent * 1.8, 0.4):
							town.cylinder(pos + tangent * 1.8 + Vector3.UP * 0.45, 0.55, 0.9, Color("4f7a6c"))
							town.cylinder(pos + tangent * 1.8 + Vector3.UP * 0.92, 0.6, 0.06, Color("3c5e53"))
					4:
						if town.clear_position(pos, 2.0):
							town.parked_car(pos, atan2(tangent.x, tangent.z))

## Ciuffi d'erba, fiori e cespugli sul verde libero, con una griglia di occupazione da 2 m.
func scatter_greenery(bounds: AABB) -> void:
	var cell := 2.0
	var origin := Vector2(bounds.position.x, bounds.position.z)
	var columns := int(bounds.size.x / cell) + 1
	var rows := int(bounds.size.z / cell) + 1
	var blocked := PackedByteArray()
	blocked.resize(columns * rows)
	for segment: Array in town.road_segments:
		var a: Vector2 = segment[0]
		var b: Vector2 = segment[1]
		var reach: float = segment[2] + 2.2
		var low := (Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2.ONE * reach - origin) / cell
		var high := (Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2.ONE * reach - origin) / cell
		for x in range(maxi(0, floori(low.x)), mini(columns, ceili(high.x) + 1)):
			for y in range(maxi(0, floori(low.y)), mini(rows, ceili(high.y) + 1)):
				var center := origin + Vector2(x + 0.5, y + 0.5) * cell
				if Geometry2D.get_closest_point_to_segment(center, a, b).distance_to(center) < reach:
					blocked[y * columns + x] = 1
	for outline: PackedVector2Array in town.footprints:
		for grown: PackedVector2Array in Geometry2D.offset_polygon(outline, 1.4):
			var low := Vector2(INF, INF)
			var high := Vector2(-INF, -INF)
			for p in grown:
				low = low.min(p)
				high = high.max(p)
			for x in range(maxi(0, floori((low.x - origin.x) / cell)), mini(columns, ceili((high.x - origin.x) / cell) + 1)):
				for y in range(maxi(0, floori((low.y - origin.y) / cell)), mini(rows, ceili((high.y - origin.y) / cell) + 1)):
					if Geometry2D.is_point_in_polygon(origin + Vector2(x + 0.5, y + 0.5) * cell, grown):
						blocked[y * columns + x] = 1
	var park_center := Vector2.INF
	var park_radius := 0.0
	if park_id != "":
		var center := geo(park_data.lat, park_data.lon)
		park_center = Vector2(center.x, center.z)
		park_radius = maxf(float(park_data.size[0]), float(park_data.size[1])) * 0.75 + 3.0
	var random := RandomNumberGenerator.new()
	random.seed = 1017
	var attempts := clampi(int(bounds.size.x * bounds.size.z / 55.0), 500, 9000)
	for attempt in attempts:
		var p := origin + Vector2(random.randf() * bounds.size.x, random.randf() * bounds.size.z)
		var x := clampi(int((p.x - origin.x) / cell), 0, columns - 1)
		var y := clampi(int((p.y - origin.y) / cell), 0, rows - 1)
		if blocked[y * columns + x] == 1 or p.distance_to(park_center) < park_radius:
			continue
		var pos := Vector3(p.x, -0.1, p.y)
		if attempt % 23 == 0:
			town.bush(pos, attempt, random.randf_range(0.8, 1.4))
		else:
			town.grass_tuft(pos, attempt)

## Frecce dorate a terra lungo il percorso, al posto dei vecchi dischi.
func route_markers(route: Array) -> void:
	for i in range(route.size() - 1):
		var a := point(data.nodes[route[i]], PAINT_Y + 0.02)
		var b := point(data.nodes[route[i + 1]], PAINT_Y + 0.02)
		var direction := (b - a).normalized()
		var yaw := atan2(-direction.x, -direction.z)
		var count := maxi(1, ceili(a.distance_to(b) / 8.0))
		for step in count:
			var tip := a.lerp(b, float(step) / count)
			for side in [-1.0, 1.0]:
				var arm_yaw: float = yaw + side * 0.65
				town.batch.add("box", tip + Basis(Vector3.UP, arm_yaw) * Vector3(0, 0, 0.36), Vector3(0.18, 0.03, 0.8), Color("ffc94d"), arm_yaw, "marker")
	var markers := Node3D.new()
	markers.name = "FrecceRotta"
	add_child(markers)
	town.batch.flush(markers)

func arrival_marker() -> void:
	var root := Node3D.new()
	root.name = "Arrivo"
	root.position = checkpoints[-1]
	add_child(root)
	var pad := G.cylinder(root, Vector3.UP * (PAINT_Y + 0.01), 4.0, 0.02, Color("69bdab"))
	pad.material_override = Materials.glass(Color(0.42, 0.85, 0.75, 0.35))
	pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 3.75
	torus.outer_radius = 4.05
	torus.rings = 48
	torus.ring_segments = 6
	ring.mesh = torus
	ring.scale = Vector3(1, 0.25, 1)
	ring.position.y = 0.0
	ring.material_override = Materials.glow(Color("6ff0d4"), 2.2)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(ring)
	var beam := MeshInstance3D.new()
	var column := CylinderMesh.new()
	column.top_radius = 3.6
	column.bottom_radius = 3.9
	column.height = 1.0
	column.radial_segments = 32
	column.cap_top = false
	column.cap_bottom = false
	beam.mesh = column
	beam.scale = Vector3(1, 36, 1)
	beam.position.y = 18.0
	beam.material_override = Materials.beacon()
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(beam)
	var arrival := G.label(root, "ARRIVO ESPLORAZIONE", Vector3.UP * 5.0, 36)
	arrival.name = "Etichetta"
	arrival.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func street_signs(roads: Array, bounds: AABB) -> void:
	var labelled: Dictionary = {}
	for road: Dictionary in roads:
		if labelled.has(road.name):
			continue
		for i in range(road.points.size() - 1):
			var a := point(road.points[i])
			var b := point(road.points[i+1])
			var forward := (b-a).normalized()
			var pos := (a+b)/2 + Vector3(forward.z, 0, -forward.x) * (float(road.width)/2+1)
			if not bounds.has_point(pos) or not town.clear_position(pos, 0.3):
				continue
			var sign := Node3D.new()
			sign.position = pos
			sign.rotation.y = atan2(-forward.x, -forward.z)
			add_child(sign)
			G.cylinder(sign, Vector3(0, 1.6, 0), 0.055, 3.2, Color("3c4b4a")).material_override = Materials.metal(Color("3c4b4a"), 0.4)
			G.box(sign, Vector3(0, 3.1, 0), Vector3(4.15, 0.72, 0.07), Color("f4efe0"))
			G.box(sign, Vector3(0, 3.1, 0), Vector3(4.0, 0.6, 0.09), Color("2f5d73"))
			var text := G.label(sign, road.name, Vector3(0, 3.1, 0.06), 28)
			text.pixel_size = 0.006
			text.outline_size = 2
			labelled[road.name] = true
			town.stats.street_signs += 1
			break
