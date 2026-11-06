extends RefCounted
## Oggetti della gara: cassette per Apollo, casse di frutta per Gino, proiettili e loro effetti.
## Tutto avviene lungo l'asse del percorso (distanza, corsia), come per le collisioni.
const Pickup = preload("res://scripts/gameplay/item_pickup.gd")
const APOLLO_LANE := -1.3
const GINO_LANE := 1.3
const PICKUP_RADIUS := 2.2
const RIVAL_REACTION := 0.6
const HIT_LENGTH := 2.6
const HIT_WIDTH := 1.3
const MAX_TRAVEL := 90.0
const APOLLO_ITEMS := ["forbici", "multimetro", "trapano", "guanti", "batteria"]
const GINO_ITEMS := ["pomodoro", "arancia", "anguria"]
const NAMES := {"forbici": "Forbici", "multimetro": "Multimetro", "trapano": "Trapano", "guanti": "Guanti isolanti",
	"batteria": "Batteria", "pomodoro": "Pomodoro", "arancia": "Arancia", "anguria": "Anguria"}
const SPEEDS := {"forbici": 22.0, "multimetro": 9.0, "pomodoro": 20.0, "arancia": 16.0, "anguria": -9.0}   # velocità relative al lanciatore
const HOMING := 3.0

var pickups: Array[Node3D] = []
var projectiles: Array[Dictionary] = []
var player_item: String = ""
var rival_item: String = ""
var rival_timer: float = 0.0
var forced_player_item: String = ""     # solo per i test
var forced_rival_item: String = ""
var tumble_time: float = 0.0            # capriola di Gino
var shield_bubble: MeshInstance3D
var parent_node: Node3D
var hits_on_rival: int = 0
var hits_on_player: int = 0
signal used(item: String)
signal player_hit(kind: String)
signal rival_hit(kind: String)

func setup(parent: Node3D, track, entries: Array) -> void:
	parent_node = parent
	for entry: Dictionary in entries:
		for kind in ["tool", "fruit"]:
			var node := Node3D.new()
			node.set_script(Pickup)
			node.kind = kind
			node.distance = float(entry.distance)
			node.lane = APOLLO_LANE if kind == "tool" else GINO_LANE
			parent.add_child(node)
			var here: Dictionary = track.sample(node.distance)
			node.global_position = (here["position"] as Vector3) + (here["direction"] as Vector3).cross(Vector3.UP) * node.lane
			pickups.append(node)
	shield_bubble = MeshInstance3D.new()
	var bubble := SphereMesh.new()
	bubble.radius = 2.6
	bubble.height = 4.2
	shield_bubble.mesh = bubble
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.9, 1.0, 0.22)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield_bubble.material_override = material
	shield_bubble.visible = false
	shield_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shield_bubble)

func reset() -> void:
	player_item = ""
	rival_item = ""
	rival_timer = 0.0
	tumble_time = 0.0
	hits_on_rival = 0
	hits_on_player = 0
	for p in projectiles:
		p.node.queue_free()
	projectiles.clear()
	for pickup in pickups:
		pickup.respawn = 0.0
		pickup.shape.show()

## Oggetto a caso, pesato a favore di chi è indietro.
func roll_player_item(behind: bool) -> String:
	if forced_player_item != "":
		return forced_player_item
	var weights := {"forbici": 2.0, "multimetro": 3.0, "trapano": 1.0, "guanti": 1.0, "batteria": 3.0} if behind \
		else {"forbici": 2.0, "multimetro": 0.0, "trapano": 2.0, "guanti": 3.0, "batteria": 1.0}
	return weighted(weights)

func roll_rival_item(behind: bool) -> String:
	if forced_rival_item != "":
		return forced_rival_item
	return weighted({"pomodoro": 3.0, "arancia": 2.0, "anguria": 1.0 if behind else 2.0})

func weighted(weights: Dictionary) -> String:
	var total := 0.0
	for key in weights:
		total += weights[key]
	var pick := randf() * total
	for key in weights:
		pick -= weights[key]
		if pick <= 0.0:
			return key
	return weights.keys()[0]

## Un aggiornamento per frame fisico. `m` è la gara (RaceMission).
func update(delta: float, m, player_lateral: float, rival_before: float) -> void:
	for pickup in pickups:
		if pickup.kind == "tool" and player_item == "" and pickup.is_ready():
			var flat: Vector3 = m.vehicle.global_position - pickup.global_position
			flat.y = 0.0
			if flat.length() < PICKUP_RADIUS:
				pickup.take()
				player_item = roll_player_item(m.rival.distance > m.player_distance)
				m.say("%s! Premi E" % NAMES[player_item], 2.5)
		elif pickup.kind == "fruit" and rival_item == "" and pickup.is_ready():
			if rival_before < pickup.distance and m.rival.distance >= pickup.distance and absf(m.rival.lane - GINO_LANE) < 1.7:
				pickup.take()
				rival_item = roll_rival_item(m.rival.distance < m.player_distance)
				rival_timer = RIVAL_REACTION
	if Input.is_action_just_pressed("use_item") and player_item != "":
		use_player_item(m, player_lateral)
	rival_ai(delta, m, player_lateral)
	move_projectiles(delta, m, player_lateral)
	tumble_time = maxf(tumble_time - delta, 0.0)
	shield_bubble.visible = m.vehicle.effects.shield_time > 0.0
	shield_bubble.global_position = m.vehicle.global_position + Vector3.UP * 1.3

