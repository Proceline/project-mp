extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const BattleState = preload("res://src/rules/battle_state.gd")
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

func test_preview_renders_orb_icons_instead_of_code_text(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)
	var battle_ui = scene.get_node("%BattleUI")
	var preview_label: Label = scene.get_node("%Preview")
	var preview_row: HBoxContainer = scene.get_node("%PreviewRow")
	var tactical_row: HBoxContainer = scene.get_node("%TacticalRow")
	battle_ui.player_hp_label = scene.get_node("%PlayerHP")
	battle_ui.shield_marks_label = scene.get_node("%ShieldMarks")
	battle_ui.boss_hp_label = scene.get_node("%BossHP")
	battle_ui.boss_action_bar = scene.get_node("%BossActionBar")
	battle_ui.preview_label = preview_label
	battle_ui.preview_row = preview_row
	battle_ui.tactical_label = scene.get_node("%Tactical")
	battle_ui.tactical_row = tactical_row
	battle_ui.status_label = scene.get_node("%Status")
	var color_ball := BallState.new_ball(1, BallState.Kind.COLOR, Vector2.ZERO)
	color_ball.color_id = 0
	var hazard := BallState.new_ball(2, BallState.Kind.HAZARD, Vector2.ZERO)
	hazard.value = 5
	var preview: Array[BallState] = [color_ball, hazard]

	var empty_tactical: Array[BallState] = []
	battle_ui.update_from_state(BattleState.new(), 0.0, preview, empty_tactical)

	runner.assert_eq(preview_label.text, "Next:", "preview label only names the queue")
	runner.assert_eq(preview_row.get_child_count(), 2, "preview row renders one icon per preview orb")
	if preview_row.get_child_count() >= 2:
		runner.assert_true(preview_row.get_child(0).has_method("current_fill_color"), "preview entries are orb icon controls")
	scene.queue_free()

func test_tactical_row_renders_separate_combat_icons(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)
	var battle_ui = scene.get_node("%BattleUI")
	battle_ui.player_hp_label = scene.get_node("%PlayerHP")
	battle_ui.shield_marks_label = scene.get_node("%ShieldMarks")
	battle_ui.boss_hp_label = scene.get_node("%BossHP")
	battle_ui.boss_action_bar = scene.get_node("%BossActionBar")
	battle_ui.preview_label = scene.get_node("%Preview")
	battle_ui.preview_row = scene.get_node("%PreviewRow")
	battle_ui.tactical_label = scene.get_node("%Tactical")
	battle_ui.tactical_row = scene.get_node("%TacticalRow")
	battle_ui.status_label = scene.get_node("%Status")
	var combat := BallState.new_ball(3, BallState.Kind.COMBAT, Vector2.ZERO)
	combat.combat_kind = BallState.CombatKind.ATTACK
	var empty_preview: Array[BallState] = []
	var tactical: Array[BallState] = [combat]

	battle_ui.update_from_state(BattleState.new(), 0.0, empty_preview, tactical)

	runner.assert_eq(battle_ui.tactical_label.text, "Tactic:", "tactical row has a separate label")
	runner.assert_eq(battle_ui.tactical_row.get_child_count(), 1, "tactical row renders combat slots separately")
	scene.queue_free()
