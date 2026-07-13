extends Node
class_name HazardSpawner

const DEFAULT_TUNING: OrbTuning = preload("res://data/orb_tuning.tres")

var next_id: int = 5000
var tuning: OrbTuning = DEFAULT_TUNING

func spawn_from_event(event: Dictionary) -> Array[BallState]:
	var hazards: Array[BallState] = []
	var count := int(event.get("count", 1))
	var angle_hint := String(event.get("angle_hint", "boss_side"))
	for i in range(count):
		next_id += 1
		var ball: BallState = BallState.new_ball(next_id, BallState.Kind.HAZARD, _spawn_position(event, angle_hint, i, count))
		ball.value = int(event.get("initial_value", 0))
		ball.hazard_damage = 0
		ball.age_seconds = 0.0
		ball.hazard_phase = BallState.HazardPhase.WARNING
		ball.entry_duration_seconds = float(event.get("entry_seconds", tuning.hazard_entry_seconds))
		hazards.append(ball)
	return hazards

func _spawn_position(event: Dictionary, angle_hint: String, index: int, count: int) -> Vector2:
	var base_angle := deg_to_rad(tuning.hazard_entry_angle_degrees)
	if event.has("angle_degrees"):
		base_angle = deg_to_rad(float(event["angle_degrees"]))
	if angle_hint == "wide" and count > 1:
		base_angle = deg_to_rad(tuning.hazard_wide_start_angle_degrees + tuning.hazard_wide_step_degrees * index)
	var distance := float(event.get("entry_distance", tuning.hazard_entry_distance))
	return Vector2(cos(base_angle), sin(base_angle)) * distance
