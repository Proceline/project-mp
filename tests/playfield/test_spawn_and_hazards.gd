extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const SpawnQueue = preload("res://src/playfield/spawn_queue.gd")
const HazardSpawner = preload("res://src/playfield/hazard_spawner.gd")
const Playfield = preload("res://src/playfield/playfield.gd")
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

func test_playfield_boundary_reports_outside_hazard(runner: TestRunner) -> void:
	var playfield: Playfield = Playfield.new()
	playfield.danger_radius = 100.0
	var hazard: BallState = BallState.new_ball(1, BallState.Kind.HAZARD, Vector2(160, 0))
	playfield.add_ball(hazard)
	var exploded: Array[BallState] = playfield.check_boundary_explosions()
	runner.assert_eq(exploded.size(), 1, "hazard outside danger radius explodes")
	playfield.free()
