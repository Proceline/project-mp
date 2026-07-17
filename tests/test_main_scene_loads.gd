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
	var preview_row: BoxContainer = scene.get_node("%PreviewRow")
	battle_ui.player_hp_label = scene.get_node("%PlayerHP")
	battle_ui.shield_marks_label = scene.get_node("%ShieldMarks")
	battle_ui.boss_hp_label = scene.get_node("%BossHP")
	battle_ui.boss_action_bar = scene.get_node("%BossActionBar")
	battle_ui.boss_hp_missing = scene.get_node("%BossHPMissing")
	battle_ui.boss_action_clip = scene.get_node("%BossActionClip")
	battle_ui.boss_action_fill = scene.get_node("%BossActionFill")
	battle_ui.boss_action_glow = scene.get_node("%BossActionGlow")
	battle_ui.preview_row = preview_row
	battle_ui.status_label = scene.get_node("%Status")
	var color_ball := BallState.new_ball(1, BallState.Kind.COLOR, Vector2.ZERO)
	color_ball.color_id = 0
	var hazard := BallState.new_ball(2, BallState.Kind.HAZARD, Vector2.ZERO)
	hazard.value = 5
	hazard.hazard_phase = BallState.HazardPhase.DANGER
	var preview: Array[BallState] = [color_ball, hazard]

	battle_ui.update_from_state(BattleState.new(), 0.0, preview)

	runner.assert_eq(preview_row.get_child_count(), 2, "preview row renders one icon per preview orb")
	if preview_row.get_child_count() >= 2:
		runner.assert_true(preview_row.get_child(0).has_method("current_fill_color"), "preview entries are orb icon controls")
	scene.queue_free()

