extends RefCounted
## Luce del mattino condivisa: cielo procedurale con Alpi, sole morbido da est e post-processing.
## SSAO, SSIL e ombre morbide richiedono Forward+; con il ripiego OpenGL vengono ignorati.

static func create(parent: Node, realistic: bool = false) -> Dictionary:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "Atmosfera"
	var env := Environment.new()
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load("res://assets/shaders/sky.gdshader")
	if realistic:
		var colors := {"top_color": Color("6185ac"), "horizon_color": Color("c0cbd0"), "ground_color": Color("8f9685"), "mountain_color": Color("7c8b98"), "hill_color": Color("8a9588")}
		for parameter: String in colors:
			sky_material.set_shader_parameter(parameter, colors[parameter])
		sky_material.set_shader_parameter("mountain_scale", 0.45)
	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color("c6d7e4")
	env.ambient_light_sky_contribution = 0.20
	env.ambient_light_energy = 0.65
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.92
	env.tonemap_white = 6.0
	env.fog_enabled = true
	env.fog_light_color = Color("79cbd0")
	# Nebbia per profondità: vicino e media distanza nitidi, campagna lontana sfumata nel cielo.
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_begin = 85.0
	env.fog_depth_end = 610.0
	env.fog_depth_curve = 1.6
	env.fog_aerial_perspective = 0.45
	env.fog_sky_affect = 0.0
	env.fog_sun_scatter = 0.12
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 1.12
	if realistic:
		env.adjustment_saturation = 0.94
		env.fog_light_color = Color("bcc8d0")
		env.fog_depth_begin = 180.0
		env.fog_depth_end = 1600.0
		env.ambient_light_color = Color("d1dae2")
	env.glow_enabled = true
	env.glow_intensity = 0.22
	env.glow_strength = 0.8
	env.glow_bloom = 0.015
	env.glow_hdr_threshold = 1.0
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.65
	env.ssao_power = 1.35
	env.ssao_detail = 0.6
	env.ssao_light_affect = 0.15
	env.ssil_radius = 4.0
	env.ssil_intensity = 0.8
	world_environment.environment = env
	parent.add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sole"
	# Sole del mattino da est-sud-est: ombre lunghe e calde verso ovest.
	sun.rotation_degrees = Vector3(-43, 62, 0)
	sun.light_color = Color("ffe6cb")
	sun.light_energy = 1.4
	if realistic:
		sun.light_color = Color("fff4e4")
		sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 0.65
	sun.shadow_blur = 1.2
	sun.directional_shadow_blend_splits = true
	sun.directional_shadow_max_distance = 150.0
	parent.add_child(sun)
	return {"environment": env, "sun": sun}

static func apply_quality(env: Environment, sun: DirectionalLight3D, high: bool, shadows: bool) -> void:
	var forward_plus := RenderingServer.get_current_rendering_method() == "forward_plus"
	if env != null:
		env.ssao_enabled = high and forward_plus
		env.ssil_enabled = high and forward_plus
		env.glow_enabled = true
	if sun != null:
		sun.shadow_enabled = shadows
		sun.light_angular_distance = 1.1 if high else 0.0
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if high else DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
