# PVE Orb Boss Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable Godot 4.7 boss battle demo with a rotating circular orb field, color-chain clearing, stacked numbered orb influence, modular boss attacks, player HP/shield, and prototype battle UI.

**Architecture:** Implement deterministic rules as small GDScript services first, then connect them to a 2D scene with physics-like orb motion. Boss behavior is modular: `BossController` dispatches configured `BossMechanic` resources, and all hazard creation goes through `HazardSpawner`.

**Tech Stack:** Godot 4.7 stable mono, GDScript, Godot headless console validation, lightweight in-project test runner scripts.

## Global Constraints

- Use Godot 4.7 project conventions.
- Use `D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe` for headless validation.
- Do not use Mario Party, Stick and Spin, Nintendo characters, Nintendo music, Nintendo sound effects, Nintendo UI language, mechanical conveyor belts, the original disk shape, or Nintendo-like character/environment motifs.
- The central object is an original circular attraction focus, such as a rune circle, astral ring, energy seal, or resonance core.
- The player HP number appears in the center of the circular field.
- Shield is displayed as optional marks or cells around the center and may hide or dim at 0.
- The playfield is free-form, not a grid.
- Player-side color/combat orbs appear in a preview list and can be fast-dropped.
- Boss hazard orbs do not appear in the player-side preview list and do not share the same fast-drop input.
- Combat and hazard orb influence stacks from multiple flashing color chains.
- Boss behavior must be modular and data-driven enough to support later boss variations.

---

## File Structure

- Create `src/rules/ball_state.gd`: reference-counted data model for rule tests and scene runtime.
- Create `src/rules/chain_resolver.gd`: proximity graph, same-color groups, flashing chain ticking, stacked influence, and clear results.
- Create `src/rules/battle_state.gd`: player HP, shield, boss HP, damage/heal/shield application, victory/loss state.
- Create `src/boss/boss_mechanic.gd`: base resource interface for boss mechanics.
- Create `src/boss/action_bar_volley_mechanic.gd`: regular timed hazard volley.
- Create `src/boss/hp_phase_mechanic.gd`: HP-threshold special hazard patterns.
- Create `src/boss/burst_counter_mechanic.gd`: player-burst counter modifier.
- Create `src/boss/boss_controller.gd`: action bar, phase dispatch, burst event dispatch, mechanic set orchestration.
- Create `src/playfield/orb_node.gd`: visual/interactive orb node backed by `BallState`.
- Create `src/playfield/playfield.gd`: rotating circular field, incoming player orb handling, settling, boundary checks.
- Create `src/playfield/spawn_queue.gd`: player-side preview list and fast-drop.
- Create `src/playfield/hazard_spawner.gd`: boss-side hazard creation from mechanics/events.
- Create `src/ui/battle_ui.gd`: HP, shield marks, preview list, boss HP, boss action bar, status text.
- Create `src/game_controller.gd`: connects battle state, playfield, boss, UI, win/loss.
- Create `scenes/main.tscn`: one playable battle screen.
- Modify `project.godot`: set `run/main_scene` and input actions.
- Create `tests/test_runner.gd`: headless test runner.
- Create `tests/rules/test_chain_resolver.gd`: rule tests for chains and stacking.
- Create `tests/rules/test_battle_state.gd`: HP/shield/victory tests.
- Create `tests/boss/test_boss_controller.gd`: modular boss behavior tests.
- Create `tests/run_all.gd`: runs all tests from Godot CLI.

---

### Task 1: Test Harness And Project Input Setup

**Files:**
- Create: `tests/test_runner.gd`
- Create: `tests/run_all.gd`
- Modify: `project.godot`

**Interfaces:**
- Produces: `TestRunner.assert_eq(actual: Variant, expected: Variant, message: String) -> void`
- Produces: `TestRunner.assert_true(value: bool, message: String) -> void`
- Produces: `TestRunner.run_suite(suite: Object) -> int`
- Produces input actions: `rotate_left`, `rotate_right`, `fast_drop_player_orb`

- [ ] **Step 1: Write the failing test runner smoke test**

Create `tests/run_all.gd` with this initial content:

```gdscript
extends SceneTree

const TestRunner = preload("res://tests/test_runner.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.assert_eq(2 + 2, 4, "basic arithmetic works")
	quit(runner.failures)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Expected: FAIL because `res://tests/test_runner.gd` does not exist.

- [ ] **Step 3: Add the minimal test runner**

Create `tests/test_runner.gd`:

```gdscript
extends RefCounted
class_name TestRunner

var failures: int = 0

func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures += 1
		push_error("%s | expected=%s actual=%s" % [message, str(expected), str(actual)])

func assert_true(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run_suite(suite: Object) -> int:
	var before := failures
	for method_name in suite.get_method_list():
		var name := String(method_name.name)
		if name.begins_with("test_"):
			suite.call(name, self)
	return failures - before
```

- [ ] **Step 4: Add project input actions**

Modify `project.godot` to include:

```ini
[input]

rotate_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
rotate_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
fast_drop_player_orb={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":32,"physical_keycode":0,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)]
}
```

- [ ] **Step 5: Run test to verify it passes**

Run the same Godot command from Step 2.

Expected: PASS with process exit code `0`.

- [ ] **Step 6: Commit**

```powershell
git add project.godot tests/test_runner.gd tests/run_all.gd
git commit -m "test: add Godot headless test runner"
```

---

### Task 2: Ball State And Battle State Rules

