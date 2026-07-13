extends Resource
class_name OrbTuning

const OrbColorGenerator = preload("res://src/config/orb_color_generator.gd")
const HazardTuning = preload("res://src/config/hazard_tuning.gd")

@export var preview_size: int = 6
@export var color_generator: OrbColorGenerator = preload("res://data/orb_color_generator_default.tres")
@export var hazard_tuning: HazardTuning = preload("res://data/hazard_tuning_default.tres")
@export var player_entry_seconds: float = 3.0
@export var player_fast_drop_entry_seconds: float = 0.35
@export var player_spawn_position: Vector2 = Vector2(-320.0, -180.0)
@export var player_spawn_lane_padding: float = 6.0
@export var player_spawn_lane_max_steps: int = 8
@export var tactical_slot_count: int = 2
@export var tactical_insert_index: int = 1
@export var hazard_entry_seconds: float = 3.0
@export var hazard_preview_insert_index: int = 2
@export var hazard_entry_angle_degrees: float = -35.0
@export var hazard_wide_start_angle_degrees: float = -70.0
@export var hazard_wide_step_degrees: float = 35.0
@export var hazard_entry_distance: float = 220.0
@export var hazard_warning_seconds: float = 1.25
@export var hazard_default_value: int = 5
@export var chain_extend_seconds: float = 0.2
@export var chain_max_flash_seconds: float = 2.0
