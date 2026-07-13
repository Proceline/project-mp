extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const ActionBarVolleyMechanic = preload("res://src/boss/action_bar_volley_mechanic.gd")
const BurstCounterMechanic = preload("res://src/boss/burst_counter_mechanic.gd")
const BossController = preload("res://src/boss/boss_controller.gd")
const GameController = preload("res://src/game_controller.gd")
const HazardSpawner = preload("res://src/playfield/hazard_spawner.gd")
const Playfield = preload("res://src/playfield/playfield.gd")
const SpawnQueue = preload("res://src/playfield/spawn_queue.gd")
const TacticalQueue = preload("res://src/playfield/tactical_queue.gd")
const TestRunner = preload("res://tests/test_runner.gd")

func test_chain_resolution_applies_effects_once_and_clears_orbs(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return

	controller.chain_flash_seconds = 0.5
	controller.battle.player_hp = 18
	controller.battle.player_shield = 0

	var counter := BurstCounterMechanic.new()
	counter.burst_threshold = 1
	controller.boss_controller.configure([counter])

	var attack := _combat_ball(100, BallState.CombatKind.ATTACK, 4, Vector2(40, 10))
	var shield := _combat_ball(101, BallState.CombatKind.SHIELD, 2, Vector2(80, 10))
	var heal := _combat_ball(102, BallState.CombatKind.HEAL, 3, Vector2(120, 10))
	var untouched := _combat_ball(103, BallState.CombatKind.ATTACK, 9, Vector2(500, 500))
	var chain_members: Array[BallState] = []
	for i in range(5):
		chain_members.append(_color_ball(i, 7, Vector2(i * 30, 0)))

	controller.playfield.balls = []
	for ball in chain_members:
		controller.playfield.add_ball(ball)
	for ball in [attack, shield, heal, untouched]:
		controller.playfield.add_ball(ball)

	controller.advance_chain_resolution(0.0)
	runner.assert_eq(attack.value, 9, "attack orb gains chain strength once when flash starts")
	runner.assert_eq(shield.value, 7, "shield orb gains chain strength once when flash starts")
	runner.assert_eq(heal.value, 8, "heal orb gains chain strength once when flash starts")
	runner.assert_eq(controller.battle.boss_hp, controller.battle.boss_max_hp, "boss hp does not change before flash resolves")
	runner.assert_eq(controller.battle.player_shield, 0, "shield is not granted before flash resolves")
	runner.assert_eq(controller.battle.player_hp, 18, "heal is not granted before flash resolves")

	controller.advance_chain_resolution(0.1)
	runner.assert_eq(attack.value, 9, "attack orb is not buffed again during the same flash window")
	runner.assert_eq(shield.value, 7, "shield orb is not buffed again during the same flash window")
	runner.assert_eq(heal.value, 8, "heal orb is not buffed again during the same flash window")

	controller.advance_chain_resolution(0.5)
	runner.assert_eq(controller.battle.boss_hp, controller.battle.boss_max_hp - 14, "attack damage includes baseline chain damage and attack orb value")
	runner.assert_eq(controller.battle.player_shield, 7, "shield bonus is applied once when flash resolves")
	runner.assert_eq(controller.battle.player_hp, 26, "heal bonus is applied once when flash resolves")
	runner.assert_eq(controller.playfield.balls.size(), 1, "resolved chain removes color members and triggered combat orbs")
	if controller.playfield.balls.size() == 1:
		runner.assert_eq(controller.playfield.balls[0].id, 103, "untouched combat orb remains on the playfield")

	var counter_state := controller.boss_controller.get_mechanic_state(counter)
	runner.assert_true(bool(counter_state.get("pending_counter", false)), "boss controller is notified about chain attack damage")

	controller.advance_chain_resolution(0.5)
	runner.assert_eq(controller.battle.boss_hp, controller.battle.boss_max_hp - 14, "resolved chain does not apply damage twice")
	_destroy_controller(controller)

func test_late_chain_member_extends_flash_window_and_clears(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return

	controller.chain_flash_seconds = 0.5
	controller.chain_extend_seconds = 0.2
	controller.chain_max_flash_seconds = 1.0
	controller.playfield.balls = []
	for i in range(5):
		controller.playfield.add_ball(_color_ball(i, 3, Vector2(i * 40, 0)))

	controller.advance_chain_resolution(0.0)
	runner.assert_eq(controller.active_chains.size(), 1, "initial five-color group starts flashing")
	runner.assert_eq(controller.chain_timer, 0.5, "initial flash timer starts at configured duration")

	var late_joiner := _color_ball(99, 3, Vector2(200, 0))
	controller.playfield.add_ball(late_joiner)
	controller.advance_chain_resolution(0.1)

	runner.assert_true(late_joiner.flashing, "late same-color orb joins the active flashing chain")
	runner.assert_eq(controller.chain_timer, 0.6, "late chain member adds configurable flash time after elapsed time")
	controller.advance_chain_resolution(0.59)
	runner.assert_eq(controller.playfield.balls.size(), 6, "extended flash window prevents early clear")
	controller.advance_chain_resolution(0.02)
	runner.assert_eq(controller.playfield.balls.size(), 0, "extended chain clears all six color members")
	_destroy_controller(controller)

func test_player_orbs_auto_drop_without_space(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	var before_count := controller.playfield.balls.size()

	controller.advance_player_orb_spawn(controller.player_auto_drop_seconds - 0.01)
	runner.assert_eq(controller.playfield.balls.size(), before_count, "auto drop waits for its timer")

	controller.advance_player_orb_spawn(0.02)
	runner.assert_eq(controller.playfield.balls.size(), before_count + 1, "auto drop adds a player-side orb when timer expires")
	var dropped: BallState = controller.playfield.balls[-1]
	runner.assert_true(dropped.kind != BallState.Kind.HAZARD, "auto drop uses the player-side queue")
	runner.assert_true(dropped.has_settle_target, "auto dropped orb receives a settle target")
	_destroy_controller(controller)

func test_tactical_combat_orb_inserts_into_main_preview(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.spawn_queue.seed_preview()
	var before_size := controller.spawn_queue.preview.size()

	var handled: bool = controller.insert_tactical_combat_orb()

	runner.assert_true(handled, "tactical insertion is handled when a combat slot is ready")
	runner.assert_eq(controller.spawn_queue.preview.size(), before_size + 1, "tactical combat insertion adds to the main preview")
	runner.assert_eq(controller.spawn_queue.preview[1].kind, BallState.Kind.COMBAT, "tactical combat orb inserts near the queue head")
	_destroy_controller(controller)

func test_player_fast_drop_accelerates_current_orb_and_starts_next(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.playfield.balls = []

	controller.advance_player_orb_spawn(controller.player_auto_drop_seconds)
	runner.assert_eq(controller.playfield.balls.size(), 1, "first timed drop starts one falling orb")
	var first: BallState = controller.playfield.balls[0]
	var first_node = controller.playfield._get_orb_node(first.id)
	var original_speed: float = first_node.attraction_speed

	var handled: bool = controller.handle_player_fast_drop()

	runner.assert_true(handled, "fast drop action is handled")
	runner.assert_eq(controller.playfield.balls.size(), 2, "fast drop also starts the next player orb immediately")
	runner.assert_true(not first.settled, "fast drop accelerates the current orb instead of instantly settling it")
	runner.assert_true(first_node.attraction_speed > original_speed, "current falling player orb receives a faster drop speed")
	var second: BallState = controller.playfield.balls[1]
	runner.assert_true(second.has_settle_target and not second.settled, "next orb starts falling after fast drop")
	_destroy_controller(controller)

func test_repeated_fast_drop_keeps_new_player_orbs_out_of_occupied_spawn_lane(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.playfield.balls = []

	controller.advance_player_orb_spawn(controller.player_auto_drop_seconds)
	controller.handle_player_fast_drop()
	controller.handle_player_fast_drop()

	var active_orbs: Array[BallState] = []
	for ball in controller.playfield.balls:
		if ball.has_settle_target and not ball.settled and not ball.board_attached:
			active_orbs.append(ball)

	for i in range(active_orbs.size()):
		for j in range(i + 1, active_orbs.size()):
			var first := active_orbs[i]
			var second := active_orbs[j]
			var minimum_distance := first.radius + second.radius - 0.1
			runner.assert_true(
				first.position.distance_to(second.position) >= minimum_distance,
				"repeated fast-drop release keeps active falling orbs from overlapping before board contact"
			)
	_destroy_controller(controller)

func test_player_fast_drop_accelerates_falling_hazard(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.playfield.balls = []
	var hazard: BallState = controller.hazard_spawner.spawn_from_event({
		"type": "spawn_hazard",
		"count": 1,
		"value": 5,
		"source": "test",
	})[0]
	controller.playfield.add_ball(hazard)
	var hazard_node = controller.playfield._get_orb_node(hazard.id)
	var original_speed: float = hazard_node.attraction_speed

	var handled: bool = controller.handle_player_fast_drop()

	runner.assert_true(handled, "fast drop handles falling hazards")
	runner.assert_true(hazard_node.attraction_speed > original_speed, "fast drop accelerates falling hazards")
	runner.assert_true(not hazard.settled, "fast drop does not instantly settle a falling hazard")
	_destroy_controller(controller)

func test_falling_hazards_do_not_damage_player_before_boundary_or_clear(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.battle.player_hp = 30
	controller.playfield.balls = []

	for hazard in controller.hazard_spawner.spawn_from_event({
		"type": "spawn_hazard",
		"count": 6,
		"value": 5,
		"source": "test",
		"angle_hint": "boss_side",
	}):
		controller.playfield.add_ball(hazard)

	controller.playfield.advance_hazard_phases(controller.playfield.hazard_warning_seconds + 0.1)
	for exploded in controller.playfield.check_boundary_explosions():
		controller.battle.apply_player_damage(max(exploded.hazard_damage, 1))
	controller.advance_chain_resolution(2.0)

	runner.assert_eq(controller.battle.player_hp, 30, "falling hazards do not damage before boundary explosion or settled clear")
	_destroy_controller(controller)

func test_boundary_hazard_damage_uses_configured_explosion_damage(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.orb_tuning.hazard_tuning.boundary_explosion_damage = 3
	var hazard: BallState = BallState.new_ball(601, BallState.Kind.HAZARD, Vector2(300, 0))
	hazard.value = 5
	hazard.hazard_damage = 9

	runner.assert_eq(controller._hazard_damage(hazard), 3, "boundary explosion damage ignores visible hazard value")
	_destroy_controller(controller)

func test_action_bar_hazard_spawn_does_not_immediately_damage_player(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.battle.player_hp = 30
	controller.playfield.balls = []
	var volley := ActionBarVolleyMechanic.new()
	volley.interval_seconds = 1.0
	volley.count = 2
	volley.value = 5
	controller.boss_controller.configure([volley])

	for i in range(3):
		for event in controller.boss_controller.tick(1.0, controller.battle):
			for hazard in controller.hazard_spawner.spawn_from_event(event):
				controller.playfield.add_ball(hazard)
		for exploded in controller.playfield.check_boundary_explosions():
			controller._apply_player_damage(max(exploded.hazard_damage, 1), "boundary_explosion")
		controller.advance_chain_resolution(0.0)

	var hazard_count := 0
	for ball in controller.playfield.balls:
		if ball.kind == BallState.Kind.HAZARD:
			hazard_count += 1
	runner.assert_eq(hazard_count, 6, "three action-bar volleys spawn six hazards")
	runner.assert_eq(controller.battle.player_hp, 30, "spawning six hazards does not directly damage the player")
	runner.assert_eq(controller.damage_events.size(), 0, "spawning hazards records no player-damage event")
	_destroy_controller(controller)

func test_action_bar_hazard_is_inserted_into_preview_before_dropping(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.playfield.balls = []
	var volley := ActionBarVolleyMechanic.new()
	volley.interval_seconds = 1.0
	volley.count = 1
	volley.value = 5
	controller.boss_controller.configure([volley])
	controller.spawn_queue.seed_preview()
	var before_preview_size := controller.spawn_queue.preview.size()

	controller.advance_boss_events(1.0)

	var hazard_count := 0
	for ball in controller.spawn_queue.preview:
		if ball.kind == BallState.Kind.HAZARD:
			hazard_count += 1
	runner.assert_eq(hazard_count, 1, "boss action inserts a hazard into the preview queue")
	runner.assert_eq(controller.spawn_queue.preview.size(), before_preview_size + 1, "queued hazard does not replace player preview balls")
	runner.assert_eq(controller.playfield.balls.size(), 0, "boss action does not immediately add hazards to the playfield")
	_destroy_controller(controller)

func test_timed_drop_releases_queued_hazard_from_its_entry_angle(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.playfield.balls = []
	controller.spawn_queue.seed_preview()
	var hazard: BallState = controller.hazard_spawner.spawn_from_event({
		"type": "spawn_hazard",
		"count": 1,
		"value": 5,
		"source": "test",
		"angle_degrees": -35.0,
	})[0]
	controller.spawn_queue.insert_preview_ball(hazard, 0)

	controller.advance_player_orb_spawn(controller.player_auto_drop_seconds)

	runner.assert_eq(controller.playfield.balls.size(), 1, "timed drop releases the queued hazard")
	var dropped: BallState = controller.playfield.balls[0]
	runner.assert_eq(dropped.kind, BallState.Kind.HAZARD, "released preview head remains a hazard")
	runner.assert_true(dropped.position.distance_to(hazard.position) < 0.001, "hazard keeps its configured entry position")
	_destroy_controller(controller)

func _instantiate_controller(runner: TestRunner) -> GameController:
	var packed: PackedScene = load("res://scenes/main.tscn")
	runner.assert_true(packed != null, "main scene resource loads for runtime test")
	if packed == null:
		return null
	var controller := packed.instantiate() as GameController
	runner.assert_true(controller != null, "main scene instantiates a game controller")
	if controller == null:
		return null
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(controller)
	controller.playfield = controller.get_node("%Playfield") as Playfield
	controller.spawn_queue = controller.get_node("%SpawnQueue") as SpawnQueue
	controller.tactical_queue = controller.get_node("%TacticalQueue") as TacticalQueue
	controller.hazard_spawner = controller.get_node("%HazardSpawner") as HazardSpawner
	controller.boss_controller = controller.get_node("%BossController") as BossController
	controller.ui = controller.get_node("%BattleUI")
	return controller

func _destroy_controller(controller: GameController) -> void:
	if controller != null and is_instance_valid(controller):
		controller.queue_free()

func _color_ball(id: int, color_id: int, pos: Vector2) -> BallState:
	var ball: BallState = BallState.new_ball(id, BallState.Kind.COLOR, pos)
	ball.color_id = color_id
	ball.settled = true
	return ball

func _combat_ball(id: int, combat_kind: BallState.CombatKind, value: int, pos: Vector2) -> BallState:
	var ball: BallState = BallState.new_ball(id, BallState.Kind.COMBAT, pos)
	ball.combat_kind = combat_kind
	ball.value = value
	ball.settled = true
	return ball
