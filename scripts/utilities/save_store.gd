extends RefCounted
## Un solo documento locale, senza coordinate o dati personali.
const DEFAULTS = {"music": 0.35, "effects": 0.65, "gentle": false, "reduced_motion": false, "shadows": true, "hq_graphics": true, "camera": 4.0, "race_assist": 0.5}
var path: String = "user://apollo_save.json"
var memory_only: bool = false
var settings: Dictionary = DEFAULTS.duplicate()
var parks: Array = []
var stories: Array = []
var achievements: Array = []
var journey_stars: Dictionary = {"school": 0, "parking": 0}
var recovered: bool = false
var last_error: String = ""

static func session(tree: SceneTree) -> RefCounted:
	if tree.has_meta("apollo_save_store"):
		return tree.get_meta("apollo_save_store")
	var result = load("res://scripts/utilities/save_store.gd").new()
	var tree_script: Script = tree.get_script()
	result.memory_only = tree_script != null and tree_script.resource_path.begins_with("res://tests/")
	if not result.memory_only:
		result.restore()
	if not tree.has_meta("apollo_park_rewards"):
		tree.set_meta("apollo_park_rewards", result.parks.duplicate())
	if not tree.has_meta("apollo_story_rewards"):
		tree.set_meta("apollo_story_rewards", result.stories.duplicate())
	tree.set_meta("apollo_save_store", result)
	return result

func read_document(filename: String) -> Dictionary:
	if not FileAccess.file_exists(filename):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(filename)) != OK:
		return {}
	if not parser.data is Dictionary or parser.data.get("version") != 1:
		return {}
	return parser.data

func restore() -> void:
	settings = DEFAULTS.duplicate()
	parks = []
	stories = []
	achievements = []
	journey_stars = {"school": 0, "parking": 0}
	recovered = false
	var data := read_document(path)
	if data.is_empty():
		data = read_document(path + ".bak")
		recovered = not data.is_empty()
	apply_document(data)

func apply_document(data: Dictionary) -> void:
	var source: Variant = data.get("settings", {})
	if source is Dictionary:
		for key in DEFAULTS:
			var value: Variant = source.get(key, DEFAULTS[key])
			if DEFAULTS[key] is bool:
				settings[key] = value if value is bool else DEFAULTS[key]
			elif (value is float or value is int) and is_finite(float(value)):
				settings[key] = clampf(float(value), 1.0 if key == "camera" else 0.0, 6.0 if key == "camera" else 1.0)
	parks = validated_ids(data.get("parks", []), ["madonna", "san_grato"])
	stories = validated_ids(data.get("stories", []), ["school", "parking"])
	if "parking" in stories and not "school" in stories:
		stories.erase("parking")
	achievements = validated_ids(data.get("achievements", []), ["wallet", "all_money"])
	var star_data: Variant = data.get("journey_stars", {})
	if star_data is Dictionary:
		for id in journey_stars:
			var value: Variant = star_data.get(id, 0)
			if (value is int or value is float) and is_finite(float(value)):
				journey_stars[id] = clampi(int(value), 0, 3)

func validated_ids(values: Variant, allowed: Array) -> Array:
	var result: Array = []
	if values is Array:
		for value in values:
			if value in allowed and not value in result:
				result.append(value)
	return result

func save(tree: SceneTree = null) -> bool:
	last_error = ""
	if tree != null:
		parks = validated_ids(tree.get_meta("apollo_park_rewards", []), ["madonna", "san_grato"])
		stories = validated_ids(tree.get_meta("apollo_story_rewards", []), ["school", "parking"])
	if memory_only:
		return true
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Impossibile scrivere il salvataggio. I premi restano disponibili nella partita."
		return false
	file.store_string(JSON.stringify({"version": 1, "settings": settings, "parks": parks, "stories": stories, "achievements": achievements, "journey_stars": journey_stars}, "\t"))
	file.flush()
	var status := file.get_error()
	file.close()
	if status != OK:
		last_error = "Scrittura del salvataggio non riuscita."
		return false
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		# Non sostituire una copia valida con un documento danneggiato.
		var suffix := ".bak" if not read_document(path).is_empty() else ".corrupt"
		if FileAccess.file_exists(path + suffix):
			if DirAccess.remove_absolute(absolute + suffix) != OK:
				last_error = "Impossibile aggiornare la copia di sicurezza."
				return false
		if DirAccess.rename_absolute(absolute, absolute + suffix) != OK:
			last_error = "Impossibile conservare il salvataggio precedente."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) != OK:
		last_error = "Impossibile completare il salvataggio; la copia precedente resta recuperabile."
		return false
	return true
