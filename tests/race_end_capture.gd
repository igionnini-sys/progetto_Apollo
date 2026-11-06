extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1600, 900)
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	main.selected_race = "level2_race"
	root.add_child(main)
	for i in 20:
		await physics_frame
	while main.story_state == "intro":
		main.dialogue.advance()
	var spot: Dictionary = main.mission.track.sample(850.0)
	main.vehicle.global_position = spot["position"] + Vector3.UP * 0.15
	main.vehicle.look_at(main.vehicle.global_position + spot["direction"], Vector3.UP)
	main.camera_rig.snap()
	for i in 40:
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/gara-finale-strada.png")
	quit(0)
