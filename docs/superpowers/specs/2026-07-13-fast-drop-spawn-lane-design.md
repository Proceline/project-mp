# Fast Drop Spawn Lane Design

## Goal

Prevent repeated fast-drop input from creating two active falling orbs at the same or nearly same spawn position, which can make them appear stuck together until a later orb perturbs the pile.

## Root Cause Summary

`GameController.handle_player_fast_drop()` accelerates all active falling orbs and immediately releases the next preview orb. Player-side orbs are always prepared at `OrbTuning.player_spawn_position`. When Space is pressed repeatedly before the previous orb has cleared that spawn lane, two active orbs can begin from overlapping or near-overlapping positions.

The contact solver has sweep detection for fast motion and a defensive penetrating-contact branch, but it is not intended to be the primary solution for invalid spawn states. Once two moving orbs overlap before clean contact, their movement can resolve inconsistently because each active orb sees the other as a blocker while both are still trying to enter the board.

## Design

Add spawn-lane spacing before a player-side orb is added to the playfield. The release should keep the current fast-drop feel: pressing Space accelerates current falling orbs and starts the next orb immediately. If the configured spawn point is occupied by an active orb, the new orb is placed farther outward on the same radial entry line until it has clearance from other active falling orbs.

The spacing distance should be tunable in `OrbTuning`, matching the existing ScriptableObject-like resource pattern. The default should be conservative: one orb diameter plus a small padding.

Hazard orbs keep their configured entry position because they already encode boss-side entry angles and distances when inserted into the shared preview queue. If a hazard is manually fast-dropped from the queue, it still uses its authored hazard entry point.

## Testing

Add a regression test that releases a player orb, triggers repeated fast-drop releases without waiting for full settle, and verifies no two active falling orbs overlap at spawn time. Add a lower-level playfield test for the spawn-lane clearance helper so the behavior is stable without relying only on scene runtime timing.

## Non-Goals

- Do not delay releasing the next orb while the spawn point is occupied.
- Do not convert the custom circle solver to Godot rigid-body collision.
- Do not alter hazard entry placement in this pass.
