extends CharacterBody3D
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
var lights_on: bool = false
var spawn_transform: Transform3D
@onready var visual: Node3D = $Visual

func _ready() -> void:
	spawn_transform = global_transform

func _physics_process(delta: float) -> void:
	if enabled and Input.is_action_just_pressed("reset"):
		reset_vehicle()
	if enabled and Input.is_action_just_pressed("lights"):
		lights_on = not lights_on
	var throttle := Input.get_axis("reverse", "accelerate") if enabled else 0.0
	var stopping := Input.is_action_pressed("brake") or not enabled
	var target := throttle * (max_speed if throttle >= 0.0 else reverse_speed)
	var rate := acceleration
	if stopping:
		target = 0.0
		rate = braking
	elif throttle == 0.0:
		rate = 2.2
	elif throttle * speed < 0.0:
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
	visual.animate(delta, speed, steering, stopping or throttle * speed < 0.0, lights_on)
	if global_position.y < -8.0 or Vector2(global_position.x - spawn_transform.origin.x, global_position.z - spawn_transform.origin.z).length() > recovery_radius:
		reset_vehicle()

func reset_vehicle() -> void:
	global_transform = spawn_transform
	velocity = Vector3.ZERO
	speed = 0.0
	steering = 0.0
	reset_physics_interpolation()
