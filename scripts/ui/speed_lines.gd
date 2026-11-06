extends Control
## Linee di velocità ai bordi dello schermo durante il turbo; disattivate con "Movimenti ridotti".
var intensity: float = 0.0   # 0..1 richiesto dal gioco
var shown: float = 0.0
var seeds: Array[float] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 36:
		seeds.append(randf())

func _process(delta: float) -> void:
	var wanted := 0.0 if get_tree().get_meta("apollo_reduced_motion", false) or get_tree().paused else intensity
	shown = lerpf(shown, wanted, 1.0 - exp(-9.0 * delta))
	visible = shown > 0.02
	if visible:
		queue_redraw()

func _draw() -> void:
	var centre := size * 0.5
	var reach := size.length() * 0.5
	var time := Time.get_ticks_msec() / 1000.0
	for i in seeds.size():
		var angle := TAU * (float(i) / seeds.size() + seeds[i] * 0.02)
		var pulse := fposmod(time * (2.2 + seeds[i]) + seeds[i] * 7.0, 1.0)
		var start := reach * (0.58 + 0.2 * pulse)
		var end := start + reach * (0.12 + 0.2 * seeds[i]) * shown
		var direction := Vector2(cos(angle), sin(angle) * 0.62)
		draw_line(centre + direction * start, centre + direction * end, Color(1, 1, 1, 0.85 * shown * (1.0 - pulse * 0.4)), 3.0 + 3.0 * seeds[i])
