extends CharacterBody3D
const Effects = preload("res://scripts/gameplay/vehicle_effects.gd")
## Arcade sul piano XZ: fronte locale -Z; velocità in metri/secondo.

@export var max_speed: float = 15.0
@export var reverse_speed: float = 5.0
@export var acceleration: float = 5.0
@export var braking: float = 12.0
@export var steering_response: float = 4.0
@export var recovery_radius: float = 190.0
var speed: float = 0.0
var steering: float = 0.0
var enabled: bool = true
var effects := Effects.new()
var boost_sparks: CPUParticles3D
var lights_on: bool = false
var spawn_transform: Transform3D
@onready var visual: Node3D = $Visual

func _ready() -> void:
	# Strato 2: muri del sottopasso. Il furgone li urta, la camera di inseguimento li attraversa.
	collision_mask = 3
	spawn_transform = global_transform
	boost_sparks = make_sparks()
	add_child(boost_sparks)

func _physics_process(delta: float) -> void:
	if enabled and Input.is_action_just_pressed("reset"):
		reset_vehicle()
	if enabled and Input.is_action_just_pressed("lights"):
		lights_on = not lights_on
	effects.update(delta)
	var throttle := Input.get_axis("reverse", "accelerate") if enabled else 0.0
	if enabled and effects.is_boosting():
		throttle = 1.0
	var stopping := Input.is_action_pressed("brake") or not enabled
	var target := throttle * (max_speed if throttle >= 0.0 else reverse_speed) * (effects.speed_multiplier() if throttle > 0.0 else 1.0)
	var rate := acceleration
	if stopping:
		target = 0.0
		rate = braking
	elif throttle == 0.0:
		rate = 2.2
	elif throttle * speed < 0.0:
		rate = braking
	if effects.is_boosting():
		rate = maxf(rate, 18.0)
	if effects.is_stunned():
		rate = braking
	speed = move_toward(speed, target, rate * delta)
	var turn := Input.get_axis("right", "left") if enabled else 0.0
	steering = move_toward(steering, turn, steering_response * delta)
	var speed_factor := lerpf(1.0, 0.5, clampf(absf(speed) / max_speed, 0.0, 1.0))
	rotate_y(steering * speed * 0.12 * speed_factor * delta)
	var forward := -global_basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	else:
		velocity.y = -0.3
	move_and_slide()
	for index in get_slide_collision_count():
		if absf(get_slide_collision(index).get_normal().y) < 0.5:
			speed = speed * 0.8
	visual.animate(delta, speed, steering, stopping or throttle * speed < 0.0, lights_on or effects.is_boosting())
	boost_sparks.emitting = effects.is_boosting() and absf(speed) > 1.0 and not get_tree().get_meta("apollo_reduced_motion", false)
	if global_position.y < -8.0 or Vector2(global_position.x - spawn_transform.origin.x, global_position.z - spawn_transform.origin.z).length() > recovery_radius:
		reset_vehicle()

## Scintille dietro al furgone durante il turbo.
func make_sparks() -> CPUParticles3D:
	var sparks := CPUParticles3D.new()
	sparks.name = "ScintilleTurbo"
	sparks.position = Vector3(0, 0.3, 2.9)
	sparks.amount = 30
	sparks.lifetime = 0.45
	sparks.emitting = false
	sparks.local_coords = false
	sparks.direction = Vector3(0, 0.5, 1)
	sparks.spread = 28.0
	sparks.initial_velocity_min = 3.0
	sparks.initial_velocity_max = 6.0
	sparks.gravity = Vector3(0, -6, 0)
	var bit := SphereMesh.new()
	bit.radius = 0.04
	bit.height = 0.08
	bit.radial_segments = 6
	bit.rings = 3
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffb23d")
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bit.material = glow
	sparks.mesh = bit
	sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return sparks

func reset_vehicle() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	speed = 0.0
	steering = 0.0
	effects = Effects.new()
	reset_physics_interpolation()
