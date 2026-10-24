extends Node3D
## Ducato X250 L2H2: pannelli in metri, asse longitudinale -Z.
const G = preload("res://scripts/utilities/geometry.gd")
const Family = preload("res://scripts/characters/family_profile.gd")
const Passenger = preload("res://scripts/characters/seated_passenger.gd")
const Materials = preload("res://scripts/utilities/materials.gd")
const Realistic = preload("res://scripts/vehicles/realistic_ducato.gd")
const X250Front = preload("res://scripts/vehicles/ducato_x250_front.gd")
const X250Rear = preload("res://scripts/vehicles/ducato_x250_rear.gd")
var headlight_material := StandardMaterial3D.new()
var reflector_material := StandardMaterial3D.new()
var exhaust: CPUParticles3D
var passengers: Array[Node3D] = []
var wheels: Array[Node3D] = []
var front_pivots: Array[Node3D] = []
var brake_material := StandardMaterial3D.new()
var lamps: Array[SpotLight3D] = []
var steering_wheel: Node3D
var specification: Dictionary
var white := Color("f2f4f1")
var trim := Color("30363a")
var seam := Color("8f9e9f")
var glass := Color(0.28, 0.46, 0.50, 0.24)
const WHEEL_RADIUS = 0.38
const AXLES = [-1.756, 1.694]

func _ready() -> void:
	specification = JSON.parse_string(FileAccess.get_file_as_string("res://data/vehicles/apollo.json"))
	brake_material.albedo_color = Color("8e1118")
	brake_material.roughness = 0.2
	brake_material.emission_enabled = true
	brake_material.emission = Color("ef201b")
	brake_material.emission_energy_multiplier = 0.08
	reflector_material.albedo_color = Color("b4bdc2")
	reflector_material.metallic = 0.9
	reflector_material.roughness = 0.18
	reflector_material.emission_enabled = true
	reflector_material.emission = Color("fff0d0")
	reflector_material.emission_energy_multiplier = 0.0
	Realistic.build(self)
	front()
	X250Rear.build(self)
	interior()
	finish_materials()
	exhaust_puffs()

func front() -> void:
	X250Front.build(self)

func plate(pos: Vector3, facing_front: bool) -> void:
	var direction := -1.0 if facing_front else 1.0
	G.box(self, pos, Vector3(0.60, 0.14, 0.025), Color("f1efdb"))
	for x in [-0.274, 0.274]:
		G.box(self, pos + Vector3(x, 0, direction * 0.016), Vector3(0.045, 0.12, 0.01), Color("476c8a"))
	var text := G.label(self, "APOLLO", pos + Vector3(0, 0, direction * 0.025), 22)
	text.pixel_size = 0.003
	text.modulate = trim
	if facing_front:
		text.rotation.y = PI

func interior() -> void:
	steering_wheel = Node3D.new()
	steering_wheel.position = Realistic.map_body(Vector3(55.4, 141, 114))
	add_child(steering_wheel)
	for item in get_children():
		if item is MeshInstance3D and str(item.name).contains("driving_wheel"):
			item.reparent(steering_wheel, true)
	var family := Family.load_profile()
	for x in [-0.54, 0.54]:
		var passenger := Node3D.new()
		passenger.set_script(Passenger)
		passenger.position = Vector3(x, 1.05, -1.05)
		passenger.scale = Vector3.ONE * 0.70
		passenger.child_passenger = x > 0
		passenger.profile = family.granddaughter if x > 0 else family.grandfather
		add_child(passenger)
		passengers.append(passenger)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.08, -1.9)
	light.omni_range = 1.6
	light.light_energy = 0.08
	add_child(light)

func animate(delta: float, speed: float, steering: float, braking: bool, headlights: bool) -> void:
	for wheel in wheels:
		wheel.rotate_x(-speed * delta / WHEEL_RADIUS)
	for pivot in front_pivots:
		pivot.rotation.y = steering * 0.4
	steering_wheel.rotation.z = -steering * 0.8
	brake_material.emission_energy_multiplier = 1.8 if braking else 0.08
	headlight_material.emission_energy_multiplier = 2.6 if headlights else 0.0
	reflector_material.emission_energy_multiplier = 0.45 if headlights else 0.0
	for lamp in lamps:
		lamp.visible = headlights
	if is_instance_valid(exhaust):
		exhaust.emitting = absf(speed) > 0.3 and not get_tree().get_meta("apollo_reduced_motion", false)

## Vernice lucida, plastiche, cromature e vetri riflettenti; i pannelli restano a doppia faccia.
func finish_materials() -> void:
	var paint := Realistic.material("varnish")
	var plastic := Realistic.material("black_plastic")
	var window := Materials.glass(Color(0.13, 0.23, 0.28, 0.68))
	headlight_material.albedo_color = Color("f3efdb")
	headlight_material.roughness = 0.08
	headlight_material.metallic = 0.0
	headlight_material.emission_enabled = true
	headlight_material.emission = Color("fff3d2")
	headlight_material.emission_energy_multiplier = 0.0
	headlight_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var chrome := Materials.metal(Color("d6dbd6"), 0.18)
	var hub := Materials.metal(Color("c3cac6"), 0.3)
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node in passengers:
			continue
		stack.append_array(node.get_children())
		var item := node as MeshInstance3D
		if item == null or not item.material_override is StandardMaterial3D:
			continue
		if item.has_meta("realistic_material"):
			continue
		if item.material_override == brake_material:
			continue
		var albedo: Color = (item.material_override as StandardMaterial3D).albedo_color
		if item.material_override == headlight_material:
			item.material_override = headlight_material
		elif albedo.is_equal_approx(white):
			item.material_override = paint
		elif albedo.is_equal_approx(trim):
			item.material_override = plastic
		elif albedo.is_equal_approx(glass):
			item.material_override = window
		elif albedo.is_equal_approx(Color("c4c9c1")) or albedo.is_equal_approx(Color("849296")):
			item.material_override = chrome
		elif albedo.is_equal_approx(Color("bdc4bf")):
			item.material_override = hub
		if item.mesh is CylinderMesh:
			(item.mesh as CylinderMesh).radial_segments = 28

## Sbuffi cartoon dal terminale di scarico, solo in movimento.
func exhaust_puffs() -> void:
	exhaust = CPUParticles3D.new()
	exhaust.name = "Sbuffi"
	exhaust.position = Vector3(-0.62, 0.3, 2.78)
	exhaust.amount = 14
	exhaust.lifetime = 1.1
	exhaust.emitting = false
	exhaust.local_coords = false
	exhaust.direction = Vector3(0, 0.4, 1)
	exhaust.spread = 18.0
	exhaust.initial_velocity_min = 0.6
	exhaust.initial_velocity_max = 1.2
	exhaust.gravity = Vector3(0, 0.6, 0)
	exhaust.scale_amount_min = 0.7
	exhaust.scale_amount_max = 1.2
	var growth := Curve.new()
	growth.add_point(Vector2(0, 0.4))
	growth.add_point(Vector2(1, 2.2))
	exhaust.scale_amount_curve = growth
	var fade := Gradient.new()
	fade.set_color(0, Color(0.95, 0.95, 0.93, 0.55))
	fade.set_color(1, Color(0.95, 0.95, 0.93, 0.0))
	exhaust.color_ramp = fade
	var puff := SphereMesh.new()
	puff.radius = 0.09
	puff.height = 0.18
	puff.radial_segments = 8
	puff.rings = 4
	var puff_material := StandardMaterial3D.new()
	puff_material.vertex_color_use_as_albedo = true
	puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.material = puff_material
	exhaust.mesh = puff
	exhaust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(exhaust)
