extends Node2D
class_name Playfield

const BallState = preload("res://src/rules/ball_state.gd")
const OrbNode = preload("res://src/playfield/orb_node.gd")

var balls: Array[BallState] = []
var orb_nodes_by_id: Dictionary = {}
var danger_radius: float = 260.0
var rotation_speed: float = 2.4
var hazard_warning_seconds: float = 1.25
var _next_settle_slot: int = 0

func _ready() -> void:
	queue_redraw()
	for ball in balls:
		_assign_settle_target_if_needed(ball)
		_ensure_orb_node(ball)

func add_ball(ball: BallState) -> void:
	_assign_settle_target_if_needed(ball)
	balls.append(ball)
	_ensure_orb_node(ball)

func rotate_settled(angle_delta: float) -> void:
	for ball in balls:
		if ball.settled:
			var rotated_position := ball.position.rotated(angle_delta)
			ball.position = rotated_position
			var node := _get_orb_node(ball.id)
			if node != null:
				node.position = rotated_position

func advance_hazard_phases(delta: float) -> void:
	if delta <= 0.0:
		return
	for ball in balls:
		if ball.kind != BallState.Kind.HAZARD or ball.hazard_phase == BallState.HazardPhase.DANGER:
			continue
		ball.age_seconds += delta
		if ball.age_seconds < hazard_warning_seconds:
			continue
		ball.hazard_phase = BallState.HazardPhase.DANGER
		var node := _get_orb_node(ball.id)
		if node != null:
			node.queue_redraw()

func check_boundary_explosions() -> Array[BallState]:
	var exploded: Array[BallState] = []
	for ball in balls:
		if ball.kind == BallState.Kind.HAZARD and ball.position.length() > danger_radius:
			exploded.append(ball)
	for ball in exploded:
		balls.erase(ball)
		_remove_orb_node(ball.id)
	return exploded

func _ensure_orb_node(ball: BallState) -> void:
	if _get_orb_node(ball.id) != null:
		return
	var node := OrbNode.new()
	node.setup(ball)
	orb_nodes_by_id[ball.id] = node
	add_child(node)

func _get_orb_node(ball_id: int) -> OrbNode:
	var node := orb_nodes_by_id.get(ball_id) as OrbNode
	if node != null and is_instance_valid(node):
		return node
	orb_nodes_by_id.erase(ball_id)
	for child in get_children():
		var orb := child as OrbNode
		if orb != null and orb.state != null and orb.state.id == ball_id:
			orb_nodes_by_id[ball_id] = orb
			return orb
	return null

func _remove_orb_node(ball_id: int) -> void:
	var node := _get_orb_node(ball_id)
	orb_nodes_by_id.erase(ball_id)
	if node == null:
		return
	if node.get_parent() == self:
		remove_child(node)
	node.queue_free()

func _assign_settle_target_if_needed(ball: BallState) -> void:
	if ball.settled or ball.has_settle_target:
		return
	var slot := _next_settle_slot
	_next_settle_slot += 1
	var layer := slot / 10
	var index_in_layer := slot % 10
	var radius := minf(88.0 + float(layer) * ball.radius * 1.85, danger_radius - ball.radius * 1.35)
	var angle_offset := -0.35 if ball.kind != BallState.Kind.HAZARD else -0.8
	var angle := angle_offset + TAU * float(index_in_layer) / 10.0 + float(layer) * 0.31
	ball.settle_target = Vector2(cos(angle), sin(angle)) * radius
	ball.has_settle_target = true
	ball.settled = false

func _draw() -> void:
	draw_circle(Vector2.ZERO, danger_radius, Color(0.9, 0.1, 0.1, 0.12))
	draw_arc(Vector2.ZERO, danger_radius, 0.0, TAU, 128, Color(0.9, 0.2, 0.2), 3.0)
	draw_arc(Vector2.ZERO, danger_radius * 0.72, 0.0, TAU, 128, Color(0.2, 0.8, 1.0), 2.0)
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var inner := Vector2(cos(angle), sin(angle)) * 42.0
		var outer := Vector2(cos(angle), sin(angle)) * 68.0
		draw_line(inner, outer, Color(0.7, 0.9, 1.0, 0.85), 2.0)
