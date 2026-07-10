extends Node2D
class_name GameController

const BattleState = preload("res://src/rules/battle_state.gd")
const ChainResolver = preload("res://src/rules/chain_resolver.gd")
const BossController = preload("res://src/boss/boss_controller.gd")
const ActionBarVolleyMechanic = preload("res://src/boss/action_bar_volley_mechanic.gd")
const HpPhaseMechanic = preload("res://src/boss/hp_phase_mechanic.gd")
const BurstCounterMechanic = preload("res://src/boss/burst_counter_mechanic.gd")
const SpawnQueue = preload("res://src/playfield/spawn_queue.gd")
const HazardSpawner = preload("res://src/playfield/hazard_spawner.gd")
const Playfield = preload("res://src/playfield/playfield.gd")
const BattleUI = preload("res://src/ui/battle_ui.gd")

@onready var playfield: Playfield = %Playfield
@onready var spawn_queue: SpawnQueue = %SpawnQueue
@onready var hazard_spawner: HazardSpawner = %HazardSpawner
@onready var boss_controller: BossController = %BossController
@onready var ui: BattleUI = %BattleUI

var battle := BattleState.new()
var chain_resolver := ChainResolver.new()
var volley_mechanic: ActionBarVolleyMechanic

func _ready() -> void:
	volley_mechanic = ActionBarVolleyMechanic.new()
	var phase70 := HpPhaseMechanic.new()
	phase70.threshold_percent = 0.7
	var phase40 := HpPhaseMechanic.new()
	phase40.threshold_percent = 0.4
	var phase15 := HpPhaseMechanic.new()
	phase15.threshold_percent = 0.15
	var counter := BurstCounterMechanic.new()
	boss_controller.configure([volley_mechanic, phase70, phase40, phase15, counter])
	spawn_queue.seed_preview()
	ui.update_from_state(battle, 0.0, spawn_queue.preview)

func _process(delta: float) -> void:
	if battle.result() != "active":
		ui.update_from_state(battle, _boss_action_ratio(), spawn_queue.preview)
		return
	var rotation_input := Input.get_axis("rotate_left", "rotate_right")
	playfield.rotate_settled(rotation_input * playfield.rotation_speed * delta)
	if Input.is_action_just_pressed("fast_drop_player_orb"):
		var ball := spawn_queue.fast_drop_current()
		ball.position = Vector2(-320, -180)
		playfield.add_ball(ball)
	for event in boss_controller.tick(delta, battle):
		for hazard in hazard_spawner.spawn_from_event(event):
			playfield.add_ball(hazard)
	for exploded in playfield.check_boundary_explosions():
		battle.apply_player_damage(max(exploded.value, 1))
		boss_controller.notify_player_damage(max(exploded.value, 1))
	ui.update_from_state(battle, _boss_action_ratio(), spawn_queue.preview)

func _boss_action_ratio() -> float:
	if volley_mechanic == null or volley_mechanic.interval_seconds <= 0.0:
		return 0.0
	var state := boss_controller.get_mechanic_state(volley_mechanic)
	return float(state.get("elapsed", 0.0)) / volley_mechanic.interval_seconds
