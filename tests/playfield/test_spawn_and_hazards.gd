extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const SpawnQueue = preload("res://src/playfield/spawn_queue.gd")
const HazardSpawner = preload("res://src/playfield/hazard_spawner.gd")
const Playfield = preload("res://src/playfield/playfield.gd")
const OrbNode = preload("res://src/playfield/orb_node.gd")
const TestRunner = preload("res://tests/test_runner.gd")

func test_spawn_queue_contains_only_player_side_orbs(runner: TestRunner) -> void:
	var queue: SpawnQueue = SpawnQueue.new()
	queue.seed_preview()
	var ball: BallState = queue.fast_drop_current()
	runner.assert_true(ball.kind != BallState.Kind.HAZARD, "fast drop never returns hazard orbs")
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

func test_playfield_advances_warning_hazard_to_danger_after_threshold(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	playfield.hazard_warning_seconds = 0.5
	var hazard: BallState = BallState.new_ball(77, BallState.Kind.HAZARD, Vector2(80, 0))
	playfield.add_ball(hazard)

	playfield.advance_hazard_phases(0.49)
	runner.assert_eq(hazard.hazard_phase, BallState.HazardPhase.WARNING, "hazard stays warning before threshold")

	playfield.advance_hazard_phases(0.01)
	runner.assert_eq(hazard.hazard_phase, BallState.HazardPhase.DANGER, "hazard becomes danger at warning threshold")
	_remove_playfield_from_tree(playfield)

func test_playfield_boundary_reports_outside_hazard(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	playfield.danger_radius = 100.0
	var hazard: BallState = BallState.new_ball(1, BallState.Kind.HAZARD, Vector2(160, 0))
	playfield.add_ball(hazard)
	var exploded: Array[BallState] = playfield.check_boundary_explosions()
	runner.assert_eq(exploded.size(), 1, "hazard outside danger radius explodes")
	playfield.free()

func test_playfield_rotation_persists_for_settled_orb_nodes(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	var ball: BallState = BallState.new_ball(1, BallState.Kind.COLOR, Vector2(24, 0))
	ball.settled = true
	playfield.balls.append(ball)
	var orb := OrbNode.new()
	orb.setup(ball)
	playfield.add_child(orb)

	playfield.rotate_settled(PI * 0.5)
	orb._process(0.0)

	var expected := Vector2(0, 24)
	runner.assert_true(ball.position.distance_to(expected) < 0.001, "rotation keeps settled state position")
	runner.assert_true(orb.position.distance_to(expected) < 0.001, "rotation updates settled orb node position")
	playfield.free()

func test_playfield_boundary_explosion_removes_hazard_node(runner: TestRunner) -> void:
	var playfield := _add_playfield_to_tree()
	playfield.danger_radius = 100.0
	var hazard: BallState = BallState.new_ball(1, BallState.Kind.HAZARD, Vector2(160, 0))
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

func _add_playfield_to_tree() -> Playfield:
	var playfield: Playfield = Playfield.new()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(playfield)
	return playfield

func _remove_playfield_from_tree(playfield: Playfield) -> void:
	if playfield.get_parent() != null:
		playfield.get_parent().remove_child(playfield)
	playfield.queue_free()
