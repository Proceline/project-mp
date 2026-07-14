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
@onready var preview_label: Label = %Preview
@onready var preview_row: BoxContainer = %PreviewRow
@onready var tactical_label: Label = %Tactical
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
	boss_action_bar.value = clampf(boss_action_ratio * 100.0, 0.0, 100.0)
	preview_label.text = "Next:"
	tactical_label.text = "Tactic:"
	_update_icon_row(preview_row, preview)
	_update_icon_row(tactical_row, tactical)
	status_label.text = battle.result()

func _update_icon_row(row: BoxContainer, orbs: Array[BallState]) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for ball in orbs:
		var icon := PreviewOrbIcon.new()
		icon.visual_theme = visual_theme
		icon.setup(ball)
		row.add_child(icon)
