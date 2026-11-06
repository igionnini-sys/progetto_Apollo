extends SceneTree
## Verifica che nessun edificio (collisione reale) invada la carreggiata lungo il percorso della gara.
## Ogni 3 m si lanciano due raggi laterali dall'asse e si confronta la distanza con la semilarghezza della strada.
var failures: int = 0
const MIN_CLEAR := 3.0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
	main.use_volpiano = true
	main.selected_race = "level2_race"
	root.add_child(main)
	for i in 5:
		await physics_frame
	var track = main.mission.track
	var space := main.get_world_3d().direct_space_state
	var bad: Array = []
	var s := 0.0
	while s < track.length:
		var here: Dictionary = track.sample(s)
		var centre: Vector3 = here["position"] + Vector3.UP * 1.0
		var right: Vector3 = (here["direction"] as Vector3).cross(Vector3.UP)
		for side in [-1.0, 1.0]:
			var query := PhysicsRayQueryParameters3D.create(centre, centre + right * side * 6.0)
			query.collision_mask = 0xFFFFFFFF
			query.exclude = [main.vehicle.get_rid()]
			var hit := space.intersect_ray(query)
			if not hit.is_empty():
				var distance: float = centre.distance_to(hit.position)
				if distance < MIN_CLEAR:
					bad.append([snappedf(s, 1.0), side, snappedf(distance, 0.01), str(hit.collider.name)])
		s += 3.0
	for entry in bad:
		print("INVASIONE a %d m, lato %s: libero %.2f m (%s)" % [entry[0], "dx" if entry[1] > 0 else "sx", entry[2], entry[3]])
	var ok := bad.is_empty()
	print("Percorso libero: %s (%d punti critici)" % ["OK" if ok else "NO", bad.size()])
	main.free()
	quit(0 if ok else 1)
