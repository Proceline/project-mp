extends RefCounted

const BattleState = preload("res://src/rules/battle_state.gd")
const BossController = preload("res://src/boss/boss_controller.gd")
const ActionBarVolleyMechanic = preload("res://src/boss/action_bar_volley_mechanic.gd")
const HpPhaseMechanic = preload("res://src/boss/hp_phase_mechanic.gd")
const BurstCounterMechanic = preload("res://src/boss/burst_counter_mechanic.gd")
const TestRunner = preload("res://tests/test_runner.gd")

func test_action_bar_volley_emits_hazard_event(runner: TestRunner) -> void:
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

func test_action_bar_volley_preserves_large_delta_overflow(runner: TestRunner) -> void:
	var battle := BattleState.new()
	var boss := BossController.new()
	var volley := ActionBarVolleyMechanic.new()
	volley.interval_seconds = 6.0
	boss.configure([volley])
	var first_events := boss.tick(13.0, battle)
	runner.assert_eq(first_events.size(), 2, "large delta can emit multiple volley events")
	if first_events.size() >= 2:
		runner.assert_eq(first_events[0].source, "action_bar", "first overflow event uses action bar source")
		runner.assert_eq(first_events[1].source, "action_bar", "second overflow event uses action bar source")
	runner.assert_eq(boss.tick(4.9, battle).size(), 0, "overflow time is preserved after repeated emits")
	runner.assert_eq(boss.tick(0.1, battle).size(), 1, "preserved overflow advances the next cadence")
	boss.free()

func test_hp_phase_mechanic_fires_once(runner: TestRunner) -> void:
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

func test_hp_phase_mechanic_state_isolated_per_controller(runner: TestRunner) -> void:
	var battle := BattleState.new()
	battle.boss_max_hp = 100
	battle.boss_hp = 39
	var shared_phase := HpPhaseMechanic.new()
	shared_phase.threshold_percent = 0.4
	var first_boss := BossController.new()
	var second_boss := BossController.new()
	first_boss.configure([shared_phase])
	second_boss.configure([shared_phase])
	runner.assert_eq(first_boss.tick(0.1, battle).size(), 1, "first controller fires shared phase")
	runner.assert_eq(second_boss.tick(0.1, battle).size(), 1, "second controller keeps independent phase state")
	first_boss.free()
	second_boss.free()

func test_burst_counter_modifies_next_action(runner: TestRunner) -> void:
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

func test_burst_counter_does_not_depend_on_mechanic_order(runner: TestRunner) -> void:
	var battle := BattleState.new()
	var boss := BossController.new()
	var volley := ActionBarVolleyMechanic.new()
	volley.interval_seconds = 6.0
	var counter := BurstCounterMechanic.new()
	counter.burst_threshold = 20
	boss.configure([counter, volley])
	boss.notify_player_damage(25)
	var events := boss.tick(6.0, battle)
	runner.assert_eq(events.size(), 2, "burst counter still triggers when ordered before volley")
	runner.assert_true(_event_sources(events).has("action_bar"), "volley event is present")
	runner.assert_true(_event_sources(events).has("burst_counter"), "counter event is present")
	boss.free()

func _event_sources(events: Array) -> Array[String]:
	var sources: Array[String] = []
	for event in events:
		sources.append(String(event.source))
	return sources
