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
		["ingresso", Vector3(156, 2.4, 112), Vector3(215, 2.0, 119)],
		["meta", Vector3(235, 2.4, 121), Vector3(300, 2.0, 124)],
		["fondo", Vector3(300, 2.4, 124), Vector3(366, 2.2, 126)],
		["alto", Vector3(200, 55, 140), Vector3(250, 0, 120)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://build/verifica/pasubio-" + shot[0] + suffix + ".png")
		assert(result == OK)
	main.queue_free()
	await process_frame
	await process_frame
	print("Catture Via Trento da foto completate", suffix)
	quit()
