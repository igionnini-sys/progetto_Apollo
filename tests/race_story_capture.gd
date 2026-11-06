extends SceneTree
## Catture della presentazione di Gino e della schermata finale.
func _initialize() -> void:
	call_deferred("run")
func shot(name: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1600, 900)
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	main.selected_race = "level2_race"
	root.add_child(main)
	for i in 30:
		await process_frame
	await shot("gara-presentazione")
	main.dialogue.advance()
	main.dialogue.advance()
	await create_timer(5.0).timeout
	await shot("gara-presentazione-2")
	while main.story_state == "intro":
		main.dialogue.advance()
	while main.mission.countdown > 0.0:
		await physics_frame
	var end: Dictionary = main.mission.track.sample(main.mission.track.length - 1.0)
	main.vehicle.global_position = end["position"] + Vector3.UP * 0.15
	main.mission.player_distance = main.mission.track.length - 1.0
	main.vehicle.global_position = end["position"] + Vector3.UP * 0.15
	main.mission.race_time = 71.4
	main.mission.player_won = true
	main.mission.finished = true
	main.finish()
	await shot("gara-risultato")
	quit(0)
