extends "res://src/boss/boss_mechanic.gd"
class_name ActionBarVolleyMechanic

@export var interval_seconds: float = 6.0
@export var count: int = 2
@export var value: int = 5

func tick(delta: float, battle, controller) -> Array:
	controller.action_bar += delta
	if controller.action_bar < interval_seconds:
		return []
	controller.action_bar = 0.0
	controller.action_triggered_this_tick = true
	return [{
		"type": "spawn_hazard",
		"count": count,
		"value": value,
		"source": "action_bar",
		"angle_hint": "boss_side",
	}]
