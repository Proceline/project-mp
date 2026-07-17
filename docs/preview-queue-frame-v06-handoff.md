# Preview Queue Frame v06 Handoff

## Goal

Update the left-side preview queue UI after tactical combat queue was removed from normal play.

The old queue frame was visually split into a main preview area and a lower tactical area. The new frame is a single continuous vertical queue frame for six preview orb icons.

## Final Asset

```text
assets/art/ui/queue/vertical_preview_queue_frame_v06.png
```

- Size: `360x760`
- Format: `RGBA`
- Transparent background
- One continuous parchment / watercolor / astral frame
- Six clear orb placement areas
- No `Next`, `Tactic`, `ATK`, `HEAL`, `DMG`, numbers, or other baked text
- No baked gameplay orbs
- No separate tactical section
- No bottom tactical ornament

## Reference Mockup

```text
assets/art/ui/queue/vertical_preview_queue_frame_v06_socket_mockup.png
```

This mockup only shows placeholder orb positions. Do not wire it into runtime UI.

## Recommended Replacement

Yes, replace the current queue frame reference:

```text
old:
assets/art/ui/queue/vertical_orb_queue_frame_v05.png

new:
assets/art/ui/queue/vertical_preview_queue_frame_v06.png
```

Do not overwrite the v05 file unless you specifically want to remove the older art variant. Keeping both files makes rollback easier.

## Socket Coordinates

Coordinates are in native texture space for `360x760`.

Suggested orb icon centers:

```text
slot 1: x=180, y=123
slot 2: x=180, y=224
slot 3: x=180, y=325
slot 4: x=180, y=426
slot 5: x=180, y=527
slot 6: x=180, y=628
```

Suggested visual socket radius:

```text
socket visual radius: ~38 px
runtime orb icon radius: ~24 px if using current preview icon scale
```

If Godot displays the frame at a different size, scale these positions by:

```text
displayed_frame_size / Vector2(360, 760)
```

## Implementation Notes

- The preview queue should render six runtime orb icons over the frame.
- Runtime orbs should be placed at the six centers above.
- The frame should not render any tactical slots.
- The tactical label/row should remain hidden or be removed from the normal layout.
- The frame art has restrained socket marks, but the orb sprites should remain the primary visual signal.

## Visual Constraints

- Keep the Astral Resonance watercolor / parchment / star-chart style.
- Do not reintroduce a separate lower tactical panel.
- Do not bake orb graphics into the frame.
- Do not add text labels to the art.
- Do not use Nintendo-like party UI, toy-like plastic, or gameplay-orb pips as UI decoration.
