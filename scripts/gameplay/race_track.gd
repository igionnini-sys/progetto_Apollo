extends RefCounted
## Percorso di gara come polilinea (anello o sprint) con avanzamento lungo la linea.
## Serve a Gino (IA), alle posizioni in classifica e ai punti di controllo.
var points: Array[Vector3] = []
var closed: bool = true
var cumulative: Array[float] = []
var length: float = 0.0

func setup(line: Array, is_closed: bool) -> void:
	points.clear()
	for p in line:
		points.append(p if p is Vector3 else Vector3(p[0], 0.0, p[1]))
	closed = is_closed
	cumulative = [0.0]
	for i in range(1, points.size()):
		cumulative.append(cumulative[i - 1] + points[i - 1].distance_to(points[i]))
	length = cumulative[-1]
	if closed and points.size() > 1:
		length += points[-1].distance_to(points[0])

func _segments() -> int:
	return points.size() if closed else points.size() - 1

## Distanza lungo il percorso (0..length) del punto più vicino a `position`.
func project(position: Vector3) -> float:
	var best := INF
	var best_s := 0.0
	for i in _segments():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var ab := b - a
		var seg := ab.length()
		if seg < 0.001:
			continue
		var t := clampf((position - a).dot(ab) / (seg * seg), 0.0, 1.0)
		var d := position.distance_to(a + ab * t)
		if d < best:
			best = d
			best_s = cumulative[i] + seg * t
	return best_s

## Punto e direzione alla distanza `s` (avvolta se l'anello è chiuso).
func sample(s: float) -> Dictionary:
	s = fposmod(s, length) if closed else clampf(s, 0.0, length)
	var count := _segments()
	for i in count:
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var seg := a.distance_to(b)
		if s <= cumulative[i] + seg or i == count - 1:
			var t := clampf((s - cumulative[i]) / maxf(seg, 0.001), 0.0, 1.0)
			return {"position": a.lerp(b, t), "direction": (b - a).normalized()}
	return {"position": points[0], "direction": Vector3.FORWARD}

## Curvatura approssimata (rad/m) alla distanza `s`, per il profilo di velocità in curva.
func curvature(s: float, span: float = 12.0) -> float:
	var d0: Vector3 = sample(s - span)["direction"]
	var d1: Vector3 = sample(s + span)["direction"]
	return absf(d0.signed_angle_to(d1, Vector3.UP)) / (span * 2.0)

## Spostamento laterale (positivo a destra) di `position` rispetto al percorso alla distanza `s`.
func lateral(position: Vector3, s: float) -> float:
	var here: Dictionary = sample(s)
	var right: Vector3 = (here["direction"] as Vector3).cross(Vector3.UP)
	return (position - (here["position"] as Vector3)).dot(right)
