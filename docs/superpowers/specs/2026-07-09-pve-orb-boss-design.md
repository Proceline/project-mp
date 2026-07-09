# PVE Orb Boss Design

Date: 2026-07-09

## Goal

Build a playable Godot boss battle demo based on an original circular orb-combat system. The game uses the abstract idea of a rotating circular attraction field, connected color groups, numbered orb interactions, and timed clearing windows, but avoids Nintendo-owned names, characters, art direction, UI, music, sound effects, and specific presentation.

The first demo should prove the core loop:

1. Rotate the central circular field.
2. Place incoming player-side orbs from a visible preview list.
3. Create connected groups of 5 or more same-color orbs.
4. Use the flashing clear window to extend chains and amplify adjacent numbered orbs.
5. Trigger combat orbs to damage the boss, create shields, or restore HP.
6. Manage boss hazard orbs from action-bar and event attacks.
7. Win by reducing boss HP to 0 before player HP reaches 0.

## Visual Direction

The central object is not a "magnetic disk." It is an original circular attraction focus, such as a rune circle, astral ring, energy seal, resonance core, or similar fantasy/sci-fi device. The exact theme can change later, but the demo should avoid mechanical conveyor belts, the original disk shape, original UI language, and Nintendo-like character or environment motifs.

The screen is split into two gameplay areas:

- Playfield area: central circular field, orb pile, safe boundary, danger boundary, player-side preview list, and incoming player-side orbs.
- Boss area: prototype boss art, boss HP, boss action bar, attack warnings, hit reactions, and attack/phase effects.

The center of the circular field displays player HP. Marks or cells around the center can display shield value. Shield display is optional when shield is 0 and may fade out or hide.

## Core Feel

The playfield should feel like a free-form orb pile, not a grid.

Incoming orbs fly in from outside the playfield and are pulled toward the circular field. They retain some inertia, collide with nearby orbs, slide or settle briefly, then become part of the pile. The player's rotation input visually appears to rotate or energize the circular focus, while the implementation can rotate the settled orb pile as a group to preserve clear control and a feel close to the reference inspiration.

Rules should not rely only on raw physics contacts. The demo should use physical motion for feel and a separate rules layer for stable neighbor detection, chain detection, charging, damage reduction, clearing, and victory conditions.

## Controls

First-version controls:

- Rotate left/right: rotate the circular focus and settled orb pile.
- Fast drop player-side orb: accelerates only color orbs and combat orbs from the player preview list.

Boss hazard orbs do not appear in the player-side preview list and do not share the same fast-drop input. If later versions add hazard interception or hazard manipulation, it should use a distinct input or player skill.

## Orb Categories

### Color Orbs

Color orbs are the main chain material. They have a color and no direct combat function. Same-color orbs form connected groups through proximity-based neighbor detection.

When a same-color connected group reaches 5 or more orbs, it enters a flashing clear window instead of clearing immediately. During this window:

- Additional same-color orbs that connect to the flashing group join the chain.
- The chain's influence increases as more orbs are added.
- The flashing window can be extended or refreshed by a small amount when new same-color orbs join.
- Adjacent numbered orbs continue receiving influence while the chain is flashing.

When the clear window ends, the color chain is consumed.

### Combat Orbs

Combat orbs are player-side numbered orbs. They appear in the player preview list and can be fast-dropped. They start at value 0.

First-version combat orb types:

- Attack orb: deals damage to the boss when triggered.
- Shield orb: adds shield to the player when triggered.
- Heal orb: restores player HP when triggered.

Combat orbs cannot form color chains. They are charged by adjacent flashing color chains. If a combat orb is adjacent to multiple flashing chains at the same time, all contributions stack. This multi-chain stacking is an intentional advanced technique and should be supported from the first version.

When a flashing color chain finishes, every combat orb influenced by that chain triggers if its value is above 0:

- Attack orbs fly or pulse toward the boss and deal damage equal to their current value or a tuned conversion of that value.
- Shield orbs fly or pulse toward the player core and add shield.
- Heal orbs fly or pulse toward the player core and restore HP.
- Triggered combat orbs are removed from the playfield.

If a combat orb was influenced by multiple chains, its total stacked value is used.

### Hazard Orbs

Hazard orbs are boss-side numbered orbs. They are spawned by boss actions and events, not by the player preview list.

Hazard orbs have two phases:

- Warning phase: the hazard can be safely reduced and cleared. If its number reaches 0 during this phase, it disappears with no player damage.
- Danger phase: the hazard can still be reduced or cleared, but clearing or bursting it may damage the player. Damage should be based on remaining value or a tuned fraction.

