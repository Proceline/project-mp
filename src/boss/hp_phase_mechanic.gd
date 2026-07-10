extends "res://src/boss/boss_mechanic.gd"
class_name HpPhaseMechanic

@export var threshold_percent: float = 0.4
@export var count: int = 3
@export var value: int = 8
var fired: bool = false

func tick(delta: float, battle, controller) -> Array:
	if fired:
		return []
	var current_percent := float(battle.boss_hp) / float(max(battle.boss_max_hp, 1))
	if current_percent <= threshold_percent:
		fired = true
		return [{
			"type": "spawn_hazard",
			"count": count,
			"value": value,
			"source": "hp_phase",
			"angle_hint": "wide",
		}]
	return []
