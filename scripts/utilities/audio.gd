extends Node
## Sintesi originale: accompagnamento discreto e motore stilizzato, non registrazione 4HV.
const RATE = 22050
var player: AudioStreamPlayer
var music: AudioStreamPlayer
var engine: AudioStreamPlayer
var ambience: AudioStreamPlayer
var vehicle: CharacterBody3D
var effects_level: float = 0.65
var brake_was_pressed: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = make_player()
	music = make_player()
	engine = make_player()
	ambience = make_player()
	music.stream = synth(8.0, "music", true)
	engine.stream = synth(1.0, "engine", true)
	ambience.stream = synth(6.0, "birds", true)
	music.play()
	engine.play()
	ambience.play()
	configure({"music": 0.35, "effects": 0.65})

func make_player() -> AudioStreamPlayer:
	var result := AudioStreamPlayer.new()
	result.volume_db = -80.0
	add_child(result)
	return result

func synth(seconds: float, kind: String, loop: bool = false, frequency: float = 440.0) -> AudioStreamWAV:
	var sample := AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_16_BITS
	sample.mix_rate = RATE
	var frames := int(seconds * RATE)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var notes := [261.6256, 329.6276, 391.9954, 329.6276, 293.6648, 349.2282, 391.9954, 293.6648]
	for i in frames:
		var t := float(i) / RATE
		var value: float
		if kind == "engine":
			value = sin(t * TAU * 50.0) * 0.48 + sin(t * TAU * 100.0) * 0.22 + sin(t * TAU * 150.0) * 0.10
			value *= 0.85 + 0.15 * sin(t * TAU * 25.0)
		elif kind == "birds":
			var phase := fmod(t, 3.0)
			var chirp := phase - 1.0 if phase < 1.3 else phase - 1.5
			value = 0.0
			if chirp >= 0 and chirp < 0.18:
				value = sin(t * TAU * 1250.0 + sin(chirp * 30) * 16) * sin(chirp / 0.18 * PI) * 0.35
		elif kind == "victory":
			var phase := fmod(t, 0.3) / 0.3
			var note: float = [523.251, 659.255, 783.991, 1046.502][mini(int(t / 0.3), 3)]
			value = sin(t * TAU * note) * sin(phase * PI) * 0.55
		elif kind == "music":
			var phase := fmod(t, 1.0)
			var envelope := sin(phase * PI) * sin(phase * PI)
			var note: float = notes[mini(int(t), 7)]
			value = (sin(t * TAU * note) * 0.65 + sin(t * TAU * note * 0.5) * 0.25) * envelope
		else:
			var envelope := minf(t * 25.0, 1.0) * minf((seconds - t) * 15.0, 1.0)
			value = sin(t * TAU * frequency) * envelope * 0.6
		bytes.encode_s16(i * 2, int(clampf(value, -1, 1) * 26000.0))
	sample.data = bytes
	if loop:
		sample.loop_mode = AudioStreamWAV.LOOP_FORWARD
		sample.loop_begin = 0
		sample.loop_end = frames
	return sample

func configure(settings: Dictionary) -> void:
	effects_level = settings.get("effects", 0.65)
	player.volume_db = level_db(effects_level, -15)
	music.volume_db = level_db(settings.get("music", 0.35), -24)
	if effects_level <= 0.0:
		engine.volume_db = -80.0
		ambience.volume_db = -80.0

func level_db(value: float, base: float) -> float:
	return -80.0 if value <= 0.0 else base + linear_to_db(value)

func tone(frequency: float, seconds: float) -> void:
	player.stream = synth(seconds, "tone", false, frequency)
	player.play()

func horn() -> void:
	tone(330.0, 0.32)

func chime() -> void:
	tone(660.0, 0.24)

func click() -> void:
	tone(480.0, 0.06)

func complete() -> void:
	player.stream = synth(1.2, "victory")
	player.play()

func _process(delta: float) -> void:
	var driving: bool = is_instance_valid(vehicle) and vehicle.enabled and not get_tree().paused
	var speed := absf(vehicle.speed) if driving else 0.0
	engine.volume_db = move_toward(engine.volume_db, level_db(effects_level, -27.0 + speed * 0.25) if driving else -80.0, delta * 100.0)
	engine.pitch_scale = lerpf(engine.pitch_scale, 1.0 + speed / 22.0, 1.0 - exp(-4.0 * delta))
	ambience.volume_db = level_db(effects_level, -30) if driving else -80.0
	var brake_pressed: bool = driving and Input.is_action_pressed("brake")
	if brake_pressed and not brake_was_pressed and speed > 0.5:
		tone(180.0, 0.12)
	brake_was_pressed = brake_pressed

func _exit_tree() -> void:
	for stream_player in [player, music, engine, ambience]:
		if is_instance_valid(stream_player):
			stream_player.stop()
			stream_player.stream = null
