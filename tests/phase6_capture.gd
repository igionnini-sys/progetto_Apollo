extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(filename: String) -> void:
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/fase6-" + filename + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await shot("menu")
	main.hud.show_settings()
	await shot("impostazioni")
	main.hud.show_collection()
	await shot("collezione")
	for i in range(3):
		main.show_garage(i)
		await shot("ducato-" + str(i))
	main.selected_story = "school"
	# La cabina può essere verificata anche nel circuito senza avviare una missione.
	main.close_garage()
	main.show_cabin()
	main.hud.overlay.hide()
	await shot("cabina")
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	quit()
