extends Control
class_name PreviewOrbIcon

const DEFAULT_VISUAL_THEME: VisualTheme = preload("res://data/visual_theme_astral_batch1.tres")

const SIZE := Vector2(34.0, 34.0)

var state: BallState
var visual_theme: VisualTheme = DEFAULT_VISUAL_THEME

func _ready() -> void:
	custom_minimum_size = _icon_size()

func setup(ball_state: BallState) -> void:
	state = ball_state
	custom_minimum_size = _icon_size()
	queue_redraw()

func _draw() -> void:
	if state == null:
		return
	var icon_size := _icon_size()
	var center := icon_size * 0.5
	var radius := 14.0
	var color := current_fill_color()
	var texture := current_texture()
	if texture != null:
		draw_texture_rect(texture, Rect2(Vector2.ZERO, icon_size), false)
	else:
		draw_circle(center, radius, color)
		draw_arc(center, radius, 0.0, TAU, 36, color.lightened(0.24), 2.0)
	var label := display_label()
	if label.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := 9 if label.length() > 2 else 12
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var baseline := center + Vector2(-text_size.x * 0.5, text_size.y * 0.35)
	draw_string(font, baseline + Vector2(0.0, 1.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color.BLACK)
	draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color.WHITE)

func display_label() -> String:
	if state == null:
		return ""
	if state.kind == BallState.Kind.HAZARD:
		if state.hazard_phase == BallState.HazardPhase.WARNING:
			return ""
		return str(state.value)
	return ""

func current_fill_color() -> Color:
	if state == null:
		return Color.WHITE
	if state.kind == BallState.Kind.COLOR:
		return [Color.RED, Color.DODGER_BLUE, Color.GOLD, Color.LIME_GREEN][max(state.color_id, 0) % 4]
	if state.kind == BallState.Kind.HAZARD:
		return Color(1.0, 0.62, 0.2) if state.hazard_phase == BallState.HazardPhase.WARNING else Color(0.9, 0.18, 0.2)
	return Color.WHITE

func current_texture() -> Texture2D:
	if visual_theme == null or state == null:
		return null
	return visual_theme.get_orb_texture(state)

func _icon_size() -> Vector2:
	if visual_theme != null:
		return visual_theme.preview_icon_size
	return SIZE
