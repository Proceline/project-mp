extends SceneTree

const TestRunner = preload("res://tests/test_runner.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.assert_eq(2 + 2, 4, "basic arithmetic works")
	quit(runner.failures)
