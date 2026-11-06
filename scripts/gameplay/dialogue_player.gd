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
var last_bark_ms: int = -100000
const BARK_COOLDOWN_MS := 4500

func _ready() -> void:
	profile = Family.load_profile()
	lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/school.json"))
	lines.merge(JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/race.json")))

func format_line(line: Dictionary) -> String:
	var text := str(line.text).replace("{cats}", str(profile.cats.name)).replace("{grandmother}", str(profile.grandmother.name))
	return str(profile[line.speaker].name) + ": «" + text + "»"

func begin(key: String, extra: String = "") -> void:
	sequence = lines[key].duplicate()
	if extra != "":
		sequence.append_array(lines[extra])
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

## Battuta ripetibile durante la gara: una variante a caso, non più di una ogni pochi secondi.
func bark(key: String) -> void:
	var now := Time.get_ticks_msec()
	if now - last_bark_ms < BARK_COOLDOWN_MS or not lines.has(key):
		return
	last_bark_ms = now
	var entry: Variant = lines[key]
	if entry is Array:
		entry = entry.pick_random()
	current_text = format_line(entry)
	line_changed.emit()

## Battuta finale scelta a caso per la schermata dei risultati.
func lines_for_result(won: bool, clean: bool) -> String:
	var key := "race_win_clean" if clean else ("race_win" if won else "race_loss")
	var entry: Array = lines[key]
	var picked: Dictionary = entry.pick_random()
	current_text = format_line(picked)
	return current_text

func bark_active() -> bool:
	return Time.get_ticks_msec() - last_bark_ms < 5500

func reset() -> void:
	last_bark_ms = -100000
	seen.clear()
	sequence = []
	current_text = ""
