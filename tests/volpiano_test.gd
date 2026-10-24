extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("OK: " + message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	root.add_child(main)
	await process_frame
	check(paused and main.hud.overlay.visible, "Menu Volpiano e pausa iniziale")
	main.start()
	await frames(60)
	check(main.vehicle.is_on_floor(), "Apollo sul terreno OSM")
	check(main.mission.points.size() > 4, "Percorso geografico caricato")
	var world: Node3D = main.world
	var trento_complete := true
	for road: Dictionary in world.data.roads:
		if road.name == "Via Trento":
			trento_complete = trento_complete and world.rendered_segments.get(str(road.id), 0) == road.points.size() - 1
			for xy: Array in road.points:
				trento_complete = trento_complete and world.map_bounds.grow(-40.0).has_point(world.point(xy))
	check(trento_complete, "Via Trento intera, tutti i segmenti renderizzati con margine dai limiti")
	var clip_bounds := AABB(Vector3.ZERO, Vector3(10, 10, 10))
	var clipped: PackedVector3Array = world.clip_road(Vector3(-5, 0, 5), Vector3(15, 0, 5), clip_bounds)
	check(clipped.size() == 2 and clipped[0].is_equal_approx(Vector3(0, 0, 5)) and clipped[1].is_equal_approx(Vector3(10, 0, 5)), "Segmento che attraversa la mappa conservato anche con estremi esterni")
	check(world.clip_road(Vector3(-5, 0, -1), Vector3(15, 0, -1), clip_bounds).is_empty(), "Segmenti interamente esterni esclusi")
	var origin: Vector3 = main.vehicle.position
	Input.action_press("accelerate")
	await frames(120)
	Input.action_release("accelerate")
	check(main.vehicle.position.distance_to(origin) > 8, "Partenza percorribile con fisica reale")
	# Seguire ogni segmento con input di guida e sterzo. Verifica collisioni lungo il percorso.
	main.start()
	var targets: Array[Vector3] = []
	if not "--visual-only" in OS.get_cmdline_user_args():
		targets.assign(main.mission.points)
	for target: Vector3 in targets:
		var target_radius := 0.9 if targets.find(target) < main.mission.departure_points else 2.0
		var offset: Vector3 = target - main.vehicle.position
		main.vehicle.rotation.y = atan2(-offset.x, -offset.z)
		var reached := false
		for step in 3600:
			var distance := Vector2(main.vehicle.position.x - target.x, main.vehicle.position.z - target.z).length()
			if distance < target_radius:
				reached = true
				break
			main.vehicle.max_speed = 3.0
			Input.action_press("accelerate")
			await physics_frame
		Input.action_release("accelerate")
		check(reached, "Segmento geografico raggiunto con guida fisica")
		if not reached:
			break
	main.vehicle.speed = 0
	Input.action_press("brake")
	await frames(90)
	Input.action_release("brake")
	if not targets.is_empty():
		check(main.mission.finished, "Percorso e parcheggio completati")
	main.start()
	main.vehicle.position += Vector3(250, 0, 0)
	await frames(2)
	check(main.vehicle.position.distance_to(main.vehicle.spawn_transform.origin) > 200, "Mappa estesa oltre il limite del circuito")
	main.vehicle.reset_vehicle()
	check(main.vehicle.position.distance_to(main.vehicle.spawn_transform.origin) < 0.1, "Reset alla partenza geografica")
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	if DisplayServer.get_name() != "headless":
		main.start()
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/verifica/volpiano.png")
		main.menu()
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/verifica/volpiano-menu.png")
	main.switch_environment()
	await process_frame
	await process_frame
	check(paused, "Ritorno al circuito e menu")
	for child in root.get_children():
		child.queue_free()
	await process_frame
	await process_frame
	# Il mixer rilascia i playback sul proprio thread, anche con frame headless accelerati.
	OS.delay_msec(100)
	print("ESITO VOLPIANO: %d errori" % failures)
	quit(0 if failures == 0 else 1)
