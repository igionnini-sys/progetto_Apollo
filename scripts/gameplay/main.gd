extends Node3D
const Controls = preload("res://scripts/utilities/controls.gd")
const World = preload("res://scripts/environment/test_world.gd")
const FollowCamera = preload("res://scripts/vehicles/follow_camera.gd")
const PracticeMission = preload("res://scripts/gameplay/practice_mission.gd")
const Hud = preload("res://scripts/ui/hud.gd")
const Audio = preload("res://scripts/utilities/audio.gd")
const Apollo = preload("res://scenes/vehicles/apollo.tscn")
const VolpianoWorld = preload("res://scripts/environment/volpiano_world.gd")
const RouteMission = preload("res://scripts/gameplay/route_mission.gd")
const ParkMission = preload("res://scripts/gameplay/park_mission.gd")
const RaceMission = preload("res://scripts/gameplay/race_mission.gd")
const GinoModel = preload("res://scripts/vehicles/gino_fiorino.gd")
const StoryMission = preload("res://scripts/gameplay/story_mission.gd")
const Dialogue = preload("res://scripts/gameplay/dialogue_player.gd")
const SaveStore = preload("res://scripts/utilities/save_store.gd")
const Atmosphere = preload("res://scripts/environment/atmosphere.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
var save_store: RefCounted
var sun: DirectionalLight3D
var environment: Environment
var garage_camera: Camera3D
var garage_active: bool = false
var garage_display: Node3D
var selected_story: String = ""
var selected_race: String = ""
var gino: Node3D
var story_state: String = "menu"
var dialogue: Node
var story_reveal: Tween
var use_volpiano: bool = false
var selected_park: String = ""
var world: Node3D
var park_camera: Camera3D
var search_open: bool = false
var park_found: bool = false
var vehicle: CharacterBody3D
var camera_rig: Node3D
var mission: Node
var hud: CanvasLayer
var audio: Node
var in_menu: bool = true
var started: bool = false
var resume_ok: bool = false

func _ready() -> void:
	save_store = SaveStore.session(get_tree())
	Controls.setup()
	lighting()
	world = Node3D.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.set_script(VolpianoWorld if use_volpiano else World)
	if use_volpiano:
		world.park_id = selected_park
		world.story_id = selected_story
		world.race_id = selected_race
	add_child(world)
	vehicle = Apollo.instantiate()
	vehicle.process_mode = Node.PROCESS_MODE_PAUSABLE
	vehicle.position = Vector3(0, 0.15, 36)
	vehicle.rotation.y = PI / 2.0
	if use_volpiano:
		vehicle.position = world.spawn
		vehicle.rotation.y = world.heading
		vehicle.recovery_radius = 2000.0
		if selected_race != "":
			# Griglia di partenza: Apollo a sinistra, Gino a destra, senza sovrapporsi.
			var route: Array = world.race_data.route
			var along := Vector3(float(route[1][0]) - float(route[0][0]), 0.0, float(route[1][1]) - float(route[0][1])).normalized()
			vehicle.position -= along.cross(Vector3.UP) * 1.3
	add_child(vehicle)
	if use_volpiano and world.home != null:
		world.home.vehicle = vehicle
	camera_rig = Node3D.new()
	camera_rig.process_mode = Node.PROCESS_MODE_PAUSABLE
	camera_rig.set_script(FollowCamera)
	camera_rig.target = vehicle
	add_child(camera_rig)
	mission = Node.new()
	mission.process_mode = Node.PROCESS_MODE_PAUSABLE
	mission.name = "ProvaGuida"
	mission.set_script(ParkMission if selected_park != "" else (RouteMission if use_volpiano else PracticeMission))
	if selected_story != "":
		mission.set_script(StoryMission)
		mission.challenge = selected_story == "parking"
		mission.traffic_light = world.story_traffic
		mission.traffic_index = world.data.route.find(str(world.story_data.traffic_node))-1
	if selected_park != "":
		mission.park_name = world.park_data.name
	if selected_race != "":
		mission.set_script(RaceMission)
	mission.vehicle = vehicle
	mission.points = world.checkpoints
	if selected_race != "":
		gino = Node3D.new()
		gino.set_script(GinoModel)
		add_child(gino)
		mission.rival_node = gino
		mission.configure(world.race_data.route, int(world.race_data.laps), race_assist_name(), false)
		mission.add_pads(self, world.race_data.boost_pads)
		mission.items.setup(self, mission.track, world.race_data.item_pickups)
		mission.race_started.connect(func(): vehicle.enabled = true)
		mission.race_finished.connect(func(_won: bool): get_tree().set_meta("apollo_race_defeats", mission.rival.defeats_in_row))
	if use_volpiano and world.home != null:
		mission.departure_points = 1
	add_child(mission)
	if selected_race != "":
		# Adattamento automatico: dopo due sconfitte Gino rallenta un poco; non viene mostrato al giocatore.
		mission.rival.defeats_in_row = int(get_tree().get_meta("apollo_race_defeats", 0))
	hud = CanvasLayer.new()
	hud.set_script(Hud)
	hud.vehicle = vehicle
	hud.mission = mission
	add_child(hud)
	audio = Node.new()
	audio.set_script(Audio)
	add_child(audio)
	audio.vehicle = vehicle
	apply_settings()
	dialogue = Node.new()
	dialogue.set_script(Dialogue)
	add_child(dialogue)
	dialogue.line_changed.connect(func():
		if story_state in ["intro", "ending"]:
			hud.show_story_dialogue()
	)
	dialogue.sequence_finished.connect(dialogue_finished)
	hud.play_requested.connect(start)
	hud.exploration_requested.connect(switch_environment)
	hud.park_requested.connect(visit_park)
	hud.search_requested.connect(search_place)
	hud.story_requested.connect(visit_story)
	hud.race_requested.connect(visit_race)
	hud.dialogue_requested.connect(func(): dialogue.advance())
	hud.resume_requested.connect(resume_game)
	hud.restart_requested.connect(start)
	hud.menu_requested.connect(menu)
	hud.quit_requested.connect(func(): persist(); get_tree().quit())
	mission.completed.connect(finish)
	if selected_race != "":
		mission.player_boosted.connect(func(_kind: String): audio.boost())
		mission.collided.connect(func(_strength: float): audio.smash())
		mission.items.used.connect(func(_item: String): audio.click())
		mission.items.rival_hit.connect(func(_kind: String): audio.smash())
		mission.items.player_hit.connect(func(kind: String):
			audio.smash()
			hud.splash_overlay.splash(Color("d8402a") if kind == "pomodoro" else (Color("f08a1c") if kind == "arancia" else Color("4f9a4a"))))
	mission.changed.connect(func(): audio.chime())
	if selected_story != "":
		mission.story_event.connect(func(key: String): dialogue.say(key))
		mission.coin_collected.connect(func(_count: int): audio.coin())
		mission.bill_collected.connect(func(_cents: int): audio.chime())
		mission.crate_smashed.connect(func(_count: int): audio.smash())
		mission.star_collected.connect(func(_count: int):
			audio.chime()
			save_store.journey_stars[selected_story] = maxi(_count, save_store.journey_stars[selected_story])
			persist()
			dialogue.say("star")
		)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Scelta una storia o una gita dal menu: si parte subito, senza un secondo menu.
	if "--smoke-test" in OS.get_cmdline_user_args() or selected_story != "" or selected_park != "" or selected_race != "":
		start()
	else:
		get_tree().paused = true

func switch_environment() -> void:
	change_environment(not use_volpiano)

func visit_park(id: String) -> void:
	change_environment(true, id)

func visit_race(id: String) -> void:
	change_environment(true, "", "", id)

func visit_story(id: String) -> void:
	if id == "parking" and not "school" in get_tree().get_meta("apollo_story_rewards", []):
		return
	change_environment(true, "", id)

func change_environment(volpiano: bool, park: String = "", story: String = "", race: String = "") -> void:
	get_tree().paused = false
	var next: Node3D = load("res://scenes/main/main.tscn").instantiate()
	next.use_volpiano = volpiano
	next.selected_park = park
	next.selected_story = story
	next.selected_race = race
	get_tree().root.add_child(next)
	queue_free()

func lighting() -> void:
	var created := Atmosphere.create(self, use_volpiano)
	environment = created.environment
	sun = created.sun

func start() -> void:
	close_garage()
	if story_reveal:
		story_reveal.kill()
	search_open = false
	park_found = false
	if is_instance_valid(park_camera):
		park_camera.queue_free()
		park_camera = null
		camera_rig.get_node("SpringArm3D/Camera3D").current = true
	if selected_park != "":
		world.playground.star.hide()
	in_menu = false
	started = true
	resume_ok = false
	get_tree().paused = false
	vehicle.enabled = true
	vehicle.reset_vehicle()
	camera_rig.snap()
	mission.restart()
	mission.active = true
	if selected_race != "":
		vehicle.enabled = false
	hud.elapsed = 0.0
	hud.overlay.hide()
	if selected_story != "":
		mission.active = false
		vehicle.enabled = false
		get_tree().paused = true
		story_state = "intro"
		dialogue.reset()
		show_cabin()
		dialogue.begin("parking_intro" if selected_story == "parking" else "intro")

func show_cabin() -> void:
	park_camera = Camera3D.new()
	add_child(park_camera)
	park_camera.global_transform = vehicle.global_transform
	park_camera.position = vehicle.to_global(Vector3(0, 2.15, -5.5))
	park_camera.look_at(vehicle.to_global(Vector3(0, 1.65, -1.55)))
	park_camera.h_offset = 1.25
	park_camera.current = true

func dialogue_finished() -> void:
	if story_state == "intro":
		story_state = "driving"
		park_camera.queue_free()
		park_camera = null
		camera_rig.camera.current = true
		get_tree().paused = false
		vehicle.enabled = true
		mission.active = true
		hud.overlay.hide()
		dialogue.say("departure")
	elif story_state == "ending":
		story_state = "complete"
		var rewards: Array = get_tree().get_meta("apollo_story_rewards", [])
		if not selected_story in rewards:
			rewards.append(selected_story)
		get_tree().set_meta("apollo_story_rewards", rewards)
		persist()
		hud.show_story_completed()

func resume_game() -> void:
	if not resume_ok:
		return
	in_menu = false
	if selected_story != "":
		story_state = "driving"
	get_tree().paused = false
	hud.overlay.hide()

## Esc: apre il menu durante la guida, oppure riprende se il menu è già aperto.
func toggle_pause() -> void:
	if in_menu:
		if resume_ok:
			resume_game()
		return
	if mission.finished or (selected_story != "" and story_state != "driving"):
		return
	menu()

func menu() -> void:
	close_garage()
	resume_ok = started and not in_menu and not mission.finished and not search_open \
		and (selected_story == "" or story_state == "driving")
	story_state = "menu"
	search_open = false
	in_menu = true
	get_tree().paused = true
	hud.show_menu()

func finish() -> void:
	vehicle.enabled = false
	audio.complete()
	get_tree().paused = true
	if selected_story != "":
		story_state = "ending"
		park_camera = Camera3D.new()
		add_child(park_camera)
		var school: Vector3 = world.geo(world.story_data.school_lat_lon[0], world.story_data.school_lat_lon[1])
		park_camera.position = school + Vector3(-48, 22, 10)
		park_camera.look_at(school + Vector3(20, 2, 0))
		park_camera.current = true
		if not save_store.settings.reduced_motion:
			story_reveal = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			story_reveal.tween_property(park_camera, "position", park_camera.position + Vector3(5, -2, -2), 2.0)
		if selected_story == "parking":
			dialogue.begin("parking_ending")
		else:
			var result: String = mission.money_result()
			for id in (["wallet", "all_money"] if result == "win" else (["wallet"] if result == "ok" else [])):
				if not id in save_store.achievements:
					save_store.achievements.append(id)
			persist()
			dialogue.begin("ending", "ending_" + result)
	elif selected_park != "":
		search_open = true
		park_camera = Camera3D.new()
		add_child(park_camera)
		park_camera.position = world.playground.global_position + Vector3(18, 23, 24)
		park_camera.look_at(world.playground.global_position + Vector3.UP)
		park_camera.current = true
		park_camera.h_offset = 8.0
		hud.show_park_search()
	elif selected_race != "":
		hud.show_race_result(mission.player_won)
	else:
		hud.show_completed()

func park_rewards() -> Array:
	return get_tree().get_meta("apollo_park_rewards", [])

func search_place(index: int) -> void:
	if not search_open or park_found or index < 0 or index > 2:
		return
	if index != world.playground.hiding_place:
		hud.show_park_search("Qui ci sono solo sorrisi! Prova un altro nascondiglio.")
		return
	park_found = true
	world.playground.star.show()
	var rewards := park_rewards()
	if not selected_park in rewards:
		rewards.append(selected_park)
	get_tree().set_meta("apollo_park_rewards", rewards)
	persist()
	audio.chime()
	hud.show_park_reward()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		toggle_pause()
	if event.is_action_pressed("horn") and not event.is_echo() and not get_tree().paused:
		audio.horn()

func persist() -> bool:
	var success: bool = save_store.save(get_tree())
	if not success and is_instance_valid(hud):
		hud.dialogue_label.text = save_store.last_error
	return success

## "Aiuto in gara": 0 = Più aiuto, 0,5 = Normale, 1 = Sfida.
func race_assist_name() -> String:
	var value: float = save_store.settings.race_assist
	return "more_help" if value < 0.25 else ("challenge" if value > 0.75 else "normal")

func apply_settings() -> void:
	var settings: Dictionary = save_store.settings
	get_tree().set_meta("apollo_reduced_motion", settings.reduced_motion)
	if is_instance_valid(vehicle):
		vehicle.max_speed = 10.0 if settings.gentle else 15.0
	if selected_race != "" and is_instance_valid(mission):
		mission.rival.setup(mission.track, race_assist_name(), vehicle.max_speed)
	if is_instance_valid(camera_rig):
		camera_rig.sensitivity = settings.camera
		camera_rig.reduced_motion = settings.reduced_motion
	Atmosphere.apply_quality(environment, sun, settings.hq_graphics, settings.shadows)
	Materials.set_reduced_motion(settings.reduced_motion)
	if is_instance_valid(audio):
		audio.configure(settings)

func show_garage(view_index: int = 0) -> void:
	garage_active = true
	get_tree().paused = true
	if not is_instance_valid(garage_camera):
		garage_display = Node3D.new()
		garage_display.process_mode = Node.PROCESS_MODE_ALWAYS
		garage_display.position = Vector3(0, 5000, 0)
		add_child(garage_display)
		var preview := Node3D.new()
		preview.set_script(load("res://scripts/vehicles/apollo_visual.gd"))
		garage_display.add_child(preview)
		garage_camera = Camera3D.new()
		add_child(garage_camera)
		preload("res://scripts/vehicles/vehicle_studio.gd").setup(garage_display, garage_camera, sun)
	var positions := [Vector3(6.5, 3.3, -7.2), Vector3(10.5, 2.5, 0), Vector3(-6.3, 3.2, 7.4)]
	garage_camera.position = garage_display.to_global(positions[clampi(view_index, 0, 2)])
	garage_camera.look_at(garage_display.to_global(Vector3(0, 1.1, 0)))
	garage_camera.h_offset = 2.0
	garage_camera.fov = 43
	garage_camera.current = true
	hud.show_garage()

func close_garage() -> void:
	if not garage_active:
		return
	garage_active = false
	if is_instance_valid(garage_camera):
		garage_camera.queue_free()
	garage_camera = null
	if is_instance_valid(garage_display):
		garage_display.queue_free()
	garage_display = null
	apply_settings()
	hud.set_gameplay_visible(true)
	if is_instance_valid(park_camera):
		park_camera.current = true
	elif is_instance_valid(camera_rig):
		camera_rig.camera.current = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and save_store != null:
		persist()
