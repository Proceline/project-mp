extends SceneTree

const TestBattleState = preload("res://tests/rules/test_battle_state.gd")
const TestChainResolver = preload("res://tests/rules/test_chain_resolver.gd")
const TestChainResolutionResults = preload("res://tests/rules/test_chain_resolution_results.gd")
const TestBossController = preload("res://tests/boss/test_boss_controller.gd")
const TestSpawnAndHazards = preload("res://tests/playfield/test_spawn_and_hazards.gd")
const TestGameControllerRuntime = preload("res://tests/test_game_controller_runtime.gd")
const TestMainSceneLoads = preload("res://tests/test_main_scene_loads.gd")
const TestVisualTheme = preload("res://tests/test_visual_theme.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.run_suite(TestBattleState.new())
	runner.run_suite(TestChainResolver.new())
	runner.run_suite(TestChainResolutionResults.new())
	runner.run_suite(TestBossController.new())
	runner.run_suite(TestSpawnAndHazards.new())
	runner.run_suite(TestGameControllerRuntime.new())
	runner.run_suite(TestMainSceneLoads.new())
	runner.run_suite(TestVisualTheme.new())
	quit(runner.failures)