func use_player_item(m, player_lateral: float) -> void:
	var item := player_item
	player_item = ""
	used.emit(item)
	match item:
		"batteria":
			m.vehicle.effects.boost(2.0)
			m.player_boosted.emit("batteria")
		"guanti":
			m.vehicle.effects.shield(5.0)
		"trapano":
			if absf(m.rival.distance - m.player_distance) < 12.0:
				m.rival.effects.slow(0.6, 1.5)
				rival_hit.emit("trapano")
				hits_on_rival += 1
		_:
			launch("apollo", item, m.player_distance + 2.5, player_lateral, m.vehicle.speed)

func rival_ai(delta: float, m, player_lateral: float) -> void:
	if rival_item == "":
		return
	var gap: float = m.rival.distance - m.player_distance    # >0: Gino davanti
	var aligned := absf(player_lateral - m.rival.lane) < 2.2
	var in_range := false
	match rival_item:
		"anguria":
			in_range = gap > 4.0 and gap < 30.0 and aligned         # Apollo dietro: rotola all'indietro
		_:
			in_range = gap < -4.0 and gap > -45.0 and aligned       # Apollo davanti: lancio in avanti
	# Reazione "umana": parte solo quando il bersaglio è a tiro.
	if not in_range:
		rival_timer = RIVAL_REACTION
		return
	rival_timer -= delta
	if rival_timer > 0.0:
		return
	var lane: float = m.rival.lane if rival_item == "anguria" else clampf(player_lateral, -2.2, 2.2)
	launch("gino", rival_item, m.rival.distance + (-2.5 if rival_item == "anguria" else 2.5), lane, m.rival.speed)
	rival_item = ""
	rival_timer = RIVAL_REACTION

func launch(owner_name: String, item: String, from_distance: float, lane: float, own_speed: float) -> void:
	var node := Pickup.projectile_visual(item)
	parent_node.add_child(node)
	projectiles.append({"owner": owner_name, "kind": item, "distance": from_distance, "lane": lane, "speed": SPEEDS[item] + (own_speed if SPEEDS[item] > 0.0 else 0.0),
		"travelled": 0.0, "node": node, "phase": randf() * TAU})

func move_projectiles(delta: float, m, player_lateral: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var p: Dictionary = projectiles[i]
		p.distance += p.speed * delta
		p.travelled += absf(p.speed) * delta
		p.phase += delta * 9.0
		var target_lane: float = m.rival.lane if p.owner == "apollo" else player_lateral
		if p.kind == "multimetro":
			p.lane = move_toward(p.lane, target_lane, HOMING * delta)
		var lane_now: float = p.lane + (sin(p.phase) * 0.5 if p.kind == "arancia" else 0.0)
		var here: Dictionary = m.track.sample(p.distance)
		var spot: Vector3 = (here["position"] as Vector3) + (here["direction"] as Vector3).cross(Vector3.UP) * lane_now + Vector3.UP * (0.7 + (absf(sin(p.phase)) * 0.4 if p.kind == "arancia" else 0.0))
		p.node.global_position = spot
		p.node.rotation.y = atan2(-here["direction"].x, -here["direction"].z)
		if p.kind in ["pomodoro", "arancia", "anguria"]:
			p.node.rotate_x(delta * 8.0)
		var victim_distance: float = m.rival.distance if p.owner == "apollo" else m.player_distance
		var victim_lane: float = m.rival.lane if p.owner == "apollo" else player_lateral
		if absf(p.distance - victim_distance) < HIT_LENGTH and absf(lane_now - victim_lane) < HIT_WIDTH:
			apply_hit(p, m)
			p.node.queue_free()
			projectiles.remove_at(i)
		elif p.travelled > MAX_TRAVEL or p.distance < -5.0 or p.distance > m.total_length() + 20.0:
			p.node.queue_free()
			projectiles.remove_at(i)

func apply_hit(p: Dictionary, m) -> void:
	if p.owner == "apollo":
		hits_on_rival += 1
		if p.kind == "forbici":
			m.rival.effects.hit(1.2)
			tumble_time = 1.2
		else:
			m.rival.effects.slow(0.5, 2.0)      # multimetro: corto circuito
		rival_hit.emit(p.kind)
		return
	hits_on_player += 1
	var absorbed: bool = not m.vehicle.effects.hit(1.2 if p.kind == "anguria" else 0.0)
	if absorbed:
		m.say("Guanti! Colpo bloccato", 1.8)
		return
	if p.kind != "anguria":
		m.vehicle.effects.slow(0.75, 1.5)
	player_hit.emit(p.kind)
