extends SceneTree
## Catture di Gino in studio (renderer reale) e controllo di costruzione.
var camera: Camera3D

func _initialize() -> void:
	call_deferred("run")

func shot(name: String, location: Vector3, target: Vector3, fov: float = 40.0) -> void:
	camera.position = location
	camera.look_at(target)
	camera.fov = fov
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/gino-" + name + ".png")

func run() -> void:
	root.size = Vector2i(1400, 900)
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var studio := Node3D.new()
	root.add_child(studio)
	var gino := Node3D.new()
	gino.set_script(load("res://scripts/vehicles/gino_fiorino.gd"))
	studio.add_child(gino)
	camera = Camera3D.new()
	studio.add_child(camera)
	camera.current = true
	preload("res://scripts/vehicles/vehicle_studio.gd").setup(studio, camera)
	await shot("anteriore", Vector3(-4.2, 2.2, -5.2), Vector3(0, 1.0, 0))
	await shot("fianco", Vector3(6.5, 1.6, 0), Vector3(0, 1.0, 0), 38.0)
	await shot("posteriore", Vector3(4.2, 2.4, 5.4), Vector3(0, 1.0, 0.3))
	await shot("frontale", Vector3(0, 1.3, -5.0), Vector3(0, 0.95, -1.0), 36.0)
	await shot("tre-quarti-basso", Vector3(-3.4, 0.9, -3.6), Vector3(0, 0.9, 0.0), 40.0)
	print("Gino costruito: %d ruote" % gino.wheels.size())
	quit(0 if gino.wheels.size() == 4 else 1)
