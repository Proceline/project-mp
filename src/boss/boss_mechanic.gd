extends Resource
class_name BossMechanic

const BattleState = preload("res://src/rules/battle_state.gd")

func tick(delta: float, battle: BattleState, controller) -> Array:
	return []

func react_to_tick(events: Array, battle: BattleState, controller) -> Array:
	return []

func on_player_damage(amount: int, controller) -> void:
	pass
