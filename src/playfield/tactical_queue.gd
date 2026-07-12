extends Node
class_name TacticalQueue

const BallState = preload("res://src/rules/ball_state.gd")
const OrbTuning = preload("res://src/config/orb_tuning.gd")
const DEFAULT_TUNING: OrbTuning = preload("res://data/orb_tuning.tres")

var slots: Array[BallState] = []
var next_id: int = 7000
var tuning: OrbTuning = DEFAULT_TUNING

func seed_slots() -> void:
	while slots.size() < tuning.tactical_slot_count:
		slots.append(_make_combat_ball())

func pop_next_combat_orb() -> BallState:
	seed_slots()
	if slots.is_empty():
		return null
	var ball := slots.pop_front() as BallState
	slots.append(_make_combat_ball())
	return ball

func _make_combat_ball() -> BallState:
	next_id += 1
	var ball: BallState = BallState.new_ball(next_id, BallState.Kind.COMBAT, Vector2.ZERO)
	var roll := next_id % 3
	ball.combat_kind = [BallState.CombatKind.ATTACK, BallState.CombatKind.SHIELD, BallState.CombatKind.HEAL][roll]
	ball.entry_duration_seconds = tuning.player_entry_seconds
	return ball
