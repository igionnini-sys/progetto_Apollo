extends SceneTree
## Eseguire prima con -- --write-fixture, poi senza: due processi indipendenti.
const Store = preload("res://scripts/utilities/save_store.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var store := Store.new()
	store.path = "res://build/verifica/process-save-fixture.json"
	if "--write-fixture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://build/verifica")
		store.parks = ["madonna", "san_grato"]
		store.stories = ["school", "parking"]
		store.settings.gentle = true
		var success := store.save()
		print("SCRITTURA PROCESSO: ", success)
		quit(0 if success else 1)
		return
	store.restore()
	var valid: bool = store.parks.size() == 2 and store.stories.size() == 2 and store.settings.gentle
	set_meta("apollo_save_store", store)
	set_meta("apollo_park_rewards", store.parks.duplicate())
	set_meta("apollo_story_rewards", store.stories.duplicate())
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	valid = valid and main.park_rewards().size() == 2 and main.vehicle.max_speed == 10.0
	main.visit_story("parking")
	await process_frame
	await process_frame
	var next: Node3D = root.get_child(root.get_child_count() - 1)
	valid = valid and next.selected_story == "parking" and next.vehicle.max_speed == 10.0
	for child in root.get_children():
		child.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(store.path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path + suffix))
	print("RIAVVIO PROCESSO, PREMI E SFIDA: ", valid)
	quit(0 if valid else 1)
