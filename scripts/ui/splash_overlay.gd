extends Control
## Schizzo di frutta sul parabrezza: macchie che svaniscono in un paio di secondi.
var blobs: Array[Dictionary] = []
var life: float = 0.0
var tint: Color = Color("d8402a")

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func splash(color: Color) -> void:
	tint = color
	life = 2.4
	blobs.clear()
	for i in 7:
		blobs.append({"p": Vector2(randf_range(0.25, 0.75), randf_range(0.2, 0.7)), "r": randf_range(0.025, 0.07)})
	show()

func _process(delta: float) -> void:
	if life <= 0.0:
		return
	life -= delta
	if life <= 0.0:
		hide()
	queue_redraw()

func _draw() -> void:
	var fade := clampf(life / 1.2, 0.0, 1.0)
	var drip := (1.0 - clampf(life / 2.4, 0.0, 1.0)) * 0.06
	for blob in blobs:
		var centre := Vector2(size.x * blob.p.x, size.y * (blob.p.y + drip))
		draw_circle(centre, size.y * blob.r, Color(tint.r, tint.g, tint.b, 0.55 * fade))
		draw_circle(centre + Vector2(0, size.y * blob.r * 0.9), size.y * blob.r * 0.45, Color(tint.r, tint.g, tint.b, 0.6 * fade))
