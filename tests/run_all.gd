extends SceneTree

const TestRunner = preload("res://tests/test_runner.gd")
const TestBattleState = preload("res://tests/rules/test_battle_state.gd")
const TestChainResolver = preload("res://tests/rules/test_chain_resolver.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.run_suite(TestBattleState.new())
	runner.run_suite(TestChainResolver.new())
	quit(runner.failures)
