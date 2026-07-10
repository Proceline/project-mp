extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const ChainResolver = preload("res://src/rules/chain_resolver.gd")

func test_finished_chain_converts_combat_values_to_results(runner) -> void:
	var resolver := ChainResolver.new()
	var attack: BallState = BallState.new_ball(20, BallState.Kind.COMBAT, Vector2(30, 0))
	attack.combat_kind = BallState.CombatKind.ATTACK
	attack.value = 9
	var shield: BallState = BallState.new_ball(21, BallState.Kind.COMBAT, Vector2(60, 0))
	shield.combat_kind = BallState.CombatKind.SHIELD
	shield.value = 4
	var heal: BallState = BallState.new_ball(22, BallState.Kind.COMBAT, Vector2(90, 0))
	heal.combat_kind = BallState.CombatKind.HEAL
	heal.value = 6
	var chain := {"color_id": 1, "members": [], "strength": 5}
	for i in range(5):
		var color: BallState = BallState.new_ball(i, BallState.Kind.COLOR, Vector2(i * 20, 0))
		color.color_id = 1
		color.flashing = true
		chain.members.append(color)
	var result: Dictionary = resolver.resolve_finished_chains([chain], [attack, shield, heal])
	runner.assert_eq(result.attack, 9, "attack value is emitted")
	runner.assert_eq(result.shield, 4, "shield value is emitted")
	runner.assert_eq(result.heal, 6, "heal value is emitted")
	runner.assert_eq(result.cleared_color_ids.size(), 5, "cleared color ids include every chain member")
	for i in range(5):
		runner.assert_true(result.cleared_color_ids.has(i), "cleared color ids include member %d" % i)
	runner.assert_true(result.removed_ball_ids.has(20), "triggered attack orb removed")
	runner.assert_true(result.removed_ball_ids.has(21), "triggered shield orb removed")
	runner.assert_true(result.removed_ball_ids.has(22), "triggered heal orb removed")

func test_finished_chain_removes_cleared_warning_hazard_without_damage(runner) -> void:
	var resolver := ChainResolver.new()
	var hazard: BallState = BallState.new_ball(30, BallState.Kind.HAZARD, Vector2(30, 0))
	hazard.value = 0
	hazard.hazard_damage = 7
	hazard.hazard_phase = BallState.HazardPhase.WARNING
	var chain := _touching_chain()

	var result: Dictionary = resolver.resolve_finished_chains([chain], [hazard])

	runner.assert_true(result.removed_ball_ids.has(30), "cleared warning hazard is removed")
	runner.assert_eq(result.hazard_removed_in_warning.size(), 1, "warning hazard removal is reported separately")
	runner.assert_eq(result.player_damage, 0, "warning hazard clears without player damage")

func test_finished_chain_removes_cleared_danger_hazard_with_damage(runner) -> void:
	var resolver := ChainResolver.new()
	var hazard: BallState = BallState.new_ball(31, BallState.Kind.HAZARD, Vector2(30, 0))
	hazard.value = 0
	hazard.hazard_damage = 7
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	var chain := _touching_chain()

	var result: Dictionary = resolver.resolve_finished_chains([chain], [hazard])

	runner.assert_true(result.removed_ball_ids.has(31), "cleared danger hazard is removed")
	runner.assert_eq(result.hazard_removed_in_danger.size(), 1, "danger hazard removal is reported separately")
	runner.assert_eq(result.player_damage, 7, "danger hazard deals its stored damage when cleared")

func _touching_chain() -> Dictionary:
	var chain := {"color_id": 1, "members": [], "strength": 5}
	for i in range(5):
		var color: BallState = BallState.new_ball(100 + i, BallState.Kind.COLOR, Vector2(i * 10, 0))
		color.color_id = 1
		color.flashing = true
		chain.members.append(color)
	return chain
