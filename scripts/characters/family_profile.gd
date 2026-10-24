extends RefCounted
## Solo nomi di fantasia e colori; configurazione locale facoltativa, mai richiesta.
static func load_profile(path: String = "res://local/family.json") -> Dictionary:
	var result: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/characters/family.json"))
	if FileAccess.file_exists(path):
		var custom: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if custom is Dictionary:
			for role: String in result:
				if not custom.get(role) is Dictionary:
					continue
				var nickname: Variant = custom[role].get("name")
				if nickname is String and not nickname.strip_edges().is_empty():
					result[role].name = nickname.strip_edges().left(24).replace("\n", " ")
				for key in ["skin", "hair", "shirt"]:
					var value: Variant = custom[role].get(key)
					if value is String and Color.html_is_valid(value):
						result[role][key] = value
	return result
