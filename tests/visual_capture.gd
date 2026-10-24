extends SceneTree
## Cattura con renderer reale, non headless. Artefatti locali esclusi da git.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	root.get_texture().get_image().save_png("res://build/verifica/menu.png")
	main.start()
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/verifica/guida.png")
	print("Catture salvate in build/verifica")
	quit()
