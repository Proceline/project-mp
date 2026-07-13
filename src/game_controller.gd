extends Node2D
class_name GameController

const BattleState = preload("res://src/rules/battle_state.gd")
const BossController = preload("res://src/boss/boss_controller.gd")
const ActionBarVolleyMechanic = preload("res://src/boss/action_bar_volley_mechanic.gd")
const HpPhaseMechanic = preload("res://src/boss/hp_phase_mechanic.gd")
const BurstCounterMechanic = preload("res://src/boss/burst_counter_mechanic.gd")
const SpawnQueue = preload("res://src/playfield/spawn_queue.gd")
const TacticalQueue = preload("res://src/playfield/tactical_queue.gd")
const HazardSpawner = preload("res://src/playfield/hazard_spawner.gd")
const Playfield = preload("res://src/playfield/playfield.gd")
const ChainResolver = preload("res://src/rules/chain_resolver.gd")
const BattleUI = preload("res://src/ui/battle_ui.gd")
const OrbTuning = preload("res://src/config/orb_tuning.gd")
const VisualTheme = preload("res://src/config/visual_theme.gd")

@onready var playfield: Playfield = %Playfield
@onready var spawn_queue: SpawnQueue = %SpawnQueue
@onready var tactical_queue: TacticalQueue = %TacticalQueue
@onready var hazard_spawner: HazardSpawner = %HazardSpawner
@onready var boss_controller: BossController = %BossController
@onready var ui: BattleUI = %BattleUI
@export var orb_tuning: OrbTuning = preload("res://data/orb_tuning.tres")
@export var visual_theme: VisualTheme = preload("res://data/visual_theme_astral_batch1.tres")

var battle := BattleState.new()
var volley_mechanic: ActionBarVolleyMechanic
var chain_resolver := ChainResolver.new()
var active_chains: Array = []
var chain_timer: float = 0.0
var chain_flash_seconds: float = 1.2
var chain_extend_seconds: float = 0.2
var chain_max_flash_seconds: float = 2.0
var chain_effects_applied: bool = false
var player_auto_drop_seconds: float = 3.0
var player_auto_drop_timer: float = 0.0
var damage_events: Array[Dictionary] = []

func _ready() -> void:
	_apply_orb_tuning()
	_apply_visual_theme()
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
	tactical_queue.seed_slots()
	ui.update_from_state(battle, 0.0, spawn_queue.preview, tactical_queue.slots)

func _process(delta: float) -> void:
	if battle.result() != "active":
		ui.update_from_state(battle, _boss_action_ratio(), spawn_queue.preview, tactical_queue.slots)
		return
	var rotation_input := Input.get_axis("rotate_left", "rotate_right")
	playfield.rotate_settled(rotation_input * playfield.rotation_speed * delta)
	playfield.advance_hazard_phases(delta)
	if Input.is_action_just_pressed("fast_drop_player_orb"):
		if handle_player_fast_drop():
			player_auto_drop_timer = 0.0
	elif Input.is_action_just_pressed("insert_tactical_orb"):
		insert_tactical_combat_orb()
	else:
		advance_player_orb_spawn(delta)
	advance_boss_events(delta)
	for exploded in playfield.check_boundary_explosions():
		var damage := _hazard_damage(exploded)
		_apply_player_damage(damage, "boundary_explosion")
		boss_controller.notify_player_damage(damage)
	advance_chain_resolution(delta)
	ui.update_from_state(battle, _boss_action_ratio(), spawn_queue.preview, tactical_queue.slots)

func advance_chain_resolution(delta: float) -> void:
	_tick_chains(delta)

func advance_player_orb_spawn(delta: float) -> void:
	player_auto_drop_timer += delta
	if player_auto_drop_timer < player_auto_drop_seconds:
		return
	player_auto_drop_timer = 0.0
	_drop_next_queued_orb()

