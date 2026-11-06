extends RefCounted
## Stati temporanei di un veicolo da gara (Apollo o Gino): turbo, scudo, rallentamento, stordimento.
## Logica pura, senza nodi: il veicolo chiama update(delta) e legge speed_multiplier().
const BOOST_PAD_SECONDS := 1.5
const BOOST_MULTIPLIER := 22.0 / 15.0   # fino a circa 22 m/s con max_speed 15
const STUN_SECONDS := 1.2

var boost_time: float = 0.0
var shield_time: float = 0.0
var slow_time: float = 0.0
var slow_factor: float = 1.0
var stun_time: float = 0.0
var draft_time: float = 0.0
const DRAFT_MULTIPLIER := 1.06

func update(delta: float) -> void:
	boost_time = maxf(boost_time - delta, 0.0)
	shield_time = maxf(shield_time - delta, 0.0)
	slow_time = maxf(slow_time - delta, 0.0)
	stun_time = maxf(stun_time - delta, 0.0)
	draft_time = maxf(draft_time - delta, 0.0)
	if slow_time == 0.0:
		slow_factor = 1.0

## Scia: da richiamare a ogni frame finché si è dietro l'altro veicolo.
func draft(seconds: float = 0.15) -> void:
	draft_time = seconds

func is_boosting() -> bool:
	return boost_time > 0.0

func boost(seconds: float = BOOST_PAD_SECONDS) -> void:
	boost_time = maxf(boost_time, seconds)

func shield(seconds: float = 5.0) -> void:
	shield_time = seconds

func slow(factor: float, seconds: float) -> void:
	if shield_time > 0.0:
		return
	slow_factor = factor
	slow_time = seconds

## Colpo: il guanto isolante assorbe un solo colpo. Restituisce true se il colpo è andato a segno.
func hit(stun_seconds: float = STUN_SECONDS) -> bool:
	if shield_time > 0.0:
		shield_time = 0.0
		return false
	stun_time = stun_seconds
	return true

func is_stunned() -> bool:
	return stun_time > 0.0

func speed_multiplier() -> float:
	if stun_time > 0.0:
		return 0.0
	var value := slow_factor if slow_time > 0.0 else 1.0
	if boost_time > 0.0:
		value *= BOOST_MULTIPLIER
	if draft_time > 0.0:
		value *= DRAFT_MULTIPLIER
	return value
