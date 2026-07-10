extends Node2D
class_name Playfield

const BallState = preload("res://src/rules/ball_state.gd")
const OrbNode = preload("res://src/playfield/orb_node.gd")

var balls: Array[BallState] = []
var orb_nodes_by_id: Dictionary = {}
var danger_radius: float = 260.0
var core_radius: float = 58.0
var core_collision_radius: float = 80.0
var settled_center_pressure_speed: float = 48.0
var rotation_speed: float = 2.4
var hazard_warning_seconds: float = 1.25

func _ready() -> void:
	queue_redraw()
	for ball in balls:
		_assign_settle_target_if_needed(ball)
		_ensure_orb_node(ball)

func _process(delta: float) -> void:
	advance_orb_physics(delta)

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
		return {
			"position": other.position + push_direction * minimum_distance,
			"settled": true,
		}
	return {
		"position": proposed_position,
		"settled": false,
	}

func advance_orb_physics(delta: float) -> void:
	if delta <= 0.0:
		return
	var moved := false
	for ball in balls:
		if not ball.settled:
			continue
		var distance := ball.position.length()
		var core_limit := _core_limit_for_ball(ball)
		if distance <= core_limit + 0.001:
			continue
		var step := minf(settled_center_pressure_speed * delta, distance - core_limit)
		ball.position -= _safe_direction(ball.position) * step
		moved = true
	if moved:
		relax_settled_balls()

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
				if _separate_core_bound_pair(first, second, minimum_distance):
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

func _separate_core_bound_pair(first: BallState, second: BallState, minimum_distance: float) -> bool:
	var first_core_limit: float = _core_limit_for_ball(first)
	var second_core_limit: float = _core_limit_for_ball(second)
	var first_core_band: float = first_core_limit + first.radius
	var second_core_band: float = second_core_limit + second.radius
	if first.position.length() > first_core_band or second.position.length() > second_core_band:
		return false
	var first_direction: Vector2 = _safe_direction(first.position)
	var second_direction: Vector2 = _safe_direction(second.position)
	var average_direction: Vector2 = _safe_direction(first_direction + second_direction)
	var average_angle: float = average_direction.angle()
	var average_radius: float = (first_core_limit + second_core_limit) * 0.5
	var ratio: float = clampf(minimum_distance / maxf(average_radius * 2.0, 0.001), 0.0, 1.0)
	var separation_angle: float = asin(ratio) * 2.0 + 0.03
	first.position = Vector2(cos(average_angle - separation_angle * 0.5), sin(average_angle - separation_angle * 0.5)) * first_core_limit
	second.position = Vector2(cos(average_angle + separation_angle * 0.5), sin(average_angle + separation_angle * 0.5)) * second_core_limit
	return true

func _core_limit_for_ball(ball: BallState) -> float:
	return core_collision_radius + ball.radius

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
