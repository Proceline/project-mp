extends Node2D
class_name OrbNode

const BallState = preload("res://src/rules/ball_state.gd")

var state: BallState
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
	if velocity.length() < 8.0:
		velocity = Vector2.ZERO
		state.settled = true

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
		state.settled = bool(resolved.settled)
		if state.settled:
			velocity = Vector2.ZERO
			if parent_playfield.has_method("relax_settled_balls"):
				parent_playfield.relax_settled_balls()
		return
	position = proposed_position
	state.position = position

func _draw() -> void:
	if state == null:
		return
	var color := current_fill_color()
	draw_circle(Vector2.ZERO, state.radius, color)
	draw_arc(Vector2.ZERO, state.radius, 0.0, TAU, 48, color.lightened(0.25), 2.0)

	var font := ThemeDB.fallback_font
	var font_size := 14
	var value_text := str(state.value)
	if state.kind == BallState.Kind.COMBAT:
		font_size = 12
		value_text = LABELS.get(state.combat_kind, "")
	elif state.kind == BallState.Kind.HAZARD:
		font_size = 16
	if value_text != "":
		_draw_centered_text(font, value_text, Vector2(0.0, 5.0), font_size, Color.BLACK)
		_draw_centered_text(font, value_text, Vector2(0.0, 4.0), font_size, Color.WHITE)
	if state.kind == BallState.Kind.COMBAT and state.value > 0:
		_draw_centered_text(font, str(state.value), Vector2(0.0, state.radius - 3.0), 11, Color.BLACK)
		_draw_centered_text(font, str(state.value), Vector2(0.0, state.radius - 4.0), 11, Color(1.0, 0.94, 0.65))

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

func _draw_centered_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	if font == null or text.is_empty():
		return
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	draw_string(font, baseline - Vector2(size.x * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
