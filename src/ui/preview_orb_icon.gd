extends Control
class_name PreviewOrbIcon

const BallState = preload("res://src/rules/ball_state.gd")

const SIZE := Vector2(34.0, 34.0)
const LABELS := {
	BallState.CombatKind.ATTACK: "ATK",
	BallState.CombatKind.SHIELD: "SHD",
	BallState.CombatKind.HEAL: "HEAL",
}

var state: BallState

func _ready() -> void:
	custom_minimum_size = SIZE

func setup(ball_state: BallState) -> void:
	state = ball_state
	custom_minimum_size = SIZE
	queue_redraw()

func _draw() -> void:
	if state == null:
		return
	var center := SIZE * 0.5
	var radius := 14.0
	var color := current_fill_color()
	draw_circle(center, radius, color)
	draw_arc(center, radius, 0.0, TAU, 36, color.lightened(0.24), 2.0)
	var label := display_label()
	if label.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := 9 if label.length() > 2 else 12
	var size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline := center + Vector2(-size.x * 0.5, size.y * 0.35)
	draw_string(font, baseline + Vector2(0.0, 1.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color.BLACK)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color.WHITE)

func display_label() -> String:
	if state == null:
		return ""
	if state.kind == BallState.Kind.COMBAT:
		return LABELS.get(state.combat_kind, "")
	if state.kind == BallState.Kind.HAZARD:
		return str(state.value)
	return ""

func current_fill_color() -> Color:
	if state == null:
		return Color.WHITE
	if state.kind == BallState.Kind.COLOR:
		return [Color.RED, Color.DODGER_BLUE, Color.GOLD, Color.LIME_GREEN][max(state.color_id, 0) % 4]
	if state.kind == BallState.Kind.COMBAT:
		return Color.MEDIUM_PURPLE
	if state.kind == BallState.Kind.HAZARD:
		return Color(1.0, 0.62, 0.2) if state.hazard_phase == BallState.HazardPhase.WARNING else Color(0.9, 0.18, 0.2)
	return Color.WHITE
