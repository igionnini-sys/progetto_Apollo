extends "res://scripts/gameplay/practice_mission.gd"
## Percorso di esplorazione OSM; non certifica l'accesso al cancello scolastico.

func _init() -> void:
	route_mode = true

func instructions() -> String:
	if finished:
		return "Bravo pilota! Hai esplorato un pezzetto di Volpiano."
	var offset := destination() - vehicle.global_position
	if stage < departure_points:
		return "↓  Esci dal cancello in retromarcia (S) · %d m" % roundi(offset.length())
	var angle := angle_difference(vehicle.rotation.y, atan2(-offset.x, -offset.z))
	var arrow := "↑"
	if angle > 0.35:
		arrow = "←"
	elif angle < -0.35:
		arrow = "→"
	if stage == points.size() - 1:
		return "%s  Arrivo esplorazione · %d m · Fermati sul cerchio" % [arrow, roundi(offset.length())]
	return "%s  Segui i punti dorati · prossima tappa %d m" % [arrow, roundi(offset.length())]
