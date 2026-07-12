extends Node
class_name SpawnQueue

const BallState = preload("res://src/rules/ball_state.gd")
const OrbTuning = preload("res://src/config/orb_tuning.gd")
const DEFAULT_TUNING: OrbTuning = preload("res://data/orb_tuning.tres")

var preview: Array[BallState] = []
var next_id: int = 1000
var tuning: OrbTuning = DEFAULT_TUNING

func seed_preview() -> void:
	while preview.size() < tuning.preview_size:
		preview.append(_make_player_ball())

func pop_next_ball() -> BallState:
	seed_preview()
	var ball := preview.pop_front() as BallState
	if ball.kind != BallState.Kind.HAZARD:
		preview.append(_make_player_ball())
	return ball

func fast_drop_current() -> BallState:
	return pop_next_ball()

func insert_preview_ball(ball: BallState, insert_index: int) -> void:
	var clamped_index: int = clampi(insert_index, 0, preview.size())
	preview.insert(clamped_index, ball)

func insert_preview_balls(new_balls: Array[BallState], insert_index: int) -> void:
	var index := clampi(insert_index, 0, preview.size())
	for ball in new_balls:
		preview.insert(index, ball)
		index += 1

func _make_player_ball() -> BallState:
	next_id += 1
	var color_ball: BallState = BallState.new_ball(next_id, BallState.Kind.COLOR, Vector2.ZERO)
	color_ball.color_id = next_id % 4
	color_ball.entry_duration_seconds = tuning.player_entry_seconds
	return color_ball
