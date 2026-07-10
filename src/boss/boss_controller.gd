extends Node
class_name BossController

var mechanics: Array = []
var action_bar: float = 0.0
var action_triggered_this_tick: bool = false

func configure(new_mechanics: Array) -> void:
	mechanics = new_mechanics

func tick(delta: float, battle) -> Array:
	action_triggered_this_tick = false
	var events: Array = []
	for mechanic in mechanics:
		events.append_array(mechanic.tick(delta, battle, self))
	return events

func notify_player_damage(amount: int) -> void:
	for mechanic in mechanics:
		mechanic.on_player_damage(amount, self)
