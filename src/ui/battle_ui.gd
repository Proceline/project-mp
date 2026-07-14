extends CanvasLayer
class_name BattleUI

const DEFAULT_VISUAL_THEME: VisualTheme = preload("res://data/visual_theme_astral_batch1.tres")

@export var visual_theme: VisualTheme = DEFAULT_VISUAL_THEME

@onready var battle_background: TextureRect = %BattleBackground
@onready var boss_hp_frame: TextureRect = %BossHPFrame
@onready var queue_frame: TextureRect = %QueueFrame
@onready var player_portrait: TextureRect = %PlayerPortrait
@onready var boss_portrait: TextureRect = %BossPortrait
@onready var player_hp_label: Label = %PlayerHP
@onready var shield_marks_label: Label = %ShieldMarks
@onready var boss_hp_label: Label = %BossHP
@onready var boss_action_bar: ProgressBar = %BossActionBar
@onready var boss_hp_missing: ColorRect = %BossHPMissing
@onready var boss_action_pips: HBoxContainer = %BossActionPips
@onready var preview_row: BoxContainer = %PreviewRow
@onready var tactical_row: BoxContainer = %TacticalRow
@onready var status_label: Label = %Status

func _ready() -> void:
	apply_visual_theme()

func apply_visual_theme() -> void:
	if battle_background == null or visual_theme == null:
		return
	battle_background.texture = visual_theme.battle_background()
	if boss_hp_frame != null:
		boss_hp_frame.texture = visual_theme.boss_hp_bar_frame()
	if queue_frame != null:
		queue_frame.texture = visual_theme.vertical_queue_frame()
	if player_portrait != null:
		player_portrait.texture = visual_theme.player_portrait()
	if boss_portrait != null:
		boss_portrait.texture = visual_theme.boss_portrait()

func update_from_state(battle: BattleState, boss_action_ratio: float, preview: Array[BallState], tactical: Array[BallState] = []) -> void:
	player_hp_label.text = str(battle.player_hp)
	var marks: int = mini(battle.player_shield, 20)
	if marks > 0:
		shield_marks_label.text = "".rpad(marks, "|")
	else:
		shield_marks_label.text = ""
	shield_marks_label.visible = battle.player_shield > 0
	boss_hp_label.text = "Boss HP %d/%d" % [battle.boss_hp, battle.boss_max_hp]
	boss_action_bar.visible = false
	boss_action_bar.value = 0.0
	_update_boss_hp_mask(battle)
	_update_boss_action_pips(boss_action_ratio)
	_update_icon_row(preview_row, preview)
	_update_icon_row(tactical_row, tactical)
	status_label.text = ""
	status_label.visible = false

func _update_icon_row(row: BoxContainer, orbs: Array[BallState]) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for ball in orbs:
		var icon := PreviewOrbIcon.new()
		icon.visual_theme = visual_theme
		icon.setup(ball)
		row.add_child(icon)

func _update_boss_hp_mask(battle: BattleState) -> void:
	if boss_hp_missing == null:
		return
	var max_hp: int = max(battle.boss_max_hp, 1)
	var hp_ratio := clampf(float(battle.boss_hp) / float(max_hp), 0.0, 1.0)
	var full_width: float = 520.0
	var missing_width := full_width * (1.0 - hp_ratio)
	boss_hp_missing.visible = missing_width > 0.5
	boss_hp_missing.size.x = missing_width
	boss_hp_missing.position.x = 170.0 + full_width - missing_width

func _update_boss_action_pips(boss_action_ratio: float) -> void:
	if boss_action_pips == null:
		return
	for child in boss_action_pips.get_children():
		boss_action_pips.remove_child(child)
		child.queue_free()
	var pip_count: int = int(ceil(clampf(boss_action_ratio, 0.0, 1.0) * 7.0))
	for i in range(pip_count):
		boss_action_pips.add_child(_new_boss_action_pip())

func _new_boss_action_pip() -> TextureRect:
	var pip := TextureRect.new()
	pip.custom_minimum_size = Vector2(19.0, 19.0)
	pip.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pip.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pip.modulate = Color(1, 1, 1, 0.92)
	if visual_theme != null:
		var hazard := BallState.new_ball(-1, BallState.Kind.HAZARD, Vector2.ZERO)
		hazard.hazard_phase = BallState.HazardPhase.DANGER
		hazard.value = 1
		pip.texture = visual_theme.get_orb_texture(hazard)
	return pip
