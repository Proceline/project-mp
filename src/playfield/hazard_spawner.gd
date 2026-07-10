extends Node
class_name HazardSpawner

const BallState = preload("res://src/rules/ball_state.gd")

var next_id: int = 5000

func spawn_from_event(event: Dictionary) -> Array[BallState]:
	var hazards: Array[BallState] = []
	var count := int(event.get("count", 1))
	var value := int(event.get("value", 5))
	var angle_hint := String(event.get("angle_hint", "boss_side"))
	for i in range(count):
		next_id += 1
		var ball: BallState = BallState.new_ball(next_id, BallState.Kind.HAZARD, _spawn_position(angle_hint, i, count))
		ball.value = value
		ball.hazard_damage = value
		ball.age_seconds = 0.0
		ball.hazard_phase = BallState.HazardPhase.WARNING
		hazards.append(ball)
	return hazards

func _spawn_position(angle_hint: String, index: int, count: int) -> Vector2:
	var base_angle := deg_to_rad(-35.0)
	if angle_hint == "wide" and count > 1:
		base_angle = deg_to_rad(-70.0 + 35.0 * index)
	var distance := 220.0
	return Vector2(cos(base_angle), sin(base_angle)) * distance
