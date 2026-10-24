extends SceneTree
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: " + message)
	else:
		failures += 1
		push_error(message)

func run() -> void:
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	root.add_child(main)
	main.start()
	await physics_frame
	var world: Node3D = main.get_node("VolpianoOSM")
	var stats: Dictionary = world.town_stats
	print("CITTA: ", stats)
	check(stats.buildings > 50 and stats.windows > 100, "Facciate generate sulle impronte OSM")
	check(stats.landmarks == 3, "Municipio, chiesa e plesso scolastico nelle impronte reali")
	check(stats.trees > 0 and stats.lamps > 0 and stats.benches > 0, "Verde e arredi cittadini presenti")
	check(stats.crossings > 0, "Attraversamenti derivati dai punti OSM")
	check(stats.signals == 2 and stats.cars > 0 and stats.street_signs > 0, "Semafori mappati, auto ferme e targhe stradali")
	check(stats.batches < 80 and stats.instances > stats.batches * 10, "Dettagli ripetuti raggruppati con MultiMesh")
	check(not world.town.clear_position(main.vehicle.position, 1.0), "Esclusione decorazioni dalla carreggiata")
	# L'indice spaziale deve conservare i risultati della ricerca completa, anche ai bordi delle celle.
	var index: Dictionary = world.town.road_index
	var probes: Array = []
	var indexed: Array = []
	var random := RandomNumberGenerator.new()
	random.seed = 20261018
	for i in 80:
		var pos: Vector3 = main.vehicle.position + Vector3(random.randf_range(-160, 160), 0, random.randf_range(-160, 160))
		if i % 3 == 0:
			pos.x = floorf(pos.x / 32.0) * 32.0
		var radius: float = [0.12, 1.1, 3.9, 4.1][i % 4]
		probes.append([pos, radius])
		indexed.append([world.town.clear_position(pos, radius), world.town.faces_street(pos, Vector3.RIGHT), world.town.faces_street(pos, Vector3.FORWARD)])
	world.town.road_index = {}
	var equivalent := true
	for i in probes.size():
		var pos: Vector3 = probes[i][0]
		var radius: float = probes[i][1]
		var full := [world.town.clear_position(pos, radius), world.town.faces_street(pos, Vector3.RIGHT), world.town.faces_street(pos, Vector3.FORWARD)]
		equivalent = equivalent and full == indexed[i]
	world.town.road_index = index
	check(equivalent, "Indice spaziale equivalente alla ricerca completa per arredi e facciate")
	check(world.get_node("MunicipioVolpiano").position.distance_to(world.geo(45.201835, 7.775600)) < 0.01, "Municipio conserva coordinate geografiche")
	check(world.get_node("ChiesaSantiPietroPaolo").position.distance_to(world.geo(45.201633, 7.775481)) < 0.01, "Chiesa conserva coordinate geografiche")
	check(world.get_node("PlessoViaTrieste").position.distance_to(world.geo(45.1993144, 7.781281)) < 0.01, "Plesso sul punto mappa della scuola, senza attivare accesso carrabile")
	await physics_frame
	var parked: Vector3 = world.town.parked_colliders[0][0]
	var ray := PhysicsRayQueryParameters3D.create(parked + Vector3.UP * 3, parked + Vector3.UP * 1.2)
	var hit: Dictionary = world.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and float(hit.position.y) > 1.3, "Le auto ferme sono rilevate dalle collisioni fisiche")
	if DisplayServer.get_name() != "headless":
		DirAccess.make_dir_recursive_absolute("res://build/verifica")
		await create_timer(1.0).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/verifica/fase3-guida.png")
		main.hud.hide()
		main.vehicle.enabled = false
		var camera := Camera3D.new()
		main.add_child(camera)
		camera.current = true
		camera.far = 1500
		for shot in [
			["panorama", Vector3(100, 65, -200), Vector3(280, 0, -300)],
			["chiesa", Vector3(174, 9, -402), Vector3(195, 7, -402)],
			["municipio", Vector3(205, 10, -402), Vector3(204, 4, -430)],
			["scuola", Vector3(605, 25, -145), Vector3(680, 0, -135)]]:
			camera.position = shot[1]
			camera.look_at(shot[2])
			await create_timer(0.4).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/verifica/fase3-%s.png" % shot[0])
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	print("ESITO CITTA: %d errori" % failures)
	quit(0 if failures == 0 else 1)
