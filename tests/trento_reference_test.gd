extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		failures += 1
		push_error(message)

func run() -> void:
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	root.add_child(main)
	main.start()
	main.mission.active = false
	var world: Node3D = main.world
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map/volpiano.json"))
	check(world.data.nodes == source.nodes and world.data.route == source.route and world.data.buildings == source.buildings, "Rifinitura fotografica conserva impronte, nodi e rotta OSM")
	check(world.trento.stats.photo_facades >= 8 and world.trento.stats.bridge_rails == 2, "Facciate dalle foto e due parapetti del ponte presenti")
	check(world.has_node("AutobloccantiViaTrento") and world.has_node("AsfaltoViaTrento"), "Via Trento usa superfici dedicate senza modificare il circuito")
	check(world.trento.stats.lamps > 0 and world.trento.stats.signs == 2, "Lampioni e segnaletica del riferimento presenti")
	await physics_frame
	# Il nuovo volume alto deve avere collisioni fino all'altezza della facciata.
	for building: Dictionary in world.data.buildings:
		if int(building.id) != 904091086:
			continue
		var a: Vector3 = world.point(building.outline[0], 13.7)
		var b: Vector3 = world.point(building.outline[1], 13.7)
		var tangent := (b - a).normalized()
		var normal := Vector3(tangent.z, 0, -tangent.x)
		var middle := (a + b) * 0.5
		var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(middle + normal, middle - normal))
		check(not hit.is_empty() and hit.collider.name == "EdificiCollisione", "Collider della palazzina coincide con la nuova facciata alta")
	var targets: Array[Vector3] = []
	for road: Dictionary in world.data.roads:
		if road.name != "Via Trento" or road.get("highway", "") != "tertiary":
			continue
		for xy: Array in road.points:
			if float(xy[1]) >= -158.0 and float(xy[1]) <= 32.0:
				var p: Vector3 = world.point(xy)
				if not targets.has(p):
					targets.append(p)
	targets.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.z > b.z)
	main.vehicle.position = targets[0] + Vector3.UP * 0.15
	main.vehicle.speed = 0.0
	main.vehicle.velocity = Vector3.ZERO
	main.vehicle.max_speed = 3.0
	for i in 60:
		await physics_frame
	var all_reached := true
	for target in targets.slice(1):
		var offset: Vector3 = target - main.vehicle.position
		main.vehicle.rotation.y = atan2(-offset.x, -offset.z)
		var reached := false
		Input.action_press("accelerate")
		for step in 3600:
			if Vector2(main.vehicle.position.x - target.x, main.vehicle.position.z - target.z).length() < 1.3:
				reached = true
				break
			await physics_frame
		Input.action_release("accelerate")
		all_reached = all_reached and reached
		if not reached:
			break
	check(all_reached, "Tratto fotografico attraversato con guida fisica, fra auto ferme e ponte")
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	print("ESITO VIA TRENTO FOTO: %d errori" % failures)
	quit(0 if failures == 0 else 1)
