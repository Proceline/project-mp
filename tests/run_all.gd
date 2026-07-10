extends SceneTree

const TestRunner = preload("res://tests/test_runner.gd")
const TestBattleState = preload("res://tests/rules/test_battle_state.gd")
const TestChainResolver = preload("res://tests/rules/test_chain_resolver.gd")
const TestBossController = preload("res://tests/boss/test_boss_controller.gd")
const TestSpawnAndHazards = preload("res://tests/playfield/test_spawn_and_hazards.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.run_suite(TestBattleState.new())
	runner.run_suite(TestChainResolver.new())
	runner.run_suite(TestBossController.new())
	runner.run_suite(TestSpawnAndHazards.new())
	quit(runner.failures)
