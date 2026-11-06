extends SceneTree
## Logica di gara del livello 2 senza scena: percorso, effetti, Gino da solo su 2 giri.
const RaceTrack = preload("res://scripts/gameplay/race_track.gd")
const Rival = preload("res://scripts/gameplay/rival_driver.gd")
const Effects = preload("res://scripts/gameplay/vehicle_effects.gd")
var failures: int = 0

func check(condition: bool, message: String) -> void:
	if condition:
		print("OK: " + message)
	else:
		failures += 1
		push_error(message)

func ring() -> RaceTrack:
	var track := RaceTrack.new()
	# Anello di prova 200 x 100 m con angoli smussati: 600 m circa.
	track.setup([Vector3(0, 0, 0), Vector3(180, 0, 0), Vector3(200, 0, 20), Vector3(200, 0, 80),
		Vector3(180, 0, 100), Vector3(20, 0, 100), Vector3(0, 0, 80), Vector3(0, 0, 20)], true)
	return track

func _initialize() -> void:
	var track := ring()
	check(track.length > 540.0 and track.length < 620.0, "lunghezza anello %.0f m" % track.length)
	check(absf(track.project(Vector3(90, 0, 3))) < 100.0 and track.project(Vector3(90, 0, 3)) > 80.0, "proiezione sul primo rettilineo")
	var fx := Effects.new()
	fx.boost()
	check(fx.speed_multiplier() > 1.4, "turbo aumenta la velocità")
	fx.update(2.0)
	check(is_equal_approx(fx.speed_multiplier(), 1.0), "turbo termina dopo 1,5 s")
	fx.shield()
	check(not fx.hit() and not fx.is_stunned(), "guanto assorbe un colpo")
	check(fx.hit() and fx.is_stunned() and fx.speed_multiplier() == 0.0, "secondo colpo stordisce")
	for level in ["more_help", "normal", "challenge"]:
		var rival := Rival.new()
		rival.setup(track, level, 15.0)
		var time := 0.0
		while rival.distance < track.length * 2.0 and time < 400.0:
			rival.step(1.0 / 60.0, rival.distance - 30.0)   # giocatore sempre 30 m dietro
			time += 1.0 / 60.0
		check(time < 400.0 and time > 60.0, "Gino (%s) completa 2 giri in %.0f s" % [level, time])
	var slow := Rival.new()
	slow.setup(track, "normal", 15.0)
	var base := slow.effective_skill()
	slow.record_result(false, 0.0)
	slow.record_result(false, 0.0)
	check(slow.effective_skill() < base, "dopo due sconfitte Gino rallenta")
	slow.record_result(true, 5.0)
	check(is_equal_approx(slow.effective_skill(), base), "vittoria larga riporta Gino normale")
	print("Verifiche logica gara: %s" % ("OK" if failures == 0 else "%d FALLITE" % failures))
	quit(failures)
