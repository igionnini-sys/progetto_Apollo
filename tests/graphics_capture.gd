extends SceneTree
## Confronto riproducibile dello stile con renderer reale e salvataggi in memoria.

func _initialize() -> void:
	call_deferred("run")

func shot(filename: String) -> void:
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png("res://build/verifica/stile-" + filename + ".png")
	assert(result == OK, "Cattura grafica non salvata")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Le catture richiedono il renderer reale.")
		quit(1)
		return
	root.size = Vector2i(1600, 900)
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var suffix := "prima" if "--before" in OS.get_cmdline_user_args() else "dopo"
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		suffix += "-opengl"
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	root.add_child(main)
	main.start()
	main.vehicle.enabled = false
	await shot("guida-" + suffix)
	main.hud.hide()
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.current = true
	camera.fov = 62.0
	camera.far = 1600.0
	# Stessa strada e stesso Apollo: vista bassa per valutare materiali e facciate.
	camera.position = main.vehicle.position + Basis(Vector3.UP, main.vehicle.rotation.y) * Vector3(-3.2, 2.8, -8.0)
	camera.look_at(main.vehicle.position + Vector3.UP * 2.6)
	await shot("strada-" + suffix)
	camera.position = main.vehicle.position + Basis(Vector3.UP, main.vehicle.rotation.y) * Vector3(-4.2, 2.65, -7.5)
	camera.look_at(main.vehicle.position + Vector3.UP * 1.5)
	camera.fov = 48.0
	camera.h_offset = -0.5
	await shot("apollo-dettagli-" + suffix)
	main.vehicle.lights_on = true
	await shot("apollo-fari-" + suffix)
	main.vehicle.lights_on = false
	# Dettaglio di un ingresso vicino alla partenza, dal lato esterno della facciata.
	var portals: Array[Transform3D] = main.world.town.entrances
	if not portals.is_empty():
		var nearest := INF
		var frame := Transform3D.IDENTITY
		for candidate: Transform3D in portals:
			var distance := candidate.origin.distance_squared_to(main.vehicle.global_position)
			if distance < nearest:
				nearest = distance
				frame = candidate
		var outward := frame.basis.z.normalized()
		var ray := PhysicsRayQueryParameters3D.create(frame.origin, frame.origin + outward * 0.6)
		if not main.world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			outward = -outward
		camera.position = frame.origin + outward * 5.0 + frame.basis.x.normalized() * 2.0 + Vector3.UP
		camera.look_at(frame.origin + Vector3.UP * 0.9)
		camera.fov = 58.0
		camera.h_offset = 0.0
		await shot("facciate-" + suffix)
	camera.fov = 62.0
	camera.h_offset = 0.0
	camera.position = Vector3(100, 65, -200)
	camera.look_at(Vector3(280, 0, -300))
	await shot("panorama-" + suffix)
	# Intera Via Trento, comprese le porzioni che prima venivano eliminate dal diorama.
	var north := INF
	var south := -INF
	for road: Dictionary in main.world.data.roads:
		if road.name != "Via Trento":
			continue
		for xy: Array in road.points:
			north = minf(north, float(xy[1]))
			south = maxf(south, float(xy[1]))
	camera.far = 3000.0
	camera.position = Vector3(-400, 900, (north + south) * 0.5 + 450)
	camera.look_at(Vector3(135, 0, (north + south) * 0.5))
	# La vista tecnica dall'alto deve mostrare i limiti, senza foschia a 1 km di quota.
	main.environment.fog_enabled = false
	await shot("via-trento-intera-" + suffix)
	main.environment.fog_enabled = true
	for z in [380.0, 850.0]:
		var nearest := INF
		var street_point := Vector3.ZERO
		for road: Dictionary in main.world.data.roads:
			if road.name != "Via Trento":
				continue
			for i in range(road.points.size() - 1):
				var a := Vector2(road.points[i][0], road.points[i][1])
				var b := Vector2(road.points[i + 1][0], road.points[i + 1][1])
				var p := Geometry2D.get_closest_point_to_segment(Vector2(140, z), a, b)
				if p.distance_squared_to(Vector2(140, z)) < nearest:
					nearest = p.distance_squared_to(Vector2(140, z))
					street_point = Vector3(p.x, 0, p.y)
		camera.position = street_point + Vector3(0, 2.4, 8)
		camera.look_at(street_point + Vector3(0, 1.8, -35))
		await shot("via-trento-%d-" % int(z) + suffix)
	main.queue_free()
	await process_frame
	await process_frame
	print("Catture stile salvate: ", suffix)
	quit()
