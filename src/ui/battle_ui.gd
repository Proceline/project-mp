extends CanvasLayer
class_name BattleUI

const BallState = preload("res://src/rules/ball_state.gd")
const BattleState = preload("res://src/rules/battle_state.gd")
const PreviewOrbIcon = preload("res://src/ui/preview_orb_icon.gd")

@onready var player_hp_label: Label = %PlayerHP
@onready var shield_marks_label: Label = %ShieldMarks
@onready var boss_hp_label: Label = %BossHP
@onready var boss_action_bar: ProgressBar = %BossActionBar
@onready var preview_label: Label = %Preview
@onready var preview_row: HBoxContainer = %PreviewRow
@onready var tactical_label: Label = %Tactical
@onready var tactical_row: HBoxContainer = %TacticalRow
@onready var status_label: Label = %Status

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

func _update_icon_row(row: HBoxContainer, orbs: Array[BallState]) -> void:
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for ball in orbs:
		var icon := PreviewOrbIcon.new()
		icon.setup(ball)
		row.add_child(icon)
