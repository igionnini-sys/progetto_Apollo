extends SceneTree
## Viste riproducibili del primo tratto modellato dalle foto dell'utente.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Le catture richiedono il renderer reale")
		quit(1)
		return
	root.size = Vector2i(1600, 900)
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	root.add_child(main)
	main.start()
	main.vehicle.enabled = false
	main.hud.hide()
	var camera := Camera3D.new()
	main.add_child(camera)
	camera.current = true
	camera.fov = 68.0
	camera.far = 1800.0
	var suffix := "-opengl" if RenderingServer.get_current_rendering_method() == "gl_compatibility" else ""
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	for shot in [
		["ponte-nord", Vector3(147, 2.7, -39), Vector3(141, 2.4, -115)],
		["palazzina-sud", Vector3(148, 2.7, -55), Vector3(158, 5.4, -7)],
		["strada-nord", Vector3(154, 2.6, 38), Vector3(148, 2.3, -40)],
		["panoramica", Vector3(96, 48, 30), Vector3(151, 0, -67)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://build/verifica/trento-foto-" + shot[0] + suffix + ".png")
		assert(result == OK)
	main.queue_free()
	await process_frame
	await process_frame
	print("Catture Via Trento da foto completate", suffix)
	quit()
