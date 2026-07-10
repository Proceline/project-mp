Status: DONE

Files changed:
- `src/playfield/spawn_queue.gd`
- `src/playfield/hazard_spawner.gd`
- `src/playfield/orb_node.gd`
- `src/playfield/playfield.gd`
- `tests/playfield/test_spawn_and_hazards.gd`
- `tests/run_all.gd`

Commits:
- `a6c3921` `feat: add playfield spawning rules`

Exact test commands:
- `& 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path 'D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo' --script res://tests/run_all.gd`

Exact test result/output summary:
- Red run: failed to load `res://src/playfield/spawn_queue.gd`, `res://src/playfield/hazard_spawner.gd`, and `res://src/playfield/playfield.gd` because the files did not exist yet.
- Green run: exited with code `0` and printed only the Godot banner.

Self-review notes:
- Player-side preview and fast drop now stay on player orb kinds only.
- Hazard spawning is isolated in `HazardSpawner` and produces warning-phase hazard balls from events.
- `Playfield.check_boundary_explosions()` removes hazard balls outside `danger_radius`.
- Tests free their `Node` instances to keep the headless run clean.

Task 5 review-fix verification:
- Exact test command: `D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe --headless --path D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo --script res://tests/run_all.gd`
- Exact output summary: exited with code `0` and printed only `Godot Engine v4.7.stable.mono.official.5b4e0cb0f - https://godotengine.org`
