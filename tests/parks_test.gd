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

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/" + path + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	set_meta("apollo_park_rewards", [])
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/map/parks.json"))
	for park: Dictionary in catalog.parks:
		var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
		main.use_volpiano = true
		main.selected_park = park.id
		root.add_child(main)
		main.start()
		await frames(60)
		check(main.vehicle.is_on_floor(), str(park.name) + ": partenza sul terreno")
		check(main.world.playground.global_position.distance_to(main.world.geo(park.lat, park.lon)) < 0.01, str(park.name) + ": posizione geografica conservata")
		check(not main.world.playground.star.visible, "Stella nascosta prima della ricerca")
		var playground: Node3D = main.world.playground
		var fence_ray := PhysicsRayQueryParameters3D.create(playground.to_global(Vector3(10, 0.5, 0)), playground.to_global(Vector3(0, 0.5, 0)))
		var fence_hit: Dictionary = main.world.get_world_3d().direct_space_state.intersect_ray(fence_ray)
		check(not fence_hit.is_empty() and playground.is_ancestor_of(fence_hit.collider), "Il recinto ha collisioni che separano furgone e giochi")
		main.search_place(0)
		check(not main.park_found, "Nessuna raccolta durante la guida")
		var goal: Vector3 = main.mission.destination()
		var arrived := false
		if "--visual-only" in OS.get_cmdline_user_args():
			main.vehicle.position = goal
			arrived = true
		else:
			main.vehicle.max_speed = 3.5
			Input.action_press("accelerate")
			for step in 2400:
				if main.vehicle.position.distance_to(goal) < 3:
					arrived = true
					break
				await physics_frame
			Input.action_release("accelerate")
		check(arrived, str(park.name) + (": sosta preparata per la cattura" if "--visual-only" in OS.get_cmdline_user_args() else ": avvicinamento percorribile con fisica"))
		Input.action_press("brake")
		await frames(120)
		Input.action_release("brake")
		check(main.mission.finished and main.search_open and paused, "Sosta apre la ricerca, con Apollo fermo")
		if not main.search_open:
			main.queue_free()
			await process_frame
			continue
		await capture("fase4-" + str(park.id) + "-ricerca")
		var correct: int = main.world.playground.hiding_place
		var count: int = main.park_rewards().size()
		main.search_place((correct+1)%3)
		check(not main.park_found and main.park_rewards().size() == count, "Tentativo diverso consente di riprovare senza premi duplicati")
		# Azione reale del pulsante, verifica anche la mappatura dei tre nascondigli.
		(main.hud.content.get_child(3+correct) as Button).pressed.emit()
		check(main.park_found and main.world.playground.star.visible, "La scelta corretta rivela la stella nel parco")
		check(main.park_rewards().size() == count+1, "Stella e adesivo assegnati una sola volta")
		main.search_place(correct)
		check(main.park_rewards().size() == count+1, "Invio ripetuto non duplica la ricompensa")
		await capture("fase4-" + str(park.id) + "-premio")
		main.hud.hide()
		main.park_camera.h_offset = 0
		await capture("fase4-" + str(park.id))
		main.hud.show()
		main.start()
		check(not paused and not main.search_open and not main.world.playground.star.visible and main.vehicle.enabled, "Rigioca ripristina guida e nascondiglio")
		main.vehicle.position = main.mission.destination()
		await frames(90)
		main.search_place(correct)
		check(main.park_rewards().size() == count+1, "Rigiocare una gita già premiata non aumenta la raccolta")
		main.menu()
		main.hud.show_parks()
		await capture("fase4-collezione")
		# Il pulsante della prima gita deve caricare proprio Madonna delle Grazie.
		(main.hud.content.get_child(3) as Button).pressed.emit()
		await process_frame
		await process_frame
		var next: Node3D = root.get_child(root.get_child_count()-1)
		check(next.selected_park == "madonna" and next.park_rewards().size() == count+1, "Cambio gita dal menu conserva la raccolta della partita")
		next.queue_free()
		await process_frame
		await process_frame
	check(get_meta("apollo_park_rewards").size() == catalog.parks.size(), "Ogni parco assegna una stella distinta")
	OS.delay_msec(100)
	print("ESITO PARCHI: %d errori" % failures)
	quit(0 if failures == 0 else 1)
