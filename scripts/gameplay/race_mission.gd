extends "res://scripts/gameplay/route_mission.gd"
## Gara contro Gino: conto alla rovescia con partenza lanciata, strisce turbo, scia, classifica e arrivo.
## Perdere non punisce: la rivincita è immediata.
signal countdown_tick(value: int)
signal race_started
signal lap_completed(lap: int)
signal race_finished(player_won: bool)
signal collided(strength: float)
signal position_changed(player_first: bool)
signal player_boosted(kind: String)   # "strisce", "lanciata", "scia"
const RaceTrack = preload("res://scripts/gameplay/race_track.gd")
const Rival = preload("res://scripts/gameplay/rival_driver.gd")
const Items = preload("res://scripts/gameplay/item_system.gd")
const BoostPad = preload("res://scripts/gameplay/boost_pad.gd")
const PAD_RADIUS := 3.0
const LAUNCH_WINDOW := 0.9       # s prima del "Via!" in cui premere l'acceleratore
const LAUNCH_BOOST := 1.4
const DRAFT_CHARGE_TIME := 2.2   # s di scia continua per un mini-turbo
const DRAFT_BOOST := 1.0
const RIVAL_PAD_BOOST := 1.0
const HIT_LENGTH := 4.2          # distanza longitudinale sotto cui i due veicoli si urtano
const HIT_WIDTH := 1.75          # distanza laterale sotto cui i due veicoli si urtano
const HIT_COOLDOWN := 0.7
const HIT_RETAIN := 0.88         # velocità mantenuta dopo l'urto
const HIT_SHARE := 0.3           # quota di velocità scambiata
const HIT_BOUNCE := 0.45         # rimbalzo laterale massimo (m)
var track := RaceTrack.new()
var rival := Rival.new()
var items := Items.new()
var laps: int = 2
var assist: String = "normal"
var countdown: float = 3.0
var running: bool = false
var player_distance: float = 0.0
var player_won: bool = false
var rival_node: Node3D
var pads: Array[Dictionary] = []
var launch_result: String = ""   # "lanciata", "presto" oppure vuoto
var draft_charge: float = 0.0
var player_drafting: bool = false
var message: String = ""
var message_time: float = 0.0
var collision_count: int = 0
var race_time: float = 0.0
var _was_first: bool = true
var _position_cooldown: float = 0.0
var _hit_cooldown: float = 0.0
var _accel_since: float = -1.0
var _last_tick: int = -1

func _init() -> void:
	route_mode = true

func configure(line: Array, lap_count: int, assist_level: String, closed: bool = true) -> void:
	track.setup(line, closed)
	laps = lap_count
	assist = assist_level
	rival.setup(track, assist, vehicle.max_speed if vehicle else 15.0)

## Crea le strisce turbo sulla strada. `entries`: elenco di {distance, position}.
func add_pads(parent: Node3D, entries: Array) -> void:
	for entry: Dictionary in entries:
		var here: Dictionary = track.sample(float(entry.distance))
		var node := Node3D.new()
		node.set_script(BoostPad)
		parent.add_child(node)
		node.global_position = here["position"]
		node.rotation.y = atan2(-here["direction"].x, -here["direction"].z)
		pads.append({"distance": float(entry.distance), "position": here["position"], "node": node, "cooldown": 0.0})

func restart() -> void:
	super.restart()
	countdown = 3.0
	running = false
	player_distance = 0.0
	player_won = false
	launch_result = ""
	collision_count = 0
	race_time = 0.0
	_was_first = true
	_position_cooldown = 0.0
	_hit_cooldown = 0.0
	draft_charge = 0.0
	player_drafting = false
	message = ""
	message_time = 0.0
	_accel_since = -1.0
	_last_tick = -1
	rival.reset()
	items.reset()
	if vehicle:
		rival.player_max_speed = vehicle.max_speed
	for pad in pads:
		pad.cooldown = 0.0
	place_rival(0.0)

