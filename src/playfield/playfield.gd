extends Node2D
class_name Playfield

const BallState = preload("res://src/rules/ball_state.gd")
const OrbNode = preload("res://src/playfield/orb_node.gd")
const VisualTheme = preload("res://src/config/visual_theme.gd")
const HazardTuning = preload("res://src/config/hazard_tuning.gd")
const DEFAULT_VISUAL_THEME: VisualTheme = preload("res://data/visual_theme_astral_batch1.tres")
const DEFAULT_HAZARD_TUNING: HazardTuning = preload("res://data/hazard_tuning_default.tres")

var balls: Array[BallState] = []
var orb_nodes_by_id: Dictionary = {}
@export var visual_theme: VisualTheme = DEFAULT_VISUAL_THEME
@export var hazard_tuning: HazardTuning = DEFAULT_HAZARD_TUNING
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

func clear_player_spawn_position(spawn_position: Vector2, radius: float, padding: float, max_steps: int = 8) -> Vector2:
	var outward := _safe_direction(spawn_position)
	var step_distance := radius * 2.0 + padding
	var candidate := spawn_position
	for step in range(maxi(max_steps, 1)):
		if _spawn_position_has_clearance(candidate, radius, padding):
			return candidate
		candidate = spawn_position + outward * step_distance * float(step + 1)
	return candidate

func accelerate_active_orbs(target_seconds: float) -> int:
	var accelerated_count := 0
	for ball in balls:
		if not ball.has_settle_target or ball.settled:
			continue
		var node := _get_orb_node(ball.id)
		if node == null:
			continue
		if node.accelerate_entry(target_seconds):
			accelerated_count += 1
	return accelerated_count

func rotate_settled(angle_delta: float) -> void:
	for ball in balls:
		if _rotates_with_disk(ball):
			var rotated_position := ball.position.rotated(angle_delta)
			ball.position = rotated_position
			var node := _get_orb_node(ball.id)
			if node != null:
				node.position = rotated_position
				node.rotation = node.visual_rotation_for_position(rotated_position) + ball.visual_rotation
	relax_settled_balls()
	release_unsupported_orbs()

func advance_hazard_phases(delta: float) -> void:
	if delta <= 0.0:
		return
	for ball in balls:
		if ball.kind != BallState.Kind.HAZARD:
			continue
		if not ball.is_on_board():
			continue
		ball.age_seconds += delta
		if ball.hazard_phase == BallState.HazardPhase.WARNING:
			if ball.age_seconds < _hazard_warning_seconds():
				continue
			ball.hazard_phase = BallState.HazardPhase.DANGER
			ball.value = _hazard_initial_value()
			ball.age_seconds = 0.0
			_redraw_orb(ball)
		elif ball.hazard_phase == BallState.HazardPhase.DANGER:
			_advance_danger_value(ball)

func check_boundary_explosions() -> Array[BallState]:
	var exploded: Array[BallState] = []
	for ball in balls:
		if ball.kind == BallState.Kind.HAZARD and ball.is_on_board() and ball.position.length() > danger_radius:
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
	node.visual_theme = visual_theme
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

func _spawn_position_has_clearance(candidate: Vector2, radius: float, padding: float) -> bool:
	for other in balls:
		if other.settled or other.board_attached:
			continue
		if not other.has_settle_target:
			continue
		var minimum_distance := radius + other.radius + padding
		if candidate.distance_to(other.position) < minimum_distance:
			return false
	return true

