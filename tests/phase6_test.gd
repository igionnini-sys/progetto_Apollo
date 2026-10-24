extends SceneTree
const Store = preload("res://scripts/utilities/save_store.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("OK: " + message)
	else:
		failures += 1
		push_error(message)

func write_text(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var filename := "res://build/verifica/phase6-test-save.json"
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(filename + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(filename + suffix))
	var store := Store.new()
	store.path = filename
	store.restore()
	check(store.settings == Store.DEFAULTS and store.parks.is_empty(), "Primo avvio senza file: impostazioni predefinite")
	store.parks = ["madonna"]
	store.stories = ["school"]
	store.settings.gentle = true
	store.journey_stars.school = 3
	check(store.save(), "Prima scrittura su disco")
	var reopened := Store.new()
	reopened.path = filename
	reopened.restore()
	check(reopened.parks == ["madonna"] and reopened.stories == ["school"] and reopened.settings.gentle, "Riapertura conserva raccolta, sblocco e impostazioni")
	check(reopened.journey_stars.school == 3 and reopened.journey_stars.parking == 0, "Stelle del viaggio conservate separatamente dalle medaglie")
	store.parks.append("san_grato")
	check(store.save(), "Aggiornamento atomico con copia precedente")
	write_text(filename, "{documento interrotto")
	reopened.restore()
	check(reopened.recovered and reopened.parks == ["madonna"], "Documento troncato: recupero della copia valida")
	check(reopened.save() and FileAccess.file_exists(filename + ".corrupt"), "Documento danneggiato conservato e copia valida protetta")
	reopened.restore()
	check(not reopened.recovered and reopened.parks == ["madonna"], "Avvio normale dopo il recupero")
	write_text(filename, '{"version":1,"settings":{"music":2,"effects":"alto","gentle":"sì","camera":-8},"parks":["madonna","madonna","inventato"],"stories":["parking"]}')
	reopened.restore()
	check(reopened.settings.music == 1.0 and reopened.settings.effects == 0.65 and not reopened.settings.gentle and reopened.settings.camera == 1.0, "Valori fuori intervallo e tipi invalidi gestiti")
	check(reopened.parks == ["madonna"] and reopened.stories.is_empty(), "Premi sconosciuti, duplicati e sblocco incoerente esclusi")
	write_text(filename, '{"version":99}')
	check(reopened.read_document(filename).is_empty(), "Schema sconosciuto respinto")
	write_text(filename + ".bak", "[]")
	reopened.restore()
	check(reopened.settings == Store.DEFAULTS and reopened.parks.is_empty(), "Entrambi i file invalidi: avvio sicuro")
	reopened.path = "res://build/cartella-inesistente/salvataggio.json"
	check(not reopened.save() and not reopened.last_error.is_empty(), "Errore di scrittura segnalato senza interrompere il gioco")
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	check(main.save_store.memory_only, "Test isolato dai salvataggi dell'utente")
	var visual: Node3D = main.vehicle.visual
	var spec: Dictionary = visual.specification
	check(spec.year == 2010 and spec.engine.code == "4HV" and spec.engine.power_kw == 74 and spec.engine.power_ps == 100 and spec.engine.emissions == "Euro 4", "Identità Ducato 2010 2.2 MultiJet 100, 4HV, Euro 4")
	check(spec.body.variant == "L2H2" and spec.body.wheelbase == "medio" and spec.body.roof == "alto", "Configurazione confermata: passo medio, tetto alto")
	var front_axle: Node3D = visual.front_pivots[0]
	var rear_axle: Node3D = visual.wheels[1].get_parent()
	check(is_equal_approx(absf(front_axle.position.z - rear_axle.position.z), 3.45), "Passo geometrico misurato: 3,45 m")
	var collider: CollisionShape3D = main.vehicle.get_node("CollisionShape3D")
	check(collider.shape.size.is_equal_approx(Vector3(2.05, 2.524, 5.413)), "Collider aggiornato all'ingombro L2H2")
	var roof: MeshInstance3D = visual.get_node("TettoH2")
	var normals: PackedVector3Array = roof.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var vertices: PackedVector3Array = roof.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var highest := 0
	for i in vertices.size():
		if vertices[i].y > vertices[highest].y:
			highest = i
	var center_faces_up := false
	for i in vertices.size():
		if absf(vertices[i].x) < 0.5 and vertices[i].y > 2.5 and normals[i].dot(Vector3.UP) > 0.99:
			center_faces_up = true
	check(center_faces_up and normals[highest].dot(Vector3.UP) > 0.7 and absf(roof.get_aabb().end.y - 2.524) < 0.002, "Tetto H2 a 2,524 m con normali rivolte all'esterno")
	check(visual.get_node("FaroObliquoX250") != null and visual.get_node("CalandraX250") != null and visual.passengers.size() == 2, "Frontale X250 e due occupanti mantenuti")
	main.save_store.settings.merge({"gentle": true, "music": 0.0, "effects": 0.0, "reduced_motion": true, "shadows": false, "camera": 2.5}, true)
	main.apply_settings()
	check(main.vehicle.max_speed == 10.0 and main.camera_rig.reduced_motion and main.camera_rig.sensitivity == 2.5 and not main.sun.shadow_enabled, "Guida tranquilla, camera e ombre applicate")
	check(main.audio.music.volume_db == -80 and main.audio.player.volume_db == -80 and main.audio.engine.volume_db == -80 and main.audio.ambience.volume_db == -80, "Musica, effetti, motore e ambiente azzerabili senza picchi iniziali")
	check(main.audio.music.stream.loop_end == 8 * 22050 and main.audio.engine.stream.loop_end == 22050, "Loop sonori generati e delimitati correttamente")
	check(main.audio.ambience.stream.loop_end == 6 * 22050, "Ambiente con uccellini sintetizzati senza asset esterni")
	main.hud.show_settings()
	(main.hud.content.get_child(3).get_child(1) as HSlider).value = 0.5
	check(main.save_store.settings.music == 0.5 and main.audio.music.volume_db > -80, "Slider modifica realmente il volume")
	(main.hud.content.get_child(10) as Button).pressed.emit()
	check(main.hud.content.get_child(1).text.contains("APOLLO"), "Salva e torna riapre il menu")
	main.show_garage(1)
	check(main.garage_camera.current and main.garage_display.global_position.y == 5000 and paused, "Vetrina isolata dal traffico e dal mondo di gioco")
	main.menu()
	check(not main.garage_active and main.camera_rig.camera.current, "Uscita vetrina ripristina la camera di gioco")
	main.start()
	check(not paused and main.vehicle.enabled, "Partenza corretta dopo impostazioni e vetrina")
	main.queue_free()
	await process_frame
	await process_frame
	OS.delay_msec(100)
	for suffix in ["", ".bak", ".tmp", ".corrupt"]:
		if FileAccess.file_exists(filename + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(filename + suffix))
	print("ESITO FASE 6: %d controlli, %d errori" % [checks, failures])
	quit(0 if failures == 0 else 1)
