extends SceneTree
## Catture effettive del modello in studio, senza mondo o salvataggi personali.
var camera: Camera3D
var visual: Node3D

func _initialize() -> void:
	call_deferred("run")

func shot(name: String, location: Vector3, target: Vector3, fov: float = 40.0) -> void:
	camera.position = location
	camera.look_at(target)
	camera.fov = fov
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var suffix := "-opengl" if RenderingServer.get_current_rendering_method() == "gl_compatibility" else ""
	assert(root.get_texture().get_image().save_png("res://build/verifica/apollo-realistico-" + name + suffix + ".png") == OK)

func run() -> void:
	assert(DisplayServer.get_name() != "headless", "Usare il renderer reale per le catture")
	root.size = Vector2i(1600, 1000)
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var studio := Node3D.new()
	root.add_child(studio)
	visual = Node3D.new()
	visual.set_script(load("res://scripts/vehicles/apollo_visual.gd"))
	studio.add_child(visual)
	camera = Camera3D.new()
	studio.add_child(camera)
	camera.current = true
	preload("res://scripts/vehicles/vehicle_studio.gd").setup(studio, camera)
	await shot("anteriore", Vector3(-6.0, 3.0, -7.8), Vector3(0, 1.15, 0))
	await shot("frontale", Vector3(0, 1.60, -6.8), Vector3(0, 1.35, -1.0), 38.0)
	await shot("fianco", Vector3(8.8, 2.5, 0.2), Vector3(0, 1.2, 0), 42.0)
	await shot("posteriore", Vector3(6.0, 3.0, 7.8), Vector3(0, 1.15, 0))
	await shot("retro-dritto", Vector3(0, 1.65, 7.8), Vector3(0, 1.40, 2.5), 34.0)
	await shot("retro-dettaglio", Vector3(-2.7, 1.85, 5.8), Vector3(-0.15, 1.35, 2.5), 38.0)
	await shot("ottiche", Vector3(-1.6, 1.45, -4.35), Vector3(-0.15, 1.0, -2.5), 43.0)
	visual.animate(0.0, 0.0, 0.0, true, true)
	await shot("retro-frenata", Vector3(0, 1.65, 7.8), Vector3(0, 1.40, 2.5), 34.0)
	await shot("fari-accesi", Vector3(-6.0, 3.0, -7.8), Vector3(0, 1.15, 0))
	# Stesso muso con luce bassa: controlla ottiche, emissione e fasci sulla pavimentazione.
	for node in studio.get_children():
		if node is Light3D:
			node.light_energy *= 0.06
	camera.environment.ambient_light_energy = 0.055
	camera.environment.background_color = Color("19212b")
	camera.environment.background_energy_multiplier = 0.20
	visual.animate(0.0, 0.0, 0.0, false, false)
	await shot("notte-spenti", Vector3(-1.6, 1.45, -4.35), Vector3(-0.15, 1.0, -2.5), 43.0)
	visual.animate(0.0, 0.0, 0.0, false, true)
	await shot("notte-accesi", Vector3(-1.6, 1.45, -4.35), Vector3(-0.15, 1.0, -2.5), 43.0)
	studio.queue_free()
	for i in 4:
		await process_frame
	print("Catture studio Apollo completate")
	quit()