func resolve_incoming_motion(ball: BallState, proposed_position: Vector2) -> Dictionary:
	var incoming_direction := _incoming_direction(ball, proposed_position)
	var swept_contacts := _sweep_contacts(ball, proposed_position)
	if not swept_contacts.is_empty():
		return _resolve_contact_motion(ball, swept_contacts)
	var core_limit := _core_limit_for_ball(ball)
	if proposed_position.length() <= core_limit:
		ball.board_attached = true
		return {
			"position": incoming_direction * core_limit,
			"settled": true,
			"roll_delta": 0.0,
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
		"roll_delta": 0.0,
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
	return ball.is_on_board()

func _sync_orb_nodes_to_state() -> void:
	for ball in balls:
		var node := _get_orb_node(ball.id)
		if node != null:
			node.position = ball.position
			node.rotation = node.visual_rotation_for_position(ball.position) + ball.visual_rotation

func _core_limit_for_ball(ball: BallState) -> float:
	return core_collision_radius + ball.radius

func _resolve_contact_motion(ball: BallState, contacts: Array[Dictionary]) -> Dictionary:
	ball.board_attached = true
	var inward := -_safe_direction(ball.position)
	if _contacts_support_inward(inward, contacts):
		return {
			"position": _average_contact_position(contacts),
			"settled": true,
			"roll_delta": 0.0,
		}
	if _has_penetrating_contact(contacts):
		return {
			"position": _average_contact_position(contacts),
			"settled": false,
			"roll_delta": 0.0,
		}
	var primary: Dictionary = contacts[0]
	var blocker_direction: Vector2 = -Vector2(primary.normal)
	var support_strength := inward.dot(blocker_direction)
	var contact_position := _contact_position(primary)
	var slide_direction := inward - blocker_direction * support_strength
	if slide_direction.length() <= 0.001:
		slide_direction = _fallback_slide_direction(inward, blocker_direction)
	var slide_position := _limit_motion_step(ball.position, contact_position + slide_direction.normalized() * contact_slide_step)
	return {
		"position": slide_position,
		"settled": false,
		"roll_delta": _signed_roll_delta(ball, contact_position, slide_position),
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

func _signed_roll_delta(ball: BallState, from_position: Vector2, to_position: Vector2) -> float:
	if ball.radius <= 0.001:
		return 0.0
	var movement := to_position - from_position
	if movement.length() <= 0.001:
		return 0.0
	var radial := _safe_direction(from_position)
	var clockwise_tangent := Vector2(-radial.y, radial.x)
	var tangent_distance := movement.dot(clockwise_tangent)
	if absf(tangent_distance) <= 0.001:
		tangent_distance = movement.length()
	return tangent_distance / ball.radius

func _hazard_warning_seconds() -> float:
	if hazard_tuning != null:
		return hazard_tuning.warning_seconds_after_board_contact
	return hazard_warning_seconds

func _hazard_initial_value() -> int:
	if hazard_tuning != null:
		return hazard_tuning.danger_initial_value
	return 1

func _advance_danger_value(ball: BallState) -> void:
	if hazard_tuning == null:
		return
	if hazard_tuning.danger_growth_seconds <= 0.0:
		return
	var grew := false
	while ball.age_seconds >= hazard_tuning.danger_growth_seconds and ball.value < hazard_tuning.danger_max_value:
		ball.age_seconds -= hazard_tuning.danger_growth_seconds
		ball.value = min(ball.value + 1, hazard_tuning.danger_max_value)
		grew = true
	if ball.value >= hazard_tuning.danger_max_value:
		ball.age_seconds = min(ball.age_seconds, hazard_tuning.danger_growth_seconds)
	if grew:
		_redraw_orb(ball)

func _redraw_orb(ball: BallState) -> void:
	var node := _get_orb_node(ball.id)
	if node != null:
		node.queue_redraw()

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
	var astrolabe_texture := visual_theme.astrolabe_base() if visual_theme != null else null
	if astrolabe_texture != null:
		_draw_centered_texture(astrolabe_texture, visual_theme.board_art_radius)
	else:
		draw_circle(Vector2.ZERO, danger_radius, Color(0.9, 0.1, 0.1, 0.12))
	var boundary_texture := visual_theme.collapse_boundary() if visual_theme != null else null
	if boundary_texture != null:
		_draw_centered_texture(boundary_texture, danger_radius)
	else:
		draw_arc(Vector2.ZERO, danger_radius, 0.0, TAU, 128, Color(0.9, 0.2, 0.2), 3.0)
	draw_arc(Vector2.ZERO, danger_radius * 0.72, 0.0, TAU, 128, Color(0.2, 0.8, 1.0), 2.0)
	var core_texture := visual_theme.heartlight_core() if visual_theme != null else null
	if core_texture != null:
		_draw_centered_texture(core_texture, visual_theme.core_art_radius)
	else:
		draw_circle(Vector2.ZERO, core_radius, Color(0.02, 0.03, 0.07, 0.78))
	var shield_texture := visual_theme.shield_ring() if visual_theme != null else null
	if shield_texture != null:
		_draw_centered_texture(shield_texture, visual_theme.core_art_radius + 14.0)
	draw_arc(Vector2.ZERO, core_collision_radius, 0.0, TAU, 96, Color(0.95, 0.95, 1.0, 0.9), 4.0)
	draw_arc(Vector2.ZERO, core_collision_radius + 10.0, 0.0, TAU, 96, Color(0.5, 0.75, 1.0, 0.7), 2.0)
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var inner := Vector2(cos(angle), sin(angle)) * 42.0
		var outer := Vector2(cos(angle), sin(angle)) * (core_collision_radius - 8.0)
		draw_line(inner, outer, Color(0.7, 0.9, 1.0, 0.85), 2.0)

func _draw_centered_texture(texture: Texture2D, target_radius: float) -> void:
	var size := texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var target_size := Vector2(target_radius * 2.0, target_radius * 2.0)
	draw_texture_rect(texture, Rect2(-target_size * 0.5, target_size), false)
