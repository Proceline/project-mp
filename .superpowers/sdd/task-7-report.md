Status: DONE

Files changed:
- src/game_controller.gd
- src/rules/chain_resolver.gd
- tests/rules/test_chain_resolution_results.gd
- tests/run_all.gd

Commits:
- d8a0a44 feat: resolve combat chain effects

Exact test commands:
1. Red verification:
   ```powershell
   & 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path 'D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo' --script res://tests/run_all.gd
   ```
2. Green verification:
   ```powershell
   & 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path 'D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo' --script res://tests/run_all.gd
   ```

Exact test result/output summary:
- Initial red run first hit compile-time issues in the new test; after correcting the test typing, the red run produced:
  - `SCRIPT ERROR: Invalid call. Nonexistent function 'resolve_finished_chains' in base 'RefCounted (ChainResolver)'.`
- Green run exited with code 0 and only printed the Godot engine banner, with no script errors.

Scene smoke result:
- Command:
  ```powershell
  & 'D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe' --headless --path 'D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo' --quit-after 2
  ```
- Result: exited with code 0, no script parse errors.

Self-review notes:
- Preserved earlier multi-chain stacking by leaving `apply_chain_influence` additive across chains.
- Applied chain influence once per flash window in `GameController` to avoid per-frame value inflation during the countdown.
- Triggered combat orbs are removed from both `playfield.balls` and their orb nodes after applying attack/shield/heal.
- Boss counter hooks are preserved by calling `boss_controller.notify_player_damage(attack)` when chain-triggered attack damage lands.

Task 7 review fix note:
- Added a deterministic `GameController.advance_chain_resolution(delta)` entry point and covered the runtime flash-window path with automated tests for attack, shield, heal, orb removal, and boss notification state.

Review fix verification:
- Red verification:
  - Command: `D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe --headless --path D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo --script res://tests/run_all.gd`
  - Output summary: exited with a script error before the fix, `Invalid call. Nonexistent function 'advance_chain_resolution' in base 'Node2D (GameController)'`.
- Green verification:
  - Command: `D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe --headless --path D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo --script res://tests/run_all.gd`
  - Output summary: exited with code 0 and only printed the Godot engine banner, with no script errors.
- Scene smoke:
  - Command: `D:\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe --headless --path D:\ProjectCI_Git\project-mp\.worktrees\pve-orb-boss-demo --quit-after 2`
  - Output summary: exited with code 0 and only printed the Godot engine banner, with no script errors.