func total_length() -> float:
	return track.length * laps

func current_lap() -> int:
	return mini(int(player_distance / track.length) + 1, laps)

## 1 se Apollo è davanti, 2 se Gino è davanti.
func position_of_player() -> int:
	return 1 if player_distance >= rival.distance else 2

func say(text: String, seconds: float = 2.5) -> void:
	message = text
	message_time = seconds

func _physics_process(delta: float) -> void:
	if not active or finished:
		return
	if not running:
		count_down(delta)
		return
	message_time = maxf(message_time - delta, 0.0)
	race_time += delta
	_position_cooldown = maxf(_position_cooldown - delta, 0.0)
	var before := current_lap()
	update_player_distance(track.project(vehicle.global_position))
	var player_lateral := track.lateral(vehicle.global_position, player_distance)
	var rival_before := rival.distance
	rival.step(delta, player_distance, player_lateral)
	apply_pads(delta, rival_before)
	apply_draft(delta, player_lateral)
	apply_collision(delta, player_lateral)
	items.update(delta, self, player_lateral, rival_before)
	animate_stun()
	var first := player_distance >= rival.distance
	if first != _was_first and _position_cooldown == 0.0 and absf(player_distance - rival.distance) > 3.0:
		_was_first = first
		_position_cooldown = 3.0
		position_changed.emit(first)
	place_rival(delta)
	if current_lap() != before:
		lap_completed.emit(before)
	if player_distance >= total_length() or rival.distance >= total_length():
		player_won = player_distance >= rival.distance
		rival.record_result(player_won, absf(player_distance - rival.distance) / maxf(vehicle.max_speed, 1.0))
		finished = true
		race_finished.emit(player_won)
		completed.emit()

func count_down(delta: float) -> void:
	countdown -= delta
	var tick := ceili(countdown)
	if tick != _last_tick and tick >= 0:
		_last_tick = tick
		countdown_tick.emit(tick)
	# Partenza lanciata: acceleratore premuto negli ultimi istanti, non prima.
	if Input.is_action_pressed("accelerate"):
		if _accel_since < 0.0:
			_accel_since = countdown
	else:
		_accel_since = -1.0
	if countdown > 0.0:
		return
	running = true
	if Input.is_action_pressed("accelerate") and _accel_since >= 0.0:
		if _accel_since <= LAUNCH_WINDOW:
			launch_result = "lanciata"
			vehicle.effects.boost(LAUNCH_BOOST)
			say("Partenza lanciata! Turbo!")
			player_boosted.emit("lanciata")
		else:
			launch_result = "presto"
			say("Troppo presto! Aspetta il Via!")
	else:
		say("Via!", 1.5)
	race_started.emit()

## Strisce turbo: Apollo ci passa sopra, Gino le prende quando le supera.
func apply_pads(delta: float, rival_before: float) -> void:
	for pad in pads:
		pad.cooldown = maxf(pad.cooldown - delta, 0.0)
		var offset: Vector3 = vehicle.global_position - (pad.position as Vector3)
		offset.y = 0.0
		if pad.cooldown == 0.0 and offset.length() < PAD_RADIUS:
			pad.cooldown = 1.5
			vehicle.effects.boost()
			player_boosted.emit("strisce")
		if rival_before < pad.distance and rival.distance >= pad.distance and absf(rival.lane) < 2.5:
			rival.effects.boost(RIVAL_PAD_BOOST)

## Scia: dietro a Gino e quasi nella sua corsia, un piccolo bonus e un turbo dopo qualche secondo.
func apply_draft(delta: float, player_lateral: float) -> void:
	var gap := rival.distance - player_distance
	player_drafting = gap > 3.0 and gap < 16.0 and absf(rival.lane - player_lateral) < 1.9
	if player_drafting:
		vehicle.effects.draft()
		draft_charge += delta
		if draft_charge >= DRAFT_CHARGE_TIME:
			draft_charge = 0.0
			vehicle.effects.boost(DRAFT_BOOST)
			say("Scia! Turbo!")
			player_boosted.emit("scia")
	else:
		draft_charge = maxf(draft_charge - delta * 2.0, 0.0)

