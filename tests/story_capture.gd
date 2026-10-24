extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func shot(name: String) -> void:
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/fase5-" + name + ".png")

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	main.selected_story = "school"
	root.add_child(main)
	await shot("menu")
	main.start()
	await shot("introduzione")
	main.menu()
	main.hud.show_stories()
	await shot("storie")
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	quit()
