extends Node
## Obiettivo di collaudo: quattro tappe in ordine, poi arresto alla partenza.
signal changed
signal completed
var vehicle: CharacterBody3D
var points: Array[Vector3] = []
var stage: int = 0
var finished: bool = false
var active: bool = false
var parking_time: float = 0.0
var route_mode: bool = false
var park_mode: bool = false
var story_mode: bool = false
var departure_points: int = 0

func _physics_process(delta: float) -> void:
	if not active or finished:
		return
	var distance := Vector2(vehicle.position.x - destination().x, vehicle.position.z - destination().z).length()
	var reach := 1.3 if stage < departure_points else 7.0
	if stage < points.size() - 1 and distance < reach:
		stage += 1
		changed.emit()
	elif stage == points.size() - 1:
		if distance < 5.0 and absf(vehicle.speed) < 0.4:
			parking_time += delta
			if parking_time > 1.0:
				finished = true
				completed.emit()
		else:
			parking_time = 0.0

func destination() -> Vector3:
	return points[mini(stage, points.size() - 1)]

func restart() -> void:
	stage = 0
	finished = false
	parking_time = 0.0
	changed.emit()

func instructions() -> String:
	if finished:
		return "Bravo pilota! Il primo giro è completato."
	if stage == points.size() - 1:
		return "Parcheggia sotto l'ultimo arco e fermati con Spazio."
	return "Segui la strada e raggiungi l'arco %d." % (stage + 1)
