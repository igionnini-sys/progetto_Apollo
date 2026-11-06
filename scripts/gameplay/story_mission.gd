extends "res://scripts/gameplay/route_mission.gd"
signal star_collected(count: int)
signal story_event(key: String)
signal coin_collected(count: int)
signal crate_smashed(count: int)
signal bill_collected(cents: int)
const Coin = preload("res://scripts/gameplay/route_coin.gd")
const Smashable = preload("res://scripts/gameplay/smashable.gd")
const Bill = preload("res://scripts/gameplay/route_bill.gd")
const COIN_CENTS := 20
const Walker = preload("res://scripts/gameplay/roadside_walker.gd")
const Star = preload("res://scripts/gameplay/story_star.gd")
const G = preload("res://scripts/utilities/geometry.gd")
var challenge: bool = false
var traffic_index: int = 0
var traffic_light: Node3D
var stops: Array[int] = []
var completed_stops: Array[int] = []
var stop_time: float = 0
var stars: Array[Node3D] = []
var collected_stars: int = 0
var stop_markers: Array[Node3D] = []
var coins: Array[Node3D] = []
var collected_coins: int = 0
var walkers: Array[Node3D] = []
var crates: Array[Node3D] = []
var bills: Array[Node3D] = []
var money_cents: int = 0
var money_total_cents: int = 0
var half_said: bool = false
var smashed_crates: int = 0

func _init() -> void:
	route_mode = true
	story_mode = true

func restart() -> void:
	super.restart()
	collected_stars = 0
	collected_coins = 0
	smashed_crates = 0
	money_cents = 0
	money_total_cents = 0
	half_said = false
	completed_stops.clear()
	stop_time = 0
	traffic_light.reset()
	for star in stars:
		star.queue_free()
	stars.clear()
	stops.clear()
	for marker in stop_markers:
		marker.queue_free()
	stop_markers.clear()
	if challenge:
		stops.assign([int(points.size()*0.25), int(points.size()*0.55)])
		for index in stops:
			var marker := Node3D.new()
			add_child(marker)
			G.cylinder(marker, points[index] + Vector3.UP*0.08, 3.0, 0.08, Color("7ab5be"))
			stop_markers.append(marker)
	for node in coins + walkers + crates + bills:
		node.queue_free()
	coins.clear()
	walkers.clear()
	crates.clear()
	bills.clear()
	if not challenge:
		scatter_coins()
		scatter_crates()
		scatter_bills()
		money_total_cents = coins.size() * COIN_CENTS
		for bill in bills:
			money_total_cents += bill.value
		scatter_walkers()
	for fraction in [0.25, 0.55, 0.80]:
		var target := maxi(1, int(points.size()*fraction))
		var forward := (points[target] - points[target-1]).normalized()
		var star := Node3D.new()
		star.set_script(Star)
		star.position = points[target-1].lerp(points[target], 0.5) + Vector3(forward.z, 0, -forward.x) * 1.2 + Vector3.UP * 1.4
		add_child(star)
		stars.append(star)

## Scia di monete a zig-zag dolce lungo la strada: premia chi guida pulito.
func scatter_coins() -> void:
	var travelled := 0.0
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var length := Vector2(b.x - a.x, b.z - a.z).length()
		if length < 0.1:
			continue
		var forward := (b - a) / length
		var side := Vector3(forward.z, 0, -forward.x)
		var along := 6.0 - fmod(travelled, 6.0)
		if along >= 6.0:
			along = 0.0
		while along < length:
			var wave := sin((travelled + along) * 0.11) * 1.1
			var coin := Node3D.new()
			coin.set_script(Coin)
			coin.position = a + forward * along + side * wave + Vector3.UP * 1.0
			if i > 1 and (i < points.size() - 2 or length > 14.0):
				add_child(coin)
				coins.append(coin)
			else:
				coin.free()
			along += 6.0
		travelled += length

## Banconote perse dal nonno: più rare delle monete e un po' fuori traiettoria.
func scatter_bills() -> void:
	var fractions := [0.08, 0.18, 0.38, 0.47, 0.68, 0.88]
	var values := [500, 1000, 500, 2000, 1000, 5000]
	for n in fractions.size():
		var target := clampi(int(points.size() * fractions[n]), 2, points.size() - 2)
		var forward := (points[target] - points[target - 1]).normalized()
		var side := Vector3(forward.z, 0, -forward.x)
		var bill := Node3D.new()
		bill.set_script(Bill)
		bill.value = values[n]
		bill.position = points[target - 1].lerp(points[target], 0.5) + side * (1.9 if n % 2 == 0 else -1.9) + Vector3.UP * 1.1
		add_child(bill)
		bills.append(bill)

func money_ratio() -> float:
	return float(money_cents) / maxf(1.0, float(money_total_cents))

## "win" = tutto recuperato, "ok" = abbastanza per tornare a testa alta, "lose" = nonna Angela lo saprà.
func money_result() -> String:
	if money_cents >= money_total_cents and money_total_cents > 0:
		return "win"
	return "ok" if money_ratio() >= 0.6 else "lose"

static func euro(cents: int) -> String:
	return "%d,%02d" % [cents / 100, cents % 100]

