extends "res://scripts/gameplay/route_mission.gd"
var park_name: String = ""

func _init() -> void:
	route_mode = true
	park_mode = true

func instructions() -> String:
	if finished:
		return "Apollo è fermo. Cerchiamo la stella fra i giochi!"
	return "Raggiungi il cerchio e fermati con Spazio · %d m" % roundi(vehicle.position.distance_to(destination()))
