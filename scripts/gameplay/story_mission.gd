extends "res://scripts/gameplay/route_mission.gd"
signal star_collected(count: int)
signal story_event(key: String)
const Star = preload("res://scripts/gameplay/story_star.gd")
const G = preload("res://scripts/utilities/geometry.gd")
var challenge: bool = false
var traffic_index: int = 0
var traffic_light: Node3D
var stops: Array[int] = []
var completed_stops: Array[int] = []
var stop_time: float = 0
var stars: Array[Node3D] = []
var collected_stars: int = 0
var stop_markers: Array[Node3D] = []

func _init() -> void:
	route_mode = true
	story_mode = true

func restart() -> void:
	super.restart()
	collected_stars = 0
	completed_stops.clear()
	stop_time = 0
	traffic_light.reset()
	for star in stars:
		star.queue_free()
	stars.clear()
	stops.clear()
	for marker in stop_markers:
		marker.queue_free()
	stop_markers.clear()
	if challenge:
		stops.assign([int(points.size()*0.25), int(points.size()*0.55)])
		for index in stops:
			var marker := Node3D.new()
			add_child(marker)
			G.cylinder(marker, points[index] + Vector3.UP*0.08, 3.0, 0.08, Color("7ab5be"))
			stop_markers.append(marker)
	for fraction in [0.25, 0.55, 0.80]:
		var target := maxi(1, int(points.size()*fraction))
		var forward := (points[target] - points[target-1]).normalized()
		var star := Node3D.new()
		star.set_script(Star)
		star.position = points[target-1].lerp(points[target], 0.5) + Vector3(forward.z, 0, -forward.x) * 1.2 + Vector3.UP * 1.4
		add_child(star)
		stars.append(star)

func _physics_process(delta: float) -> void:
	if not active or finished:
		return
	for star in stars:
		var offset: Vector3 = vehicle.position - star.position
		if not star.collected and Vector2(offset.x, offset.z).length() < 2.4:
			star.collect()
			collected_stars += 1
			star_collected.emit(collected_stars)
	if stage == traffic_index and not traffic_light.released:
		story_event.emit("traffic")
		if stopped_near_target():
			stop_time += delta
			if stop_time >= 1.0:
				traffic_light.release()
				stop_time = 0
				story_event.emit("green")
		else:
			stop_time = 0
		return
	if stage in stops and not stage in completed_stops:
		if stopped_near_target():
			stop_time += delta
			if stop_time >= 1.0:
				completed_stops.append(stage)
				stop_time = 0
				story_event.emit("parking")
		else:
			stop_time = 0
		return
	var previous := stage
	super._physics_process(delta)
	if stage != previous:
		if stage > points.size()/3:
			story_event.emit("midway")
		if stage == points.size()-1:
			story_event.emit("arrival")

func stopped_near_target() -> bool:
	var offset := vehicle.position - destination()
	return Vector2(offset.x, offset.z).length() < 5 and absf(vehicle.speed) < 0.4

func instructions() -> String:
	if stage == traffic_index and not traffic_light.released:
		return "ROSSO · Fermati al punto guida per un secondo"
	if stage in stops and not stage in completed_stops:
		return "SOSTA %d / 3 · Fermati nel punto guida" % (completed_stops.size()+1)
	if stage == points.size()-1:
		return "Sosta finale · Fermati nel cerchio azzurro"
	return super.instructions()
