extends RefCounted

func test_batch1_visual_theme_maps_orb_textures(runner: TestRunner) -> void:
	var theme: VisualTheme = load("res://data/visual_theme_astral_batch1.tres")
	runner.assert_true(theme != null, "batch 1 visual theme resource loads")
	if theme == null:
		return
	var red := BallState.new_ball(1, BallState.Kind.COLOR, Vector2.ZERO)
	red.color_id = 0
	var attack := BallState.new_ball(2, BallState.Kind.COMBAT, Vector2.ZERO)
	attack.combat_kind = BallState.CombatKind.ATTACK
	var warning := BallState.new_ball(3, BallState.Kind.HAZARD, Vector2.ZERO)
	warning.hazard_phase = BallState.HazardPhase.WARNING
	var danger := BallState.new_ball(4, BallState.Kind.HAZARD, Vector2.ZERO)
	danger.hazard_phase = BallState.HazardPhase.DANGER

	runner.assert_true(theme.get_orb_texture(red) != null, "theme maps red color orb texture")
	runner.assert_true(theme.get_orb_texture(attack) != null, "theme maps attack combat orb texture")
	runner.assert_true(theme.get_orb_texture(warning) != null, "theme maps warning eclipse orb texture")
	runner.assert_true(theme.get_orb_texture(danger) != null, "theme maps danger eclipse orb texture")

func test_batch1_visual_theme_uses_v04_body_and_glow_paths(runner: TestRunner) -> void:
	var theme: VisualTheme = load("res://data/visual_theme_astral_batch1.tres")
	runner.assert_true(theme != null, "batch 1 visual theme resource loads for v04 checks")
	if theme == null:
		return
	runner.assert_true(theme.color_orb_red_path.ends_with("_body_v04.png"), "star orb body path uses v04 runtime body art")
	runner.assert_true(theme.combat_orb_attack_path.ends_with("_body_v04.png"), "combat orb body path uses v04 runtime body art")
	runner.assert_true(theme.eclipse_orb_danger_path.ends_with("_body_v04.png"), "eclipse orb body path uses v04 runtime body art")
	var red := BallState.new_ball(11, BallState.Kind.COLOR, Vector2.ZERO)
	red.color_id = 0
	var attack := BallState.new_ball(12, BallState.Kind.COMBAT, Vector2.ZERO)
	attack.combat_kind = BallState.CombatKind.ATTACK
	var danger := BallState.new_ball(13, BallState.Kind.HAZARD, Vector2.ZERO)
	danger.hazard_phase = BallState.HazardPhase.DANGER

	runner.assert_true(theme.get_orb_glow_texture(red) != null, "theme maps red star orb glow texture separately")
	runner.assert_true(theme.get_orb_glow_texture(attack) != null, "theme maps attack combat orb glow texture separately")
	runner.assert_true(theme.get_orb_glow_texture(danger) != null, "theme maps danger eclipse orb glow texture separately")

func test_preview_icons_receive_theme_from_battle_ui(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene: Node = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)
	var battle_ui = scene.get_node("%BattleUI")
	var theme: VisualTheme = load("res://data/visual_theme_astral_batch1.tres")
	battle_ui.visual_theme = theme
	battle_ui.player_hp_label = scene.get_node("%PlayerHP")
	battle_ui.shield_marks_label = scene.get_node("%ShieldMarks")
	battle_ui.boss_hp_label = scene.get_node("%BossHP")
	battle_ui.boss_action_bar = scene.get_node("%BossActionBar")
	battle_ui.preview_label = scene.get_node("%Preview")
	battle_ui.preview_row = scene.get_node("%PreviewRow")
	battle_ui.tactical_label = scene.get_node("%Tactical")
	battle_ui.tactical_row = scene.get_node("%TacticalRow")
	battle_ui.status_label = scene.get_node("%Status")
	var color_ball := BallState.new_ball(5, BallState.Kind.COLOR, Vector2.ZERO)
	color_ball.color_id = 1
	var preview: Array[BallState] = [color_ball]
	var tactical: Array[BallState] = []

	battle_ui.update_from_state(BattleState.new(), 0.0, preview, tactical)

	var icon := battle_ui.preview_row.get_child(0) as PreviewOrbIcon
	runner.assert_true(icon != null, "preview row creates themed orb icon")
	if icon != null:
		runner.assert_eq(icon.visual_theme, theme, "preview icon receives the UI visual theme")
	scene.queue_free()

func test_game_controller_applies_visual_theme_to_playfield_and_ui(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)

	runner.assert_eq(scene.get_node("%Playfield").visual_theme, scene.visual_theme, "controller passes visual theme to playfield")
	runner.assert_eq(scene.get_node("%BattleUI").visual_theme, scene.visual_theme, "controller passes visual theme to battle UI")
	scene.queue_free()

func test_battle_background_uses_visual_theme_texture(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	var scene = packed.instantiate()
	var tree := Engine.get_main_loop() as SceneTree
	tree.root.add_child(scene)

	var background := scene.get_node("%BattleBackground") as TextureRect
	var battle_ui = scene.get_node("%BattleUI")
	battle_ui.battle_background = background
	battle_ui.visual_theme = scene.visual_theme
	battle_ui.apply_visual_theme()
	runner.assert_true(background != null, "main scene has a battle background texture rect")
	if background != null:
		runner.assert_true(background.texture != null, "battle background texture comes from the visual theme")
	scene.queue_free()
