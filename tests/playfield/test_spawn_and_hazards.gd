extends RefCounted

func test_spawn_queue_contains_only_player_side_orbs(runner: TestRunner) -> void:
	var queue: SpawnQueue = SpawnQueue.new()
	queue.seed_preview()
	var ball: BallState = queue.fast_drop_current()
	runner.assert_true(ball.kind != BallState.Kind.HAZARD, "fast drop never returns hazard orbs")
	queue.free()

func test_spawn_queue_seeds_only_color_orbs_without_combat_clutter(runner: TestRunner) -> void:
	var queue: SpawnQueue = SpawnQueue.new()
	queue.seed_preview()

	for ball in queue.preview:
		runner.assert_eq(ball.kind, BallState.Kind.COLOR, "main preview seed contains only color orbs by default")
	queue.free()

func test_spawn_queue_uses_configurable_color_generator(runner: TestRunner) -> void:
	var generator_script: Script = load("res://src/config/orb_color_generator.gd")
	runner.assert_true(generator_script != null, "orb color generator resource script exists")
	if generator_script == null:
		return
	var generator = generator_script.new()
	generator.mode = generator.Mode.SEQUENCE
	generator.sequence = PackedInt32Array([2, 2])
	var tuning := OrbTuning.new()
	tuning.preview_size = 2
	tuning.color_generator = generator
	var queue: SpawnQueue = SpawnQueue.new()
	queue.tuning = tuning

	queue.seed_preview()

	runner.assert_eq(queue.preview[0].color_id, 2, "first preview color comes from configured generator")
	runner.assert_eq(queue.preview[1].color_id, 2, "configured generator can produce consecutive same-color orbs")
	queue.free()

func test_spawn_queue_inserts_hazard_at_configured_preview_index(runner: TestRunner) -> void:
	var queue: SpawnQueue = SpawnQueue.new()
	queue.seed_preview()
	var hazard: BallState = BallState.new_ball(900, BallState.Kind.HAZARD, Vector2(120, 0))

	queue.insert_preview_ball(hazard, 2)

	runner.assert_eq(queue.preview[2].id, 900, "hazard is inserted at the configured preview index")
	runner.assert_eq(queue.preview.size(), 7, "inserting a hazard keeps the existing player preview sequence")
	queue.free()

func test_fast_drop_releases_hazard_preview_head(runner: TestRunner) -> void:
	var queue: SpawnQueue = SpawnQueue.new()
	queue.seed_preview()
	var hazard: BallState = BallState.new_ball(901, BallState.Kind.HAZARD, Vector2(120, 0))
	queue.insert_preview_ball(hazard, 0)

	var dropped: BallState = queue.fast_drop_current()

	runner.assert_eq(dropped.id, 901, "fast drop releases a hazard preview head")
	runner.assert_true(queue.preview[0].id != 901, "released hazard is removed from the preview head")
	queue.free()

func test_timed_drop_can_release_hazard_preview_head(runner: TestRunner) -> void:
	var queue: SpawnQueue = SpawnQueue.new()
	queue.seed_preview()
	var hazard: BallState = BallState.new_ball(902, BallState.Kind.HAZARD, Vector2(120, 0))
	queue.insert_preview_ball(hazard, 0)

	var dropped: BallState = queue.pop_next_ball()

	runner.assert_eq(dropped.id, 902, "timed drop releases the hazard when it reaches the preview head")
	runner.assert_eq(queue.preview.size(), 6, "queue is refilled after a timed drop")
	queue.free()

func test_hazard_spawner_creates_warning_hazards(runner: TestRunner) -> void:
	var spawner: HazardSpawner = HazardSpawner.new()
	var hazards: Array[BallState] = spawner.spawn_from_event({
		"type": "spawn_hazard",
		"count": 2,
		"value": 7,
		"source": "test",
		"angle_hint": "boss_side",
	})
	runner.assert_eq(hazards.size(), 2, "hazard count matches event")
	runner.assert_eq(hazards[0].hazard_phase, BallState.HazardPhase.WARNING, "new hazards start in warning phase")
	spawner.free()

