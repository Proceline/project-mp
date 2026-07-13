extends Node2D
class_name OrbNode

const BallState = preload("res://src/rules/ball_state.gd")
const VisualTheme = preload("res://src/config/visual_theme.gd")
const DEFAULT_VISUAL_THEME: VisualTheme = preload("res://data/visual_theme_astral_batch1.tres")

var state: BallState
var visual_theme: VisualTheme = DEFAULT_VISUAL_THEME
var velocity: Vector2 = Vector2.ZERO
var attraction_speed: float = 120.0
const LABELS := {
	BallState.CombatKind.ATTACK: "ATK",
	BallState.CombatKind.SHIELD: "SHD",
	BallState.CombatKind.HEAL: "HEAL",
}

func setup(ball_state: BallState) -> void:
	state = ball_state
	position = state.position
	_update_visual_rotation()
	_apply_entry_duration()
	queue_redraw()

func _process(delta: float) -> void:
	if state == null:
		return
	if state.flashing:
		queue_redraw()
	if state.has_settle_target and not state.settled:
		_move_toward_settle_target(delta)
		return
	if velocity == Vector2.ZERO:
		return
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 260.0 * delta)
	state.position = position
	_update_visual_rotation()
	if velocity.length() < 8.0:
		velocity = Vector2.ZERO
		state.settled = true

func accelerate_entry(target_seconds: float) -> bool:
	if state == null or state.settled or not state.has_settle_target:
		return false
	if target_seconds <= 0.0:
		return false
	var travel_distance := position.distance_to(state.settle_target)
	if travel_distance <= 0.001:
		return false
	attraction_speed = maxf(attraction_speed, travel_distance / target_seconds)
	return true

func _move_toward_settle_target(delta: float) -> void:
	var to_target := state.settle_target - position
	var distance := to_target.length()
	if distance <= 2.0:
		position = state.settle_target
		state.position = position
		velocity = Vector2.ZERO
		state.settled = true
		return
	var step := minf(attraction_speed * delta, distance)
	var proposed_position := position + to_target.normalized() * step
	var parent_playfield := get_parent()
	if parent_playfield != null and parent_playfield.has_method("resolve_incoming_motion"):
		var resolved: Dictionary = parent_playfield.resolve_incoming_motion(state, proposed_position)
		position = resolved.position
		state.position = position
		_apply_contact_roll(float(resolved.get("roll_delta", 0.0)))
		_update_visual_rotation()
		state.settled = bool(resolved.settled)
		if state.settled:
			velocity = Vector2.ZERO
		return
	position = proposed_position
	state.position = position
	_update_visual_rotation()

func _apply_entry_duration() -> void:
	if state == null or state.entry_duration_seconds <= 0.0:
		return
	var travel_distance := state.position.distance_to(state.settle_target)
	if travel_distance <= 0.001:
		return
	attraction_speed = travel_distance / state.entry_duration_seconds

func _draw() -> void:
	if state == null:
		return
	var color := current_fill_color()
	var glow_texture := current_glow_texture()
	if glow_texture != null:
		_draw_centered_texture(glow_texture, state.radius * visual_theme.orb_glow_radius_scale, Color(1, 1, 1, visual_theme.orb_glow_alpha))
	var texture := current_texture()
	if texture != null:
		_draw_centered_texture(texture, state.radius)
		if state.flashing:
			draw_arc(Vector2.ZERO, state.radius + 2.0, 0.0, TAU, 48, color.lightened(0.4), 2.0)
	else:
		draw_circle(Vector2.ZERO, state.radius, color)
		draw_arc(Vector2.ZERO, state.radius, 0.0, TAU, 48, color.lightened(0.25), 2.0)

	var font := ThemeDB.fallback_font
	var value_text := display_label()
	var font_size := 14 if value_text.length() <= 2 else 12
	if state.kind == BallState.Kind.COMBAT:
		font_size = 12
	if state.kind == BallState.Kind.HAZARD:
		font_size = 16
	if value_text != "":
		_draw_centered_text(font, value_text, Vector2(0.0, 5.0), font_size, Color.BLACK)
		_draw_centered_text(font, value_text, Vector2(0.0, 4.0), font_size, Color.WHITE)
	if state.kind == BallState.Kind.COMBAT and state.value > 0:
		_draw_centered_text(font, str(state.value), Vector2(0.0, state.radius - 3.0), 11, Color.BLACK)
		_draw_centered_text(font, str(state.value), Vector2(0.0, state.radius - 4.0), 11, Color(1.0, 0.94, 0.65))

func display_label() -> String:
	if state == null:
		return ""
	if state.kind == BallState.Kind.COMBAT:
		return LABELS.get(state.combat_kind, "")
	if state.kind == BallState.Kind.HAZARD:
		if state.hazard_phase == BallState.HazardPhase.WARNING:
			return ""
		return str(state.value)
	return ""

func _update_visual_rotation() -> void:
	if state == null:
		return
	rotation = visual_rotation_for_position(state.position) + state.visual_rotation

func visual_rotation_for_position(world_position: Vector2) -> float:
	if world_position.length() <= 0.001:
		return state.visual_rotation if state != null else 0.0
	var inward := -world_position.normalized()
	return inward.angle() - Vector2.DOWN.angle()

func _apply_contact_roll(roll_delta: float) -> void:
	if state == null:
		return
	if absf(roll_delta) <= 0.001:
		return
	state.visual_rotation += roll_delta

func current_fill_color() -> Color:
	if state == null:
		return Color.WHITE
	if state.kind == BallState.Kind.COLOR:
		var color: Color = [Color.RED, Color.DODGER_BLUE, Color.GOLD, Color.LIME_GREEN][max(state.color_id, 0) % 4]
		if state.flashing:
			var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 90.0)
			return color.lerp(Color.WHITE, pulse * 0.35)
		return color
	if state.kind == BallState.Kind.COMBAT:
		return Color.MEDIUM_PURPLE
	if state.kind == BallState.Kind.HAZARD:
		return Color(1.0, 0.62, 0.2) if state.hazard_phase == BallState.HazardPhase.WARNING else Color(0.9, 0.18, 0.2)
	return Color.WHITE

func current_texture() -> Texture2D:
	if visual_theme == null or state == null:
		return null
	return visual_theme.get_orb_texture(state)

func current_glow_texture() -> Texture2D:
	if visual_theme == null or state == null:
		return null
	return visual_theme.get_orb_glow_texture(state)

func _draw_centered_texture(texture: Texture2D, target_radius: float, modulate: Color = Color.WHITE) -> void:
	var size := texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var target_size := Vector2(target_radius * 2.0, target_radius * 2.0)
	var rect := Rect2(-target_size * 0.5, target_size)
	draw_texture_rect(texture, rect, false, modulate)

func _draw_centered_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	if font == null or text.is_empty():
		return
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(font, baseline - Vector2(size.x * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
