# Project Notes for AI Agents

## Current Stable Prototype Node

- Stable checkpoint: `e7ad9d0 feat: use v09 stacked boss bar shell`
- This is the current rollback/reference point for the Godot prototype after the v04 runtime orb visual pass, chain/pacing rule pass, hazard lifecycle tuning, orb visual rotation pass, fast-drop spawn-lane stability pass, GDScript reload-warning cleanup, v05 layout art pass, grouped battle UI roots, and stacked Boss HP / Boss Action UI pass: color-chain combat effects, flashing chains that absorb late same-color members with tunable timer extension, configurable color-orb generation, tuned warning/danger hazard behavior, contact-only rolling visual offsets, shared-queue hazard/fast-drop behavior, player fast-drop spawn-lane spacing that treats attached orbs as blockers, themed board/background rendering, v04 runtime orb body/glow sprites aligned to gameplay radius, clean headless reload output, editor-adjustable UI roots, clipped stacked Boss Action fill/warning/glow behavior, and the v09 stacked Boss HP / Boss Action shell with a separately clipped dynamic HP fill that is visible before gameplay starts.

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

## GDScript Maintenance Notes

- Many scripts use `class_name`; those classes are global in Godot. Do not reintroduce same-name `const Foo = preload(...)` aliases for global classes, because Godot reports them as reload warnings.
- Avoid names that shadow Godot built-ins such as `seed`, `size`, and `modulate`; use explicit names such as `random_seed`, `text_size`, `texture_size`, or `tint`.
- Intentionally unused function parameters should be prefixed with `_` to keep reload output clean.

## Orb Behavior Notes

- The main preview queue should naturally generate color orbs. Tactical combat orbs have been removed from normal play.
- Tactical combat orbs can be manually inserted into the main preview queue.
- Boss hazard events insert hazard orbs into the shared preview queue. They should not add hazards directly to the playfield.
- Player fast-drop releases the current preview head, including hazard orbs.
- Player fast-drop accelerates currently falling orbs, including hazard orbs, then immediately starts the next preview orb. It should not instantly settle or teleport the current orb.
- Player-side fast-drop spawning uses spawn-lane clearance. New player orbs should be placed farther outward on the same entry ray when another orb already occupies the lane, including `board_attached && !settled` orbs.
- The preview queue should render as orb icons, not text codes such as `C0` or `DMG5`.
- Falling orbs move toward the center until they contact the core isolation ring or the orb pile.
- Orb visuals face the center by default based on current board position. Falling movement and board rotation do not add roll offset; contact sliding adds signed roll offset based on tangent direction.
- Orbs touching the core isolation ring are locked.
- A single orb support should not lock another orb unless the support is the core isolation ring; one-point ball support should slide inward when possible.
- Releasing/recomputing unsupported locked orbs should generally happen after board-changing events such as chain clears or explosions, not as constant global jitter.

## Chain and Hazard Rules

- Five or more connected same-color orbs start flashing.
- Resolved color chains directly produce color-specific combat effects; combat orbs are no longer part of normal play.
- Red chains deal 2 boss damage per orb.
- Blue chains deal 1 boss damage per orb and grant hazard mitigation, which reduces damage from clearing danger hazard orbs. Unused mitigation can carry forward.
- Yellow chains deal 0 direct damage and grant next-hit vulnerability. The next positive boss damage consumes stored yellow vulnerability.
- Green chains deal 1 boss damage per orb and heal the player for half of that chain damage.
- While flashing, additional same-color orbs can still join and increase the chain effect. New members extend the flash window by a tunable amount, capped by a tunable maximum.
- Tactical combat orbs remain in compatibility code, but normal play does not seed, insert, charge, or render them.
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
