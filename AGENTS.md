# Project Notes for AI Agents

## Current Stable Prototype Node

- Stable checkpoint: `1a6a7d9 fix: let board-attached orbs participate in rules`
- This is the current rollback/reference point for the Godot prototype after the first major orb physics and rule-state pass.

## Project Context

- Godot version: 4.7 Mono.
- Local Godot executable folder:
  `D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64`
- Repository remote:
  `https://github.com/Proceline/project-mp.git`

## Game Direction

- The prototype is inspired by the feel of Mario Party's Stick and Spin, but must avoid Nintendo-specific presentation, naming, and assets.
- Core game mode is PvE boss combat.
- The playfield is a circular board with a central HP/core area and an isolation ring.
- The screen is split between the orb board and a boss presentation area.
- Boss mechanics should stay decoupled so future bosses can combine and modify attack patterns easily.

## Important Rule Semantics

- `settled` means physically locked/stable.
- `board_attached` means the orb has contacted the board structure or orb pile and should rotate with the board.
- `BallState.is_on_board()` means `settled or board_attached`.
- Gameplay rules should usually use `is_on_board()`, not only `settled`.
- Pure falling orbs have `settled == false` and `board_attached == false`; they should not rotate with the disk and should not trigger chain or hazard boundary rules.

## Orb Behavior Notes

- Player-side orbs and combat orbs can be fast-dropped.
- Boss hazard orbs are spawned by boss mechanics, not from the normal player preview queue.
- Falling orbs move toward the center until they contact the core isolation ring or the orb pile.
- Orbs touching the core isolation ring are locked.
- A single orb support should not lock another orb unless the support is the core isolation ring; one-point ball support should slide inward when possible.
- Releasing/recomputing unsupported locked orbs should generally happen after board-changing events such as chain clears or explosions, not as constant global jitter.

## Chain and Hazard Rules

- Five or more connected same-color orbs start flashing.
- While flashing, additional same-color orbs can still join and increase the chain effect.
- Combat orbs start at value `0`; nearby flashing color chains increase their value.
- A combat orb near multiple flashing chains stacks all nearby chain contributions.
- Hazard orbs have a value and phase:
  - Warning phase: clearing removes it without player damage.
  - Danger phase: clearing removes it and deals its stored player damage.
  - If an on-board hazard orb moves outside the danger boundary, it explodes, is removed, and deals its stored damage.
- Falling hazard orbs should not deal boundary damage before contacting the board.

## Verification Commands

Run all tests:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Smoke-load the project:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --quit-after 2
```
