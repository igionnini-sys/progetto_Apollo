extends RefCounted
## IA di Gino: segue la polilinea, frena in anticipo in curva, sceglie la corsia per non sovrapporsi ad Apollo,
## sfrutta la scia e regola il ritmo sul giocatore (rubber banding morbido).
## Logica pura: il veicolo di Gino legge `distance`, `lane` e si posiziona con track.sample(distance).
const Effects = preload("res://scripts/gameplay/vehicle_effects.gd")
const RACE_ASSIST := {"more_help": 0.90, "normal": 0.935, "challenge": 1.0}   # frazione della velocità massima di Apollo
const MAX_GAP := 40.0
const CATCH_UP := 0.10
const SLOW_DOWN := 0.16
const CATCH_UP_BOOST_GAP := 35.0   # se Apollo è così avanti Gino usa un turbo "di rimonta"
const CATCH_UP_BOOST_EVERY := 9.0
const ACCEL := 5.5
const BOOST_ACCEL := 14.0
const BRAKE := 10.0
const LATERAL_ACCEL := 6.5      # m/s² tollerati in curva
const START_LANE := 1.3
const LANE_LIMIT := 2.0
const LOOKAHEAD := [0.0, 8.0, 16.0, 24.0, 32.0, 42.0]

var track
var effects := Effects.new()
var player_max_speed: float = 15.0
var skill: float = 0.935
var distance: float = 0.0      # avanzamento lungo il percorso (m, non avvolto)
var speed: float = 0.0
var lane: float = START_LANE   # spostamento laterale, positivo a destra
var defeats_in_row: int = 0
var drafting: bool = false
var yielding: bool = false
var time: float = 0.0
var catch_up_cooldown: float = 0.0

func setup(race_track, assist: String = "normal", max_speed: float = 15.0) -> void:
	track = race_track
	player_max_speed = max_speed
	skill = RACE_ASSIST.get(assist, RACE_ASSIST["normal"])

func reset() -> void:
	distance = 0.0
	speed = 0.0
	lane = START_LANE
	time = 0.0
	catch_up_cooldown = 0.0
	drafting = false
	yielding = false
	effects = Effects.new()

## Dopo due sconfitte di fila Gino rallenta un poco; una vittoria larga azzera l'aiuto.
func record_result(player_won: bool, margin_seconds: float) -> void:
	if player_won:
		defeats_in_row = 0 if margin_seconds > 3.0 else maxi(defeats_in_row - 1, 0)
	else:
		defeats_in_row += 1

func effective_skill() -> float:
	return skill * (0.97 if defeats_in_row >= 2 else 1.0)

## Velocità massima ammessa dalle curve nei prossimi metri, includendo lo spazio di frenata.
func corner_limit() -> float:
	var limit := INF
	for look: float in LOOKAHEAD:
		var curve: float = track.curvature(distance + look, 9.0)
		if curve > 0.004:
			var safe: float = sqrt(LATERAL_ACCEL / curve)
			limit = minf(limit, sqrt(safe * safe + 2.0 * BRAKE * look))
	return limit

## player_distance / player_lateral: posizione di Apollo sullo stesso asse di `distance` e `lane`.
func step(delta: float, player_distance: float, player_lateral: float = 0.0) -> void:
	time += delta
	effects.update(delta)
	var gap := distance - player_distance      # >0: Gino è davanti
	var diff := lane - player_lateral
	# Rimonta: se Apollo è molto avanti, Gino usa un turbo ogni tanto (come se avesse preso una striscia).
	catch_up_cooldown = maxf(catch_up_cooldown - delta, 0.0)
	if gap < -CATCH_UP_BOOST_GAP and catch_up_cooldown == 0.0 and not effects.is_boosting():
		effects.boost(1.0)
		catch_up_cooldown = CATCH_UP_BOOST_EVERY
	# Scia: dietro ad Apollo, quasi nella sua corsia.
	drafting = gap < -3.0 and gap > -16.0 and absf(diff) < 1.9
	if drafting:
		effects.draft()
	# Corsia: libera quella di Apollo quando gli è accanto o davanti da vicino.
	var target_lane := START_LANE
	yielding = gap > -6.0 and gap < 7.0 and absf(diff) < 2.6
	if yielding:
		var preferred := 1.0 if diff >= 0.0 else -1.0
		target_lane = clampf(player_lateral + preferred * 2.7, -LANE_LIMIT, LANE_LIMIT)
		var other := clampf(player_lateral - preferred * 2.7, -LANE_LIMIT, LANE_LIMIT)
		# Se da una parte non c'è spazio, passa dall'altra.
		if absf(other - player_lateral) > absf(target_lane - player_lateral) + 0.3:
			target_lane = other
	lane = move_toward(lane, target_lane, 2.2 * delta)
	# Ritmo: rubber banding morbido più una piccola variazione, così non sembra un binario.
	var assist := clampf(-gap / MAX_GAP, -1.0, 1.0)
	# Più forte quando Gino è indietro (rimonta), un po' più lieve quando è davanti.
	var rubber := 1.0 + (CATCH_UP if assist > 0.0 else SLOW_DOWN) * assist
	var target := player_max_speed * effective_skill() * rubber * (1.0 + 0.02 * sin(time * 0.9))
	target *= effects.speed_multiplier()
	var squeezed := yielding and absf(lane - player_lateral) < 2.0
	if squeezed:
		target *= 0.92
	target = minf(target, corner_limit())
	var rate := BOOST_ACCEL if effects.is_boosting() else ACCEL
	if speed < target:
		speed = minf(speed + rate * delta, target)
	else:
		speed = maxf(speed - BRAKE * delta, target)
	distance += speed * delta