## Cataste di casse e cassette di frutta ai lati della strada, da sfondare per gioco.
func scatter_crates() -> void:
	var index := 4
	var n := 0
	while index < points.size() - 3:
		var a := points[index]
		var forward := (points[index + 1] - a).normalized()
		var side := Vector3(forward.z, 0, -forward.x)
		for k in (2 if n % 3 == 0 else 1):
			var crate := Node3D.new()
			crate.set_script(Smashable)
			crate.fruit = (n + k) % 2 == 1
			crate.position = a + side * (3.4 if n % 2 == 0 else -3.4) + forward * (k * 1.2)
			add_child(crate)
			crates.append(crate)
		n += 1
		index += 5

## Passanti sul bordo strada, ogni tanto un bambino che saluta.
func scatter_walkers() -> void:
	var index := 6
	var n := 0
	while index < points.size() - 3:
		var a := points[index]
		var forward := (points[index + 1] - a).normalized()
		var side := Vector3(forward.z, 0, -forward.x)
		var walker := Node3D.new()
		walker.set_script(Walker)
		walker.position = a + side * (4.6 if n % 2 == 0 else -4.6)
		walker.axis = forward
		walker.span = 8.0 + (n % 3) * 2.0
		add_child(walker)
		var shirts := [Color("d8584a"), Color("4f8fbf"), Color("e0b640"), Color("6aa86a"), Color("9a6bb5")]
		walker.setup(shirts[n % shirts.size()], Color("3f4a5c"), n % 3 == 2)
		walkers.append(walker)
		n += 1
		index += 9

func _physics_process(delta: float) -> void:
	if not active or finished:
		return
	for crate in crates:
		if is_instance_valid(crate) and not crate.smashed:
			var gap: Vector3 = vehicle.position - crate.position
			if Vector2(gap.x, gap.z).length() < 2.4 and absf(vehicle.speed) > 2.0:
				var heading := Vector3(-gap.x, 0, -gap.z).normalized() + Vector3(0, 0.0, 0)
				crate.smash(heading + Vector3(-vehicle.global_transform.basis.z) * 0.5)
				smashed_crates += 1
				crate_smashed.emit(smashed_crates)
				if smashed_crates == 5:
					story_event.emit("crates_5")
				elif smashed_crates == 20:
					story_event.emit("crates_20")
	for bill in bills:
		var distance: Vector3 = vehicle.position - bill.position
		if not bill.collected and Vector2(distance.x, distance.z).length() < 2.6 and absf(distance.y) < 3.0:
			bill.collect()
			money_cents += bill.value
			bill_collected.emit(bill.value)
			story_event.emit("bill_first")
			check_half()
	for coin in coins:
		var gap: Vector3 = vehicle.position - coin.position
		if not coin.collected and Vector2(gap.x, gap.z).length() < 2.3 and absf(gap.y) < 3.0:
			coin.collect()
			collected_coins += 1
			money_cents += COIN_CENTS
			coin_collected.emit(collected_coins)
			check_half()
			if collected_coins == 15:
				story_event.emit("coins_15")
			elif collected_coins == 50:
				story_event.emit("coins_50")
	for star in stars:
		var offset: Vector3 = vehicle.position - star.position
		if not star.collected and Vector2(offset.x, offset.z).length() < 2.4:
			star.collect()
			collected_stars += 1
			star_collected.emit(collected_stars)
	# Il cerchio finale vale sempre: se una tappa intermedia è stata saltata, ci si porta comunque all'ultima.
	var final_offset := vehicle.position - points[points.size() - 1]
	if stage < points.size() - 1 and Vector2(final_offset.x, final_offset.z).length() < 5.0:
		stage = points.size() - 1
		traffic_light.release()
		changed.emit()
		story_event.emit("arrival")
	if stage == traffic_index and not traffic_light.released:
		story_event.emit("traffic")
		if stopped_near_target():
			stop_time += delta
			if stop_time >= 1.0:
				traffic_light.release()
				stop_time = 0
				story_event.emit("green")
		else:
			stop_time = 0
		return
	if stage in stops and not stage in completed_stops:
		if stopped_near_target():
			stop_time += delta
			if stop_time >= 1.0:
				completed_stops.append(stage)
				stop_time = 0
				story_event.emit("parking")
		else:
			stop_time = 0
		return
	var previous := stage
	super._physics_process(delta)
	if stage != previous:
		if stage > points.size()/3:
			story_event.emit("midway")
		if stage == points.size()-1:
			story_event.emit("arrival")

func check_half() -> void:
	if not half_said and money_ratio() >= 0.5:
		half_said = true
		story_event.emit("money_half")

func stopped_near_target() -> bool:
	var offset := vehicle.position - destination()
	return Vector2(offset.x, offset.z).length() < 5 and absf(vehicle.speed) < 0.4

func instructions() -> String:
	if stage == traffic_index and not traffic_light.released:
		return "ROSSO · Fermati al punto guida per un secondo"
	if stage in stops and not stage in completed_stops:
		return "SOSTA %d / 3 · Fermati nel punto guida" % (completed_stops.size()+1)
	if stage == points.size()-1:
		return "Sosta finale · Fermati nel cerchio azzurro"
	return super.instructions()
