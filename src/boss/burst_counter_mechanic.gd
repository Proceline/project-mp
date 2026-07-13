extends "res://src/boss/boss_mechanic.gd"
class_name BurstCounterMechanic

@export var burst_threshold: int = 25
@export var counter_value: int = 10

func on_player_damage(amount: int, controller: Object) -> void:
	if amount >= burst_threshold:
		controller.call("get_mechanic_state", self)["pending_counter"] = true

func react_to_tick(events: Array, _battle: BattleState, controller: Object) -> Array:
	var state: Dictionary = controller.call("get_mechanic_state", self)
	if bool(state.get("pending_counter", false)) and _has_action_bar_event(events):
		state["pending_counter"] = false
		return [{
			"type": "spawn_hazard",
			"count": 1,
			"value": counter_value,
			"source": "burst_counter",
			"angle_hint": "boss_side",
		}]
	return []

func _has_action_bar_event(events: Array) -> bool:
	for event in events:
		if String(event.get("source", "")) == "action_bar":
			return true
	return false
