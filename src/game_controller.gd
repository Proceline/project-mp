extends Node2D
class_name GameController

const BattleState = preload("res://src/rules/battle_state.gd")
const BossController = preload("res://src/boss/boss_controller.gd")
const ActionBarVolleyMechanic = preload("res://src/boss/action_bar_volley_mechanic.gd")
const HpPhaseMechanic = preload("res://src/boss/hp_phase_mechanic.gd")
const BurstCounterMechanic = preload("res://src/boss/burst_counter_mechanic.gd")
const SpawnQueue = preload("res://src/playfield/spawn_queue.gd")
const HazardSpawner = preload("res://src/playfield/hazard_spawner.gd")
const Playfield = preload("res://src/playfield/playfield.gd")
const ChainResolver = preload("res://src/rules/chain_resolver.gd")
const BattleUI = preload("res://src/ui/battle_ui.gd")

@onready var playfield: Playfield = %Playfield
@onready var spawn_queue: SpawnQueue = %SpawnQueue
@onready var hazard_spawner: HazardSpawner = %HazardSpawner
@onready var boss_controller: BossController = %BossController
@onready var ui: BattleUI = %BattleUI

var battle := BattleState.new()
var volley_mechanic: ActionBarVolleyMechanic
var chain_resolver := ChainResolver.new()
var active_chains: Array = []
var chain_timer: float = 0.0
var chain_flash_seconds: float = 1.2
var chain_effects_applied: bool = false

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
	playfield.advance_hazard_phases(delta)
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
	advance_chain_resolution(delta)
	ui.update_from_state(battle, _boss_action_ratio(), spawn_queue.preview)

func advance_chain_resolution(delta: float) -> void:
	_tick_chains(delta)

func _boss_action_ratio() -> float:
	if volley_mechanic == null or volley_mechanic.interval_seconds <= 0.0:
		return 0.0
	var state := boss_controller.get_mechanic_state(volley_mechanic)
	return float(state.get("elapsed", 0.0)) / volley_mechanic.interval_seconds

func _tick_chains(delta: float) -> void:
	if active_chains.is_empty():
		active_chains = chain_resolver.start_flash_groups(playfield.balls)
		chain_timer = chain_flash_seconds if not active_chains.is_empty() else 0.0
		chain_effects_applied = false
	if active_chains.is_empty():
		return
	if not chain_effects_applied:
		chain_resolver.apply_chain_influence(active_chains, playfield.balls)
		chain_effects_applied = true
	chain_timer -= delta
	if chain_timer > 0.0:
		return
	var result := chain_resolver.resolve_finished_chains(active_chains, playfield.balls)
	_apply_chain_result(result)
	active_chains.clear()
	chain_timer = 0.0
	chain_effects_applied = false

func _apply_chain_result(result: Dictionary) -> void:
	var attack := int(result.attack)
	if attack > 0:
		battle.apply_attack_to_boss(attack)
		boss_controller.notify_player_damage(attack)
	if int(result.shield) > 0:
		battle.add_shield(int(result.shield))
	if int(result.heal) > 0:
		battle.heal_player(int(result.heal))
	_remove_balls_by_id(result.cleared_color_ids)
	_remove_balls_by_id(result.removed_ball_ids)

func _remove_balls_by_id(ids: Array) -> void:
	for i in range(playfield.balls.size() - 1, -1, -1):
		var ball = playfield.balls[i]
		if ids.has(ball.id):
			playfield.balls.remove_at(i)
			playfield._remove_orb_node(ball.id)
