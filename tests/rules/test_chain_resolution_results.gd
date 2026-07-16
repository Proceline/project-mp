extends RefCounted

func test_finished_red_chain_deals_double_attack(runner) -> void:
	var resolver := ChainResolver.new()
	var chain := _chain(0, 5)

	var result: Dictionary = resolver.resolve_finished_chains([chain], [])

	runner.assert_eq(result.attack, 10, "red chain deals 2 damage per orb")
	runner.assert_eq(result.heal, 0, "red chain does not heal")
	runner.assert_eq(result.hazard_mitigation, 0, "red chain does not grant hazard mitigation")
	runner.assert_eq(result.yellow_vulnerability, 0, "red chain does not grant vulnerability")
	runner.assert_eq(result.cleared_color_ids.size(), 5, "cleared color ids include every chain member")
	for i in range(5):
		runner.assert_true(result.cleared_color_ids.has(i), "cleared color ids include member %d" % i)

func test_finished_green_chain_deals_damage_and_heals_half(runner) -> void:
	var resolver := ChainResolver.new()
	var chain := _chain(3, 6)

	var result: Dictionary = resolver.resolve_finished_chains([chain], [])

	runner.assert_eq(result.attack, 6, "green chain deals 1 damage per orb")
	runner.assert_eq(result.heal, 3, "green chain heals for half its damage")
	runner.assert_eq(result.cleared_color_ids.size(), 6, "green chain clears all color members")

func test_finished_blue_chain_grants_hazard_mitigation(runner) -> void:
	var resolver := ChainResolver.new()
	var chain := _chain(1, 5)

	var result: Dictionary = resolver.resolve_finished_chains([chain], [])

	runner.assert_eq(result.attack, 5, "blue chain deals 1 damage per orb")
	runner.assert_eq(result.hazard_mitigation, 5, "blue chain grants 1 hazard mitigation per orb")

func test_finished_yellow_chain_grants_vulnerability_without_damage(runner) -> void:
	var resolver := ChainResolver.new()
	var chain := _chain(2, 5)

	var result: Dictionary = resolver.resolve_finished_chains([chain], [])

	runner.assert_eq(result.attack, 0, "yellow chain has 0 base damage")
	runner.assert_eq(result.yellow_vulnerability, 5, "yellow chain grants 1 next-hit vulnerability per orb")

func test_finished_chain_removes_cleared_warning_hazard_without_damage(runner) -> void:
	var resolver := ChainResolver.new()
	var hazard: BallState = BallState.new_ball(30, BallState.Kind.HAZARD, Vector2(30, 0))
	hazard.value = 0
	hazard.hazard_damage = 7
	hazard.hazard_phase = BallState.HazardPhase.WARNING
	hazard.settled = true
	var chain := _touching_chain()

	var result: Dictionary = resolver.resolve_finished_chains([chain], [hazard])

	runner.assert_true(result.removed_ball_ids.has(30), "cleared warning hazard is removed")
	runner.assert_eq(result.hazard_removed_in_warning.size(), 1, "warning hazard removal is reported separately")
	runner.assert_eq(result.player_damage, 0, "warning hazard clears without player damage")

func test_finished_chain_removes_cleared_danger_hazard_with_damage(runner) -> void:
	var resolver := ChainResolver.new()
	var hazard: BallState = BallState.new_ball(31, BallState.Kind.HAZARD, Vector2(30, 0))
	hazard.value = 3
	hazard.hazard_damage = 7
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	hazard.settled = true
	var chain := _touching_chain()

	var result: Dictionary = resolver.resolve_finished_chains([chain], [hazard])

	runner.assert_true(result.removed_ball_ids.has(31), "cleared danger hazard is removed")
	runner.assert_eq(result.hazard_removed_in_danger.size(), 1, "danger hazard removal is reported separately")
	runner.assert_eq(result.player_damage, 3, "danger hazard deals damage equal to its visible value when cleared")

func _touching_chain() -> Dictionary:
	return _chain(0, 5, 100, 10)

func _chain(color_id: int, strength: int, id_offset: int = 0, spacing: float = 20.0) -> Dictionary:
	var chain := {"color_id": color_id, "members": [], "strength": strength}
	for i in range(strength):
		var color: BallState = BallState.new_ball(id_offset + i, BallState.Kind.COLOR, Vector2(i * spacing, 0))
		color.color_id = color_id
		color.flashing = true
		chain.members.append(color)
	return chain