func test_tactical_queue_ui_is_removed_from_main_scene(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()

	runner.assert_true(not scene.has_node("TacticalQueue"), "tactical queue node is removed from normal play")
	runner.assert_true(not scene.has_node("BattleUI/LeftQueueRoot/TacticalRow"), "left queue UI no longer has a tactical row")
	scene.queue_free()

func test_v05_layout_uses_safe_margins_and_quiet_queue_chrome(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)

	var left_queue_root := scene.get_node("BattleUI/LeftQueueRoot") as Control
	var top_boss_bar_root := scene.get_node("BattleUI/TopBossBarRoot") as Control
	var boss_presentation_root := scene.get_node("BattleUI/BattleBackground/BossPresentationRoot") as Control
	var boss_hp_frame := scene.get_node("BattleUI/TopBossBarRoot/BossHPFrame") as TextureRect
	var queue_frame := scene.get_node("BattleUI/LeftQueueRoot/QueueFrame") as TextureRect
	var boss_portrait := scene.get_node("BattleUI/BattleBackground/BossPresentationRoot/BossPortrait") as TextureRect
	var player_portrait := scene.get_node("BattleUI/BattleBackground/PlayerPortrait") as TextureRect
	var boss_panel := scene.get_node("BattleUI/BossPanel") as ColorRect
	var boss_name := scene.get_node("BattleUI/BattleBackground/BossPresentationRoot/BossName") as Label
	var preview_row := scene.get_node("%PreviewRow")
	var status_label := scene.get_node("%Status") as Label
	var boss_hp := scene.get_node("%BossHP") as Label
	var boss_hp_clip := scene.get_node("%BossHPClip") as Control
	var boss_hp_fill := scene.get_node("%BossHPFill") as ColorRect
	var boss_hp_missing := scene.get_node("%BossHPMissing") as ColorRect
	var boss_action_bar := scene.get_node("%BossActionBar") as ProgressBar
	var boss_action_clip := scene.get_node("%BossActionClip") as Control
	var boss_action_fill := scene.get_node("%BossActionFill") as TextureRect
	var boss_action_glow := scene.get_node("%BossActionGlow") as TextureRect
	var playfield := scene.get_node("%Playfield") as Node2D
	var battle_ui = scene.get_node("%BattleUI")
	battle_ui.battle_background = scene.get_node("%BattleBackground")
	battle_ui.boss_hp_frame = boss_hp_frame
	battle_ui.boss_action_fill = boss_action_fill
	battle_ui.boss_action_glow = boss_action_glow
	battle_ui.queue_frame = queue_frame
	battle_ui.boss_portrait = boss_portrait
	battle_ui.player_portrait = player_portrait
	battle_ui.apply_visual_theme()

	runner.assert_true(left_queue_root != null, "left queue UI has an editor-adjustable root")
	runner.assert_true(top_boss_bar_root != null, "top boss bar UI has an editor-adjustable root")
	runner.assert_true(boss_presentation_root != null, "boss presentation UI has an editor-adjustable root")
	runner.assert_true(boss_hp_frame != null and boss_hp_frame.texture != null, "v05 layout has a top boss HP art frame")
	runner.assert_true(boss_hp_frame.texture.resource_path.ends_with("boss_hp_bar_frame_v09_stacked_shell.png"), "top boss bar uses the v09 empty shell before runtime")
	runner.assert_true(boss_hp_clip != null and boss_hp_clip.visible, "boss HP fill lane is visible in the static scene")
	runner.assert_true(boss_hp_fill != null and boss_hp_fill.visible, "boss HP fill is already placed before gameplay starts")
	runner.assert_true(boss_hp_clip.size.x > 570.0 and boss_hp_clip.size.x < 585.0, "static boss HP starts full-width in the v09 shell")
	runner.assert_true(boss_hp_missing != null and not boss_hp_missing.visible, "legacy boss HP damage mask is hidden with the v09 shell")
	runner.assert_true(boss_action_clip != null, "boss action progress has a clipped lane")
	runner.assert_true(boss_action_fill != null and boss_action_fill.texture != null, "boss action progress uses stacked bar fill before runtime")
	runner.assert_true(boss_action_glow != null and boss_action_glow.texture != null, "boss action progress has stacked warning glow before runtime")
	runner.assert_true(queue_frame != null and queue_frame.texture != null, "v05 layout has a vertical queue art frame")
	runner.assert_true(boss_portrait != null and boss_portrait.texture != null, "v05 layout has a boss portrait")
	runner.assert_true(player_portrait != null and player_portrait.texture != null, "v05 layout has a player portrait")
	runner.assert_true(preview_row is VBoxContainer, "main preview queue is vertical")
	runner.assert_true(boss_hp.get_parent() == top_boss_bar_root, "boss HP text is grouped with the top boss bar")
	runner.assert_true(boss_hp.position.y < 60.0, "boss HP text is placed near the top bar")
	runner.assert_true(playfield.position.x > 430.0 and playfield.position.x < 700.0, "playfield sits near the center after v05 layout shift")
	runner.assert_true(top_boss_bar_root.position.x >= 280.0, "boss HP root keeps a left safe margin")
	runner.assert_true(top_boss_bar_root.position.x + top_boss_bar_root.size.x <= 1140.0, "boss HP root keeps a right safe margin")
	runner.assert_true(not boss_action_bar.visible, "old transparent boss action bar is hidden")
	runner.assert_true(not scene.has_node("BattleUI/TopBossBarRoot/BossActionPips"), "legacy boss action pip row is removed")
	runner.assert_true(boss_portrait.get_parent() == boss_presentation_root, "boss portrait is grouped with the boss presentation root")
	runner.assert_true(boss_presentation_root.get_parent() == battle_ui.battle_background, "boss presentation root is composed inside the painted background")
	runner.assert_eq(boss_portrait.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "boss portrait should not crop the source art")
	runner.assert_true(boss_name.get_parent() == boss_presentation_root, "boss name is grouped with boss portrait")
	runner.assert_true(boss_name.position.x + boss_name.size.x <= boss_presentation_root.size.x, "boss name stays inside boss presentation root")
	runner.assert_true(player_portrait.get_parent() == battle_ui.battle_background, "player portrait is composed inside the painted background")
	runner.assert_eq(player_portrait.anchor_bottom, 1.0, "player portrait is anchored to the bottom edge")
	runner.assert_true(player_portrait.offset_left >= 36.0, "player portrait keeps a left safe margin")
	runner.assert_true(player_portrait.offset_bottom >= 0.0, "player portrait is grounded near the bottom edge")
	runner.assert_true(queue_frame.get_parent() == left_queue_root, "queue frame is grouped with queue rows")
	runner.assert_true(preview_row.get_parent() == left_queue_root, "preview icon row is grouped with the queue frame")
	runner.assert_true(not scene.has_node("BattleUI/Preview"), "legacy preview label node is removed")
	runner.assert_true(not scene.has_node("BattleUI/Tactical"), "legacy tactical label node is removed")
	runner.assert_true(not scene.has_node("BattleUI/LeftQueueRoot/TacticalRow"), "legacy tactical row node is removed")
	runner.assert_true(left_queue_root.position.x >= 32.0, "queue root keeps a left safe margin")
	runner.assert_true(queue_frame.modulate.a <= 0.75, "queue frame is subdued behind the orb icons")
	runner.assert_true(not status_label.visible, "debug status label is hidden")
	runner.assert_true(not boss_panel.visible, "old boss panel tint is hidden")
	scene.queue_free()

func test_boss_hp_and_stacked_action_bar_update_from_state(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)
	var battle_ui = scene.get_node("%BattleUI")
	battle_ui.player_hp_label = scene.get_node("%PlayerHP")
	battle_ui.shield_marks_label = scene.get_node("%ShieldMarks")
	battle_ui.boss_hp_label = scene.get_node("%BossHP")
	battle_ui.boss_action_bar = scene.get_node("%BossActionBar")
	battle_ui.boss_hp_clip = scene.get_node("%BossHPClip")
	battle_ui.boss_hp_fill = scene.get_node("%BossHPFill")
	battle_ui.boss_hp_missing = scene.get_node("%BossHPMissing")
	battle_ui.boss_action_clip = scene.get_node("%BossActionClip")
	battle_ui.boss_action_fill = scene.get_node("%BossActionFill")
	battle_ui.boss_action_glow = scene.get_node("%BossActionGlow")
	battle_ui.preview_row = scene.get_node("%PreviewRow")
	battle_ui.status_label = scene.get_node("%Status")
	var battle := BattleState.new()
	battle.boss_hp = 127
	battle.boss_max_hp = 200
	var empty_preview: Array[BallState] = []

	battle_ui.update_from_state(battle, 0.5, empty_preview)

	runner.assert_eq(battle_ui.boss_hp_label.text, "Boss HP 127/200", "boss HP label shows current HP")
	runner.assert_true(battle_ui.boss_hp_clip.visible, "boss HP fill lane remains visible after boss damage")
	runner.assert_true(battle_ui.boss_hp_clip.size.x > 360.0 and battle_ui.boss_hp_clip.size.x < 370.0, "boss HP fill clips to the current HP ratio")
	runner.assert_true(not battle_ui.boss_hp_missing.visible, "legacy missing HP mask stays hidden with the v09 shell")
	runner.assert_true(battle_ui.boss_action_clip.visible, "boss action clip is visible while progress exists")
	runner.assert_true(battle_ui.boss_action_fill.visible, "boss action fill is visible while progress exists")
	runner.assert_true(battle_ui.boss_action_clip.size.x > 250.0 and battle_ui.boss_action_clip.size.x < 320.0, "half-full boss action ratio clips about half the stacked bar")
	runner.assert_true(battle_ui.boss_action_fill.size.x <= 580.0, "boss action fill art stays inside the stacked bar lane")
	runner.assert_eq(battle_ui.boss_action_fill.texture, battle_ui.visual_theme.boss_action_bar_fill(), "normal action progress uses stacked normal fill")
	runner.assert_true(not battle_ui.boss_action_glow.visible, "normal action progress does not show warning glow")

	battle_ui.update_from_state(battle, 0.9, empty_preview)

	runner.assert_eq(battle_ui.boss_action_fill.texture, battle_ui.visual_theme.boss_action_bar_fill_warning(), "near-full action progress switches to warning fill")
	runner.assert_true(battle_ui.boss_action_glow.visible, "near-full action progress shows glow")
	scene.queue_free()

func test_preview_warning_hazard_draws_without_value_label(runner: TestRunner) -> void:
	var hazard := BallState.new_ball(4, BallState.Kind.HAZARD, Vector2.ZERO)
	hazard.hazard_phase = BallState.HazardPhase.WARNING
	hazard.value = 5
	var icon := PreviewOrbIcon.new()
	icon.setup(hazard)

	runner.assert_eq(icon.display_label(), "", "preview warning hazards do not draw damage numbers")
	icon.queue_free()
