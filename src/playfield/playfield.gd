extends Node2D
class_name Playfield

const BallState = preload("res://src/rules/ball_state.gd")
const OrbNode = preload("res://src/playfield/orb_node.gd")

var balls: Array[BallState] = []
var orb_nodes_by_id: Dictionary = {}
var danger_radius: float = 260.0
var core_radius: float = 58.0
var core_collision_radius: float = 80.0
var support_slop: float = 1.5
var stable_support_dot: float = 0.94
var rotation_speed: float = 2.4
var hazard_warning_seconds: float = 1.25

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
	relax_settled_balls()
	release_unsupported_orbs()

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
	if not exploded.is_empty():
		release_unsupported_orbs()
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
	ball.settle_target = Vector2.ZERO
	ball.has_settle_target = true
	ball.settled = false

func resolve_incoming_motion(ball: BallState, proposed_position: Vector2) -> Dictionary:
	var incoming_direction := _incoming_direction(ball, proposed_position)
	var core_limit := _core_limit_for_ball(ball)
	if proposed_position.length() <= core_limit:
		return {
			"position": incoming_direction * core_limit,
			"settled": true,
		}
	for other in balls:
		if other == ball or not other.settled:
			continue
		var minimum_distance := ball.radius + other.radius
		var offset := proposed_position - other.position
		if offset.length() >= minimum_distance:
			continue
		var push_direction := offset.normalized()
		if push_direction == Vector2.ZERO:
			push_direction = -incoming_direction
		return _resolve_contact_motion(ball, other, push_direction, minimum_distance)
	return {
		"position": proposed_position,
		"settled": false,
	}

func advance_orb_physics(delta: float) -> void:
	if delta <= 0.0:
		return
	release_unsupported_orbs()

func release_unsupported_orbs() -> void:
	for ball in balls:
		if not ball.settled:
			continue
		if _has_inward_support(ball):
			continue
		ball.settled = false
		ball.has_settle_target = true
		ball.settle_target = Vector2.ZERO

func relax_settled_balls() -> void:
	var core_limit_by_id := {}
	for iteration in range(6):
		for ball in balls:
			if not ball.settled:
				continue
			var core_limit: float = float(core_limit_by_id.get(ball.id, _core_limit_for_ball(ball)))
			core_limit_by_id[ball.id] = core_limit
			if ball.position.length() < core_limit:
				ball.position = _safe_direction(ball.position) * core_limit
		for i in range(balls.size()):
			var first := balls[i]
			if not first.settled:
				continue
			for j in range(i + 1, balls.size()):
				var second := balls[j]
				if not second.settled:
					continue
				var minimum_distance := first.radius + second.radius
				var offset := second.position - first.position
				var distance := offset.length()
				if distance >= minimum_distance:
					continue
				var direction := _safe_direction(offset)
				var correction := (minimum_distance - distance) * 0.5
				first.position -= direction * correction
				second.position += direction * correction
	for ball in balls:
		if not ball.settled:
			continue
		var core_limit: float = _core_limit_for_ball(ball)
		if ball.position.length() < core_limit:
			ball.position = _safe_direction(ball.position) * core_limit
	_sync_orb_nodes_to_state()

func _sync_orb_nodes_to_state() -> void:
	for ball in balls:
		var node := _get_orb_node(ball.id)
		if node != null:
			node.position = ball.position

func _core_limit_for_ball(ball: BallState) -> float:
	return core_collision_radius + ball.radius

func _resolve_contact_motion(ball: BallState, other: BallState, contact_normal: Vector2, minimum_distance: float) -> Dictionary:
	var inward := -_safe_direction(ball.position)
	var blocker_direction := -contact_normal
	var support_strength := inward.dot(blocker_direction)
	var contact_position := other.position + contact_normal * minimum_distance
	if support_strength >= stable_support_dot:
		return {
			"position": contact_position,
			"settled": true,
		}
	var slide_direction := inward - blocker_direction * support_strength
	if slide_direction.length() <= 0.001:
		return {
			"position": contact_position,
			"settled": true,
		}
	return {
		"position": contact_position + slide_direction.normalized() * 2.0,
		"settled": false,
	}

func _has_inward_support(ball: BallState) -> bool:
	var core_limit := _core_limit_for_ball(ball)
	if ball.position.length() <= core_limit + support_slop:
		return true
	var inward := -_safe_direction(ball.position)
	for other in balls:
		if other == ball or not other.settled:
			continue
		if other.position.length() >= ball.position.length():
			continue
		var offset := other.position - ball.position
		var distance := offset.length()
		if distance > ball.radius + other.radius + support_slop:
			continue
		var blocker_direction := _safe_direction(offset)
		if inward.dot(blocker_direction) >= stable_support_dot:
			return true
	return false

func _safe_direction(vector: Vector2) -> Vector2:
	if vector.length() <= 0.001:
		return Vector2.RIGHT
	return vector.normalized()

func _incoming_direction(ball: BallState, fallback_position: Vector2) -> Vector2:
	var source := ball.position if ball.position.length() > 0.001 else fallback_position
	if source.length() <= 0.001:
		return Vector2.RIGHT
	return source.normalized()

func _draw() -> void:
	draw_circle(Vector2.ZERO, danger_radius, Color(0.9, 0.1, 0.1, 0.12))
	draw_arc(Vector2.ZERO, danger_radius, 0.0, TAU, 128, Color(0.9, 0.2, 0.2), 3.0)
	draw_arc(Vector2.ZERO, danger_radius * 0.72, 0.0, TAU, 128, Color(0.2, 0.8, 1.0), 2.0)
	draw_circle(Vector2.ZERO, core_radius, Color(0.02, 0.03, 0.07, 0.78))
	draw_arc(Vector2.ZERO, core_collision_radius, 0.0, TAU, 96, Color(0.95, 0.95, 1.0, 0.9), 4.0)
	draw_arc(Vector2.ZERO, core_collision_radius + 10.0, 0.0, TAU, 96, Color(0.5, 0.75, 1.0, 0.7), 2.0)
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var inner := Vector2(cos(angle), sin(angle)) * 42.0
		var outer := Vector2(cos(angle), sin(angle)) * (core_collision_radius - 8.0)
		draw_line(inner, outer, Color(0.7, 0.9, 1.0, 0.85), 2.0)
