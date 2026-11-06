extends Node3D

@export var follow_distance: float = 10.5
@export var sensitivity: float = 4.0
var target: CharacterBody3D
var alternate: bool = false
var arm: SpringArm3D
var camera: Camera3D
var reduced_motion: bool = false
var boost_blend: float = 0.0

func _ready() -> void:
	arm = SpringArm3D.new()
	arm.name = "SpringArm3D"
	arm.rotation.x = deg_to_rad(-19.0)
	arm.spring_length = follow_distance
	arm.margin = 0.3
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	arm.shape = shape
	add_child(arm)
	arm.add_excluded_object(target.get_rid())
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 61.0
	camera.near = 0.08
	camera.far = 1600.0
	arm.add_child(camera)
	camera.current = true
	snap()

func in_underpass() -> bool:
	var main := get_parent()
	if main == null or not "world" in main or main.world == null or not "underpass" in main.world:
		return false
	return main.world.underpass.contains(target.global_position)

func snap() -> void:
	global_position = target.global_position + Vector3.UP * 2.6
	rotation.y = target.rotation.y

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("camera"):
		alternate = not alternate
	follow_distance = clampf(follow_distance + Input.get_axis("zoom_in", "zoom_out") * delta * 6.0, 6.5, 18.0)
	var tunnel := in_underpass()
	var length := 6.5 if alternate else follow_distance
	var pitch := -12.0 if alternate else -19.0
	if tunnel:
		# Sotto il ponte ferroviario: camera bassa e vicina, per non finire dentro impalcato e rotaie.
		length = minf(length, 6.0)
		pitch = -7.0
	var boosting: bool = "effects" in target and target.effects.is_boosting() and not reduced_motion
	boost_blend = lerpf(boost_blend, 1.0 if boosting else 0.0, 1.0 - exp(-5.0 * delta))
	length += boost_blend * 1.6
	arm.spring_length = lerpf(arm.spring_length, length, 1.0 - exp(-6.0 * delta))
	arm.rotation.x = lerp_angle(arm.rotation.x, deg_to_rad(pitch), 1.0 - exp(-6.0 * delta))
	if global_position.distance_to(target.global_position) > 30.0:
		snap()
	global_position = global_position.lerp(target.global_position + Vector3.UP * 2.6, 1.0 - exp(-8.0 * delta))
	rotation.y = lerp_angle(rotation.y, target.rotation.y, 1.0 - exp(-(minf(sensitivity, 2.0) if reduced_motion else sensitivity) * delta))
	# Sensazione di velocità: campo visivo leggermente più ampio, disattivato con movimenti ridotti.
	var speed_ratio := 0.0 if reduced_motion else clampf(absf(target.speed) / 15.0, 0.0, 1.0)
	camera.fov = lerpf(camera.fov, 61.0 + speed_ratio * 7.0 + boost_blend * 12.0, 1.0 - exp(-3.0 * delta))
	# Tremolio leggero durante il turbo.
	camera.h_offset = randf_range(-1.0, 1.0) * 0.035 * boost_blend
	camera.v_offset = randf_range(-1.0, 1.0) * 0.035 * boost_blend
