extends Resource
class_name HazardTuning

@export var warning_seconds_after_board_contact: float = 10.0
@export var danger_initial_value: int = 1
@export var danger_growth_seconds: float = 20.0
@export var danger_max_value: int = 5
@export var boundary_explosion_damage: int = 3