func advance_boss_events(delta: float) -> void:
	for event in boss_controller.tick(delta, battle):
		_queue_hazards_from_event(event)

func handle_player_fast_drop() -> bool:
	var accelerated_count := playfield.accelerate_active_orbs(orb_tuning.player_fast_drop_entry_seconds)
	var dropped_next := _fast_drop_next_orb()
	return accelerated_count > 0 or dropped_next

func insert_tactical_combat_orb() -> bool:
	var ball := tactical_queue.pop_next_combat_orb()
	if ball == null:
		return false
	spawn_queue.insert_preview_ball(ball, orb_tuning.tactical_insert_index)
	return true

func _fast_drop_next_orb() -> bool:
	var ball := spawn_queue.fast_drop_current()
	if ball == null:
		return false
	if ball.kind != BallState.Kind.HAZARD:
		_prepare_player_entry(ball)
	playfield.add_ball(ball)
	return true

func _drop_next_queued_orb() -> void:
	var ball := spawn_queue.pop_next_ball()
	if ball.kind != BallState.Kind.HAZARD:
		_prepare_player_entry(ball)
	playfield.add_ball(ball)

func _prepare_player_entry(ball: BallState) -> void:
	ball.position = orb_tuning.player_spawn_position
	ball.entry_duration_seconds = orb_tuning.player_entry_seconds

func _queue_hazards_from_event(event: Dictionary) -> void:
	if String(event.get("type", "")) != "spawn_hazard":
		return
	var hazards := hazard_spawner.spawn_from_event(event)
	var insert_index := int(event.get("insert_index", orb_tuning.hazard_preview_insert_index))
	spawn_queue.insert_preview_balls(hazards, insert_index)

func _apply_orb_tuning() -> void:
	if orb_tuning == null:
		return
	spawn_queue.tuning = orb_tuning
	tactical_queue.tuning = orb_tuning
	hazard_spawner.tuning = orb_tuning
	playfield.hazard_warning_seconds = orb_tuning.hazard_warning_seconds
	playfield.hazard_tuning = orb_tuning.hazard_tuning
	chain_extend_seconds = orb_tuning.chain_extend_seconds
	chain_max_flash_seconds = orb_tuning.chain_max_flash_seconds

func _apply_visual_theme() -> void:
	if visual_theme == null:
		return
	playfield.visual_theme = visual_theme
	ui.visual_theme = visual_theme
	ui.apply_visual_theme()

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
	var added_count := chain_resolver.refresh_flashing_chains(active_chains, playfield.balls)
	if added_count > 0:
		chain_timer = minf(chain_timer + chain_extend_seconds, chain_max_flash_seconds)
	chain_resolver.apply_chain_influence_growth(active_chains, playfield.balls)
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
	if int(result.player_damage) > 0:
		_apply_player_damage(int(result.player_damage), "danger_hazard_clear")
		boss_controller.notify_player_damage(int(result.player_damage))
	_remove_balls_by_id(result.cleared_color_ids)
	_remove_balls_by_id(result.removed_ball_ids)

func _remove_balls_by_id(ids: Array) -> void:
	var removed_any := false
	for i in range(playfield.balls.size() - 1, -1, -1):
		var ball = playfield.balls[i]
		if ids.has(ball.id):
			playfield.balls.remove_at(i)
			playfield._remove_orb_node(ball.id)
			removed_any = true
	if removed_any:
		playfield.release_unsupported_orbs()

func _hazard_damage(ball: BallState) -> int:
	if orb_tuning != null and orb_tuning.hazard_tuning != null:
		return orb_tuning.hazard_tuning.boundary_explosion_damage
	return 3

func _apply_player_damage(amount: int, source: String) -> void:
	battle.apply_player_damage(amount)
	damage_events.append({
		"amount": amount,
		"source": source,
		"hp_after": battle.player_hp,
	})
	print("player_damage source=%s amount=%d hp_after=%d" % [source, amount, battle.player_hp])
