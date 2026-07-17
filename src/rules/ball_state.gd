extends RefCounted
class_name BallState

enum Kind { COLOR, HAZARD }
enum HazardPhase { WARNING, DANGER }

var id: int
var kind: Kind
var position: Vector2
var radius: float = 24.0
var color_id: int = -1
var value: int = 0
var hazard_phase: HazardPhase = HazardPhase.WARNING
var hazard_damage: int = 0
var age_seconds: float = 0.0
var flashing: bool = false
var settled: bool = false
var board_attached: bool = false
var has_settle_target: bool = false
var settle_target: Vector2 = Vector2.ZERO
var entry_duration_seconds: float = 0.0
var visual_rotation: float = 0.0

func is_on_board() -> bool:
	return settled or board_attached

static func new_ball(ball_id: int, ball_kind: Kind, ball_position: Vector2) -> BallState:
	var ball := new()
	ball.id = ball_id
	ball.kind = ball_kind
	ball.position = ball_position
	return ball