**Files:**
- Create: `src/rules/ball_state.gd`
- Create: `src/rules/battle_state.gd`
- Create: `tests/rules/test_battle_state.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Produces: `BallState.Kind` enum with `COLOR`, `COMBAT`, `HAZARD`
- Produces: `BallState.CombatKind` enum with `NONE`, `ATTACK`, `SHIELD`, `HEAL`
- Produces: `BallState.HazardPhase` enum with `WARNING`, `DANGER`
- Produces: `BallState.new_ball(id: int, kind: int, position: Vector2) -> BallState`
- Produces: `BattleState.apply_player_damage(amount: int) -> void`
- Produces: `BattleState.apply_attack_to_boss(amount: int) -> void`
- Produces: `BattleState.add_shield(amount: int) -> void`
- Produces: `BattleState.heal_player(amount: int) -> void`
- Produces: `BattleState.result() -> String`

- [ ] **Step 1: Write failing battle state tests**

Create `tests/rules/test_battle_state.gd`:

```gdscript
extends RefCounted

const BattleState = preload("res://src/rules/battle_state.gd")

func test_shield_absorbs_before_hp(runner: TestRunner) -> void:
	var state := BattleState.new()
	state.player_hp = 20
	state.player_shield = 7
	state.apply_player_damage(10)
	runner.assert_eq(state.player_shield, 0, "shield is consumed first")
	runner.assert_eq(state.player_hp, 17, "remaining damage reaches hp")

func test_heal_clamps_to_max_hp(runner: TestRunner) -> void:
	var state := BattleState.new()
	state.player_hp = 18
	state.player_max_hp = 20
	state.heal_player(10)
	runner.assert_eq(state.player_hp, 20, "heal does not exceed max hp")

func test_boss_damage_and_results(runner: TestRunner) -> void:
	var state := BattleState.new()
	state.boss_hp = 12
	state.apply_attack_to_boss(12)
	runner.assert_eq(state.boss_hp, 0, "boss hp clamps to zero")
	runner.assert_eq(state.result(), "win", "boss at zero means win")
```

Modify `tests/run_all.gd`:

```gdscript
extends SceneTree

