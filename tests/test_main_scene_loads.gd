extends RefCounted

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
	var preview_row: BoxContainer = scene.get_node("%PreviewRow")
	var tactical_row: BoxContainer = scene.get_node("%TacticalRow")
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
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	var preview: Array[BallState] = [color_ball, hazard]

	var empty_tactical: Array[BallState] = []
	battle_ui.update_from_state(BattleState.new(), 0.0, preview, empty_tactical)

	runner.assert_eq(preview_label.text, "", "preview label is hidden in the v05 art frame")
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

	runner.assert_eq(battle_ui.tactical_label.text, "", "tactical label is hidden in the v05 art frame")
	runner.assert_eq(battle_ui.tactical_row.get_child_count(), 1, "tactical row renders combat slots separately")
	scene.queue_free()

func test_v05_layout_uses_safe_margins_and_quiet_queue_chrome(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)

	var boss_hp_frame := scene.get_node("BattleUI/BossHPFrame") as TextureRect
	var queue_frame := scene.get_node("BattleUI/QueueFrame") as TextureRect
	var boss_portrait := scene.get_node("BattleUI/BossPortrait") as TextureRect
	var player_portrait := scene.get_node("BattleUI/PlayerPortrait") as TextureRect
	var boss_panel := scene.get_node("BattleUI/BossPanel") as ColorRect
	var boss_name := scene.get_node("BattleUI/BossName") as Label
	var preview_row := scene.get_node("%PreviewRow")
	var tactical_row := scene.get_node("%TacticalRow")
	var preview_label := scene.get_node("%Preview") as Label
	var tactical_label := scene.get_node("%Tactical") as Label
	var status_label := scene.get_node("%Status") as Label
	var boss_hp := scene.get_node("%BossHP") as Label
	var playfield := scene.get_node("%Playfield") as Node2D
	var battle_ui = scene.get_node("%BattleUI")
	battle_ui.battle_background = scene.get_node("%BattleBackground")
	battle_ui.boss_hp_frame = boss_hp_frame
	battle_ui.queue_frame = queue_frame
	battle_ui.boss_portrait = boss_portrait
	battle_ui.player_portrait = player_portrait
	battle_ui.apply_visual_theme()

	runner.assert_true(boss_hp_frame != null and boss_hp_frame.texture != null, "v05 layout has a top boss HP art frame")
	runner.assert_true(queue_frame != null and queue_frame.texture != null, "v05 layout has a vertical queue art frame")
	runner.assert_true(boss_portrait != null and boss_portrait.texture != null, "v05 layout has a boss portrait")
	runner.assert_true(player_portrait != null and player_portrait.texture != null, "v05 layout has a player portrait")
	runner.assert_true(preview_row is VBoxContainer, "main preview queue is vertical")
	runner.assert_true(tactical_row is VBoxContainer, "tactical queue is vertical")
	runner.assert_true(boss_hp.position.y < 60.0, "boss HP text is placed near the top bar")
	runner.assert_true(playfield.position.x > 430.0 and playfield.position.x < 700.0, "playfield sits near the center after v05 layout shift")
	runner.assert_true(boss_hp_frame.position.x >= 280.0, "boss HP art keeps a left safe margin")
	runner.assert_true(boss_hp_frame.position.x + boss_hp_frame.size.x <= 1140.0, "boss HP art keeps a right safe margin")
	runner.assert_true(boss_portrait.position.x >= 760.0, "boss portrait stays in the right presentation zone")
	runner.assert_true(boss_portrait.position.x + boss_portrait.size.x <= 1240.0, "boss portrait keeps a right safe margin")
	runner.assert_eq(boss_portrait.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "boss portrait should not crop the source art")
	runner.assert_true(boss_name.position.x + boss_name.size.x <= 1220.0, "boss name keeps a right safe margin")
	runner.assert_true(player_portrait.position.x >= 36.0, "player portrait keeps a left safe margin")
	runner.assert_true(player_portrait.position.y + player_portrait.size.y <= 710.0, "player portrait keeps a bottom safe margin")
	runner.assert_true(queue_frame.position.x >= 32.0, "queue frame keeps a left safe margin")
	runner.assert_true(queue_frame.modulate.a <= 0.75, "queue frame is subdued behind the orb icons")
	runner.assert_eq(preview_label.text, "", "preview text label is removed")
	runner.assert_eq(tactical_label.text, "", "tactical text label is removed")
	runner.assert_true(not status_label.visible, "debug status label is hidden")
	runner.assert_true(not boss_panel.visible, "old boss panel tint is hidden")
	scene.queue_free()

func test_preview_warning_hazard_draws_without_value_label(runner: TestRunner) -> void:
	var hazard := BallState.new_ball(4, BallState.Kind.HAZARD, Vector2.ZERO)
	hazard.hazard_phase = BallState.HazardPhase.WARNING
	hazard.value = 5
	var icon := PreviewOrbIcon.new()
	icon.setup(hazard)

	runner.assert_eq(icon.display_label(), "", "preview warning hazards do not draw damage numbers")
	icon.queue_free()
