extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const ChainResolver = preload("res://src/rules/chain_resolver.gd")

func _color_ball(id: int, color_id: int, pos: Vector2) -> BallState:
	var ball: BallState = BallState.new_ball(id, BallState.Kind.COLOR, pos)
	ball.color_id = color_id
	ball.settled = true
	return ball

func _attack_ball(id: int, pos: Vector2) -> BallState:
	var ball: BallState = BallState.new_ball(id, BallState.Kind.COMBAT, pos)
	ball.combat_kind = BallState.CombatKind.ATTACK
	ball.settled = true
	return ball

func _hazard_ball(id: int, value: int, pos: Vector2) -> BallState:
	var ball: BallState = BallState.new_ball(id, BallState.Kind.HAZARD, pos)
	ball.value = value
	ball.settled = true
	return ball

func test_five_same_color_orbs_start_flashing(runner) -> void:
	var resolver := ChainResolver.new()
	var balls: Array[BallState] = []
	for i in range(5):
		balls.append(_color_ball(i, 1, Vector2(i * 40, 0)))
	var chains := resolver.start_flash_groups(balls)
	runner.assert_eq(chains.size(), 1, "five adjacent color orbs create one chain")
	runner.assert_true(balls[0].flashing, "chain members enter flashing state")

func test_board_attached_color_orbs_can_start_flashing_before_locking(runner) -> void:
	var resolver := ChainResolver.new()
	var balls: Array[BallState] = []
	for i in range(5):
		var ball := _color_ball(i, 1, Vector2(i * 40, 0))
		ball.settled = false
		ball.board_attached = true
		balls.append(ball)

	var chains := resolver.start_flash_groups(balls)

	runner.assert_eq(chains.size(), 1, "board-attached color orbs can form a chain while still sliding")
	runner.assert_true(balls[0].flashing, "board-attached chain members enter flashing state")

func test_flashing_chain_absorbs_new_connected_same_color_orb(runner) -> void:
	var resolver := ChainResolver.new()
	var balls: Array[BallState] = []
	for i in range(5):
		balls.append(_color_ball(i, 1, Vector2(i * 40, 0)))
	var chains := resolver.start_flash_groups(balls)
	var late_joiner := _color_ball(99, 1, Vector2(200, 0))
	balls.append(late_joiner)

	var added_count: int = resolver.refresh_flashing_chains(chains, balls)

	runner.assert_eq(added_count, 1, "newly connected same-color orb joins the flashing chain")
	runner.assert_true(late_joiner.flashing, "late chain member starts flashing")
	runner.assert_eq(int(chains[0].strength), 6, "chain strength grows when a new member joins")
	var result := resolver.resolve_finished_chains(chains, balls)
	runner.assert_true(result.cleared_color_ids.has(99), "resolved chain clears late-joined member")

func test_combat_orb_stacks_from_multiple_chains(runner) -> void:
	var resolver := ChainResolver.new()
	var combat := _attack_ball(100, Vector2(80, 0))
	var chain_a: Dictionary = {"color_id": 1, "members": [], "strength": 5}
	var chain_b: Dictionary = {"color_id": 2, "members": [], "strength": 6}
	for i in range(5):
		chain_a.members.append(_color_ball(i, 1, Vector2(i * 30, -20)))
	for i in range(5):
		chain_b.members.append(_color_ball(20 + i, 2, Vector2(i * 30, 20)))
	resolver.apply_chain_influence([chain_a, chain_b], [combat])
	runner.assert_eq(combat.value, 11, "combat value stacks from both chains")

func test_hazard_orb_value_is_not_reduced_by_chain_influence(runner) -> void:
	var resolver := ChainResolver.new()
	var hazard := _hazard_ball(200, 15, Vector2(80, 0))
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	var chain_a: Dictionary = {"color_id": 1, "members": [], "strength": 4}
	var chain_b: Dictionary = {"color_id": 2, "members": [], "strength": 5}
	for i in range(5):
		chain_a.members.append(_color_ball(i, 1, Vector2(i * 30, -20)))
		chain_b.members.append(_color_ball(20 + i, 2, Vector2(i * 30, 20)))
	resolver.apply_chain_influence([chain_a, chain_b], [hazard])
	runner.assert_eq(hazard.value, 15, "hazard visible damage value is not reduced by chain influence")

func test_board_attached_warning_hazard_clears_before_locking(runner) -> void:
	var resolver := ChainResolver.new()
	var hazard := _hazard_ball(202, 0, Vector2(80, 0))
	hazard.settled = false
	hazard.board_attached = true
	hazard.hazard_phase = BallState.HazardPhase.WARNING
	var chain: Dictionary = {"color_id": 1, "members": [], "strength": 5}
	for i in range(5):
		chain.members.append(_color_ball(i, 1, Vector2(i * 30, 0)))

	resolver.apply_chain_influence([chain], [hazard])
	var result := resolver.resolve_finished_chains([chain], [hazard])

	runner.assert_true(result.removed_ball_ids.has(202), "board-attached cleared hazard is removed")

func test_unsettled_hazard_is_not_cleared_by_chain(runner) -> void:
	var resolver := ChainResolver.new()
	var hazard := _hazard_ball(201, 5, Vector2(80, 0))
	hazard.settled = false
	hazard.board_attached = false
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	var chain: Dictionary = {"color_id": 1, "members": [], "strength": 5}
	for i in range(5):
		chain.members.append(_color_ball(i, 1, Vector2(i * 30, 0)))

	resolver.apply_chain_influence([chain], [hazard])
	var result := resolver.resolve_finished_chains([chain], [hazard])

	runner.assert_eq(hazard.value, 5, "unsettled hazard keeps its value while still moving")
	runner.assert_eq(result.player_damage, 0, "unsettled hazard cannot deal hidden clear damage")
	runner.assert_true(not result.removed_ball_ids.has(201), "unsettled hazard is not removed by a chain")
