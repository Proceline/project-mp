extends "res://src/boss/boss_mechanic.gd"
class_name ActionBarVolleyMechanic

@export var interval_seconds: float = 6.0
@export var count: int = 2
@export var value: int = 5

func tick(delta: float, battle: BattleState, controller) -> Array:
	var state: Dictionary = controller.get_mechanic_state(self)
	var elapsed := float(state.get("elapsed", 0.0)) + delta
	var events: Array = []
	if interval_seconds <= 0.0:
		state["elapsed"] = 0.0
		return events
	while elapsed >= interval_seconds:
		elapsed -= interval_seconds
		events.append({
			"type": "spawn_hazard",
			"count": count,
			"value": value,
			"source": "action_bar",
			"angle_hint": "boss_side",
		})
	state["elapsed"] = elapsed
	return events
