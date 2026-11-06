extends RefCounted
## Mappature disponibili anche nei test senza impostazioni dell'editor.

static func setup() -> void:
	bind("accelerate", [KEY_W, KEY_UP], JOY_BUTTON_A)
	bind("reverse", [KEY_S, KEY_DOWN], JOY_BUTTON_B)
	bind("left", [KEY_A, KEY_LEFT], JOY_BUTTON_DPAD_LEFT)
	bind("right", [KEY_D, KEY_RIGHT], JOY_BUTTON_DPAD_RIGHT)
	bind("brake", [KEY_SPACE], JOY_BUTTON_X)
	bind("reset", [KEY_R], JOY_BUTTON_Y)
	bind("pause", [KEY_ESCAPE], JOY_BUTTON_START)
	bind("lights", [KEY_L], JOY_BUTTON_RIGHT_SHOULDER)
	bind("horn", [KEY_H], JOY_BUTTON_LEFT_SHOULDER)
	bind("use_item", [KEY_E], JOY_BUTTON_LEFT_STICK)
	bind("camera", [KEY_C], JOY_BUTTON_RIGHT_STICK)
	bind("zoom_in", [KEY_PAGEUP])
	bind("zoom_out", [KEY_PAGEDOWN])
	for entry in [["left", -1.0], ["right", 1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = entry[1]
		InputMap.action_add_event(entry[0], axis)

static func bind(action: String, keys: Array, button: int = -1) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, 0.18)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	if button >= 0:
		var event := InputEventJoypadButton.new()
		event.button_index = button
		InputMap.action_add_event(action, event)
