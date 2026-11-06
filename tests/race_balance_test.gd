extends SceneTree
## Equilibratura del livello 2 senza scena: Apollo automatico a bassa/media/alta abilità contro Gino.
## Il giocatore simulato segue il percorso, frena in curva, prende strisce e partenza lanciata in base all'abilità.
const RaceTrack = preload("res://scripts/gameplay/race_track.gd")
const Rival = preload("res://scripts/gameplay/rival_driver.gd")
const Effects = preload("res://scripts/gameplay/vehicle_effects.gd")
const RUNS := 60
const DT := 1.0 / 60.0
var failures: int = 0
var track: RaceTrack
var pads: Array = []
var items: Array = []

func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: " + message)
	else:
		failures += 1
		push_error(message)

## skill: frazione della velocità massima; pad_rate: probabilità di centrare una striscia; launch: probabilità di partenza lanciata.
func race(assist: String, skill: float, pad_rate: float, launch: float, defeats: int = 0, item_rate: float = 0.7) -> Dictionary:
	var rival := Rival.new()
	rival.setup(track, assist, 15.0)
	rival.defeats_in_row = defeats
	rival.reset()
	var effects := Effects.new()
	var distance := 0.0
	var speed := 0.0
	var time := 0.0
	var lateral := -1.3
	var corner_accel := 5.0 + skill * 3.0
	var next_pad := 0
	var next_item := 0
	var rival_next_item := 0
	var draft_charge := 0.0
	var skill_now := skill * randf_range(0.93, 1.07)
	if randf() < launch:
		effects.boost(1.4)
	while distance < track.length and rival.distance < track.length and time < 300.0:
		effects.update(DT)
		var gap := rival.distance - distance
		var drafting := gap > 3.0 and gap < 16.0 and absf(rival.lane - lateral) < 1.9
		if drafting:
			effects.draft()
			draft_charge += DT
			if draft_charge > 2.2:
				effects.boost(1.0)
				draft_charge = 0.0
		else:
			draft_charge = maxf(draft_charge - 2.0 * DT, 0.0)
		rival.step(DT, distance, lateral)
		var target := 15.0 * skill_now * effects.speed_multiplier()
		var limit := INF
		for look in [0.0, 8.0, 16.0, 24.0, 32.0, 42.0]:
			var curve: float = track.curvature(distance + look, 9.0)
			if curve > 0.004:
				var safe := sqrt(corner_accel / curve)
				limit = minf(limit, sqrt(safe * safe + 2.0 * 10.0 * look))
		target = minf(target, limit)
		speed = move_toward(speed, target, (18.0 if effects.is_boosting() else 5.0) * DT) if speed < target else maxf(speed - 10.0 * DT, target)
		var before := distance
		distance += speed * DT
		while next_pad < pads.size() and before < pads[next_pad] and distance >= pads[next_pad]:
			if randf() < pad_rate:
				effects.boost()
			next_pad += 1
		# Oggetti: cassette ogni 130 m dal metro 90. Il giocatore usa batteria o forbici; Gino lancia frutta.
		while next_item < items.size() and before < items[next_item] and distance >= items[next_item]:
			if randf() < item_rate:
				var roll := randf()
				if roll < 0.45:
					effects.boost(2.0)
				elif roll < 0.8:
					rival.effects.hit(1.2)
			next_item += 1
		while rival_next_item < items.size() and rival.distance >= items[rival_next_item]:
			if randf() < 0.5 and rival.distance < distance:
				pass
			elif randf() < 0.5 and rival.distance > distance:
				effects.slow(0.75, 1.5)
			rival_next_item += 1
		time += DT
	return {"won": distance >= track.length and distance >= rival.distance, "margin": (distance - rival.distance) / 15.0, "time": time}

func series(assist: String, skill: float, pad_rate: float, launch: float, defeats: int = 0, item_rate: float = 0.7) -> Dictionary:
	var wins := 0
	var margin := 0.0
	var total_time := 0.0
	for i in RUNS:
		var result := race(assist, skill, pad_rate, launch, defeats, item_rate)
		wins += 1 if result.won else 0
		margin += result.margin
		total_time += result.time
	return {"win_rate": float(wins) / RUNS, "margin": margin / RUNS, "time": total_time / RUNS}

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/level2_race.json"))
	track = RaceTrack.new()
	track.setup(data.route, false)
	for pad: Dictionary in data.boost_pads:
		pads.append(float(pad.distance))
	for pickup: Dictionary in data.item_pickups:
		items.append(float(pickup.distance))
	seed(20261106)
	var profiles := {"bassa": [0.86, 0.5, 0.2, 0.5], "media": [0.92, 0.8, 0.6, 0.8], "alta": [0.98, 1.0, 0.95, 1.0]}
	var results := {}
	for assist in ["more_help", "normal", "challenge"]:
		for profile in profiles:
			var p: Array = profiles[profile]
			var r := series(assist, p[0], p[1], p[2], 0, p[3])
			results[assist + "/" + profile] = r
			print("%-9s %-5s vittorie %3d%%  margine medio %+5.1f s  tempo %4.0f s" % [assist, profile, roundi(r.win_rate * 100.0), r.margin, r.time])
	var low_after_losses := series("normal", 0.86, 0.5, 0.2, 2, 0.5)
	print("normal/bassa dopo 2 sconfitte: vittorie %d%%" % roundi(low_after_losses.win_rate * 100.0))
	# Obiettivi: facile ma non scontato.
	check(results["normal/alta"].win_rate >= 0.8 and results["normal/alta"].win_rate <= 1.0, "Normale: l'abilità alta vince spesso ma non sempre")
	check(results["normal/media"].win_rate >= 0.45 and results["normal/media"].win_rate <= 0.95, "Normale: l'abilità media se la gioca")
	check(results["normal/bassa"].win_rate >= 0.1 and results["normal/bassa"].win_rate <= 0.55, "Normale: l'abilità bassa può ancora vincere con turbo e strisce")
	check(results["more_help/bassa"].win_rate > results["normal/bassa"].win_rate, "Più aiuto rende la vittoria più facile")
	check(results["challenge/media"].win_rate < results["normal/media"].win_rate, "Sfida è più difficile di Normale")
	check(low_after_losses.win_rate > results["normal/bassa"].win_rate, "Dopo due sconfitte Gino è più lento")
	for key in results:
		check(results[key].time > 55.0 and results[key].time < 110.0, "Durata plausibile " + key)
	print("Equilibratura gara: %s" % ("OK" if failures == 0 else "%d FALLITE" % failures))
	quit(failures)
