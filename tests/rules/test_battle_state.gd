extends RefCounted

const BattleState = preload("res://src/rules/battle_state.gd")

func test_shield_absorbs_before_hp(runner) -> void:
	var state := BattleState.new()
	state.player_hp = 20
	state.player_shield = 7
	state.apply_player_damage(10)
	runner.assert_eq(state.player_shield, 0, "shield is consumed first")
	runner.assert_eq(state.player_hp, 17, "remaining damage reaches hp")

func test_heal_clamps_to_max_hp(runner) -> void:
	var state := BattleState.new()
	state.player_hp = 18
	state.player_max_hp = 20
	state.heal_player(10)
	runner.assert_eq(state.player_hp, 20, "heal does not exceed max hp")

func test_boss_damage_and_results(runner) -> void:
	var state := BattleState.new()
	state.boss_hp = 12
	state.apply_attack_to_boss(12)
	runner.assert_eq(state.boss_hp, 0, "boss hp clamps to zero")
	runner.assert_eq(state.result(), "win", "boss at zero means win")
