extends SceneTree
func _initialize() -> void:
	call_deferred("run")

func shot(name: String, delay: float = 0.6) -> void:
	await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var suffix := "-opengl" if RenderingServer.get_current_rendering_method() == "gl_compatibility" else ""
	assert(root.get_texture().get_image().save_png("res://build/verifica/casa-apollo-" + name + suffix + ".png") == OK)

func run() -> void:
	root.size = Vector2i(1600, 900)
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	root.add_child(main)
	if main.world.home == null:
		push_error("Cattura casa: configurazione locale richiesta, usare -- --with-home")
		quit(1)
		return
	var home: Node3D = main.world.home
	main.hud.hide()
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.fov = 70.0
	camera.current = true
	camera.position = home.to_global(Vector3(1, 2.8, -7.5))
	camera.look_at(home.to_global(Vector3(3.0, 3.3, 6.5)))
	await shot("cancello")
	main.start()
	main.vehicle.enabled = false
	main.hud.hide()
	camera.current = true
	await shot("cancello-aperto", 1.6)
	camera.current = false
	main.camera_rig.get_node("SpringArm3D/Camera3D").current = true
	await shot("partenza")
	camera.current = true
	camera.position = home.to_global(Vector3(-12, 7.2, -12))
	camera.look_at(home.to_global(Vector3(5, 3.5, 7)))
	await shot("casa")
	main.queue_free()
	await process_frame
	await process_frame
	print("Catture casa e partenza completate")
	quit()
