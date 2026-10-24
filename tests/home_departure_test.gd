extends SceneTree
const Home = preload("res://scripts/environment/home_departure.gd")
const G = preload("res://scripts/utilities/geometry.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	# Raccordo sintetico senza posizione o civico personali nel test distribuito.
	var data := {"metadata": {}, "nodes": {"a": [0, 0], "b": [0, -20], "c": [0, -40]}, "edges": [["a", "b"], ["b", "c"]], "route": ["b", "c"], "roads": [{"name": "Via Trento", "drivable": true, "points": [[0, 0], [0, -40]]}, {"name": "Incrocio test", "points": [[10, 0], [0, 0]]}]}
	var config := Home.resolve(data, {"corner_street": "Incrocio test", "gate_offset_from_corner": [6, 0], "public_join_node": "a", "yaw_degrees": 90})
	check(not config.is_empty() and Home.attach_route(data, config), "Partenza locale raccordata al grafo pubblico")
	check(data.route[0] == "home_spawn" and data.route[-1] == "c" and data.nodes.home_spawn[0] > config.origin[0], "Apollo parte dentro il cortile mantenendo la destinazione")
	check(Home.path_to(data, "c", "a").is_empty(), "Il raccordo pubblico rispetta gli archi diretti")
	load("res://scripts/utilities/controls.gd").setup()
	var scene := Node3D.new()
	root.add_child(scene)
	G.box(scene, Vector3(0, -0.6, 0), Vector3(100, 1, 100), Color.GRAY, true)
	var home := Home.new()
	home.automatic = false
	scene.add_child(home)
	var vehicle: CharacterBody3D = load("res://scenes/vehicles/apollo.tscn").instantiate()
	vehicle.position = Vector3(0, 0.15, 7)
	vehicle.enabled = false
	scene.add_child(vehicle)
	home.vehicle = vehicle
	await frames(30)
	var space := scene.get_world_3d().direct_space_state
	var closed := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0.4, 1, 2), Vector3(0.4, 1, -2)))
	check(not closed.is_empty() and closed.collider is AnimatableBody3D, "Le ante chiuse hanno collisioni reali")
	home.automatic = true
	await frames(95)
	var opened := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0.4, 1, 2), Vector3(0.4, 1, -2)))
	check(home.opening > 0.99 and opened.is_empty(), "Il cancello si apre automaticamente e libera il varco")
	vehicle.enabled = true
	Input.action_press("accelerate")
	await frames(160)
	Input.action_release("accelerate")
	check(vehicle.position.z < -4.0 and vehicle.is_on_floor(), "Apollo esce dal cortile guidando fra i pilastri")
	vehicle.reset_vehicle()
	check(vehicle.position.distance_to(Vector3(0, 0.15, 7)) < 0.1, "Reset alla partenza dentro casa")
	scene.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	print("ESITO CASA APOLLO: %d errori" % failures)
	quit(0 if failures == 0 else 1)
