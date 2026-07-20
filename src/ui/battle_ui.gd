extends CanvasLayer
class_name BattleUI

const DEFAULT_VISUAL_THEME: VisualTheme = preload("res://data/visual_theme_astral_batch1.tres")

@export var visual_theme: VisualTheme = DEFAULT_VISUAL_THEME
@export_file("*.tscn") var main_menu_scene_path: String = "res://scenes/start.tscn"
@export_file("*.tscn") var restart_scene_path: String = "res://scenes/main.tscn"

@onready var battle_background: TextureRect = %BattleBackground
@onready var boss_hp_frame: TextureRect = %BossHPFrame
@onready var queue_frame: TextureRect = %QueueFrame
@onready var player_portrait: TextureRect = %PlayerPortrait
@onready var boss_portrait: TextureRect = %BossPortrait
@onready var player_hp_label: Label = %PlayerHP
@onready var shield_badge: Control = %ShieldBadge
@onready var shield_value_label: Label = %ShieldValue
@onready var boss_hp_label: Label = %BossHP
@onready var boss_action_bar: ProgressBar = %BossActionBar
@onready var boss_hp_clip: Control = %BossHPClip
@onready var boss_hp_fill: ColorRect = %BossHPFill
@onready var boss_hp_missing: ColorRect = %BossHPMissing
@onready var boss_action_clip: Control = %BossActionClip
@onready var boss_action_fill: TextureRect = %BossActionFill
@onready var boss_action_glow: TextureRect = %BossActionGlow
@onready var preview_row: BoxContainer = %PreviewRow
@onready var status_label: Label = %Status
@onready var main_menu_button: Button = %MainMenuButton
@onready var restart_button: Button = %RestartButton
@onready var end_game_button: Button = %EndGameButton

const BOSS_HP_FILL_X := 197.0
const BOSS_HP_FILL_WIDTH := 577.0
const BOSS_HP_FILL_HEIGHT := 26.0
const BOSS_ACTION_FILL_WIDTH := 577.0
const BOSS_ACTION_FILL_HEIGHT := 12.0
const BOSS_ACTION_WARNING_THRESHOLD := 0.85

func _ready() -> void:
	_connect_scene_menu()
	apply_visual_theme()

func apply_visual_theme() -> void:
	if battle_background == null or visual_theme == null:
		return
	battle_background.texture = visual_theme.battle_background()
	if boss_hp_frame != null:
		boss_hp_frame.texture = visual_theme.boss_hp_bar_frame()
	if boss_action_fill != null:
		boss_action_fill.texture = visual_theme.boss_action_bar_fill()
	if boss_action_glow != null:
		boss_action_glow.texture = visual_theme.boss_action_bar_glow()
	if queue_frame != null:
		queue_frame.texture = visual_theme.vertical_queue_frame()
	if player_portrait != null:
		player_portrait.texture = visual_theme.player_portrait()
	if boss_portrait != null:
		boss_portrait.texture = visual_theme.boss_portrait()

func update_from_state(battle: BattleState, boss_action_ratio: float, preview: Array[BallState], shield_display_value: int = -1) -> void:
	player_hp_label.text = str(battle.player_hp)
	var displayed_shield := battle.player_shield if shield_display_value < 0 else shield_display_value
	if shield_badge != null:
		shield_badge.visible = displayed_shield > 0
	if shield_value_label != null:
		shield_value_label.text = str(displayed_shield)
	boss_hp_label.text = "Boss HP %d/%d" % [battle.boss_hp, battle.boss_max_hp]
	boss_action_bar.visible = false
	boss_action_bar.value = 0.0
	_update_boss_hp_fill(battle)
	_update_boss_action_bar(boss_action_ratio)
	_update_icon_row(preview_row, preview)
	status_label.text = ""
	status_label.visible = false

func _update_icon_row(row: BoxContainer, orbs: Array[BallState]) -> void:
	if row == null:
		return
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for ball in orbs:
		var icon := PreviewOrbIcon.new()
		icon.visual_theme = visual_theme
		icon.setup(ball)
		row.add_child(icon)

func _update_boss_hp_fill(battle: BattleState) -> void:
	if boss_hp_clip == null or boss_hp_fill == null:
		return
	var max_hp: int = max(battle.boss_max_hp, 1)
	var hp_ratio := clampf(float(battle.boss_hp) / float(max_hp), 0.0, 1.0)
	boss_hp_clip.visible = hp_ratio > 0.001
	boss_hp_clip.size.x = BOSS_HP_FILL_WIDTH * hp_ratio
	boss_hp_clip.size.y = BOSS_HP_FILL_HEIGHT
	boss_hp_fill.visible = true
	boss_hp_fill.size.x = BOSS_HP_FILL_WIDTH
	boss_hp_fill.size.y = BOSS_HP_FILL_HEIGHT
	if boss_hp_missing != null:
		boss_hp_missing.visible = false

func _update_boss_action_bar(boss_action_ratio: float) -> void:
	if boss_action_clip == null or boss_action_fill == null:
		return
	var ratio := clampf(boss_action_ratio, 0.0, 1.0)
	boss_action_clip.visible = ratio > 0.001
	boss_action_clip.size.x = BOSS_ACTION_FILL_WIDTH * ratio
	boss_action_fill.visible = true
	boss_action_fill.size.x = BOSS_ACTION_FILL_WIDTH
	boss_action_fill.size.y = BOSS_ACTION_FILL_HEIGHT
	if visual_theme != null:
		boss_action_fill.texture = visual_theme.boss_action_bar_fill_warning() if ratio >= BOSS_ACTION_WARNING_THRESHOLD else visual_theme.boss_action_bar_fill()
	if boss_action_glow != null:
		boss_action_glow.visible = ratio >= BOSS_ACTION_WARNING_THRESHOLD
		if visual_theme != null:
			boss_action_glow.texture = visual_theme.boss_action_bar_glow()

func _connect_scene_menu() -> void:
	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	if restart_button != null:
		restart_button.pressed.connect(_on_restart_button_pressed)
	if end_game_button != null:
		end_game_button.pressed.connect(_on_end_game_button_pressed)

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file(main_menu_scene_path)

func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file(restart_scene_path)

func _on_end_game_button_pressed() -> void:
	get_tree().quit()
