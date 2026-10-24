extends Node
signal line_changed
signal sequence_finished
const Family = preload("res://scripts/characters/family_profile.gd")
var lines: Dictionary
var profile: Dictionary
var sequence: Array = []
var index: int = 0
var current_text: String = ""
var seen: Dictionary = {}

func _ready() -> void:
	profile = Family.load_profile()
	lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/school.json"))

func format_line(line: Dictionary) -> String:
	return str(profile[line.speaker].name) + ": «" + str(line.text) + "»"

func begin(key: String) -> void:
	sequence = lines[key]
	index = 0
	current_text = format_line(sequence[index])
	line_changed.emit()

func advance() -> void:
	if sequence.is_empty():
		return
	index += 1
	if index >= sequence.size():
		sequence = []
		sequence_finished.emit()
	else:
		current_text = format_line(sequence[index])
		line_changed.emit()

func say(key: String) -> void:
	if seen.has(key):
		return
	seen[key] = true
	current_text = format_line(lines[key])
	line_changed.emit()

func reset() -> void:
	seen.clear()
	sequence = []
	current_text = ""
