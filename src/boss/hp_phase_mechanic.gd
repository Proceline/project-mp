extends "res://src/boss/boss_mechanic.gd"
class_name HpPhaseMechanic

@export var threshold_percent: float = 0.4
@export var count: int = 3
@export var value: int = 8

func tick(delta: float, battle: BattleState, controller: Object) -> Array:
	var state: Dictionary = controller.call("get_mechanic_state", self)
	if bool(state.get("fired", false)):
		return []
	var current_percent := float(battle.boss_hp) / float(max(battle.boss_max_hp, 1))
	if current_percent <= threshold_percent:
		state["fired"] = true
		return [{
			"type": "spawn_hazard",
			"count": count,
			"value": value,
			"source": "hp_phase",
			"angle_hint": "wide",
		}]
	return []
