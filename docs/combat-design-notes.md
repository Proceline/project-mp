# Combat Design Notes

Last updated: 2026-07-11

This document is the ongoing design summary for combat pacing, boss presentation, orb role clarity, and visual direction. Future design sessions should update this file with settled conclusions so implementation-focused sessions can use it as a practical reference.

## Current Creative Anchor

Recommended theme direction: **Astral Resonance**.

Working fiction:

- The playfield is a **Resonance Astrolabe**, not a magnetic disk or mechanical toy.
- The center is the **Heartlight Core**, where player HP and shield are represented.
- The outer danger limit is the **Collapse Boundary**.
- Color orbs are **Star Orbs** or **Resonance Orbs**.
- Boss hazard orbs are **Eclipse Orbs**.
- The first boss direction is an astral entity such as **The Eclipsing One**.

Avoid:

- Nintendo names, characters, UI language, sound language, or visual style.
- Conveyor-belt presentation.
- Magnetic disk wording.
- Toy-like mechanical disk shapes.
- Plastic, party-game, or mascot-heavy presentation.

## Boss Direction Notes

The boss should feel like the source of pressure, not a background decoration.

Initial boss concept:

- A large astral entity partially emerging from a cosmic rift.
- It corrupts the player's astrolabe by inserting Eclipse Orbs into the shared preview queue.
- It should visibly charge, recoil, attack, and react to player hits.

Example modular boss mechanics:

- **Eclipse Projection**: inserts 1-3 Eclipse Orbs into the preview queue.
- **Tidal Pull**: shifts or widens upcoming orb entry angles.
- **Collapse Pressure**: empowers or highlights the Collapse Boundary for a short window.
- **Constellation Backlash**: after the player deals a large burst, the boss changes its next action into a defensive, charged, or retaliatory move.

Boss mechanics should stay composable. A future boss should be able to combine queue insertion, entry angle changes, warning duration changes, boundary pressure, and phase behavior without rewriting the core playfield rules.

## Combat Orb Pacing Problem

Current player feel:

- Combat orbs appear too frequently.
- Frequent combat orb drops interrupt the intended color-orb rhythm.
- Rhythm disruption should mostly be the role of boss hazard orbs.
- Combat orbs should feel tactical or beneficial, not like another form of clutter.

Design principle:

**Color orbs create plans, Eclipse Orbs disrupt plans, and combat orbs amplify plans only when the player chooses to deploy them.**

## Recommended Combat Structure

Use a hybrid structure:

1. Color chains provide baseline combat progress.
2. Combat orbs become low-frequency tactical amplifiers.
3. Hazard orbs remain boss-driven rhythm disruption.

### Color Chain Baseline Effects

Color chains should not require a combat orb to matter.

Recommended baseline:

- Clearing a 5+ color chain deals a small amount of base boss damage.
- Larger chains or extended flashing chains increase that base effect.
- This guarantees the boss fight progresses through core board play.

Optional lightweight stance layer:

- The player, character, or astrolabe has an active stance such as Attack, Guard, or Recover.
- A resolved color chain triggers a small extra effect based on the active stance.
- This layer should stay simple at first and should not replace the spatial strategy of combat orbs.

### Tactical Combat Orb Queue

Combat orbs should be removed from frequent automatic main-queue generation.

Recommended model:

- Add a small separate tactical queue or tactical slot system.
- The tactical queue slowly generates combat orbs.
- The player chooses when to insert the next tactical combat orb into the main preview queue.
- Initial limit: 2 tactical slots.
- Initial insertion rule: insert at the main queue head or near-head, such as position 1 or 2.
- Avoid giving too many insertion choices in the first pass.

This turns combat orbs into deliberate tactical opportunities instead of random pacing interruptions.

### Combat Orb Role

Combat orbs should remain high-value targets that interact with flashing color chains.

Examples:

- Attack orb: a charged tactical strike against the boss.
- Shield orb: creates or reinforces player shield.
- Heal orb: restores player HP.

