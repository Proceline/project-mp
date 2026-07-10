extends RefCounted

const TestRunner = preload("res://tests/test_runner.gd")

func test_main_scene_loads(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	runner.assert_true(packed != null, "main scene resource loads")
	var scene: Node = null
	if packed != null:
		scene = packed.instantiate()
	runner.assert_true(scene != null, "main scene instantiates")
	if scene != null:
		scene.queue_free()