If a hazard orb crosses the danger boundary or lands outside the allowed playfield threshold, it explodes and damages the player. Shield absorbs damage before HP.

Hazard orbs are reduced by adjacent flashing color chains. If a hazard orb is adjacent to multiple flashing chains, all reductions stack. This allows skilled players to surround and neutralize major threats.

## Chain Influence

Chain influence applies during the flashing clear window. The rules layer should evaluate nearby numbered orbs repeatedly or in short ticks:

- 5 connected color orbs create the base influence.
- Each added orb increases influence.
- Multiple flashing chains can influence the same numbered orb.
- Combat orbs gain value from influence.
- Hazard orbs lose value from influence.

The first version should provide clear feedback for stacked influence: number changes, pulse effects, small connecting lines, or other readable signals.

## Boss System

The first demo has one boss, but the boss architecture must be modular and data-driven enough to support later boss variations.

The boss uses both action-bar attacks and event attacks.

### Action Bar

The boss action bar fills over time. When full, it triggers a regular attack pattern, then resets. A first tuning target is one regular attack every 6 seconds.

Regular attacks spawn 1 to 3 hazard orbs. As boss HP decreases, regular attacks may increase hazard value, hazard count, flight speed, warning duration pressure, or incoming angle variety.

### Events

The boss can also react to battle events:

- HP phase events: trigger special attacks at 70%, 40%, and 15% boss HP.
- Player burst events: after high player damage within a short window, the next boss action may gain an extra counter hazard orb.
- Field pressure events: if hazards or pile pressure are already too high, the demo may soften or delay extra pressure to keep the fight playable.

### Modular Boss Mechanics

Boss behavior must be separated into composable mechanics:

- BossController owns HP, action-bar state, current phase, and dispatching.
- BossMechanic modules define trigger conditions and effects.
- BossMechanicSet or resource configuration assembles a boss from multiple mechanics.
- HazardSpawner is the shared path for all hazard orb creation.
- Boss mechanics should not directly implement orb pile rules, chain rules, or hazard clearing rules.

Examples of future mechanics that should fit this structure:

- Action-bar volley.
- HP-threshold burst.
- Counterattack after player burst.
- Passive modifier that shortens warning phase below 40% HP.
- Pattern modifier that changes incoming directions.

## UI

First-version UI:

- Player HP: large number in the center of the circular field.
- Player shield: optional marks or cells around the center; hidden or dimmed when shield is 0.
- Player preview list: upcoming color and combat orbs only.
- Safe boundary and danger boundary: readable rings or field effects around the playfield.
- Boss HP: in the boss area.
- Boss action bar: visible near the boss.
- Boss warnings: show when regular or event attacks are about to spawn hazard orbs.

Required feedback:

- Flashing color chains.
- Combat orb value increases.
- Hazard orb value decreases.
- Multi-chain stacked influence.
- Combat orb launch/trigger.
- Boss hit reaction and damage numbers.
- Shield gain and heal feedback.
- Hazard explosion and player damage feedback.

## Win And Loss

- Player wins when boss HP reaches 0.
- Player loses when player HP reaches 0.
- Shield absorbs damage before HP.
- Warning-phase hazard clearance deals no damage.
- Danger-phase hazard clearance may deal partial damage.
- Boundary explosion deals direct hazard damage, reduced by shield first.

## First Demo Scope

Included:

- One playable battle screen.
- Free-form circular playfield with rotating settled orb pile.
- Player-side preview list.
- Fast drop for player-side orbs.
- Color chain detection at 5 or more connected orbs.
- Flashing clear window and chain extension.
- Multi-chain stacking into combat orbs and hazard orbs.
- Attack, shield, and heal combat orbs.
- Boss HP, player HP, shield, and boss action bar.
- One modular boss assembled from action-bar and event mechanics.
- Hazard orb warning and danger phases.
- Basic effects and prototype visuals.

Excluded from first version:

- Multiple bosses.
- Full upgrade system.
- Long-term progression.
- Final art direction.
- Final sound design.
- Online or multiplayer features.
- Nintendo-style names, characters, UI, art, audio, or level composition.

## Implementation Notes

Use Godot 4.7 project conventions. Prefer small, focused scripts with clear responsibilities. Use physics or physics-like motion for orb entry and settling, but use deterministic rule services for chain and neighbor logic.

Neighbor detection should be based on orb centers and tuned radius thresholds. Rule calculations should tolerate slight physical jitter by using stable settled states, short sampling intervals, or hysteresis.

The boss system should be implemented in a way that lets later bosses be assembled by changing resources or configuration rather than rewriting the central boss controller.
