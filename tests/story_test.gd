extends SceneTree
const Family = preload("res://scripts/characters/family_profile.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
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
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/" + path + ".png")

func next_line(main: Node3D) -> void:
	(main.hud.content.get_child(3) as Button).pressed.emit()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var family_file := "user://apollo_test_family.json"
	var file := FileAccess.open(family_file, FileAccess.WRITE)
	file.store_string('{"granddaughter":{"name":"Luna","shirt":"f0be69","hair":"colore non valido"}}')
	file.close()
	var family := Family.load_profile(family_file)
	check(family.granddaughter.name == "Luna" and family.granddaughter.shirt == "f0be69" and family.granddaughter.hair == "795b48", "Configurazione personaggi parziale e colori invalidi gestiti")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(family_file))
	set_meta("apollo_story_rewards", [])
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	main.selected_story = "school"
	root.add_child(main)
	main.visit_story("parking")
	check(not main.is_queued_for_deletion(), "Sfida parcheggio bloccata prima di completare la storia")
	main.start()
	check(paused and not main.vehicle.enabled and not main.mission.active, "Introduzione ferma Apollo e la missione")
	var origin: Vector3 = main.vehicle.position
	Input.action_press("accelerate")
	await frames(30)
	Input.action_release("accelerate")
	check(main.vehicle.position.is_equal_approx(origin), "Accelerazione durante il dialogo non muove il mezzo")
	main.toggle_pause()
	check(paused and main.story_state == "intro", "Esc non aggira l'introduzione")
	check(main.vehicle.visual.passengers.size() == 2, "Due personaggi seduti modulari")
	for passenger: Node3D in main.vehicle.visual.passengers:
		check(passenger.get_node("CinturaDiagonale").visible and passenger.get_node("CinturaAddominale").visible, "Cintura diagonale e addominale presenti")
	await capture("fase5-introduzione")
	var first_line: String = main.dialogue.current_text
	next_line(main)
	check(main.dialogue.current_text != first_line and main.dialogue.index == 1, "Avanti cambia interlocutore e battuta")
	main.menu()
	main.start()
	check(main.dialogue.index == 0 and main.story_state == "intro", "Abbandono e riavvio ripartono dall'introduzione")
	while main.story_state == "intro":
		next_line(main)
	check(not paused and main.vehicle.enabled and main.mission.active and main.story_state == "driving", "Fine introduzione attiva la guida")
	main.toggle_pause()
	check(paused, "Pausa disponibile durante la storia")
	main.resume_game()
	check(not paused, "Ripresa della guida narrativa")
	# Percorrenza di tutti i segmenti con input fisico; orientamento impostato alle giunzioni.
	for i in main.mission.points.size():
		var target_radius := 0.9 if i < main.mission.departure_points else 1.5
		var target: Vector3 = main.mission.points[i]
		var offset: Vector3 = target - main.vehicle.position
		main.vehicle.rotation.y = atan2(-offset.x, -offset.z)
		var reached := false
		if "--visual-only" in OS.get_cmdline_user_args():
			var start: Vector3 = main.vehicle.position
			var steps := maxi(1, ceili(start.distance_to(target)/2.0))
			for step in range(1, steps+1):
				main.vehicle.position = start.lerp(target, float(step)/steps)
				await physics_frame
			reached = true
		else:
			main.vehicle.max_speed = 3.0
			Input.action_press("accelerate")
			for step in maxi(3600, ceili(offset.length() / 3.0 * 75.0)):
				if Vector2(main.vehicle.position.x-target.x, main.vehicle.position.z-target.z).length() < target_radius:
					reached = true
					break
				await physics_frame
			Input.action_release("accelerate")
		check(reached, "Segmento narrativo %d raggiunto" % (i+1))
		if not reached:
			break
		if i == main.mission.traffic_index:
			check(not main.world.story_traffic.released, "Semaforo ancora rosso prima della sosta")
			Input.action_press("brake")
			await frames(30)
			check(not main.world.story_traffic.released, "Mezzo secondo non basta per il verde")
			await frames(70)
			Input.action_release("brake")
			check(main.world.story_traffic.released, "Sosta completa sblocca il verde")
			await capture("fase5-semaforo")
	Input.action_press("brake")
	await frames(100)
	Input.action_release("brake")
	check(main.mission.finished and main.story_state == "ending" and paused, "Arresto finale apre l'epilogo")
	check(main.mission.collected_stars == 3, "Tre stelle raccolte lungo la strada senza uscire dal percorso")
	await capture("fase5-arrivo")
	for i in 3:
		next_line(main)
	check(main.story_state == "complete" and "school" in get_meta("apollo_story_rewards", []), "Epilogo assegna medaglia e sblocca sfida")
	await capture("fase5-completamento")
	main.start()
	check(main.mission.collected_stars == 0 and not main.world.story_traffic.released and main.story_state == "intro", "Nuovo viaggio azzera stelle e semaforo")
	# La sfida viene attivata attraverso il pulsante presente nella schermata storie.
	main.menu()
	main.hud.show_stories()
	(main.hud.content.get_child(4) as Button).pressed.emit()
	await process_frame
	await process_frame
	main = root.get_child(root.get_child_count()-1)
	check(main.selected_story == "parking", "Menu sblocca e carica Il Parcheggio Perfetto")
	main.start()
	for i in 3:
		next_line(main)
	# Stati della sfida: preparazione delle soste, non secondo test completo di guida.
	for i in main.mission.points.size():
		main.vehicle.position = main.mission.points[i]
		main.vehicle.speed = 0
		await frames(125)
	check(main.mission.completed_stops.size() == 2 and main.mission.finished, "Sfida richiede due soste intermedie e parcheggio finale")
	for i in 2:
		next_line(main)
	check("parking" in get_meta("apollo_story_rewards", []), "Sfida assegna la medaglia Pilota gentile")
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	print("ESITO STORIA: %d controlli, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
