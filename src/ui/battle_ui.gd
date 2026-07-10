extends CanvasLayer
class_name BattleUI

const BallState = preload("res://src/rules/ball_state.gd")
const BattleState = preload("res://src/rules/battle_state.gd")

@onready var player_hp_label: Label = %PlayerHP
@onready var shield_marks_label: Label = %ShieldMarks
@onready var boss_hp_label: Label = %BossHP
@onready var boss_action_bar: ProgressBar = %BossActionBar
@onready var preview_label: Label = %Preview
@onready var status_label: Label = %Status

func update_from_state(battle: BattleState, boss_action_ratio: float, preview: Array[BallState]) -> void:
	player_hp_label.text = str(battle.player_hp)
	shield_marks_label.text = _shield_marks_text(battle.player_shield)
	shield_marks_label.visible = battle.player_shield > 0
	boss_hp_label.text = "Boss HP %d/%d" % [battle.boss_hp, battle.boss_max_hp]
	boss_action_bar.value = clampf(boss_action_ratio * 100.0, 0.0, 100.0)
	preview_label.text = _preview_text(preview)
	status_label.text = battle.result()

func _preview_text(preview: Array[BallState]) -> String:
	var parts: Array[String] = []
	for ball in preview:
		if ball.kind == BallState.Kind.COLOR:
			parts.append("C%d" % ball.color_id)
		elif ball.kind == BallState.Kind.COMBAT:
			parts.append(["", "ATK", "SHD", "HEAL"][ball.combat_kind])
	return "Next: " + " ".join(parts)

func _shield_marks_text(shield: int) -> String:
	if shield <= 0:
		return ""
	return "|".repeat(min(shield, 12))
