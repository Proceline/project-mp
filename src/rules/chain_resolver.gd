extends RefCounted
class_name ChainResolver

const BallState = preload("res://src/rules/ball_state.gd")

var neighbor_distance: float = 52.0
var influence_distance: float = 72.0
var minimum_chain_size: int = 5

func find_color_groups(balls: Array[BallState]) -> Array:
	var color_balls: Array[BallState] = []
	for ball in balls:
		if ball.kind == BallState.Kind.COLOR and ball.settled and not ball.flashing:
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

func apply_chain_influence(chains: Array, balls: Array[BallState]) -> void:
	for target in balls:
		if target.kind == BallState.Kind.COLOR:
			continue

		var total := 0
		for chain in chains:
			if _chain_touches_ball(chain, target):
				total += int(chain.strength)

		if total == 0:
			continue

		if target.kind == BallState.Kind.COMBAT:
			target.value += total
		elif target.kind == BallState.Kind.HAZARD:
			target.value = max(target.value - total, 0)

func _chain_touches_ball(chain: Dictionary, target: BallState) -> bool:
	for member in chain.members:
		if member.position.distance_to(target.position) <= influence_distance:
			return true
	return false
