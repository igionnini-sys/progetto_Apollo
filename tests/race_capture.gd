extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1600, 900)
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	main.selected_race = "level2_race"
	root.add_child(main)
	for i in 60:
		await physics_frame
	await shot("gara-partenza")
	for i in 130:
		await physics_frame
	Input.action_press("accelerate")
	for i in 60:
		await physics_frame
	await shot("gara-lanciata")
	var pad: Dictionary = main.mission.pads[1]
	var here: Dictionary = main.mission.track.sample(pad.distance - 22.0)
	main.vehicle.global_position = here["position"] + Vector3.UP * 0.15
	main.vehicle.look_at(main.vehicle.global_position + here["direction"], Vector3.UP)
	main.vehicle.speed = 15.0
	main.mission.player_distance = pad.distance - 22.0
	for i in 40:
		await physics_frame
	await shot("gara-striscia")
	for i in 40:
		await physics_frame
	await shot("gara-turbo")
	Input.action_release("accelerate")
	var tool_pad: Node3D = main.mission.items.pickups[0]
	var spot: Dictionary = main.mission.track.sample(tool_pad.distance - 14.0)
	main.vehicle.global_position = spot["position"] + Vector3.UP * 0.15
	main.vehicle.look_at(main.vehicle.global_position + spot["direction"], Vector3.UP)
	main.vehicle.speed = 0.0
	main.mission.player_distance = tool_pad.distance - 14.0
	main.mission.rival.distance = tool_pad.distance + 6.0
	main.mission.items.launch("gino", "pomodoro", tool_pad.distance - 20.0, -1.0, 8.0)
	for i in 20:
		await physics_frame
	await shot("gara-oggetti")
	quit(0)
