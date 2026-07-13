# Fast Drop Spawn Lane Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent repeated fast-drop input from spawning active player orbs on top of each other.

**Architecture:** Keep fast-drop release immediate, but move player-side spawn preparation through a playfield clearance helper. The helper returns the nearest outward position on the configured radial spawn lane that does not overlap active falling orbs. The spacing is configured through `OrbTuning`.

**Tech Stack:** Godot 4.7 Mono project, GDScript resources, existing custom 2D orb solver, existing `tests/run_all.gd` runner.

## Global Constraints

- Use Godot 4.7 Mono.
- Preserve immediate fast-drop behavior: Space accelerates active falling orbs and starts the next preview orb.
- Player color/combat orbs use player spawn-lane clearance.
- Hazard orbs keep authored hazard entry positions.
- Add tests before production code changes.
- Do not open a duplicate Godot editor; use headless console verification.

---

### Task 1: Regression Test For Fast-Drop Spawn Spacing

**Files:**
- Modify: `tests/test_game_controller_runtime.gd`

**Interfaces:**
- Consumes: `GameController.advance_player_orb_spawn(delta: float)`, `GameController.handle_player_fast_drop()`, `Playfield.balls`.
- Produces: A failing regression test that detects overlapping active falling orbs after repeated fast-drop release.

- [ ] **Step 1: Write the failing test**

Add this test near the existing fast-drop tests:

```gdscript
func test_repeated_fast_drop_keeps_new_player_orbs_out_of_occupied_spawn_lane(runner: TestRunner) -> void:
	var controller := _instantiate_controller(runner)
	if controller == null:
		return
	controller.playfield.balls = []

	controller.advance_player_orb_spawn(controller.player_auto_drop_seconds)
	controller.handle_player_fast_drop()
	controller.handle_player_fast_drop()

	var active_orbs: Array[BallState] = []
	for ball in controller.playfield.balls:
		if ball.has_settle_target and not ball.settled and not ball.board_attached:
			active_orbs.append(ball)

	for i in range(active_orbs.size()):
		for j in range(i + 1, active_orbs.size()):
			var first := active_orbs[i]
			var second := active_orbs[j]
			var minimum_distance := first.radius + second.radius - 0.1
			runner.assert_true(
				first.position.distance_to(second.position) >= minimum_distance,
				"repeated fast-drop release keeps active falling orbs from overlapping before board contact"
			)
	_destroy_controller(controller)
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Expected: FAIL on the new repeated fast-drop overlap assertion.

### Task 2: Spawn-Lane Clearance Implementation

**Files:**
- Modify: `src/config/orb_tuning.gd`
- Modify: `data/orb_tuning.tres`
- Modify: `src/playfield/playfield.gd`
- Modify: `src/game_controller.gd`
- Test: `tests/test_game_controller_runtime.gd`

**Interfaces:**
- Consumes: `OrbTuning.player_spawn_position`, `BallState.radius`, `Playfield.balls`.
- Produces: `Playfield.clear_player_spawn_position(spawn_position: Vector2, radius: float, padding: float) -> Vector2`.

- [ ] **Step 1: Add tuning fields**

Add to `src/config/orb_tuning.gd`:

```gdscript
@export var player_spawn_lane_padding: float = 6.0
@export var player_spawn_lane_max_steps: int = 8
```

Add matching values to `data/orb_tuning.tres`:

```gdscript
player_spawn_lane_padding = 6.0
player_spawn_lane_max_steps = 8
```

- [ ] **Step 2: Add playfield helper**

Add this method to `src/playfield/playfield.gd`:

```gdscript
func clear_player_spawn_position(spawn_position: Vector2, radius: float, padding: float, max_steps: int = 8) -> Vector2:
	var outward := _safe_direction(spawn_position)
	var step_distance := radius * 2.0 + padding
	var candidate := spawn_position
	for step in range(maxi(max_steps, 1)):
		if _spawn_position_has_clearance(candidate, radius, padding):
			return candidate
		candidate = spawn_position + outward * step_distance * float(step + 1)
	return candidate
```

Add this private helper:

```gdscript
func _spawn_position_has_clearance(candidate: Vector2, radius: float, padding: float) -> bool:
	for other in balls:
		if other.settled or other.board_attached:
			continue
		if not other.has_settle_target:
			continue
		var minimum_distance := radius + other.radius + padding
		if candidate.distance_to(other.position) < minimum_distance:
			return false
	return true
```

- [ ] **Step 3: Use helper for player entries**

Change `_prepare_player_entry(ball)` in `src/game_controller.gd` to:

```gdscript
func _prepare_player_entry(ball: BallState) -> void:
	var spawn_position := orb_tuning.player_spawn_position
	if playfield != null:
		spawn_position = playfield.clear_player_spawn_position(
			spawn_position,
			ball.radius,
			orb_tuning.player_spawn_lane_padding,
			orb_tuning.player_spawn_lane_max_steps
		)
	ball.position = spawn_position
	ball.entry_duration_seconds = orb_tuning.player_entry_seconds
```

- [ ] **Step 4: Run regression test**

Run:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Expected: all tests pass, including the new regression.

### Task 3: Verification And Commit

**Files:**
- Verify all modified files.
- Commit docs, tests, and implementation.

**Interfaces:**
- Consumes: Task 1 and Task 2 output.
- Produces: One commit containing the fix.

- [ ] **Step 1: Run full tests**

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Expected: all tests pass.

- [ ] **Step 2: Smoke-load project**

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --quit-after 2
```

Expected: exit code 0.

- [ ] **Step 3: Commit and push**

```powershell
git add docs/superpowers/specs/2026-07-13-fast-drop-spawn-lane-design.md docs/superpowers/plans/2026-07-13-fast-drop-spawn-lane.md tests/test_game_controller_runtime.gd src/config/orb_tuning.gd data/orb_tuning.tres src/playfield/playfield.gd src/game_controller.gd
git commit -m "fix: space fast-dropped orb spawns"
git push
```
