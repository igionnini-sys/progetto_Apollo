extends SceneTree
## Test integrato con fisica reale e input sintetici, senza UI manuale.
var failures: Array[String] = []
var main: Node3D
var car: CharacterBody3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)
	else:
		print("OK: " + message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	main.start()
	car = main.vehicle
	await frames(60)
	check(car.is_on_floor(), "Apollo poggia sul terreno")
	check(car.get_node("Visual").wheels.size() == 4, "Quattro ruote presenti")
	var start := car.position
	Input.action_press("accelerate")
	await frames(120)
	Input.action_release("accelerate")
	check(car.speed > 8.0 and car.position.distance_to(start) > 8.0, "Accelerazione e movimento")
	Input.action_press("brake")
	await frames(90)
	Input.action_release("brake")
	check(absf(car.speed) < 0.1, "Frenata fino all'arresto")
	Input.action_press("reverse")
	await frames(90)
	Input.action_release("reverse")
	check(car.speed < -3.0, "Retromarcia")
	car.reset_vehicle()
	var heading := car.rotation.y
	Input.action_press("accelerate")
	Input.action_press("left")
	await frames(90)
	Input.action_release("left")
	Input.action_release("accelerate")
	check(absf(angle_difference(heading, car.rotation.y)) > 0.2, "Sterzata")
	car.reset_vehicle()
	Input.action_press("accelerate")
	await frames(240)
	Input.action_release("accelerate")
	check(car.speed <= car.max_speed + 0.01, "Limite di velocità")
	car.position = Vector3(110, 0.1, 12)
	car.rotation = Vector3.ZERO
	car.speed = 0.0
	Input.action_press("accelerate")
	await frames(180)
	Input.action_release("accelerate")
	check(car.position.z > 4.8, "Collisione contro ostacolo: nessun attraversamento")
	car.position.y = -10.0
	await frames(4)
	check(car.position.distance_to(car.spawn_transform.origin) < 1.0, "Recupero automatico sotto terreno")
	car.reset_vehicle()
	await frames(60)
	check(absf(car.speed) < 0.01 and car.is_on_floor(), "Reset sicuro e riappoggio a terra")
	check(main.camera_rig.global_position.distance_to(car.global_position) < 5.0, "Telecamera segue il riposizionamento")
	var arm: SpringArm3D = main.camera_rig.arm
	var blocker := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4, 4, 0.7)
	shape.shape = box
	blocker.add_child(shape)
	main.add_child(blocker)
	blocker.global_transform = arm.global_transform
	blocker.global_position += arm.global_basis.z * 4.0
	await frames(10)
	check(arm.get_hit_length() < 5.0, "SpringArm evita un ostacolo dietro Apollo")
	blocker.queue_free()
	main.toggle_pause()
	check(paused and main.hud.overlay.visible, "Pausa e pannello visibile")
	var parked_position := car.position
	Input.action_press("accelerate")
	await frames(30)
	Input.action_release("accelerate")
	check(car.position.is_equal_approx(parked_position), "Pausa ferma effettivamente la fisica")
	main.resume_game()
	check(not paused and not main.hud.overlay.visible, "Ripresa dalla pausa")
	main.mission.active = true
	main.mission.restart()
	for target in main.mission.points:
		car.position = target + Vector3.UP * 0.1
		car.speed = 0.0
		await frames(4)
	await frames(90)
	check(main.mission.finished, "Quattro tappe e parcheggio completano la prova")
	check(paused and main.hud.overlay.visible, "Schermata di completamento")
	main.start()
	check(not paused and not main.mission.finished and main.mission.stage == 0, "Nuovo giro azzera la prova")
	print("ESITO: %d errori" % failures.size())
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	quit(0 if failures.is_empty() else 1)
