extends Resource
class_name BossMechanic

const BattleState = preload("res://src/rules/battle_state.gd")

func tick(delta: float, battle: BattleState, controller: Object) -> Array:
	return []

func react_to_tick(events: Array, battle: BattleState, controller: Object) -> Array:
	return []

func on_player_damage(amount: int, controller: Object) -> void:
	pass
