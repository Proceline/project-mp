# Project Notes for AI Agents

## Current Stable Prototype Node

- Stable checkpoint: `e677369 feat: tune hazards and orb rolling visuals`
- This is the current rollback/reference point for the Godot prototype after the v04 runtime orb visual pass, chain/pacing rule pass, hazard lifecycle tuning, and orb visual rotation pass: baseline color-chain boss damage, flashing chains that absorb late same-color members with tunable timer extension, configurable color-orb generation, tuned warning/danger hazard behavior, contact-only rolling visual offsets, a separate tactical combat orb queue, shared-queue hazard/fast-drop behavior, themed board/background rendering, and v04 runtime orb body/glow sprites aligned to gameplay radius.

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

- The main preview queue should naturally generate color orbs. Combat orbs come from the separate tactical queue.
- Tactical combat orbs can be manually inserted into the main preview queue.
- Boss hazard events insert hazard orbs into the shared preview queue. They should not add hazards directly to the playfield.
- Player fast-drop releases the current preview head, including hazard orbs.
- Player fast-drop accelerates currently falling orbs, including hazard orbs, then immediately starts the next preview orb. It should not instantly settle or teleport the current orb.
- The preview queue should render as orb icons, not text codes such as `C0` or `DMG5`.
- Falling orbs move toward the center until they contact the core isolation ring or the orb pile.
- Orb visuals face the center by default based on current board position. Falling movement and board rotation do not add roll offset; contact sliding adds signed roll offset based on tangent direction.
- Orbs touching the core isolation ring are locked.
- A single orb support should not lock another orb unless the support is the core isolation ring; one-point ball support should slide inward when possible.
- Releasing/recomputing unsupported locked orbs should generally happen after board-changing events such as chain clears or explosions, not as constant global jitter.

## Chain and Hazard Rules

- Five or more connected same-color orbs start flashing.
- Resolved color chains deal baseline boss damage equal to chain strength, even without combat orbs.
- While flashing, additional same-color orbs can still join and increase the chain effect. New members extend the flash window by a tunable amount, capped by a tunable maximum.
- Combat orbs start at value `0`; nearby flashing color chains increase their value.
- A combat orb near multiple flashing chains stacks all nearby chain contributions.
- Hazard orbs have a value and phase:
  - Warning phase starts when the hazard contacts the board. Warning hazards show no number, and clearing one removes it without player damage.
  - Danger phase starts after the configured warning duration. Danger hazards start at the configured value, show that value, grow on the configured interval up to the configured cap, and clearing one deals damage equal to its visible value.
  - If an on-board hazard orb moves outside the danger boundary, it explodes, is removed, and deals the configured boundary explosion damage.
- Falling hazard orbs should not deal boundary damage before contacting the board.
- Tunable orb values live in `data/orb_tuning.tres` through `src/config/orb_tuning.gd`; use this for preview insert index, entry angles, entry distance, entry duration, chain extension timing, the configurable color generator resource, and the hazard tuning resource (`data/hazard_tuning_default.tres` / `src/config/hazard_tuning.gd`).

## Verification Commands

Run all tests:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --script res://tests/run_all.gd
```

Smoke-load the project:

```powershell
& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path D:\ProjectCI_Git\project-mp --quit-after 2
```