func test_hazard_spawner_places_default_hazards_inside_playfield_boundary(runner: TestRunner) -> void:
	var spawner: HazardSpawner = HazardSpawner.new()
	var playfield: Playfield = Playfield.new()
	var hazards: Array[BallState] = spawner.spawn_from_event({
		"type": "spawn_hazard",
		"count": 2,
		"value": 7,
		"source": "test",
		"angle_hint": "boss_side",
	})

	for hazard in hazards:
		runner.assert_true(hazard.position.length() < playfield.danger_radius, "default spawned hazards begin inside danger boundary")
		playfield.add_ball(hazard)
	var exploded: Array[BallState] = playfield.check_boundary_explosions()
	runner.assert_eq(exploded.size(), 0, "default spawned hazards do not immediately explode")
	runner.assert_eq(playfield.balls.size(), hazards.size(), "default spawned hazards remain visible after boundary check")

	spawner.free()
	playfield.free()

func test_playfield_advances_warning_hazard_to_danger_after_threshold(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var tuning = _new_hazard_tuning(runner)
	if tuning == null:
		_remove_playfield_from_tree(playfield)
		return
	tuning.warning_seconds_after_board_contact = 0.5
	playfield.hazard_tuning = tuning
	var hazard: BallState = BallState.new_ball(77, BallState.Kind.HAZARD, Vector2(80, 0))
	hazard.board_attached = true
	playfield.add_ball(hazard)

	playfield.advance_hazard_phases(0.49)
	runner.assert_eq(hazard.hazard_phase, BallState.HazardPhase.WARNING, "hazard stays warning before threshold")

	playfield.advance_hazard_phases(0.01)
	runner.assert_eq(hazard.hazard_phase, BallState.HazardPhase.DANGER, "hazard becomes danger at warning threshold")
	_remove_playfield_from_tree(playfield)

func test_hazard_warning_timer_starts_after_board_contact(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var tuning = _new_hazard_tuning(runner)
	if tuning == null:
		_remove_playfield_from_tree(playfield)
		return
	tuning.warning_seconds_after_board_contact = 10.0
	playfield.set("hazard_tuning", tuning)
	var hazard: BallState = BallState.new_ball(78, BallState.Kind.HAZARD, Vector2(120, 0))
	hazard.settled = false
	hazard.board_attached = false
	playfield.add_ball(hazard)

	playfield.advance_hazard_phases(30.0)

	runner.assert_eq(hazard.hazard_phase, BallState.HazardPhase.WARNING, "falling hazard stays in warning phase")
	runner.assert_eq(hazard.age_seconds, 0.0, "falling hazard does not spend warning time")
	hazard.board_attached = true
	playfield.advance_hazard_phases(9.9)
	runner.assert_eq(hazard.hazard_phase, BallState.HazardPhase.WARNING, "contacted hazard stays warning before configured duration")
	playfield.advance_hazard_phases(0.1)
	runner.assert_eq(hazard.hazard_phase, BallState.HazardPhase.DANGER, "contacted hazard enters danger after configured duration")
	runner.assert_eq(hazard.value, 1, "danger hazard starts at configured initial value")
	_remove_playfield_from_tree(playfield)

func test_danger_hazard_value_grows_on_configured_interval(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var tuning = _new_hazard_tuning(runner)
	if tuning == null:
		_remove_playfield_from_tree(playfield)
		return
	tuning.danger_initial_value = 1
	tuning.danger_growth_seconds = 20.0
	tuning.danger_max_value = 5
	playfield.set("hazard_tuning", tuning)
	var hazard: BallState = BallState.new_ball(79, BallState.Kind.HAZARD, Vector2(120, 0))
	hazard.board_attached = true
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	hazard.value = 1
	playfield.add_ball(hazard)

	playfield.advance_hazard_phases(19.9)
	runner.assert_eq(hazard.value, 1, "danger value waits for full growth interval")
	playfield.advance_hazard_phases(0.1)
	runner.assert_eq(hazard.value, 2, "danger value grows after one interval")
	playfield.advance_hazard_phases(1000.0)
	runner.assert_eq(hazard.value, 5, "danger value caps at configured maximum")
	_remove_playfield_from_tree(playfield)

func test_playfield_boundary_reports_outside_hazard(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	playfield.danger_radius = 100.0
	var hazard: BallState = BallState.new_ball(1, BallState.Kind.HAZARD, Vector2(160, 0))
	hazard.settled = true
	playfield.add_ball(hazard)
	var exploded: Array[BallState] = playfield.check_boundary_explosions()
	runner.assert_eq(exploded.size(), 1, "hazard outside danger radius explodes")
	playfield.free()

func test_playfield_boundary_ignores_falling_hazard_outside_radius(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	playfield.danger_radius = 100.0
	var hazard: BallState = BallState.new_ball(2, BallState.Kind.HAZARD, Vector2(160, 0))
	hazard.settled = false
	hazard.board_attached = false
	playfield.add_ball(hazard)
	var exploded: Array[BallState] = playfield.check_boundary_explosions()
	runner.assert_eq(exploded.size(), 0, "falling hazard outside danger radius waits until it settles")
	runner.assert_eq(playfield.balls.size(), 1, "falling hazard remains on the playfield")
	playfield.free()

func test_playfield_boundary_explodes_board_attached_hazard_before_locking(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	playfield.danger_radius = 100.0
	var hazard: BallState = BallState.new_ball(3, BallState.Kind.HAZARD, Vector2(160, 0))
	hazard.settled = false
	hazard.board_attached = true
	playfield.add_ball(hazard)

	var exploded: Array[BallState] = playfield.check_boundary_explosions()

	runner.assert_eq(exploded.size(), 1, "board-attached hazard outside danger radius explodes even before locking")
	runner.assert_eq(playfield.balls.size(), 0, "exploded board-attached hazard is removed")
	playfield.free()

func test_playfield_rotation_persists_for_settled_orb_nodes(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	var ball: BallState = BallState.new_ball(1, BallState.Kind.COLOR, Vector2(120, 0))
	ball.settled = true
	playfield.balls.append(ball)
	var orb := OrbNode.new()
	orb.setup(ball)
	playfield.add_child(orb)

	playfield.rotate_settled(PI * 0.5)
	orb._process(0.0)

	var expected := Vector2(0, 120)
	runner.assert_true(ball.position.distance_to(expected) < 0.001, "rotation keeps settled state position")
	runner.assert_true(orb.position.distance_to(expected) < 0.001, "rotation updates settled orb node position")
	playfield.free()

func test_playfield_rotation_recomputes_center_gravity_visuals_without_roll(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	var ball: BallState = BallState.new_ball(4, BallState.Kind.COLOR, Vector2(120, 0))
	ball.settled = true
	playfield.balls.append(ball)
	var orb := OrbNode.new()
	orb.setup(ball)
	playfield.add_child(orb)
	var start_rotation := orb.rotation

	playfield.rotate_settled(PI * 0.5)

	runner.assert_true(absf(orb.rotation - start_rotation) > 0.001, "orb visual gravity direction updates after board rotation changes its position")
	runner.assert_true(absf(wrapf(orb.rotation - PI, -PI, PI)) < 0.001, "orb below center points its heavy side toward center without extra rolling")
	playfield.free()

func test_orb_visual_defaults_to_center_gravity_rotation(runner: TestRunner) -> void:
	var top_ball: BallState = BallState.new_ball(5, BallState.Kind.COLOR, Vector2(0, -120))
	var right_ball: BallState = BallState.new_ball(6, BallState.Kind.COLOR, Vector2(120, 0))
	var lower_right_ball: BallState = BallState.new_ball(7, BallState.Kind.COLOR, Vector2(120, 120))
	var top_orb := OrbNode.new()
	var right_orb := OrbNode.new()
	var lower_right_orb := OrbNode.new()

	top_orb.setup(top_ball)
	right_orb.setup(right_ball)
	lower_right_orb.setup(lower_right_ball)

	runner.assert_true(absf(top_orb.rotation) < 0.001, "orb above center keeps default downward-heavy visual rotation")
	runner.assert_true(absf(wrapf(right_orb.rotation - PI * 0.5, -PI, PI)) < 0.001, "orb right of center rotates its heavy side toward center")
	runner.assert_true(absf(wrapf(lower_right_orb.rotation - right_orb.rotation, -PI, PI)) > 0.001, "different board positions produce different gravity-facing visual rotations")
	top_orb.queue_free()
	right_orb.queue_free()
	lower_right_orb.queue_free()

func test_playfield_rotation_ignores_falling_orbs_until_contact(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	var ball: BallState = BallState.new_ball(2, BallState.Kind.COLOR, Vector2(160, 0))
	ball.has_settle_target = true
	ball.settle_target = Vector2.ZERO
	ball.settled = false
	ball.board_attached = false
	playfield.balls.append(ball)
	var orb := OrbNode.new()
	orb.setup(ball)
	playfield.add_child(orb)

	playfield.rotate_settled(PI * 0.5)

	runner.assert_true(ball.position.distance_to(Vector2(160, 0)) < 0.001, "falling orb does not rotate before contact")
	runner.assert_true(orb.position.distance_to(Vector2(160, 0)) < 0.001, "falling orb node does not rotate before contact")
	playfield.free()

func test_falling_orb_does_not_accumulate_roll_offset_before_contact(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	var ball: BallState = BallState.new_ball(8, BallState.Kind.COLOR, Vector2(220, 0))
	ball.has_settle_target = true
	ball.settle_target = Vector2.ZERO
	ball.settled = false
	ball.board_attached = false
	playfield.balls.append(ball)
	var orb := OrbNode.new()
	orb.setup(ball)
	playfield.add_child(orb)

	orb._process(1.0 / 60.0)

	runner.assert_eq(ball.visual_rotation, 0.0, "falling movement before contact does not accumulate roll offset")
	playfield.free()

func test_playfield_rotation_carries_contacted_board_orbs(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	var ball: BallState = BallState.new_ball(3, BallState.Kind.COLOR, Vector2(160, 0))
	ball.has_settle_target = true
	ball.settle_target = Vector2.ZERO
	ball.settled = false
	ball.board_attached = true
	playfield.balls.append(ball)
	var orb := OrbNode.new()
	orb.setup(ball)
	playfield.add_child(orb)

	playfield.rotate_settled(PI * 0.5)

	var expected := Vector2(0, 160)
	runner.assert_true(ball.position.distance_to(expected) < 0.001, "contacted board orb rotates with the disk")
	runner.assert_true(orb.position.distance_to(expected) < 0.001, "contacted board orb node rotates with the disk")
	playfield.free()

func test_playfield_assigns_center_target_for_new_orbs(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var first: BallState = BallState.new_ball(10, BallState.Kind.COLOR, Vector2(-320, -180))
	var second: BallState = BallState.new_ball(11, BallState.Kind.COLOR, Vector2(-320, -180))

	playfield.add_ball(first)
	playfield.add_ball(second)

	runner.assert_true(first.has_settle_target, "first new orb receives a settle target")
	runner.assert_true(second.has_settle_target, "second new orb receives a settle target")
	runner.assert_eq(first.settle_target, Vector2.ZERO, "new orbs aim at the center")
	runner.assert_eq(second.settle_target, Vector2.ZERO, "new orbs aim at the center")
	runner.assert_true(not first.settled, "newly added orb starts moving before it settles")
	_remove_playfield_from_tree(playfield)

func test_spawn_lane_clearance_treats_board_attached_orbs_as_blockers(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var spawn_position := Vector2(-320, -180)
	var blocker: BallState = BallState.new_ball(13, BallState.Kind.COLOR, spawn_position)
	blocker.has_settle_target = true
	blocker.settle_target = Vector2.ZERO
	blocker.board_attached = true
	blocker.settled = false
	playfield.add_ball(blocker)

	var cleared_position := playfield.clear_player_spawn_position(spawn_position, 24.0, 6.0, 8)

	runner.assert_true(
		cleared_position.distance_to(blocker.position) >= blocker.radius + 24.0 + 6.0,
		"spawn lane clearance treats board-attached moving orbs as occupied space"
	)
	_remove_playfield_from_tree(playfield)

func test_orb_node_moves_toward_center_and_stops_at_core_ring(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var ball: BallState = BallState.new_ball(12, BallState.Kind.COLOR, Vector2(-180, 0))
	playfield.add_ball(ball)
	runner.assert_true(playfield.get_child_count() > 0, "adding a ball creates an orb node")
	var orb: OrbNode = playfield.get_child(0) as OrbNode
	var start_distance := ball.position.length()

	for i in range(90):
		orb._process(1.0 / 60.0)

	var core_limit: float = playfield.core_collision_radius + ball.radius
	runner.assert_true(ball.position.length() < start_distance, "orb moves inward toward center")
	runner.assert_true(ball.position.length() >= core_limit - 0.1, "orb does not penetrate the HP core ring")
	runner.assert_true(ball.settled, "orb settles at the first blocker")
	var settled_position := ball.position
	playfield.rotate_settled(PI * 0.5)
	runner.assert_true(ball.position.distance_to(settled_position) > 1.0, "settled orb rotates with playfield")
	_remove_playfield_from_tree(playfield)

func test_single_ball_contact_does_not_lock_incoming_orb(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var blocker: BallState = BallState.new_ball(20, BallState.Kind.COLOR, Vector2(-120, 0))
	blocker.settled = true
	playfield.add_ball(blocker)

	var incoming: BallState = BallState.new_ball(21, BallState.Kind.COLOR, Vector2(-180, 0))
	playfield.add_ball(incoming)
	var incoming_node: OrbNode = playfield.get_child(1) as OrbNode
	for i in range(20):
		incoming_node._process(1.0 / 60.0)

	var minimum_distance: float = blocker.radius + incoming.radius
	runner.assert_true(not incoming.settled, "single ball contact keeps moving instead of locking")
	runner.assert_true(incoming.position.distance_to(blocker.position) >= minimum_distance - 0.1, "settled balls do not overlap")
	_remove_playfield_from_tree(playfield)

func test_fast_incoming_orb_does_not_tunnel_through_settled_ball(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var blocker: BallState = BallState.new_ball(27, BallState.Kind.COLOR, Vector2(-130, 0))
	blocker.settled = true
	playfield.add_ball(blocker)

	var incoming: BallState = BallState.new_ball(28, BallState.Kind.COLOR, Vector2(-190, 0))
	playfield.add_ball(incoming)

	var resolved: Dictionary = playfield.resolve_incoming_motion(incoming, Vector2(-70, 0))
	var resolved_position: Vector2 = resolved.position

	runner.assert_true(resolved_position.distance_to(blocker.position) >= incoming.radius + blocker.radius - 0.1, "fast orb sweep stops before overlap")
	runner.assert_true(resolved_position.x <= blocker.position.x - incoming.radius - blocker.radius + 0.1, "fast orb remains on the approach side")
	_remove_playfield_from_tree(playfield)

func test_overlapping_dynamic_orb_is_pushed_out_before_sliding(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var blocker: BallState = BallState.new_ball(29, BallState.Kind.COLOR, Vector2(-118, 24))
	blocker.settled = true
	playfield.add_ball(blocker)

	var incoming: BallState = BallState.new_ball(35, BallState.Kind.COLOR, Vector2(-150, 10))
	playfield.add_ball(incoming)

	var resolved: Dictionary = playfield.resolve_incoming_motion(incoming, Vector2(-148, 10))
	var resolved_position: Vector2 = resolved.position

	runner.assert_true(resolved_position.distance_to(blocker.position) >= incoming.radius + blocker.radius - 0.1, "overlapping orb is depenetrated before further motion")
	_remove_playfield_from_tree(playfield)

func test_incoming_orb_slides_when_single_contact_does_not_support_center_gravity(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var blocker: BallState = BallState.new_ball(22, BallState.Kind.COLOR, Vector2(-118, 24))
	blocker.settled = true
	playfield.add_ball(blocker)

	var incoming: BallState = BallState.new_ball(23, BallState.Kind.COLOR, Vector2(-180, 0))
	playfield.add_ball(incoming)
	var incoming_node: OrbNode = playfield.get_child(1) as OrbNode
	var previous_position := incoming.position
	var largest_step := 0.0
	var starting_roll := incoming.visual_rotation
	for i in range(20):
		incoming_node._process(1.0 / 60.0)
		largest_step = maxf(largest_step, incoming.position.distance_to(previous_position))
		previous_position = incoming.position

	runner.assert_true(not incoming.settled, "off-center single contact keeps sliding instead of locking")
	runner.assert_true(incoming.position.length() < 180.0, "sliding contact still moves the orb inward")
	runner.assert_true(largest_step <= 3.0, "contact slide is friction-limited instead of slippery")
	runner.assert_true(absf(incoming.visual_rotation - starting_roll) > 0.001, "contact sliding accumulates visual roll offset")
	_remove_playfield_from_tree(playfield)

func test_contact_slide_roll_direction_changes_with_tangent_direction(runner: TestRunner) -> void:
	var left_playfield := _add_playfield_to_tree()
	var left_blocker: BallState = BallState.new_ball(60, BallState.Kind.COLOR, Vector2(-118, 24))
	left_blocker.settled = true
	left_playfield.add_ball(left_blocker)
	var left_incoming: BallState = BallState.new_ball(61, BallState.Kind.COLOR, Vector2(-180, 0))
	left_playfield.add_ball(left_incoming)
	var left_node: OrbNode = left_playfield.get_child(1) as OrbNode
	for i in range(20):
		left_node._process(1.0 / 60.0)
	var left_roll := left_incoming.visual_rotation
	_remove_playfield_from_tree(left_playfield)

	var right_playfield := _add_playfield_to_tree()
	var right_blocker: BallState = BallState.new_ball(62, BallState.Kind.COLOR, Vector2(118, 24))
	right_blocker.settled = true
	right_playfield.add_ball(right_blocker)
	var right_incoming: BallState = BallState.new_ball(63, BallState.Kind.COLOR, Vector2(180, 0))
	right_playfield.add_ball(right_incoming)
	var right_node: OrbNode = right_playfield.get_child(1) as OrbNode
	for i in range(20):
		right_node._process(1.0 / 60.0)
	var right_roll := right_incoming.visual_rotation
	_remove_playfield_from_tree(right_playfield)

	runner.assert_true(left_roll * right_roll < 0.0, "opposite tangent slide directions roll in opposite visual directions")

func test_two_point_contact_supports_settled_orb(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var left_support: BallState = BallState.new_ball(24, BallState.Kind.COLOR, Vector2(-118, -24))
	var right_support: BallState = BallState.new_ball(25, BallState.Kind.COLOR, Vector2(-118, 24))
	var carried: BallState = BallState.new_ball(26, BallState.Kind.COLOR, Vector2(-160, 0))
	left_support.settled = true
	right_support.settled = true
	carried.settled = true
	playfield.add_ball(left_support)
	playfield.add_ball(right_support)
	playfield.add_ball(carried)
	var carried_start := carried.position

	playfield.release_unsupported_orbs()

	runner.assert_true(carried.settled, "two inner contacts hold a settled orb in place")
	runner.assert_true(carried.position.distance_to(carried_start) < 0.001, "two-point support does not teleport the orb")
	_remove_playfield_from_tree(playfield)

func test_two_ball_contact_locks_incoming_orb(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var left_support: BallState = BallState.new_ball(30, BallState.Kind.COLOR, Vector2(-118, -24))
	var right_support: BallState = BallState.new_ball(31, BallState.Kind.COLOR, Vector2(-118, 24))
	left_support.settled = true
	right_support.settled = true
	playfield.add_ball(left_support)
	playfield.add_ball(right_support)

	var incoming: BallState = BallState.new_ball(32, BallState.Kind.COLOR, Vector2(-180, 0))
	playfield.add_ball(incoming)
	var incoming_node: OrbNode = playfield.get_child(2) as OrbNode
	for i in range(90):
		incoming_node._process(1.0 / 60.0)

	runner.assert_true(incoming.settled, "two inner support contacts lock the incoming orb")
	runner.assert_true(left_support.position.distance_to(Vector2(-118, -24)) < 0.001, "left support remains locked in place")
	runner.assert_true(right_support.position.distance_to(Vector2(-118, 24)) < 0.001, "right support remains locked in place")
	_remove_playfield_from_tree(playfield)

func test_global_relax_does_not_move_locked_orbs(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var first: BallState = BallState.new_ball(33, BallState.Kind.COLOR, Vector2(-130, 0))
	var second: BallState = BallState.new_ball(34, BallState.Kind.COLOR, Vector2(-150, 0))
	first.settled = true
	second.settled = true
	playfield.add_ball(first)
	playfield.add_ball(second)
	var first_start := first.position
	var second_start := second.position

	playfield.relax_settled_balls()

	runner.assert_true(first.position.distance_to(first_start) < 0.001, "locked orb is not globally pushed by relaxation")
	runner.assert_true(second.position.distance_to(second_start) < 0.001, "other locked orb is not globally pushed by relaxation")
	_remove_playfield_from_tree(playfield)

func test_playfield_keeps_orb_edge_outside_visual_core_isolation(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var ball: BallState = BallState.new_ball(40, BallState.Kind.COLOR, Vector2(playfield.core_collision_radius, 0))
	ball.settled = true
	playfield.add_ball(ball)

	playfield.relax_settled_balls()

	runner.assert_true(ball.position.length() - ball.radius >= playfield.core_collision_radius - 0.1, "orb edge stays outside the visible core isolation ring")
	_remove_playfield_from_tree(playfield)

func test_supported_settled_orbs_do_not_keep_pushing_each_other(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var inner: BallState = BallState.new_ball(41, BallState.Kind.COLOR, Vector2(playfield.core_collision_radius + 24.0, 0))
	var outer: BallState = BallState.new_ball(42, BallState.Kind.COLOR, Vector2(playfield.core_collision_radius + 72.0, 0))
	inner.settled = true
	outer.settled = true
	playfield.add_ball(inner)
	playfield.add_ball(outer)
	var inner_start := inner.position
	var outer_start := outer.position

	for i in range(30):
		playfield.advance_orb_physics(1.0 / 60.0)

	runner.assert_true(inner.position.distance_to(inner_start) < 0.001, "core-supported orb stays locked")
	runner.assert_true(outer.position.distance_to(outer_start) < 0.001, "orb supported by another orb does not keep pushing")
	_remove_playfield_from_tree(playfield)

func test_unsupported_settled_orb_releases_after_support_check(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	var ball: BallState = BallState.new_ball(43, BallState.Kind.COLOR, Vector2(180, 0))
	ball.settled = true
	playfield.add_ball(ball)

	playfield.release_unsupported_orbs()

	runner.assert_true(not ball.settled, "unsupported settled orb becomes active again")
	_remove_playfield_from_tree(playfield)

func test_playfield_boundary_explosion_removes_hazard_node(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	playfield.danger_radius = 100.0
	var hazard: BallState = BallState.new_ball(1, BallState.Kind.HAZARD, Vector2(160, 0))
	hazard.settled = true
	playfield.balls.append(hazard)
	var orb := OrbNode.new()
	orb.setup(hazard)
	playfield.add_child(orb)

	var exploded: Array[BallState] = playfield.check_boundary_explosions()

	runner.assert_eq(exploded.size(), 1, "hazard outside danger radius still explodes in-tree")
	runner.assert_eq(playfield.balls.size(), 0, "exploded hazard is removed from playfield state")
	runner.assert_eq(playfield.get_child_count(), 0, "exploded hazard orb node is removed from playfield")
	_remove_playfield_from_tree(playfield)

func test_orb_node_uses_danger_color_for_reachable_hazard_state(runner: TestRunner) -> void:
	var hazard: BallState = BallState.new_ball(88, BallState.Kind.HAZARD, Vector2.ZERO)
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	var orb := OrbNode.new()
	orb.setup(hazard)

	runner.assert_true(orb.has_method("current_fill_color"), "orb node exposes the fill color used for hazard draw state")
	if orb.has_method("current_fill_color"):
		runner.assert_eq(orb.current_fill_color(), Color(0.9, 0.18, 0.2), "danger hazards draw with the red fill color")
	orb.queue_free()

func test_warning_hazard_draws_without_value_label(runner: TestRunner) -> void:
	var hazard: BallState = BallState.new_ball(87, BallState.Kind.HAZARD, Vector2.ZERO)
	hazard.hazard_phase = BallState.HazardPhase.WARNING
	hazard.value = 5
	var orb := OrbNode.new()
	orb.setup(hazard)

	runner.assert_eq(orb.display_label(), "", "warning hazards do not draw damage numbers")
	orb.queue_free()

func test_color_orb_draws_without_value_label(runner: TestRunner) -> void:
	var color_ball: BallState = BallState.new_ball(89, BallState.Kind.COLOR, Vector2.ZERO)
	color_ball.color_id = 1
	color_ball.value = 0
	var orb := OrbNode.new()
	orb.setup(color_ball)

	runner.assert_true(orb.has_method("display_label"), "orb node exposes display label rules")
	if orb.has_method("display_label"):
		runner.assert_eq(orb.display_label(), "", "color orbs do not draw numeric value labels")
	orb.queue_free()

func _add_playfield_to_tree() -> Playfield:
	var playfield: Playfield = Playfield.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(playfield)
	return playfield

func _remove_playfield_from_tree(playfield: Playfield) -> void:
	if playfield.get_parent() != null:
		playfield.get_parent().remove_child(playfield)
	playfield.queue_free()

func _new_hazard_tuning(runner: TestRunner):
	var script: Script = load("res://src/config/hazard_tuning.gd")
	runner.assert_true(script != null, "hazard tuning resource script exists")
	if script == null:
		return null
	return script.new()