Current valuable rule to preserve:

- Combat orbs start at value 0.
- Nearby flashing color chains increase their value.
- Multiple flashing chains can stack onto the same combat orb.

Design intent:

- A basic chain always helps.
- A well-placed combat orb turns a good chain into a major tactical payoff.
- The player should feel clever for choosing when to insert and where to land a combat orb.

## Alternative Considered: Remove Combat Orbs

An alternative design is to remove combat orbs entirely and let color chains trigger the active stance directly.

Example:

- The player cycles between Attack, Guard, and Recover.
- Any resolved 5+ color chain triggers the currently active stance.

Pros:

- Much simpler board contents.
- Stronger focus on color chains and hazards.
- Less visual clutter.

Cons:

- Loses the spatial strategy of charging a specific combat orb.
- Reduces the distinctiveness of the current chain-to-number interaction.
- Makes combat outcomes feel more global and less physical.

Conclusion:

- Do not choose this as the primary direction yet.
- Keep it as a fallback if tactical combat orbs remain too complex or too distracting.

## Boss Visibility And Attention

Problem:

- If the board contains too many object types and urgent rules, players will stare only at the astrolabe.
- If the boss is ignored, the game risks feeling like a pure circular puzzle instead of a PvE boss fight.

Recommended rules:

### Boss Intent Must Be Visible

The boss should show its next action clearly.

Examples:

- The boss charges an Eclipse Projection before Eclipse Orbs enter the preview queue.
- The boss performs a pulling animation before Tidal Pull changes entry angles.
- The boss darkens or expands its aura before Collapse Pressure activates.

### Board Warnings Should Echo Boss Actions

Players should not need to stare at the boss constantly.

Each boss action should have a corresponding readable board-side warning:

- Entry-angle danger gates on the astrolabe rim.
- Preview queue corruption effects when Eclipse Orbs are inserted.
- Collapse Boundary pulse or color shift during boundary pressure.
- Distinct warning and danger visuals on Eclipse Orbs.

### Completion Feedback Windows

Successful player actions should create short moments where the player's eye can move from the board to the boss.

Examples:

- A resolved chain fires a resonance beam, comet strike, or constellation burst from the astrolabe toward the boss.
- The player character or avatar performs a brief attack animation after a successful offensive chain.
- The boss visibly recoils, cracks, sheds star fragments, or loses aura intensity.
- The next orb should not instantly steal all attention during this short hit-confirm window.

Suggested duration:

- Small chain hit: about 0.2-0.3 seconds of readable impact feedback.
- Large tactical combat orb payoff: about 0.4-0.6 seconds of stronger boss reaction.

The feedback window should not freeze the whole game for long. It should briefly lower visual noise and make the boss feel physically involved.

## UI And Feedback Priorities

Important near-term feedback improvements:

- Preview queue should remain icon-based.
- Tactical combat queue should be visually separate from the main preview queue.
- Eclipse Orb warning and danger states need strong shape, color, and animation differences.
- Fast drop should feel like acceleration or forced entry, not teleportation.
- Flashing color chains should visually connect as constellations or resonance lines.
- Combat orb charging should show stacked contribution clearly, such as rings, pulses, or value ticks.
- Boss damage should appear on the boss side, not clutter the board center.
- Shield and HP should remain anchored to the Heartlight Core.

## Working Summary For Future Implementation Sessions

Recommended next design implementation target:

- Keep color orbs as the dominant board content.
- Make 5+ color chain clears produce baseline boss damage.
- Move combat orbs into a slow, separate tactical queue.
- Let the player manually insert tactical combat orbs into the main preview queue.
- Keep combat orbs compatible with existing chain influence and stacking rules.
- Keep boss hazards in the shared main preview queue as the primary disruption system.
- Add clear boss intent, board-side warning echoes, and short completion feedback windows.

Primary goal:

**Make the game feel like a boss duel played through a resonance astrolabe, not a puzzle board with a boss picture attached.**
