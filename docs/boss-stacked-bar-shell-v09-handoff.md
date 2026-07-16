# Boss Stacked Bar Shell v09 Handoff

## Goal

Use a cleaner static Boss HP / Boss Action shell now that the game dynamically renders the HP and Action fill layers.

The previous `boss_hp_bar_frame_v08_stacked_action.png` still had a red HP fill baked into the frame. That made the editor/static state look like it already had a filled HP lane, while runtime adds dynamic fill on top. The v09 shell fixes that.

## Final Shell Asset

```text
assets/art/ui/boss/boss_hp_bar_frame_v09_stacked_shell.png
```

- Size: `1600x240`
- Format: `RGBA`
- Contains the full boss top-frame art.
- Upper lane is only an empty dark wine HP trough.
- Lower lane is only an empty dark blue Boss Action trough.
- No baked red HP fill.
- No baked blue Action fill.
- No old orb slots / pips / circular placeholders.

## Keep Using Existing Fill Assets

Use the already accepted stacked fill set:

```text
assets/art/ui/boss/action_bar/boss_action_bar_fill_v04_stacked.png
assets/art/ui/boss/action_bar/boss_action_bar_fill_warning_v04_stacked.png
assets/art/ui/boss/action_bar/boss_action_bar_glow_v04_stacked.png
```

Do not replace these unless a later art pass explicitly asks for it.

## Mockups

Reference only. Do not wire these into runtime UI.

```text
assets/art/ui/boss/action_bar/boss_action_bar_mockup_empty_shell_v09.png
assets/art/ui/boss/action_bar/boss_action_bar_mockup_runtime_filled_v09.png
assets/art/ui/boss/action_bar/boss_action_bar_mockup_runtime_warning_v09.png
assets/art/ui/boss/action_bar/boss_action_bar_mockup_bar_area_v09.png
```

`boss_action_bar_mockup_empty_shell_v09.png` shows the intended editor/static look.

`boss_action_bar_mockup_runtime_filled_v09.png` shows the intended runtime look with dynamic HP and Action fills.

## Source-Space Layout

The shell texture is `1600x240`.

Approximate lanes:

```text
HP lane:      x=382, y=72,  w=1120, h=51
Action lane:  x=382, y=132, w=1120, h=22
```

The action fill texture is `1120x22`, so it is designed to line up directly with the lower lane.

If the frame is displayed at a different size in Godot, scale these coordinates by:

```text
displayed_frame_size / Vector2(1600, 240)
```

## Implementation Notes For Main Code Session

Recommended replacement:

```text
old frame: assets/art/ui/boss/boss_hp_bar_frame_v08_stacked_action.png
new frame: assets/art/ui/boss/boss_hp_bar_frame_v09_stacked_shell.png
```

Keep the current dynamic HP fill and stacked Boss Action fill behavior.

The static frame should only provide:

- parchment outer frame
- upper empty HP trough
- lower empty Action trough
- decorative star-chart ticks

Runtime layers should provide:

- dynamic red HP fill
- dynamic cyan-blue Action fill
- optional warning fill
- optional Action glow near full

## Visual Constraints

- Do not reintroduce old right-end pips, orb slots, circular sockets, or gameplay-orb-like progress.
- Do not bake HP numbers, boss names, `ATK`, `DMG`, or other text into the art.
- Keep Action as a clear cast/progress bar, not a row of collectible/gameplay objects.
- Keep the upper HP red and lower Action cyan-blue visually distinct.