const TestRunner = preload("res://tests/test_runner.gd")
const TestBattleState = preload("res://tests/rules/test_battle_state.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.run_suite(TestBattleState.new())
	quit(runner.failures)
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Expected: FAIL because `battle_state.gd` does not exist.

- [ ] **Step 3: Implement rule data models**

Create `src/rules/ball_state.gd`:

```gdscript
extends RefCounted
class_name BallState

enum Kind { COLOR, COMBAT, HAZARD }
enum CombatKind { NONE, ATTACK, SHIELD, HEAL }
enum HazardPhase { WARNING, DANGER }

var id: int
var kind: Kind
var position: Vector2
var radius: float = 24.0
var color_id: int = -1
var value: int = 0
var combat_kind: CombatKind = CombatKind.NONE
var hazard_phase: HazardPhase = HazardPhase.WARNING
var flashing: bool = false
var settled: bool = false

static func new_ball(ball_id: int, ball_kind: Kind, ball_position: Vector2) -> BallState:
	var ball := BallState.new()
	ball.id = ball_id
	ball.kind = ball_kind
	ball.position = ball_position
	return ball
```

Create `src/rules/battle_state.gd`:

```gdscript
extends RefCounted
class_name BattleState

var player_max_hp: int = 30
var player_hp: int = 30
var player_shield: int = 0
var boss_max_hp: int = 200
var boss_hp: int = 200

func apply_player_damage(amount: int) -> void:
	var remaining := max(amount, 0)
	var absorbed: int = min(player_shield, remaining)
	player_shield -= absorbed
	remaining -= absorbed
	player_hp = max(player_hp - remaining, 0)

func apply_attack_to_boss(amount: int) -> void:
	boss_hp = max(boss_hp - max(amount, 0), 0)

func add_shield(amount: int) -> void:
	player_shield += max(amount, 0)

func heal_player(amount: int) -> void:
	player_hp = min(player_hp + max(amount, 0), player_max_hp)

func result() -> String:
	if boss_hp <= 0:
		return "win"
	if player_hp <= 0:
		return "loss"
	return "active"
```

- [ ] **Step 4: Run tests to verify they pass**

Run the same Godot command from Step 2.

Expected: PASS with process exit code `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/rules/ball_state.gd src/rules/battle_state.gd tests/rules/test_battle_state.gd tests/run_all.gd
git commit -m "feat: add battle state rules"
```

---

### Task 3: Chain Resolver With Multi-Chain Stacking

**Files:**
- Create: `src/rules/chain_resolver.gd`
- Create: `tests/rules/test_chain_resolver.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `BallState`
- Produces: `ChainResolver.neighbor_distance: float`
- Produces: `ChainResolver.find_color_groups(balls: Array[BallState]) -> Array`
- Produces: `ChainResolver.start_flash_groups(balls: Array[BallState]) -> Array`
- Produces: `ChainResolver.apply_chain_influence(chains: Array, balls: Array[BallState]) -> void`
- Produces chain dictionaries with keys `color_id`, `members`, `strength`

- [ ] **Step 1: Write failing chain tests**

Create `tests/rules/test_chain_resolver.gd`:

```gdscript
extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const ChainResolver = preload("res://src/rules/chain_resolver.gd")

func _color_ball(id: int, color_id: int, pos: Vector2) -> BallState:
	var ball := BallState.new_ball(id, BallState.Kind.COLOR, pos)
	ball.color_id = color_id
	ball.settled = true
	return ball

func _attack_ball(id: int, pos: Vector2) -> BallState:
	var ball := BallState.new_ball(id, BallState.Kind.COMBAT, pos)
	ball.combat_kind = BallState.CombatKind.ATTACK
	ball.settled = true
	return ball

func _hazard_ball(id: int, value: int, pos: Vector2) -> BallState:
	var ball := BallState.new_ball(id, BallState.Kind.HAZARD, pos)
	ball.value = value
	ball.settled = true
	return ball

func test_five_same_color_orbs_start_flashing(runner: TestRunner) -> void:
	var resolver := ChainResolver.new()
	var balls: Array[BallState] = []
	for i in range(5):
		balls.append(_color_ball(i, 1, Vector2(i * 40, 0)))
	var chains := resolver.start_flash_groups(balls)
	runner.assert_eq(chains.size(), 1, "five adjacent color orbs create one chain")
	runner.assert_true(balls[0].flashing, "chain members enter flashing state")

func test_combat_orb_stacks_from_multiple_chains(runner: TestRunner) -> void:
	var resolver := ChainResolver.new()
	var combat := _attack_ball(100, Vector2(80, 0))
	var chain_a: Dictionary = {"color_id": 1, "members": [], "strength": 5}
	var chain_b: Dictionary = {"color_id": 2, "members": [], "strength": 6}
	for i in range(5):
		chain_a.members.append(_color_ball(i, 1, Vector2(i * 30, -20)))
	for i in range(5):
		chain_b.members.append(_color_ball(20 + i, 2, Vector2(i * 30, 20)))
	resolver.apply_chain_influence([chain_a, chain_b], [combat])
	runner.assert_eq(combat.value, 11, "combat value stacks from both chains")

func test_hazard_orb_reduces_from_multiple_chains(runner: TestRunner) -> void:
	var resolver := ChainResolver.new()
	var hazard := _hazard_ball(200, 15, Vector2(80, 0))
	var chain_a: Dictionary = {"color_id": 1, "members": [], "strength": 4}
	var chain_b: Dictionary = {"color_id": 2, "members": [], "strength": 5}
	for i in range(5):
		chain_a.members.append(_color_ball(i, 1, Vector2(i * 30, -20)))
		chain_b.members.append(_color_ball(20 + i, 2, Vector2(i * 30, 20)))
	resolver.apply_chain_influence([chain_a, chain_b], [hazard])
	runner.assert_eq(hazard.value, 6, "hazard value is reduced by both chains")
```

Modify `tests/run_all.gd`:

```gdscript
extends SceneTree

const TestRunner = preload("res://tests/test_runner.gd")
const TestBattleState = preload("res://tests/rules/test_battle_state.gd")
const TestChainResolver = preload("res://tests/rules/test_chain_resolver.gd")

func _initialize() -> void:
	var runner := TestRunner.new()
	runner.run_suite(TestBattleState.new())
	runner.run_suite(TestChainResolver.new())
	quit(runner.failures)
```

- [ ] **Step 2: Run tests to verify they fail**

Run the Godot headless test command.

Expected: FAIL because `chain_resolver.gd` does not exist.

- [ ] **Step 3: Implement chain resolver**

Create `src/rules/chain_resolver.gd`:

```gdscript
extends RefCounted
class_name ChainResolver

const BallState = preload("res://src/rules/ball_state.gd")

var neighbor_distance: float = 52.0
var influence_distance: float = 72.0
var minimum_chain_size: int = 5

func find_color_groups(balls: Array[BallState]) -> Array:
	var color_balls: Array[BallState] = []
	for ball in balls:
		if ball.kind == BallState.Kind.COLOR and ball.settled and not ball.flashing:
			color_balls.append(ball)
	var visited := {}
	var groups: Array = []
	for ball in color_balls:
		if visited.has(ball.id):
			continue
		var group: Array[BallState] = []
		var stack: Array[BallState] = [ball]
		visited[ball.id] = true
		while not stack.is_empty():
			var current: BallState = stack.pop_back()
			group.append(current)
			for other in color_balls:
				if visited.has(other.id):
					continue
				if other.color_id == current.color_id and current.position.distance_to(other.position) <= neighbor_distance:
					visited[other.id] = true
					stack.append(other)
		groups.append(group)
	return groups

func start_flash_groups(balls: Array[BallState]) -> Array:
	var chains: Array = []
	for group in find_color_groups(balls):
		if group.size() >= minimum_chain_size:
			for member in group:
				member.flashing = true
			chains.append({
				"color_id": group[0].color_id,
				"members": group,
				"strength": group.size()
			})
	return chains

func apply_chain_influence(chains: Array, balls: Array[BallState]) -> void:
	for target in balls:
		if target.kind == BallState.Kind.COLOR:
			continue
		var total := 0
		for chain in chains:
			if _chain_touches_ball(chain, target):
				total += int(chain.strength)
		if total == 0:
			continue
		if target.kind == BallState.Kind.COMBAT:
			target.value += total
		elif target.kind == BallState.Kind.HAZARD:
			target.value = max(target.value - total, 0)

func _chain_touches_ball(chain: Dictionary, target: BallState) -> bool:
	for member in chain.members:
		if member.position.distance_to(target.position) <= influence_distance:
			return true
	return false
```

- [ ] **Step 4: Run tests to verify they pass**

Run the Godot headless test command.

Expected: PASS with process exit code `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/rules/chain_resolver.gd tests/rules/test_chain_resolver.gd tests/run_all.gd
git commit -m "feat: add chain resolver stacking rules"
```

---

### Task 4: Modular Boss Controller Rules

**Files:**
- Create: `src/boss/boss_mechanic.gd`
- Create: `src/boss/action_bar_volley_mechanic.gd`
- Create: `src/boss/hp_phase_mechanic.gd`
- Create: `src/boss/burst_counter_mechanic.gd`
- Create: `src/boss/boss_controller.gd`
- Create: `tests/boss/test_boss_controller.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `BattleState`
- Produces: `BossController.configure(mechanics: Array[BossMechanic]) -> void`
- Produces: `BossController.tick(delta: float, battle: BattleState) -> Array`
- Produces: `BossController.notify_player_damage(amount: int) -> void`
- Produces event dictionaries with keys `type`, `count`, `value`, `source`, `angle_hint`

- [ ] **Step 1: Write failing boss tests**

Create `tests/boss/test_boss_controller.gd`:

```gdscript
extends RefCounted

const BattleState = preload("res://src/rules/battle_state.gd")
const BossController = preload("res://src/boss/boss_controller.gd")
const ActionBarVolleyMechanic = preload("res://src/boss/action_bar_volley_mechanic.gd")
const HpPhaseMechanic = preload("res://src/boss/hp_phase_mechanic.gd")
const BurstCounterMechanic = preload("res://src/boss/burst_counter_mechanic.gd")

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
```

Update `tests/run_all.gd` to include `TestBossController`.

- [ ] **Step 2: Run tests to verify they fail**

Run the Godot headless test command.

Expected: FAIL because boss scripts do not exist.

- [ ] **Step 3: Implement boss mechanic resources and controller**

Create `src/boss/boss_mechanic.gd`:

```gdscript
extends Resource
class_name BossMechanic

func tick(delta: float, battle: BattleState, controller: BossController) -> Array:
	return []

func on_player_damage(amount: int, controller: BossController) -> void:
	pass
```

Create `src/boss/action_bar_volley_mechanic.gd`:

```gdscript
extends BossMechanic
class_name ActionBarVolleyMechanic

@export var interval_seconds: float = 6.0
@export var count: int = 2
@export var value: int = 5

func tick(delta: float, battle: BattleState, controller: BossController) -> Array:
	controller.action_bar += delta
	if controller.action_bar < interval_seconds:
		return []
	controller.action_bar = 0.0
	controller.action_triggered_this_tick = true
	return [{"type": "spawn_hazard", "count": count, "value": value, "source": "action_bar", "angle_hint": "boss_side"}]
```

Create `src/boss/hp_phase_mechanic.gd`:

```gdscript
extends BossMechanic
class_name HpPhaseMechanic

@export var threshold_percent: float = 0.4
@export var count: int = 3
@export var value: int = 8
var fired: bool = false

func tick(delta: float, battle: BattleState, controller: BossController) -> Array:
	if fired:
		return []
	var current_percent := float(battle.boss_hp) / float(max(battle.boss_max_hp, 1))
	if current_percent <= threshold_percent:
		fired = true
		return [{"type": "spawn_hazard", "count": count, "value": value, "source": "hp_phase", "angle_hint": "wide"}]
	return []
```

Create `src/boss/burst_counter_mechanic.gd`:

```gdscript
extends BossMechanic
class_name BurstCounterMechanic

@export var burst_threshold: int = 25
@export var counter_value: int = 10
var pending_counter: bool = false

func on_player_damage(amount: int, controller: BossController) -> void:
	if amount >= burst_threshold:
		pending_counter = true

func tick(delta: float, battle: BattleState, controller: BossController) -> Array:
	if pending_counter and controller.action_triggered_this_tick:
		pending_counter = false
		return [{"type": "spawn_hazard", "count": 1, "value": counter_value, "source": "burst_counter", "angle_hint": "boss_side"}]
	return []
```

Create `src/boss/boss_controller.gd`:

```gdscript
extends Node
class_name BossController

const BattleState = preload("res://src/rules/battle_state.gd")

var mechanics: Array = []
var action_bar: float = 0.0
var action_triggered_this_tick: bool = false

func configure(new_mechanics: Array) -> void:
	mechanics = new_mechanics

func tick(delta: float, battle: BattleState) -> Array:
	action_triggered_this_tick = false
	var events: Array = []
	for mechanic in mechanics:
		events.append_array(mechanic.tick(delta, battle, self))
	return events

func notify_player_damage(amount: int) -> void:
	for mechanic in mechanics:
		mechanic.on_player_damage(amount, self)
```

- [ ] **Step 4: Run tests to verify they pass**

Run the Godot headless test command.

Expected: PASS with process exit code `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/boss tests/boss tests/run_all.gd
git commit -m "feat: add modular boss mechanics"
```

---

### Task 5: Playfield, Spawn Queue, And Hazard Spawner

**Files:**
- Create: `src/playfield/spawn_queue.gd`
- Create: `src/playfield/hazard_spawner.gd`
- Create: `src/playfield/orb_node.gd`
- Create: `src/playfield/playfield.gd`
- Create: `tests/playfield/test_spawn_and_hazards.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `BallState`
- Produces: `SpawnQueue.preview: Array`
- Produces: `SpawnQueue.pop_next_player_ball() -> BallState`
- Produces: `SpawnQueue.fast_drop_current() -> BallState`
- Produces: `HazardSpawner.spawn_from_event(event: Dictionary) -> Array[BallState]`
- Produces: `Playfield.add_ball(ball: BallState) -> void`
- Produces: `Playfield.rotate_settled(angle_delta: float) -> void`
- Produces: `Playfield.check_boundary_explosions() -> Array[BallState]`

- [ ] **Step 1: Write failing playfield tests**

Create `tests/playfield/test_spawn_and_hazards.gd`:

```gdscript
extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const SpawnQueue = preload("res://src/playfield/spawn_queue.gd")
const HazardSpawner = preload("res://src/playfield/hazard_spawner.gd")
const Playfield = preload("res://src/playfield/playfield.gd")

func test_spawn_queue_contains_only_player_side_orbs(runner: TestRunner) -> void:
	var queue := SpawnQueue.new()
	queue.seed_preview()
	var ball := queue.fast_drop_current()
	runner.assert_true(ball.kind != BallState.Kind.HAZARD, "fast drop never returns hazard orbs")

func test_hazard_spawner_creates_warning_hazards(runner: TestRunner) -> void:
	var spawner := HazardSpawner.new()
	var hazards := spawner.spawn_from_event({"type": "spawn_hazard", "count": 2, "value": 7, "source": "test", "angle_hint": "boss_side"})
	runner.assert_eq(hazards.size(), 2, "hazard count matches event")
	runner.assert_eq(hazards[0].hazard_phase, BallState.HazardPhase.WARNING, "new hazards start in warning phase")

func test_playfield_boundary_reports_outside_hazard(runner: TestRunner) -> void:
	var playfield := Playfield.new()
	playfield.danger_radius = 100.0
	var hazard := BallState.new_ball(1, BallState.Kind.HAZARD, Vector2(160, 0))
	playfield.add_ball(hazard)
	var exploded := playfield.check_boundary_explosions()
	runner.assert_eq(exploded.size(), 1, "hazard outside danger radius explodes")
```

Update `tests/run_all.gd` to include `TestSpawnAndHazards`.

- [ ] **Step 2: Run tests to verify they fail**

Run the Godot headless test command.

Expected: FAIL because playfield scripts do not exist.

- [ ] **Step 3: Implement spawn and playfield scripts**

Create `src/playfield/spawn_queue.gd`:

```gdscript
extends Node
class_name SpawnQueue

const BallState = preload("res://src/rules/ball_state.gd")

var preview: Array[BallState] = []
var next_id: int = 1000

func seed_preview() -> void:
	while preview.size() < 6:
		preview.append(_make_player_ball())

func pop_next_player_ball() -> BallState:
	seed_preview()
	var ball := preview.pop_front() as BallState
	preview.append(_make_player_ball())
	return ball

func fast_drop_current() -> BallState:
	return pop_next_player_ball()

func _make_player_ball() -> BallState:
	next_id += 1
	var roll := next_id % 8
	if roll < 5:
		var color_ball := BallState.new_ball(next_id, BallState.Kind.COLOR, Vector2.ZERO)
		color_ball.color_id = roll % 4
		return color_ball
	var combat := BallState.new_ball(next_id, BallState.Kind.COMBAT, Vector2.ZERO)
	combat.combat_kind = [BallState.CombatKind.ATTACK, BallState.CombatKind.SHIELD, BallState.CombatKind.HEAL][roll - 5]
	return combat
```

Create `src/playfield/hazard_spawner.gd`:

```gdscript
extends Node
class_name HazardSpawner

const BallState = preload("res://src/rules/ball_state.gd")

var next_id: int = 5000

func spawn_from_event(event: Dictionary) -> Array[BallState]:
	var hazards: Array[BallState] = []
	var count := int(event.get("count", 1))
	var value := int(event.get("value", 5))
	for i in range(count):
		next_id += 1
		var ball := BallState.new_ball(next_id, BallState.Kind.HAZARD, _spawn_position(event.get("angle_hint", "boss_side"), i, count))
		ball.value = value
		ball.hazard_phase = BallState.HazardPhase.WARNING
		hazards.append(ball)
	return hazards

func _spawn_position(angle_hint: String, index: int, count: int) -> Vector2:
	var base_angle := deg_to_rad(-35.0)
	if angle_hint == "wide":
		base_angle = deg_to_rad(-70.0 + 35.0 * index)
	var distance := 520.0
	return Vector2(cos(base_angle), sin(base_angle)) * distance
```

Create `src/playfield/orb_node.gd`:

```gdscript
extends Node2D
class_name OrbNode

const BallState = preload("res://src/rules/ball_state.gd")

var state: BallState
var velocity: Vector2 = Vector2.ZERO

func setup(ball_state: BallState) -> void:
	state = ball_state
	position = state.position
	queue_redraw()

func _process(delta: float) -> void:
	if state == null:
		return
	position += velocity * delta
	velocity = velocity.move_toward(Vector2.ZERO, 260.0 * delta)
	state.position = position
	if velocity.length() < 8.0:
		state.settled = true

func _draw() -> void:
	if state == null:
		return
	var color := Color.WHITE
	if state.kind == BallState.Kind.COLOR:
		color = [Color.RED, Color.DODGER_BLUE, Color.GOLD, Color.LIME_GREEN][max(state.color_id, 0) % 4]
	elif state.kind == BallState.Kind.COMBAT:
		color = Color.MEDIUM_PURPLE
	elif state.kind == BallState.Kind.HAZARD:
		color = Color.ORANGE_RED
	draw_circle(Vector2.ZERO, state.radius, color)
	if state.kind != BallState.Kind.COLOR:
		draw_string(ThemeDB.fallback_font, Vector2(-8, 8), str(state.value), HORIZONTAL_ALIGNMENT_CENTER, 16, 18, Color.WHITE)
```

Create `src/playfield/playfield.gd`:

```gdscript
extends Node2D
class_name Playfield

const BallState = preload("res://src/rules/ball_state.gd")
const OrbNode = preload("res://src/playfield/orb_node.gd")

var balls: Array[BallState] = []
var danger_radius: float = 260.0
var rotation_speed: float = 2.4

func add_ball(ball: BallState) -> void:
	balls.append(ball)
	if is_inside_tree():
		var node := OrbNode.new()
		node.setup(ball)
		add_child(node)

func rotate_settled(angle_delta: float) -> void:
	for ball in balls:
		if ball.settled:
			ball.position = ball.position.rotated(angle_delta)

func check_boundary_explosions() -> Array[BallState]:
	var exploded: Array[BallState] = []
	for ball in balls:
		if ball.kind == BallState.Kind.HAZARD and ball.position.length() > danger_radius:
			exploded.append(ball)
	for ball in exploded:
		balls.erase(ball)
	return exploded
```

- [ ] **Step 4: Run tests to verify they pass**

Run the Godot headless test command.

Expected: PASS with process exit code `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/playfield tests/playfield tests/run_all.gd
git commit -m "feat: add playfield spawning rules"
```

---

### Task 6: Main Scene And Battle UI

**Files:**
- Create: `src/ui/battle_ui.gd`
- Create: `src/game_controller.gd`
- Create: `scenes/main.tscn`
- Modify: `project.godot`

**Interfaces:**
- Consumes: `BattleState`, `SpawnQueue`, `Playfield`, `HazardSpawner`, `BossController`
- Produces: `BattleUI.update_from_state(battle: BattleState, boss_action_ratio: float, preview: Array[BallState]) -> void`
- Produces: playable scene at `res://scenes/main.tscn`

- [ ] **Step 1: Write a scene validation test**

Create `tests/test_main_scene_loads.gd`:

```gdscript
extends RefCounted

func test_main_scene_loads(runner: TestRunner) -> void:
	var packed := load("res://scenes/main.tscn")
	runner.assert_true(packed != null, "main scene resource loads")
	var scene := packed.instantiate()
	runner.assert_true(scene != null, "main scene instantiates")
	scene.queue_free()
```

Update `tests/run_all.gd` to include `TestMainSceneLoads`.

- [ ] **Step 2: Run tests to verify they fail**

Run the Godot headless test command.

Expected: FAIL because `scenes/main.tscn` does not exist.

- [ ] **Step 3: Implement UI and controller scripts**

Create `src/ui/battle_ui.gd`:

```gdscript
extends CanvasLayer
class_name BattleUI

const BallState = preload("res://src/rules/ball_state.gd")
const BattleState = preload("res://src/rules/battle_state.gd")

@onready var player_hp_label: Label = %PlayerHP
@onready var shield_label: Label = %Shield
@onready var boss_hp_label: Label = %BossHP
@onready var boss_action_bar: ProgressBar = %BossActionBar
@onready var preview_label: Label = %Preview
@onready var status_label: Label = %Status

func update_from_state(battle: BattleState, boss_action_ratio: float, preview: Array[BallState]) -> void:
	player_hp_label.text = str(battle.player_hp)
	shield_label.text = "Shield %d" % battle.player_shield if battle.player_shield > 0 else ""
	boss_hp_label.text = "Boss HP %d/%d" % [battle.boss_hp, battle.boss_max_hp]
	boss_action_bar.value = clampf(boss_action_ratio * 100.0, 0.0, 100.0)
	preview_label.text = _preview_text(preview)
	status_label.text = battle.result()

func _preview_text(preview: Array[BallState]) -> String:
	var parts: Array[String] = []
	for ball in preview:
		if ball.kind == BallState.Kind.COLOR:
			parts.append("C%d" % ball.color_id)
		elif ball.kind == BallState.Kind.COMBAT:
			parts.append(["", "ATK", "SHD", "HEAL"][ball.combat_kind])
	return "Next: " + " ".join(parts)
```

Create `src/game_controller.gd`:

```gdscript
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

func _ready() -> void:
	var volley := ActionBarVolleyMechanic.new()
	var phase70 := HpPhaseMechanic.new()
	phase70.threshold_percent = 0.7
	var phase40 := HpPhaseMechanic.new()
	phase40.threshold_percent = 0.4
	var phase15 := HpPhaseMechanic.new()
	phase15.threshold_percent = 0.15
	var counter := BurstCounterMechanic.new()
	boss_controller.configure([volley, phase70, phase40, phase15, counter])
	spawn_queue.seed_preview()
	ui.update_from_state(battle, 0.0, spawn_queue.preview)

func _process(delta: float) -> void:
	if battle.result() != "active":
		ui.update_from_state(battle, boss_controller.action_bar / 6.0, spawn_queue.preview)
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
	ui.update_from_state(battle, boss_controller.action_bar / 6.0, spawn_queue.preview)
```

- [ ] **Step 4: Create main scene**

Create `scenes/main.tscn`:

```ini
[gd_scene load_steps=8 format=3 uid="uid://orb_boss_main"]

[ext_resource type="Script" path="res://src/game_controller.gd" id="1_game"]
[ext_resource type="Script" path="res://src/playfield/playfield.gd" id="2_playfield"]
[ext_resource type="Script" path="res://src/playfield/spawn_queue.gd" id="3_queue"]
[ext_resource type="Script" path="res://src/playfield/hazard_spawner.gd" id="4_hazard"]
[ext_resource type="Script" path="res://src/boss/boss_controller.gd" id="5_boss"]
[ext_resource type="Script" path="res://src/ui/battle_ui.gd" id="6_ui"]

[node name="GameController" type="Node2D"]
script = ExtResource("1_game")

[node name="Playfield" type="Node2D" parent="."]
unique_name_in_owner = true
position = Vector2(420, 360)
script = ExtResource("2_playfield")

[node name="SpawnQueue" type="Node" parent="."]
unique_name_in_owner = true
script = ExtResource("3_queue")

[node name="HazardSpawner" type="Node" parent="."]
unique_name_in_owner = true
script = ExtResource("4_hazard")

[node name="BossController" type="Node" parent="."]
unique_name_in_owner = true
script = ExtResource("5_boss")

[node name="BattleUI" type="CanvasLayer" parent="."]
unique_name_in_owner = true
script = ExtResource("6_ui")

[node name="PlayerHP" type="Label" parent="BattleUI"]
unique_name_in_owner = true
offset_left = 386.0
offset_top = 330.0
offset_right = 454.0
offset_bottom = 382.0
theme_override_font_sizes/font_size = 42
horizontal_alignment = 1
text = "30"

[node name="Shield" type="Label" parent="BattleUI"]
unique_name_in_owner = true
offset_left = 350.0
offset_top = 386.0
offset_right = 490.0
offset_bottom = 410.0
horizontal_alignment = 1
text = ""

[node name="BossHP" type="Label" parent="BattleUI"]
unique_name_in_owner = true
offset_left = 900.0
offset_top = 54.0
offset_right = 1180.0
offset_bottom = 86.0
text = "Boss HP 200/200"

[node name="BossActionBar" type="ProgressBar" parent="BattleUI"]
unique_name_in_owner = true
offset_left = 900.0
offset_top = 94.0
offset_right = 1180.0
offset_bottom = 118.0
max_value = 100.0
value = 0.0
show_percentage = false

[node name="Preview" type="Label" parent="BattleUI"]
unique_name_in_owner = true
offset_left = 40.0
offset_top = 28.0
offset_right = 640.0
offset_bottom = 58.0
text = "Next:"

[node name="Status" type="Label" parent="BattleUI"]
unique_name_in_owner = true
offset_left = 900.0
offset_top = 130.0
offset_right = 1180.0
offset_bottom = 160.0
text = "active"
```

Set `project.godot`:

```ini
[application]

run/main_scene="res://scenes/main.tscn"
```

- [ ] **Step 5: Run tests to verify they pass**

Run the Godot headless test command.

Expected: PASS with process exit code `0`.

- [ ] **Step 6: Commit**

```powershell
git add src/ui src/game_controller.gd scenes/main.tscn project.godot tests/test_main_scene_loads.gd tests/run_all.gd
git commit -m "feat: add playable battle scene shell"
```

---

### Task 7: Runtime Chain Resolution And Combat Effects

**Files:**
- Modify: `src/game_controller.gd`
- Modify: `src/rules/chain_resolver.gd`
- Create: `tests/rules/test_chain_resolution_results.gd`
- Modify: `tests/run_all.gd`

**Interfaces:**
- Consumes: `ChainResolver.apply_chain_influence`
- Produces: `ChainResolver.resolve_finished_chains(chains: Array, balls: Array[BallState]) -> Dictionary`
- Produces result dictionary keys `attack`, `shield`, `heal`, `cleared_color_ids`, `removed_ball_ids`

- [ ] **Step 1: Write failing result tests**

Create `tests/rules/test_chain_resolution_results.gd`:

```gdscript
extends RefCounted

const BallState = preload("res://src/rules/ball_state.gd")
const ChainResolver = preload("res://src/rules/chain_resolver.gd")

func test_finished_chain_converts_combat_values_to_results(runner: TestRunner) -> void:
	var resolver := ChainResolver.new()
	var attack := BallState.new_ball(20, BallState.Kind.COMBAT, Vector2(30, 0))
	attack.combat_kind = BallState.CombatKind.ATTACK
	attack.value = 9
	var shield := BallState.new_ball(21, BallState.Kind.COMBAT, Vector2(60, 0))
	shield.combat_kind = BallState.CombatKind.SHIELD
	shield.value = 4
	var chain := {"color_id": 1, "members": [], "strength": 5}
	for i in range(5):
		var color := BallState.new_ball(i, BallState.Kind.COLOR, Vector2(i * 20, 0))
		color.color_id = 1
		color.flashing = true
		chain.members.append(color)
	var result := resolver.resolve_finished_chains([chain], [attack, shield])
	runner.assert_eq(result.attack, 9, "attack value is emitted")
	runner.assert_eq(result.shield, 4, "shield value is emitted")
	runner.assert_true(result.removed_ball_ids.has(20), "triggered attack orb removed")
	runner.assert_true(result.removed_ball_ids.has(21), "triggered shield orb removed")
```

Update `tests/run_all.gd` to include `TestChainResolutionResults`.

- [ ] **Step 2: Run tests to verify they fail**

Run the Godot headless test command.

Expected: FAIL because `resolve_finished_chains` does not exist.

- [ ] **Step 3: Implement chain resolution results**

Add to `src/rules/chain_resolver.gd`:

```gdscript
func resolve_finished_chains(chains: Array, balls: Array[BallState]) -> Dictionary:
	var result := {
		"attack": 0,
		"shield": 0,
		"heal": 0,
		"cleared_color_ids": [],
		"removed_ball_ids": []
	}
	for chain in chains:
		for member in chain.members:
			result.cleared_color_ids.append(member.id)
	for ball in balls:
		if ball.kind != BallState.Kind.COMBAT or ball.value <= 0:
			continue
		if not _is_touched_by_any_chain(chains, ball):
			continue
		if ball.combat_kind == BallState.CombatKind.ATTACK:
			result.attack += ball.value
		elif ball.combat_kind == BallState.CombatKind.SHIELD:
			result.shield += ball.value
		elif ball.combat_kind == BallState.CombatKind.HEAL:
			result.heal += ball.value
		result.removed_ball_ids.append(ball.id)
	return result

func _is_touched_by_any_chain(chains: Array, target: BallState) -> bool:
	for chain in chains:
		if _chain_touches_ball(chain, target):
			return true
	return false
```

Modify `src/game_controller.gd` by adding these fields near the existing `battle` and `chain_resolver` fields:

```gdscript
var active_chains: Array = []
var chain_timer: float = 0.0
var chain_flash_seconds: float = 1.2
```

Replace the bottom of `_process(delta)` after boundary explosion handling with:

```gdscript
	_tick_chains(delta)
	ui.update_from_state(battle, boss_controller.action_bar / 6.0, spawn_queue.preview)
```

Add these helper functions to `src/game_controller.gd`:

```gdscript
func _tick_chains(delta: float) -> void:
	if active_chains.is_empty():
		active_chains = chain_resolver.start_flash_groups(playfield.balls)
		chain_timer = chain_flash_seconds if not active_chains.is_empty() else 0.0
	if active_chains.is_empty():
		return
	chain_resolver.apply_chain_influence(active_chains, playfield.balls)
	chain_timer -= delta
	if chain_timer > 0.0:
		return
	var result := chain_resolver.resolve_finished_chains(active_chains, playfield.balls)
	_apply_chain_result(result)
	active_chains.clear()
	chain_timer = 0.0

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
```

- [ ] **Step 4: Run tests to verify they pass**

Run the Godot headless test command.

Expected: PASS with process exit code `0`.

- [ ] **Step 5: Launch scene smoke test**

Run:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --quit-after 2
```

Expected: Process exits with code `0`, no script parse errors.

- [ ] **Step 6: Commit**

```powershell
git add src/game_controller.gd src/rules/chain_resolver.gd tests/rules/test_chain_resolution_results.gd tests/run_all.gd
git commit -m "feat: resolve combat chain effects"
```

---

### Task 8: Visual Polish Pass And Final Verification

**Files:**
- Modify: `src/playfield/orb_node.gd`
- Modify: `src/playfield/playfield.gd`
- Modify: `src/ui/battle_ui.gd`
- Modify: `src/game_controller.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes all prior runtime interfaces.
- Produces readable prototype demo with original circular field, boss area, HP center, shield display, preview list, action bar, hazard feedback, and no Nintendo-owned presentation.

- [ ] **Step 1: Add visible prototype field and boss-area drawing**

Update `Playfield._draw()` to draw original rings:

```gdscript
func _draw() -> void:
	draw_circle(Vector2.ZERO, danger_radius, Color(0.9, 0.1, 0.1, 0.12))
	draw_arc(Vector2.ZERO, danger_radius, 0.0, TAU, 128, Color(0.9, 0.2, 0.2), 3.0)
	draw_arc(Vector2.ZERO, danger_radius * 0.72, 0.0, TAU, 128, Color(0.2, 0.8, 1.0), 2.0)
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var inner := Vector2(cos(angle), sin(angle)) * 42.0
		var outer := Vector2(cos(angle), sin(angle)) * 68.0
		draw_line(inner, outer, Color(0.7, 0.9, 1.0, 0.85), 2.0)
```

Update `scenes/main.tscn` by adding these boss-area nodes under `BattleUI`:

```ini
[node name="BossPanel" type="ColorRect" parent="BattleUI"]
offset_left = 860.0
offset_top = 24.0
offset_right = 1240.0
offset_bottom = 700.0
color = Color(0.16, 0.08, 0.12, 0.82)

[node name="BossName" type="Label" parent="BattleUI"]
offset_left = 900.0
offset_top = 180.0
offset_right = 1180.0
offset_bottom = 214.0
theme_override_font_sizes/font_size = 24
horizontal_alignment = 1
text = "Resonance Warden"

[node name="BossBody" type="ColorRect" parent="BattleUI"]
offset_left = 960.0
offset_top = 250.0
offset_right = 1120.0
offset_bottom = 500.0
color = Color(0.45, 0.12, 0.2, 1.0)
```

- [ ] **Step 2: Add orb feedback drawing**

Update `OrbNode._draw()` so flashing color orbs pulse, combat/hazard numbers are readable, warning hazards are orange, danger hazards are red, and combat orb type has a small text label `ATK`, `SHD`, or `HEAL`.

- [ ] **Step 3: Add UI shield marks**

Update `BattleUI.update_from_state` to show shield marks with repeated `|` characters capped at 20 visible marks:

```gdscript
var marks := min(battle.player_shield, 20)
shield_label.text = "".rpad(marks, "|") if marks > 0 else ""
```

- [ ] **Step 4: Run automated tests**

Run:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Expected: PASS with process exit code `0`.

- [ ] **Step 5: Run scene smoke test**

Run:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --quit-after 3
```

Expected: Process exits with code `0`, no script parse errors.

- [ ] **Step 6: Manual play check**

Run:

```powershell
Start-Process -WindowStyle Hidden 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64.exe' -ArgumentList '--path D:\ProjectCI_Git\project-mp'
```

Check:

- `A` and `D` rotate the settled orb pile.
- `Space` fast-drops only player-side color/combat orbs.
- Boss action bar spawns hazard orbs independently.
- Player HP appears in the circular field center.
- Shield marks appear only after shield gain.
- Boss area is visually separate from playfield area.
- No Nintendo-owned art, names, UI, music, sound effects, conveyor belt, original disk shape, or character motifs are present.

- [ ] **Step 7: Commit**

```powershell
git add src/playfield src/ui src/game_controller.gd scenes/main.tscn
git commit -m "feat: polish playable orb boss prototype"
```

---

## Final Verification

After all tasks:

```powershell
git status --short --branch
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --quit-after 3
```

Expected:

- `git status` shows the implementation branch state clearly.
- All tests pass with exit code `0`.
- Scene smoke test exits with code `0`.
- The demo can be opened in Godot 4.7 and played with `A`, `D`, and `Space`.

## Spec Coverage Self-Review

- Core loop: covered by Tasks 3, 5, 6, and 7.
- Original visual direction and split screen: covered by Tasks 6 and 8.
- Free-form playfield and rotating settled pile: covered by Task 5.
- Player-side preview list and fast drop: covered by Tasks 5 and 6.
- Boss hazards excluded from player preview and fast drop: covered by Task 5 tests.
- Color chain detection and flashing window foundation: covered by Tasks 3 and 7.
- Multi-chain stacking into combat and hazard orbs: covered by Task 3 tests.
- Combat orb trigger results: covered by Task 7.
- Player HP, shield, boss HP, action bar: covered by Tasks 2, 4, 6, and 8.
- Modular boss mechanics: covered by Task 4.
- Hazard warning/danger phases and boundary explosions: covered by Task 5, with visual/state polish in Task 8.
- Copyright avoidance: covered by Global Constraints and Task 8 manual check.
