extends SceneTree

func _initialize() -> void:
	var packed := load("res://scenes/main.tscn")
	var scene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	var playfield = scene.get_node("%Playfield")
	_add_sample_orbs(playfield)
	await process_frame
	await process_frame

	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		push_error("visual smoke capture requires a rendered viewport; run without --headless")
		quit(1)
		return
	var image := viewport_texture.get_image()
	if image == null:
		push_error("visual smoke capture requires a rendered viewport image; run without --headless")
		quit(1)
		return
	var output_path := "res://artifacts/visual_smoke_main.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var error := image.save_png(output_path)
	if error != OK:
		push_error("failed to write visual smoke screenshot")
		quit(1)
		return
	print("visual_smoke_screenshot=%s" % ProjectSettings.globalize_path(output_path))
	quit(0)

func _add_sample_orbs(playfield) -> void:
	var positions := [
		Vector2(-72, -12),
		Vector2(-28, -54),
		Vector2(24, -60),
		Vector2(78, -24),
		Vector2(92, 34),
		Vector2(26, 72),
		Vector2(-42, 64),
	]
	for i in range(positions.size()):
		var ball := BallState.new_ball(9000 + i, BallState.Kind.COLOR, positions[i])
		ball.color_id = i % 4
		ball.settled = true
		playfield.add_ball(ball)
	var attack := BallState.new_ball(9010, BallState.Kind.COMBAT, Vector2(-108, 40))
	attack.combat_kind = BallState.CombatKind.ATTACK
	attack.settled = true
	playfield.add_ball(attack)
	var hazard := BallState.new_ball(9011, BallState.Kind.HAZARD, Vector2(132, 70))
	hazard.value = 5
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	hazard.settled = true
	playfield.add_ball(hazard)
