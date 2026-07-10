extends "res://src/boss/boss_mechanic.gd"
class_name BurstCounterMechanic

@export var burst_threshold: int = 25
@export var counter_value: int = 10
var pending_counter: bool = false

func on_player_damage(amount: int, controller) -> void:
	if amount >= burst_threshold:
		pending_counter = true

func tick(delta: float, battle, controller) -> Array:
	if pending_counter and controller.action_triggered_this_tick:
		pending_counter = false
		return [{
			"type": "spawn_hazard",
			"count": 1,
			"value": counter_value,
			"source": "burst_counter",
			"angle_hint": "boss_side",
		}]
	return []
