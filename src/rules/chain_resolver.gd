extends RefCounted
class_name ChainResolver

var neighbor_distance: float = 52.0
var influence_distance: float = 72.0
var minimum_chain_size: int = 5

const COLOR_RED := 0
const COLOR_BLUE := 1
const COLOR_YELLOW := 2
const COLOR_GREEN := 3

const RED_DAMAGE_PER_ORB := 2
const DEFAULT_DAMAGE_PER_ORB := 1
const YELLOW_DAMAGE_PER_ORB := 0
const YELLOW_VULNERABILITY_PER_ORB := 1
const BLUE_HAZARD_MITIGATION_PER_ORB := 1
const GREEN_HEAL_DIVISOR := 2

func find_color_groups(balls: Array[BallState]) -> Array:
	var color_balls: Array[BallState] = []
	for ball in balls:
		if ball.kind == BallState.Kind.COLOR and ball.is_on_board() and not ball.flashing:
			color_balls.append(ball)

	var visited: Dictionary = {}
	var groups: Array = []
	for ball in color_balls:
		if visited.has(ball.id):
			continue

		var group: Array[BallState] = []
		var stack: Array[BallState] = [ball]
		visited[ball.id] = true

		while not stack.is_empty():
			var current: BallState = stack.pop_back()
			group.append(current)

			for other in color_balls:
				if visited.has(other.id):
					continue
				if other.color_id == current.color_id and current.position.distance_to(other.position) <= neighbor_distance:
					visited[other.id] = true
					stack.append(other)

		groups.append(group)

	return groups

func start_flash_groups(balls: Array[BallState]) -> Array:
	var chains: Array = []
	for group in find_color_groups(balls):
		if group.size() < minimum_chain_size:
			continue

		for member in group:
			member.flashing = true

		chains.append({
			"color_id": group[0].color_id,
			"members": group,
			"strength": group.size(),
		})

	return chains

func refresh_flashing_chains(chains: Array, balls: Array[BallState]) -> int:
	var added_count := 0
	for chain in chains:
		var members: Array = chain.get("members", [])
		var color_id := int(chain.get("color_id", -1))
		var expanded := true
		while expanded:
			expanded = false
			for ball in balls:
				if not _can_join_flashing_chain(ball, color_id, members):
					continue
				members.append(ball)
				ball.flashing = true
				added_count += 1
				expanded = true
		chain["members"] = members
		chain["strength"] = members.size()
	return added_count

func apply_chain_influence(_chains: Array, _balls: Array[BallState]) -> void:
	pass

func apply_chain_influence_growth(chains: Array, _balls: Array[BallState]) -> void:
	var deltas: Array[int] = []
	for chain in chains:
		var strength := int(chain.get("strength", 0))
		var applied_strength := int(chain.get("applied_strength", 0))
		deltas.append(max(strength - applied_strength, 0))

	for i in range(chains.size()):
		chains[i]["applied_strength"] = int(chains[i].get("applied_strength", 0)) + deltas[i]

func resolve_finished_chains(chains: Array, balls: Array[BallState]) -> Dictionary:
	var result := {
		"attack": 0,
		"shield": 0,
		"heal": 0,
		"hazard_mitigation": 0,
		"yellow_vulnerability": 0,
		"player_damage": 0,
		"cleared_color_ids": [],
		"removed_ball_ids": [],
		"hazard_removed_in_warning": [],
		"hazard_removed_in_danger": [],
	}
	for chain in chains:
		var strength := int(chain.get("strength", 0))
		var color_id := int(chain.get("color_id", -1))
		var chain_attack := _attack_for_color(color_id, strength)
		result.attack += chain_attack
		if color_id == COLOR_GREEN:
			result.heal += chain_attack / GREEN_HEAL_DIVISOR
		elif color_id == COLOR_BLUE:
			result.hazard_mitigation += strength * BLUE_HAZARD_MITIGATION_PER_ORB
		elif color_id == COLOR_YELLOW:
			result.yellow_vulnerability += strength * YELLOW_VULNERABILITY_PER_ORB
		for member in chain.members:
			result.cleared_color_ids.append(member.id)
	for ball in balls:
		if ball.kind != BallState.Kind.HAZARD:
			continue
		if not ball.is_on_board():
			continue
		if not _is_touched_by_any_chain(chains, ball):
			continue
		result.removed_ball_ids.append(ball.id)
		if ball.hazard_phase == BallState.HazardPhase.DANGER:
			result.hazard_removed_in_danger.append(ball.id)
			result.player_damage += max(ball.value, 1)
		else:
			result.hazard_removed_in_warning.append(ball.id)
	return result

func _attack_for_color(color_id: int, strength: int) -> int:
	if color_id == COLOR_RED:
		return strength * RED_DAMAGE_PER_ORB
	if color_id == COLOR_YELLOW:
		return strength * YELLOW_DAMAGE_PER_ORB
	return strength * DEFAULT_DAMAGE_PER_ORB

func _is_touched_by_any_chain(chains: Array, target: BallState) -> bool:
	for chain in chains:
		if _chain_touches_ball(chain, target):
			return true
	return false

func _chain_touches_ball(chain: Dictionary, target: BallState) -> bool:
	for member in chain.members:
		if member.position.distance_to(target.position) <= influence_distance:
			return true
	return false

func _can_join_flashing_chain(ball: BallState, color_id: int, members: Array) -> bool:
	if ball.kind != BallState.Kind.COLOR:
		return false
	if not ball.is_on_board():
		return false
	if ball.color_id != color_id:
		return false
	for member in members:
		if member == ball:
			return false
	for member in members:
		if ball.position.distance_to(member.position) <= neighbor_distance:
			return true
	return false
