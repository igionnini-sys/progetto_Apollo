extends SceneTree
## Renderer reale, 1920x1080, VSync e limite FPS disabilitati; nessun fixed-fps.
var samples: Array[float] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Il benchmark richiede il renderer reale.")
		quit(1)
		return
	root.size = Vector2i(1920, 1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var report := {"date": Time.get_datetime_string_from_system(), "gpu": RenderingServer.get_video_adapter_name(), "cpu": OS.get_processor_name(), "renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method")) + " · " + RenderingServer.get_video_adapter_api_version(), "viewport": [1920, 1080], "msaa": "4x", "vsync": false, "frames_per_scene": 240, "warmup_frames": 90, "scenes": []}
	for town in [false, true]:
		var before := Time.get_ticks_usec()
		var main: Node3D = load("res://scenes/main/main.tscn").instantiate()
		main.use_volpiano = town
		root.add_child(main)
		main.start()
		var build_ms := (Time.get_ticks_usec() - before) / 1000.0
		main.vehicle.enabled = false
		for i in range(90):
			await process_frame
		samples.clear()
		var previous := Time.get_ticks_usec()
		for i in range(240):
			# Ripresa in movimento lungo il primo tratto; senza costo di input umano.
			if town:
				var points: Array = main.mission.points
				var t := float(i) / 239.0
				var segment := mini(int(t * (points.size() - 1)), points.size() - 2)
				main.vehicle.position = points[segment].lerp(points[segment + 1], fmod(t * (points.size() - 1), 1.0)) + Vector3.UP * 0.03
				main.vehicle.look_at(points[segment + 1] + Vector3.UP * 0.03)
				main.camera_rig.snap()
			else:
				main.vehicle.rotation.y += 0.004
			await RenderingServer.frame_post_draw
			var now := Time.get_ticks_usec()
			samples.append((now - previous) / 1000.0)
			previous = now
			await process_frame
		samples.sort()
		var median := samples[samples.size() / 2]
		var p95 := samples[int(samples.size() * 0.95)]
		var result := {"scene": "volpiano" if town else "circuito", "build_ms": snappedf(build_ms, 0.1), "median_ms": snappedf(median, 0.01), "p95_ms": snappedf(p95, 0.01), "median_fps": snappedf(1000.0 / median, 0.1), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
		report.scenes.append(result)
		print(JSON.stringify(result))
		main.queue_free()
		await process_frame
		await process_frame
		OS.delay_msec(100)
	DirAccess.make_dir_recursive_absolute("res://build/verifica")
	var file := FileAccess.open("res://build/verifica/performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	quit()
