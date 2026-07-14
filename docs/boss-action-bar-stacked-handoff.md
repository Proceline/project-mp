# Boss Action Bar Stacked UI Handoff

## Goal

Replace the old boss action indicator that used small orb-like pips with a clear stacked boss bar layout:

- Top lane: Boss HP, red, about 2/3 of the stacked channel height.
- Bottom lane: Boss Action / cast progress, cyan-blue, about 1/3 of the stacked channel height.
- No orb slots, no baked circular placeholders, no text, no numbers.
- The action lane should be visible in peripheral vision while the player focuses on the board.

## Use This Final Asset Set

Use only the `v08_stacked_action` / `v04_stacked` files below. Older v01-v03 iteration files were removed from the folder to avoid accidental use.

### Main Boss Frame

```text
assets/art/ui/boss/boss_hp_bar_frame_v08_stacked_action.png
```

- Size: `1600x240`
- Format: `RGBA`
- Contains the full top boss UI frame.
- Includes the upper HP lane art and the lower action trough art.
- The bottom action trough is empty/dark by default and expects a runtime fill overlay.

### Action Fill

```text
assets/art/ui/boss/action_bar/boss_action_bar_fill_v04_stacked.png
```

- Size: `1120x22`
- Format: `RGBA`
- Cyan-blue hand-painted fill for normal boss action progress.
- Runtime should reveal/crop horizontally from left to right.

### Action Warning Fill

```text
assets/art/ui/boss/action_bar/boss_action_bar_fill_warning_v04_stacked.png
```

- Size: `1120x22`
- Format: `RGBA`
- Cyan-to-gold warning fill for near-full cast state.
- Suggested threshold: use when action ratio is `>= 0.85`.

### Optional Glow

```text
assets/art/ui/boss/action_bar/boss_action_bar_glow_v04_stacked.png
```

- Size: `1150x42`
- Format: `RGBA`
- Separate glow layer for near-full state.
- Do not bake it into the fill. Render behind or above the fill as a separate TextureRect/Sprite2D with pulsing alpha.

### Optional Action Guide Frame

```text
assets/art/ui/boss/action_bar/boss_action_bar_frame_v04_stacked.png
```

- Size: `1128x30`
- Format: `RGBA`
- Transparent guide/outline if the runtime wants a separate TextureProgressBar frame.
- The main recommended path is to use `boss_hp_bar_frame_v08_stacked_action.png`, which already includes the visible lower trough.

## Mockups

```text
assets/art/ui/boss/action_bar/boss_action_bar_mockup_full_hp_v04_stacked.png
assets/art/ui/boss/action_bar/boss_action_bar_mockup_bar_area_v04_stacked.png
assets/art/ui/boss/action_bar/boss_action_bar_mockup_warning_full_hp_v04_stacked.png
```

These are preview/reference images only. Do not wire them into gameplay UI.

## Source Texture Coordinates

The new main boss frame is `1600x240`. Approximate source-space lanes:

```text
HP lane outer:      x=382, y=72,  w=1120, h=51
Action lane outer:  x=382, y=132, w=1120, h=22
```

The action fill texture is exactly intended for the lower lane:

```text
fill texture: 1120x22
```

So the simplest implementation is:

- Put `boss_hp_bar_frame_v08_stacked_action.png` in the existing top boss HP frame TextureRect.
- Render an action fill TextureRect over the lower action lane.
- Clip/crop fill width by `boss_action_ratio` from `0.0` to `1.0`.
- Switch to warning fill and optional glow near full.

If the frame is scaled in Godot, scale these coordinates by the same `TextureRect displayed_size / Vector2(1600, 240)` ratio.

## Runtime Behavior Recommendation

For a `TextureRect` based implementation:

```text
visible_fill_width = full_fill_width * clamp(action_ratio, 0.0, 1.0)
```

Use one of these approaches:

- `TextureProgressBar` with the fill texture and left-to-right fill mode.
- A child `TextureRect` with clipping enabled by parent Control width.
- A `TextureRect` with region enabled and its region width updated each frame.

Layer order:

```text
Boss HP/action frame background
Boss action fill or warning fill
Optional near-full glow
Boss HP text / labels, if any
```

The action bar should not use pips, orbs, circular sockets, baked text, `ATK`, `DMG`, or numbers.

## Visual Spec / Regeneration Prompt

Use this prompt if the stacked bar needs to be regenerated or extended:

```text
Create 2D game UI assets for a Godot boss battle top bar in a watercolor, gouache, colored pencil, hand-painted astral parchment style.
The boss UI frame is a long horizontal parchment-and-dark-gold frame with two stacked lanes: the upper lane is a red boss HP bar occupying about two thirds of the channel height, the lower lane is a cyan-blue boss action/cast progress lane occupying about one third. The lower action lane must be clearly visible but not use orb pips or circular slots. Keep the style old parchment, muted dark gold trim, subtle star-chart ticks, hand-painted paper grain, low-to-medium contrast. The action fill should be cyan-blue to teal, clearly different from the HP red. The warning action fill may transition from cyan/teal to muted gold near the right edge. Transparent background for individual UI sprites. No text, no numbers, no letters, no ATK, no DMG, no gameplay orbs, no circular placeholder slots, no toy-like or plastic style, no Nintendo-like party-game style.
```

## Copyright / Style Constraints

- No Nintendo/Mario Party visual language.
- No toy-like plastic UI.
- No orb-shaped progress units.
- No baked labels or gameplay-like balls in the boss action indicator.
- Keep the action progress as a UI/cast bar, not a preview queue or falling-object hint.
