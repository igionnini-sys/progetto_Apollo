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
		["sp3", Vector3(352, 2.4, 414), Vector3(385, 1.8, 345)],
		["sud", Vector3(430, 2.4, 245), Vector3(470, 1.8, 175)],
		["centro", Vector3(505, 2.4, 95), Vector3(540, 1.8, 20)],
		["scuola", Vector3(585, 3.0, -70), Vector3(630, 1.5, -150)],
		["parcheggio", Vector3(600, 9.0, -80), Vector3(640, 0.5, -120)],
		["alto", Vector3(560, 90, 40), Vector3(520, 0, 30)]]:
		camera.position = shot[1]
		camera.look_at(shot[2])
		await create_timer(0.7).timeout
		await RenderingServer.frame_post_draw
		var result := root.get_texture().get_image().save_png("res://build/verifica/trieste-" + shot[0] + suffix + ".png")
		assert(result == OK)
	main.queue_free()
	await process_frame
	await process_frame
	print("Catture Via Trento da foto completate", suffix)
	quit()
