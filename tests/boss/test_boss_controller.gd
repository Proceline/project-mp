extends RefCounted

const BattleState = preload("res://src/rules/battle_state.gd")
const BossController = preload("res://src/boss/boss_controller.gd")
const ActionBarVolleyMechanic = preload("res://src/boss/action_bar_volley_mechanic.gd")
const HpPhaseMechanic = preload("res://src/boss/hp_phase_mechanic.gd")
const BurstCounterMechanic = preload("res://src/boss/burst_counter_mechanic.gd")

func test_action_bar_volley_emits_hazard_event(runner) -> void:
	var battle := BattleState.new()
	var boss := BossController.new()
	var volley := ActionBarVolleyMechanic.new()
	volley.interval_seconds = 6.0
	volley.count = 2
	volley.value = 5
	boss.configure([volley])
	var events := boss.tick(6.0, battle)
	runner.assert_eq(events.size(), 1, "action bar emits one event")
	runner.assert_eq(events[0].count, 2, "volley count comes from mechanic")
	boss.free()

func test_hp_phase_mechanic_fires_once(runner) -> void:
	var battle := BattleState.new()
	battle.boss_max_hp = 100
	battle.boss_hp = 39
	var boss := BossController.new()
	var phase := HpPhaseMechanic.new()
	phase.threshold_percent = 0.4
	phase.count = 4
	phase.value = 8
	boss.configure([phase])
	runner.assert_eq(boss.tick(0.1, battle).size(), 1, "phase fires when crossed")
	runner.assert_eq(boss.tick(0.1, battle).size(), 0, "phase fires only once")
	boss.free()

func test_burst_counter_modifies_next_action(runner) -> void:
	var battle := BattleState.new()
	var boss := BossController.new()
	var volley := ActionBarVolleyMechanic.new()
	volley.interval_seconds = 6.0
	var counter := BurstCounterMechanic.new()
	counter.burst_threshold = 20
	boss.configure([volley, counter])
	boss.notify_player_damage(25)
	var events := boss.tick(6.0, battle)
	runner.assert_eq(events.size(), 2, "burst counter adds an event to next action")
	runner.assert_eq(events[1].source, "burst_counter", "second event is counter hazard")
	boss.free()
