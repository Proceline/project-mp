extends SceneTree

const TestRunner = preload("res://tests/test_runner.gd")
const TestBattleState = preload("res://tests/rules/test_battle_state.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.run_suite(TestBattleState.new())
	quit(runner.failures)
