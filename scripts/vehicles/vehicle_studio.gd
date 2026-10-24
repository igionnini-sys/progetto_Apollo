extends RefCounted
## Vetrina con luce neutra, fondale continuo e pannelli di riflessione.
const Materials = preload("res://scripts/utilities/materials.gd")

static func setup(stage: Node3D, camera: Camera3D, sun: DirectionalLight3D = null) -> void:
	if sun != null:
		sun.light_cull_mask &= ~2
	var stack: Array[Node] = [stage]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is VisualInstance3D:
			node.layers = 2
		if node is Light3D:
			node.light_cull_mask = 2
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(200, 200)
	floor_mesh.subdivide_width = 32
	floor_mesh.subdivide_depth = 32
	var floor := MeshInstance3D.new()
	floor.mesh = floor_mesh
	floor.position.y = 0.015
	floor.layers = 2
	floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	floor.material_override = Materials.plastic(Color("6d747b"), 0.68)
	stage.add_child(floor)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("a9afb5")
	var sky_material := ShaderMaterial.new()
	sky_material.shader = load("res://assets/shaders/studio_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dfe7ee")
	env.ambient_light_energy = 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.ssao_radius = 0.4
	env.ssao_intensity = 1.2
	camera.environment = env
	camera.cull_mask = 2
	camera.near = 0.15
	camera.far = 80.0
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -35, 0)
	key.light_energy = 0.85
	key.light_color = Color("fff7ed")
	key.light_cull_mask = 2
	key.layers = 2
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 35.0
	key.shadow_normal_bias = 0.5
	key.shadow_bias = 0.06
	key.shadow_blur = 1.5
	key.light_angular_distance = 0.8
	stage.add_child(key)
	for spec: Array in [[Vector3(-4, 6, -4), 0.7, Color("fff7ed")], [Vector3(4, 4, 1), 0.8, Color("edf5ff")], [Vector3(0, 5, 5), 1.0, Color.WHITE]]:
		var light := SpotLight3D.new()
		light.position = spec[0]
		light.light_cull_mask = 2
		light.layers = 2
		light.light_energy = spec[1]
		light.light_color = spec[2]
		light.light_size = 0.25
		light.spot_range = 18.0
		light.spot_angle = 65.0
		light.shadow_enabled = false
		stage.add_child(light)
		light.look_at(stage.to_global(Vector3(0, 1, 0)))