## Urto morbido: i due rallentano di poco, si scambiano un po' di velocità e rimbalzano di lato.
## Mai testacoda e mai blocco: Gino rientra da solo nella sua corsia, Apollo resta sotto il controllo del giocatore.
func apply_collision(delta: float, player_lateral: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	var along := player_distance - rival.distance
	var across := player_lateral - rival.lane
	if _hit_cooldown > 0.0 or absf(along) > HIT_LENGTH or absf(across) > HIT_WIDTH:
		return
	_hit_cooldown = HIT_COOLDOWN
	collision_count += 1
	var apollo_speed: float = vehicle.speed
	var gino_speed: float = rival.speed
	vehicle.speed = lerpf(apollo_speed, gino_speed, HIT_SHARE) * HIT_RETAIN
	rival.speed = lerpf(gino_speed, apollo_speed, HIT_SHARE) * HIT_RETAIN
	# Rimbalzo laterale: lontano dall'altro veicolo, mai oltre il bordo corsia di Gino.
	var side := 1.0 if across >= 0.0 else -1.0
	var here: Dictionary = track.sample(player_distance)
	var right: Vector3 = (here["direction"] as Vector3).cross(Vector3.UP)
	vehicle.global_position += right * side * HIT_BOUNCE
	rival.lane = clampf(rival.lane - side * HIT_BOUNCE, -rival.LANE_LIMIT, rival.LANE_LIMIT)
	say("Urto morbido!", 1.2)
	collided.emit(clampf(absf(apollo_speed - gino_speed) / 10.0 + 0.3, 0.0, 1.0))

## Capriola di Apollo e di Gino quando sono storditi (colpo di forbici o di anguria).
func animate_stun() -> void:
	var stun: float = vehicle.effects.stun_time
	vehicle.visual.rotation.x = -TAU * (1.0 - stun / 1.2) if stun > 0.0 else 0.0

## Gino sta a destra di Apollo alla partenza e nella sua corsia lungo il percorso.
func place_rival(delta: float) -> void:
	if rival_node == null:
		return
	var here: Dictionary = track.sample(rival.distance)
	var direction: Vector3 = here["direction"]
	var spot: Vector3 = here["position"] + direction.cross(Vector3.UP) * rival.lane + Vector3.UP * 0.15
	rival_node.global_position = spot
	rival_node.look_at(spot + direction, Vector3.UP)
	var stun: float = rival.effects.stun_time
	if stun > 0.0:
		var progress := 1.0 - stun / 1.2
		rival_node.rotate_object_local(Vector3.RIGHT, -TAU * progress)
		rival_node.global_position += Vector3.UP * sin(PI * progress) * 0.9
	if rival_node.has_method("animate"):
		rival_node.animate(rival.speed, delta)

## L'avanzamento non torna indietro e non salta quando l'anello si richiude.
func update_player_distance(projected: float) -> void:
	var lap_base := floorf(player_distance / track.length) * track.length
	var candidate := lap_base + projected
	if candidate < player_distance - track.length * 0.5:
		candidate += track.length
	elif candidate > player_distance + track.length * 0.5:
		candidate -= track.length
	player_distance = maxf(player_distance, candidate)

func instructions() -> String:
	if finished:
		return "Hai battuto Gino!" if player_won else "Gino ha vinto: rivincita subito!"
	if not running:
		return "Pronti… %d  ·  tieni premuto W appena prima del Via!" % maxi(ceili(countdown), 1)
	if message_time > 0.0:
		return message
	var text := "Giro %d/%d · posizione %d/2" % [current_lap(), laps, position_of_player()]
	if items.player_item != "":
		text += " · E: " + items.NAMES[items.player_item]
	if player_drafting:
		text += " · SCIA"
	return text
