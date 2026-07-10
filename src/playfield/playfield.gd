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
var two_point_support_dot: float = 0.72
var contact_slide_step: float = 0.55
var max_contact_motion_step: float = 3.0
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
		if _rotates_with_disk(ball):
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
	var swept_contacts := _sweep_contacts(ball, proposed_position)
	if not swept_contacts.is_empty():
		return _resolve_contact_motion(ball, swept_contacts)
	var core_limit := _core_limit_for_ball(ball)
	if proposed_position.length() <= core_limit:
		return {
			"position": incoming_direction * core_limit,
			"settled": true,
		}
	var contacts: Array[Dictionary] = []
	for other in balls:
		if other == ball:
			continue
		var minimum_distance := ball.radius + other.radius
		var offset := proposed_position - other.position
		if offset.length() >= minimum_distance:
			continue
		var push_direction := offset.normalized()
		if push_direction == Vector2.ZERO:
			push_direction = -incoming_direction
		contacts.append({
			"other": other,
			"normal": push_direction,
			"minimum_distance": minimum_distance,
		})
	if not contacts.is_empty():
		return _resolve_contact_motion(ball, contacts)
	return {
		"position": proposed_position,
		"settled": false,
	}

func _sweep_contacts(ball: BallState, proposed_position: Vector2) -> Array[Dictionary]:
	var start_position := ball.position
	var travel := proposed_position - start_position
	var earliest_t := INF
	var contacts: Array[Dictionary] = []
	for other in balls:
		if other == ball:
			continue
		var minimum_distance := ball.radius + other.radius
		var start_offset := start_position - other.position
		var start_distance := start_offset.length()
		if start_distance < minimum_distance:
			var normal := _safe_direction(start_offset)
			contacts.append({
				"other": other,
				"normal": normal,
				"minimum_distance": minimum_distance,
				"penetrating": true,
			})
			earliest_t = 0.0
			continue
		if travel.length_squared() <= 0.000001:
			continue
		var a := travel.length_squared()
		var b := 2.0 * start_offset.dot(travel)
		var c := start_offset.length_squared() - minimum_distance * minimum_distance
		var discriminant := b * b - 4.0 * a * c
		if discriminant < 0.0:
			continue
		var t := (-b - sqrt(discriminant)) / (2.0 * a)
		if t < 0.0 or t > 1.0:
			continue
		if t > earliest_t + 0.001:
			continue
		var contact_position := start_position + travel * t
		var contact := {
			"other": other,
			"normal": _safe_direction(contact_position - other.position),
			"minimum_distance": minimum_distance,
			"penetrating": false,
		}
		if t < earliest_t - 0.001:
			earliest_t = t
			contacts.clear()
		contacts.append(contact)
	if earliest_t > 0.0:
		var earliest_contacts: Array[Dictionary] = []
		for contact in contacts:
			if not bool(contact.get("penetrating", false)):
				earliest_contacts.append(contact)
		return earliest_contacts
	return contacts

func advance_orb_physics(delta: float) -> void:
	if delta <= 0.0:
		return
	release_unsupported_orbs()

func release_unsupported_orbs() -> void:
	var settled_snapshot := {}
	for ball in balls:
		if ball.settled:
			settled_snapshot[ball.id] = true
	var to_release: Array[BallState] = []
	for ball in balls:
		if not ball.settled:
			continue
		if not _has_inward_support(ball, settled_snapshot):
			to_release.append(ball)
	for ball in to_release:
		ball.settled = false
		ball.has_settle_target = true
		ball.settle_target = Vector2.ZERO

func relax_settled_balls() -> void:
	for ball in balls:
		if not ball.settled:
			continue
		var core_limit: float = _core_limit_for_ball(ball)
		if ball.position.length() < core_limit:
			ball.position = _safe_direction(ball.position) * core_limit
	_sync_orb_nodes_to_state()

func _rotates_with_disk(ball: BallState) -> bool:
	return ball.position.length() <= danger_radius + ball.radius

func _sync_orb_nodes_to_state() -> void:
	for ball in balls:
		var node := _get_orb_node(ball.id)
		if node != null:
			node.position = ball.position

func _core_limit_for_ball(ball: BallState) -> float:
	return core_collision_radius + ball.radius

func _resolve_contact_motion(ball: BallState, contacts: Array[Dictionary]) -> Dictionary:
	var inward := -_safe_direction(ball.position)
	if _contacts_support_inward(inward, contacts):
		return {
			"position": _average_contact_position(contacts),
			"settled": true,
		}
	if _has_penetrating_contact(contacts):
		return {
			"position": _average_contact_position(contacts),
			"settled": false,
		}
	var primary: Dictionary = contacts[0]
	var blocker_direction: Vector2 = -Vector2(primary.normal)
	var support_strength := inward.dot(blocker_direction)
	var contact_position := _contact_position(primary)
	var slide_direction := inward - blocker_direction * support_strength
	if slide_direction.length() <= 0.001:
		slide_direction = _fallback_slide_direction(inward, blocker_direction)
	return {
		"position": _limit_motion_step(ball.position, contact_position + slide_direction.normalized() * contact_slide_step),
		"settled": false,
	}

func _has_penetrating_contact(contacts: Array[Dictionary]) -> bool:
	for contact in contacts:
		if bool(contact.get("penetrating", false)):
			return true
	return false

func _contacts_support_inward(inward: Vector2, contacts: Array[Dictionary]) -> bool:
	if contacts.size() < 2:
		return false
	var tangent := Vector2(-inward.y, inward.x)
	var has_left_support := false
	var has_right_support := false
	for contact in contacts:
		var blocker_direction := -Vector2(contact.normal)
		if inward.dot(blocker_direction) < two_point_support_dot:
			continue
		if tangent.dot(blocker_direction) < 0.0:
			has_left_support = true
		else:
			has_right_support = true
	return has_left_support and has_right_support

func _average_contact_position(contacts: Array[Dictionary]) -> Vector2:
	var position_sum := Vector2.ZERO
	for contact in contacts:
		position_sum += _contact_position(contact)
	return position_sum / float(contacts.size())

func _contact_position(contact: Dictionary) -> Vector2:
	var other := contact.other as BallState
	return other.position + Vector2(contact.normal) * float(contact.minimum_distance)

func _fallback_slide_direction(inward: Vector2, blocker_direction: Vector2) -> Vector2:
	var tangent := Vector2(-inward.y, inward.x)
	if tangent.dot(blocker_direction) < 0.0:
		return -tangent
	return tangent

func _has_inward_support(ball: BallState, settled_snapshot: Dictionary = {}) -> bool:
	var core_limit := _core_limit_for_ball(ball)
	if ball.position.length() <= core_limit + support_slop:
		return true
	var inward := -_safe_direction(ball.position)
	var tangent := Vector2(-inward.y, inward.x)
	var has_left_support := false
	var has_right_support := false
	for other in balls:
		if other == ball:
			continue
		if not settled_snapshot.is_empty() and not settled_snapshot.has(other.id):
			continue
		if settled_snapshot.is_empty() and not other.settled:
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
		if inward.dot(blocker_direction) >= two_point_support_dot:
			if tangent.dot(blocker_direction) < 0.0:
				has_left_support = true
			else:
				has_right_support = true
	if has_left_support and has_right_support:
		return true
	return false

func _limit_motion_step(from_position: Vector2, to_position: Vector2) -> Vector2:
	var delta := to_position - from_position
	if delta.length() <= max_contact_motion_step:
		return to_position
	return from_position + delta.normalized() * max_contact_motion_step

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
