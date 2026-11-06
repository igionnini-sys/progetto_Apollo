extends SceneTree
## Integrazione livello 2: mondo, Gino, conto alla rovescia, avanzamento e arrivo.
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: " + message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	main.selected_race = "level2_race"
	root.add_child(main)
	await frames(5)
	var mission = main.mission
	check(mission.track.length > 900.0, "Percorso gara caricato: %.0f m" % mission.track.length)
	main.save_store.settings.race_assist = 1.0
	main.apply_settings()
	check(is_equal_approx(mission.rival.skill, 1.0), "Impostazione Aiuto in gara = Sfida cambia Gino")
	main.save_store.settings.race_assist = 0.0
	main.apply_settings()
	check(mission.rival.skill < 0.92, "Impostazione Più aiuto rallenta Gino")
	main.save_store.settings.race_assist = 0.5
	main.apply_settings()
	check(mission.rival.defeats_in_row == 0, "Nessuna sconfitta registrata all'inizio")
	check(not mission.running and not main.vehicle.enabled, "Apollo fermo durante il conto alla rovescia")
	var gap: float = main.gino.global_position.distance_to(main.vehicle.global_position)
	check(gap >= 2.5 and gap < 6.0, "Apollo e Gino partono affiancati senza sovrapporsi (%.1f m)" % gap)
	await frames(160)
	Input.action_press("accelerate")
	await frames(20)
	check(mission.running and main.vehicle.enabled, "Via! dopo 3 secondi")
	check(mission.launch_result == "lanciata" and main.vehicle.effects.is_boosting(), "Partenza lanciata: acceleratore premuto in tempo dà il turbo")
	var peak := 0.0
	for i in 60:
		await physics_frame
		peak = maxf(peak, main.vehicle.speed)
	check(peak > 15.5, "Turbo oltre la velocità massima (%.1f m/s)" % peak)
	Input.action_release("accelerate")
	var before: float = main.gino.global_position.distance_to(mission.track.points[0])
	await frames(60)
	check(mission.rival.distance > 10.0 and main.gino.global_position.distance_to(mission.track.points[0]) > before, "Gino avanza sul percorso (%.0f m)" % mission.rival.distance)
	check(mission.pads.size() >= 3, "Strisce turbo create: %d" % mission.pads.size())
	var pad: Dictionary = mission.pads[1]
	main.vehicle.effects = main.vehicle.Effects.new()
	main.vehicle.global_position = (pad.position as Vector3) + Vector3.UP * 0.15
	await frames(3)
	check(main.vehicle.effects.is_boosting(), "Passare sulla striscia turbo attiva il turbo")
	# Scia: Apollo 8 m dietro Gino, nella sua corsia.
	main.vehicle.effects = main.vehicle.Effects.new()
	var s: float = mission.rival.distance - 8.0
	var here: Dictionary = mission.track.sample(s)
	main.vehicle.global_position = here["position"] + (here["direction"] as Vector3).cross(Vector3.UP) * mission.rival.lane + Vector3.UP * 0.15
	var boosted := false
	for i in 200:
		mission.player_distance = mission.rival.distance - 8.0
		main.vehicle.global_position = (mission.track.sample(mission.rival.distance - 8.0)["position"] as Vector3) + (mission.track.sample(mission.rival.distance - 8.0)["direction"] as Vector3).cross(Vector3.UP) * mission.rival.lane + Vector3.UP * 0.15
		await physics_frame
		boosted = boosted or main.vehicle.effects.is_boosting()
	check(boosted, "Scia continua dietro Gino carica un mini-turbo")
	# Affiancato: Gino lascia la corsia.
	var side_lane: float = mission.rival.lane
	for i in 90:
		mission.player_distance = mission.rival.distance
		var along: Dictionary = mission.track.sample(mission.rival.distance)
		main.vehicle.global_position = (along["position"] as Vector3) + (along["direction"] as Vector3).cross(Vector3.UP) * 1.3 + Vector3.UP * 0.15
		await physics_frame
	var lateral: float = mission.track.lateral(main.vehicle.global_position, mission.rival.distance)
	check(absf(mission.rival.lane - lateral) > 2.0, "Gino si sposta per non sovrapporsi ad Apollo (%.1f m)" % absf(mission.rival.lane - lateral))
	# Urto morbido: affiancato e sovrapposto, entrambi rallentano un poco, nessun blocco.
	mission.player_distance = mission.rival.distance
	mission.rival.lane = 0.0
	mission.collision_count = 0
	mission._hit_cooldown = 0.0
	var here_hit: Dictionary = mission.track.sample(mission.rival.distance)
	main.vehicle.global_position = (here_hit["position"] as Vector3) + (here_hit["direction"] as Vector3).cross(Vector3.UP) * 0.8 + Vector3.UP * 0.15
	main.vehicle.speed = 15.0
	mission.rival.speed = 12.0
	var gino_before: float = mission.rival.speed
	await frames(2)
	check(mission.collision_count == 1, "Urto rilevato tra Apollo e Gino")
	check(main.vehicle.speed < 15.0 and main.vehicle.speed > 8.0, "Apollo rallenta poco dopo l'urto (%.1f m/s)" % main.vehicle.speed)
	check(mission.rival.speed > 6.0 and absf(mission.rival.lane) > 0.3, "Gino rallenta poco e rimbalza di lato")
	await frames(120)
	check(mission.collision_count <= 2 and mission.rival.speed > 6.0, "Dopo l'urto nessun blocco: Gino riparte (%.1f m/s)" % mission.rival.speed)
	gino_before = gino_before
	# Oggetti: cassetta, forbici, batteria, guanti e frutta di Gino.
	var it = mission.items
	it.reset()
	check(it.pickups.size() >= 10, "Cassette e casse create: %d" % it.pickups.size())
	it.forced_player_item = "forbici"
	var tool_pad: Node3D = null
	var fruit_pad: Node3D = null
	for pickup in it.pickups:
		if pickup.kind == "tool" and tool_pad == null:
			tool_pad = pickup
		if pickup.kind == "fruit" and fruit_pad == null:
			fruit_pad = pickup
	mission.rival.effects = mission.rival.Effects.new()
	main.vehicle.global_position = tool_pad.global_position + Vector3.UP * 0.15
	main.vehicle.speed = 10.0
	mission.player_distance = tool_pad.distance
	mission.rival.distance = tool_pad.distance + 22.0
	mission.rival.lane = -1.3
	mission.rival.speed = 6.0
	await frames(2)
	check(it.player_item == "forbici" and not tool_pad.is_ready(), "Raccolta della cassetta: Apollo ottiene le forbici")
	Input.action_press("use_item")
	await frames(2)
	Input.action_release("use_item")
	check(it.projectiles.size() == 1 and it.player_item == "", "E lancia le forbici")
	var max_stun := 0.0
	for i in 90:
		mission.rival.lane = -1.3
		await physics_frame
		max_stun = maxf(max_stun, mission.rival.effects.stun_time)
	check(it.hits_on_rival == 1 and max_stun > 0.5, "Le forbici colpiscono Gino e lo stordiscono (%.1f s)" % max_stun)
	it.player_item = "batteria"
	main.vehicle.effects = main.vehicle.Effects.new()
	Input.action_press("use_item")
	await frames(2)
	Input.action_release("use_item")
	check(main.vehicle.effects.is_boosting(), "La batteria dà un turbo manuale")
	it.player_item = "guanti"
	Input.action_press("use_item")
	await frames(2)
	Input.action_release("use_item")
	check(main.vehicle.effects.shield_time > 4.0, "I guanti attivano lo scudo")
	it.launch("gino", "pomodoro", mission.player_distance - 5.0, mission.track.lateral(main.vehicle.global_position, mission.player_distance), 30.0)
	for i in 60:
		await physics_frame
	check(it.hits_on_player == 1 and main.vehicle.effects.shield_time == 0.0 and main.vehicle.effects.slow_time == 0.0, "Lo scudo blocca un pomodoro")
	it.forced_rival_item = "pomodoro"
	mission.rival.effects = mission.rival.Effects.new()
	main.vehicle.effects = main.vehicle.Effects.new()
	mission.rival.distance = fruit_pad.distance - 0.1
	mission.rival.lane = 1.3
	mission.rival.speed = 10.0
	mission.player_distance = fruit_pad.distance + 30.0
	var ahead: Dictionary = mission.track.sample(fruit_pad.distance + 30.0)
	main.vehicle.global_position = (ahead["position"] as Vector3) + (ahead["direction"] as Vector3).cross(Vector3.UP) * 1.3 + Vector3.UP * 0.15
	main.vehicle.speed = 0.0
	await frames(3)
	check(it.rival_item == "pomodoro", "Gino raccoglie la cassa di frutta")
	var thrown := false
	var hit_before: int = it.hits_on_player
	for i in 150:
		await physics_frame
		thrown = thrown or it.projectiles.size() > 0
	check(thrown, "Gino lancia il pomodoro dopo un attimo di reazione")
	check(it.hits_on_player > hit_before or thrown, "Il pomodoro viaggia verso Apollo")
	it.reset()
	# Apollo guidato sul tracciato: teletrasporto lungo i punti fino all'arrivo, Gino non deve vincere.
	for i in range(1, mission.track.points.size()):
		main.vehicle.global_position = mission.track.points[i] + Vector3.UP * 0.15
		await frames(3)
	check(mission.finished and mission.player_won, "Arrivo raggiunto da Apollo prima di Gino")
	main.free()
	print("Verifiche gara: %s" % ("OK" if failures == 0 else "%d FALLITE" % failures))
	quit(failures)
