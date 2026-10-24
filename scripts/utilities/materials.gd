extends RefCounted
## Materiali condivisi: shader originali in assets/shaders, nessuna texture esterna.
## Gli effetti avanzati funzionano con Forward+; con il ripiego OpenGL restano compatibili.
const SHADERS = "res://assets/shaders/"
static var cache: Dictionary = {}

static func shader(file: String, params: Dictionary = {}) -> ShaderMaterial:
	var key := file + str(params)
	if not cache.has(key):
		var result := ShaderMaterial.new()
		result.shader = load(SHADERS + file)
		for parameter: String in params:
			result.set_shader_parameter(parameter, params[parameter])
		cache[key] = result
	return cache[key]

static func grass(fields: bool = false) -> ShaderMaterial:
	return shader("ground.gdshader", {"fields": fields})

static func hedge() -> ShaderMaterial:
	return shader("ground.gdshader", {"grass_light": Color("6f9a52"), "grass_dark": Color("44703f"), "grass_dry": Color("5f8a4a"), "flowers": 0.0})

static func asphalt(color: Color = Color("626b70")) -> ShaderMaterial:
	return shader("asphalt.gdshader", {"base_color": color})

static func paving(color: Color = Color("d6d3c5"), tile: float = 0.7) -> ShaderMaterial:
	return shader("paving.gdshader", {"base_color": color, "tile": tile})

static func walls() -> ShaderMaterial:
	return shader("building.gdshader")

static func roofs() -> ShaderMaterial:
	return shader("roof.gdshader")

static func foliage() -> ShaderMaterial:
	return shader("foliage.gdshader")

static func beacon(color: Color = Color("74f2d8")) -> ShaderMaterial:
	return shader("beacon.gdshader", {"tint": color})

## Materiali per MultiMesh con colore per istanza.
static func instanced(kind: String) -> Material:
	if kind == "trento_paving":
		return paving(Color("ba9d8c"), 0.24)
	if kind == "stone":
		return shader("stone.gdshader")
	if kind == "roller":
		return shader("roller.gdshader")
	if kind == "foliage":
		return foliage()
	if kind == "shutter":
		return shader("shutter.gdshader")
	if kind == "window":
		return shader("window.gdshader")
	if kind == "paving":
		return paving()
	var key := "instanced_" + kind
	if not cache.has(key):
		var result := StandardMaterial3D.new()
		result.vertex_color_use_as_albedo = true
		result.vertex_color_is_srgb = true
		result.roughness = 0.8
		match kind:
			"glass":
				result.roughness = 0.12
				result.metallic = 0.35
				result.metallic_specular = 0.8
			"metal":
				result.roughness = 0.35
				result.metallic = 0.6
			"paint":
				result.roughness = 0.3
				result.metallic_specular = 0.7
				result.clearcoat_enabled = true
				result.clearcoat = 0.5
				result.clearcoat_roughness = 0.2
			"glow":
				result.emission_enabled = true
				result.emission = Color("ffe7a8")
				result.emission_energy_multiplier = 1.6
			"marker":
				result.emission_enabled = true
				result.emission = Color("ffc94d")
				result.emission_energy_multiplier = 1.2
				result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cache[key] = result
	return cache[key]

static func glow(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var key := "glow_" + color.to_html() + str(energy)
	if not cache.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.emission_enabled = true
		result.emission = color
		result.emission_energy_multiplier = energy
		result.roughness = 0.4
		cache[key] = result
	return cache[key]

static func paint(color: Color, gloss: float = 0.28) -> StandardMaterial3D:
	var key := "paint_" + color.to_html() + str(gloss)
	if not cache.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = gloss
		result.metallic_specular = 0.7
		result.clearcoat_enabled = true
		result.clearcoat = 0.6
		result.clearcoat_roughness = 0.15
		result.rim_enabled = true
		result.rim = 0.25
		result.rim_tint = 0.6
		cache[key] = result
	return cache[key]

static func plastic(color: Color, roughness: float = 0.55) -> StandardMaterial3D:
	var key := "plastic_" + color.to_html() + str(roughness)
	if not cache.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = roughness
		cache[key] = result
	return cache[key]

static func metal(color: Color, roughness: float = 0.25) -> StandardMaterial3D:
	var key := "metal_" + color.to_html() + str(roughness)
	if not cache.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.metallic = 0.9
		result.roughness = roughness
		cache[key] = result
	return cache[key]

static func glass(color: Color) -> StandardMaterial3D:
	var key := "glass_" + color.to_html()
	if not cache.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.roughness = 0.04
		result.metallic = 0.3
		result.metallic_specular = 1.0
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
		cache[key] = result
	return cache[key]

## Movimenti ridotti: ferma vento e pulsazioni senza ricreare i materiali.
static func set_reduced_motion(reduced: bool) -> void:
	foliage().set_shader_parameter("sway", 0.0 if reduced else 0.035)
	beacon().set_shader_parameter("pulse", 0.0 if reduced else 1.0)
