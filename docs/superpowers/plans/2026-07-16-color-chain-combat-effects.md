# Color Chain Combat Effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the tactical combat-orb burden from the core loop by giving each color chain a direct combat effect.

**Architecture:** Keep `BallState.Kind.COLOR` and the existing chain flashing flow. Move combat output into `ChainResolver.resolve_finished_chains()` based on `color_id`, then let `GameController._apply_chain_result()` apply boss damage, healing, and hazard mitigation counters. Tactical combat orbs can remain in code for compatibility but should no longer be seeded, inserted, or rendered in normal play.

**Tech Stack:** Godot 4.7 Mono, GDScript, existing headless test runner.

## Global Constraints

- Preserve existing color-chain flashing, late-join extension, board-attached semantics, and hazard warning/danger lifecycle.
- Do not introduce new UI art in this pass.
- New numerical effects must live behind named constants so they can later move into tuning resources.
- Verify with the project Godot console test command and smoke-load command.

---

### Task 1: Add Color-Chain Combat Result Rules

**Files:**
- Modify: `src/rules/chain_resolver.gd`
- Modify: `tests/rules/test_chain_resolver.gd`
- Modify: `tests/test_game_controller_runtime.gd`

**Interfaces:**
- Consumes: `BallState.color_id`, chain dictionaries with `color_id`, `members`, and `strength`.
- Produces: result keys `attack`, `heal`, `hazard_mitigation`, `yellow_vulnerability`, `cleared_color_ids`, `removed_ball_ids`, and `player_damage`.

- [ ] **Step 1: Write failing tests**
  - Red chain of 5 deals 10 boss damage.
  - Green chain of 6 deals 6 damage and heals 3.
  - Blue chain grants hazard mitigation that reduces danger hazard clear damage.
  - Yellow chain deals 0 damage and stores vulnerability for the next damaging chain.

- [ ] **Step 2: Run tests and confirm red**
  - Run the full Godot test command.
  - Expected: tests fail because chain results still use old baseline damage and no yellow/blue/green color effects.

- [ ] **Step 3: Implement minimal resolver/controller changes**
  - Add color constants and chain effect constants.
  - Calculate direct color effects at chain resolution.
  - Apply stored yellow vulnerability to the next positive attack.
  - Apply blue mitigation to danger-hazard clear damage.

- [ ] **Step 4: Run tests and confirm green**
  - Run the full Godot test command.
  - Expected: all tests pass.

### Task 2: Remove Tactical Combat Orbs From Normal Play

**Files:**
- Modify: `src/game_controller.gd`
- Modify: `src/playfield/tactical_queue.gd`
- Modify: `tests/test_game_controller_runtime.gd`
- Modify: `tests/test_main_scene_loads.gd`

**Interfaces:**
- Consumes: `tactical_queue.slots`, `GameController.insert_tactical_combat_orb()`, `BattleUI.update_from_state(...)`.
- Produces: empty tactical queue in normal play and no tactical insert effect.

- [ ] **Step 1: Write failing tests**
  - Fresh controller has no tactical combat slots.
  - Tactical insert returns `false` and does not add combat orbs to preview.
  - Tactical UI row starts empty.

- [ ] **Step 2: Run tests and confirm red**
  - Run the full Godot test command.
  - Expected: tests fail while tactical slots still seed combat orbs.

- [ ] **Step 3: Implement minimal tactical removal**
  - Make tactical queue seed no slots by default.
  - Make tactical insertion a no-op for normal play.
  - Keep class available to avoid breaking scene wiring.

- [ ] **Step 4: Run tests and confirm green**
  - Run the full Godot test command.
  - Expected: all tests pass.

### Task 3: Verification And Stable Commit

**Files:**
- Modify: `AGENTS.md` only if the user asks to record this as a stable node after testing.

- [ ] **Step 1: Run full tests**
  - `& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd`

- [ ] **Step 2: Run smoke-load**
  - `& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --quit-after 2`

- [ ] **Step 3: Check diff**
  - `git diff --check`

- [ ] **Step 4: Commit and push**
  - Commit with `feat: move combat effects onto color chains`.
