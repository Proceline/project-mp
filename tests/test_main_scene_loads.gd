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

func test_playfield_renders_above_background_panels(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	var battle_ui: CanvasLayer = scene.get_node("%BattleUI")
	var playfield: Node = scene.get_node("%Playfield")
	var field_ring: Node = battle_ui.get_node("FieldRing")

	runner.assert_eq(playfield.get_parent(), battle_ui, "playfield is inside the UI canvas layer")
	runner.assert_true(playfield.get_index() > field_ring.get_index(), "playfield renders after field background panels")

	scene.queue_free()
