extends Node2D
class_name OrbNode

const BallState = preload("res://src/rules/ball_state.gd")

var state: BallState
var velocity: Vector2 = Vector2.ZERO

func setup(ball_state: BallState) -> void:
	state = ball_state
	position = state.position
	queue_redraw()

func _process(delta: float) -> void:
	if state == null:
		return
	if velocity == Vector2.ZERO:
		return
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 260.0 * delta)
	state.position = position
	if velocity.length() < 8.0:
		velocity = Vector2.ZERO
		state.settled = true

func _draw() -> void:
	if state == null:
		return
	var color := Color.WHITE
	if state.kind == BallState.Kind.COLOR:
		color = [Color.RED, Color.DODGER_BLUE, Color.GOLD, Color.LIME_GREEN][max(state.color_id, 0) % 4]
	elif state.kind == BallState.Kind.COMBAT:
		color = Color.MEDIUM_PURPLE
	elif state.kind == BallState.Kind.HAZARD:
		color = Color.ORANGE_RED
	draw_circle(Vector2.ZERO, state.radius, color)
