extends Node
class_name SpawnQueue

const BallState = preload("res://src/rules/ball_state.gd")

var preview: Array[BallState] = []
var next_id: int = 1000

func seed_preview() -> void:
	while preview.size() < 6:
		preview.append(_make_player_ball())

func pop_next_player_ball() -> BallState:
	seed_preview()
	var ball := preview.pop_front() as BallState
	preview.append(_make_player_ball())
	return ball

func fast_drop_current() -> BallState:
	return pop_next_player_ball()

func _make_player_ball() -> BallState:
	next_id += 1
	var roll := next_id % 8
	if roll < 5:
		var color_ball: BallState = BallState.new_ball(next_id, BallState.Kind.COLOR, Vector2.ZERO)
		color_ball.color_id = roll % 4
		return color_ball
	var combat: BallState = BallState.new_ball(next_id, BallState.Kind.COMBAT, Vector2.ZERO)
	combat.combat_kind = [BallState.CombatKind.ATTACK, BallState.CombatKind.SHIELD, BallState.CombatKind.HEAL][roll - 5]
	return combat
