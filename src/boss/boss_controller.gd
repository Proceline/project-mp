extends Node
class_name BossController

const BattleState = preload("res://src/rules/battle_state.gd")

var mechanics: Array = []
var _mechanic_state: Dictionary = {}

func configure(new_mechanics: Array) -> void:
	mechanics = new_mechanics
	_mechanic_state.clear()

func tick(delta: float, battle: BattleState) -> Array:
	var events: Array = []
	for mechanic in mechanics:
		events.append_array(mechanic.tick(delta, battle, self))
	for mechanic in mechanics:
		events.append_array(mechanic.react_to_tick(events, battle, self))
	return events

func notify_player_damage(amount: int) -> void:
	for mechanic in mechanics:
		mechanic.on_player_damage(amount, self)

func get_mechanic_state(mechanic) -> Dictionary:
	var key: int = mechanic.get_instance_id()
	if not _mechanic_state.has(key):
		_mechanic_state[key] = {}
	return _mechanic_state[key]
