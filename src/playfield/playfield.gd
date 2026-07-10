extends Node2D
class_name Playfield

const BallState = preload("res://src/rules/ball_state.gd")
const OrbNode = preload("res://src/playfield/orb_node.gd")

var balls: Array[BallState] = []
var danger_radius: float = 260.0
var rotation_speed: float = 2.4

func add_ball(ball: BallState) -> void:
	balls.append(ball)
	if is_inside_tree():
		var node := OrbNode.new()
		node.setup(ball)
		add_child(node)

func rotate_settled(angle_delta: float) -> void:
	for ball in balls:
		if ball.settled:
			ball.position = ball.position.rotated(angle_delta)

func check_boundary_explosions() -> Array[BallState]:
	var exploded: Array[BallState] = []
	for ball in balls:
		if ball.kind == BallState.Kind.HAZARD and ball.position.length() > danger_radius:
			exploded.append(ball)
	for ball in exploded:
		balls.erase(ball)
	return exploded
