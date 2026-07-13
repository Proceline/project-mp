extends Resource
class_name BossMechanic

func tick(_delta: float, _battle: BattleState, _controller: Object) -> Array:
	return []

func react_to_tick(_events: Array, _battle: BattleState, _controller: Object) -> Array:
	return []

func on_player_damage(_amount: int, _controller: Object) -> void:
	pass
