# Layout Art v05 Handoff

Last updated: 2026-07-13

This document summarizes the watercolor/gouache layout art package for the next implementation session. This session did not change code; it produced art assets and a layout recommendation for the new boss-duel screen composition.

## Layout Direction

Recommended layout:

```text
Top:       wide boss HP bar, readable from peripheral vision
Left:      vertical main preview queue, tactical queue below it
Center:    circular resonance board remains the primary focus
Bottom-L:  small player duelist facing the boss
Right:     large veiled seraph boss portrait, integrated with background
```

Key intent:

- The player mainly watches the circular board.
- Boss HP should be visible from the board area without looking into a right-side debug panel.
- Preview and tactical queues should sit near the board's left edge, vertically stacked.
- Boss portrait should provide pressure and identity, but should not steal focus from the board.
- Remove the current large right-side rectangular panel layout.

## Preview Images

Use these to understand the intended composition:

```text
assets/art/source/layout_mockups/layout_art_v05_composite_preview.png
assets/art/source/layout_mockups/layout_art_v05_contact_sheet.png
```

`layout_art_v05_composite_preview.png` is a rough art composite, not a final in-engine screenshot.

## Runtime Asset Candidates

### Background

```text
assets/art/backgrounds/battle/astral_watercolor_layout_bg_v05.png
```

- Size: `1920x1080`
- Type: RGB PNG
- Purpose: hand-painted astral watercolor battle background.
- Notes: left-center is intentionally calmer for the board; right side has eclipse atmosphere for boss portrait.

### Boss HP Bar

```text
assets/art/ui/boss/boss_hp_bar_frame_v05.png
```

- Size: `1600x240`
- Type: RGBA PNG
- Purpose: top boss HP bar frame/backing.
- Suggested placement: top center/top right, spanning most of the screen width.
- Implementation note: draw actual HP fill/text in Godot above or within this frame if needed. The image includes a painted red backing, but the gameplay fill can still be controlled separately.

### Vertical Queue Frame

```text
assets/art/ui/queue/vertical_orb_queue_frame_v05.png
```

- Size: `360x1000`
- Type: RGBA PNG
- Purpose: far-left vertical queue frame.
- Structure: six main preview sockets plus two tactical sockets below.
- Suggested use: place orb icons on top of the sockets. Do not bake orb icons into the frame.
- Note: this is a little ornate, but it provides a readable first art target.

### Player Portrait

```text
assets/art/player/duelist/player_duelist_idle_v05.png
```

- Size: `560x720`
- Type: RGBA PNG
- Purpose: bottom-left player-side identity anchor.
- Suggested placement: lower-left, facing toward boss/right side.
- Note: keep it small enough that it does not compete with the board.

### Boss Portrait

```text
assets/art/boss/veiled_seraph/veiled_seraph_idle_v05.png
```

- Size: `900x1080`
- Type: RGBA PNG
- Purpose: right-side boss portrait.
- Concept: blindfolded fallen angel / veiled seraph with eclipse halo.
- Suggested placement: right third of the screen, optionally alpha-modulated or darkened so it remains atmospheric.
- Note: this is an idle portrait candidate, not a full animation set.

### Heartlight Core

```text
assets/art/board/core/heartlight_core_painted_v05.png
```

- Size: `1024x1024`
- Type: RGBA PNG
- Purpose: painted center core replacement.
- Suggested use: scale down at board center; keep HP number as Godot text overlay.
- Note: this asset includes a larger decorative ring. If it feels too large, use it as a core + shield ring layer or crop/regenerate a simpler core-only version later.

### Collapse Boundary

```text
assets/art/board/boundary/collapse_boundary_painted_v05.png
```

- Size: `1024x1024`
- Type: RGBA PNG
- Purpose: hand-painted outer danger boundary.
- Suggested use: replace the current neon boundary; alpha-modulate for calm/warning/danger states.
- Note: use shader/animation later for danger pulsing instead of returning to bright neon magenta.

## Source Files

Raw generated sources are preserved here:

```text
assets/art/source/generated_raw/*_v05_chroma.png
assets/art/source/generated_raw/astral_watercolor_layout_bg_v05_raw.png
assets/art/source/generated_raw/tmp_alpha_v05/
```

Do not use chroma source files in-game. Use the categorized runtime PNGs listed above.

## Suggested Implementation Order

1. Replace the old battle background with `astral_watercolor_layout_bg_v05.png`.
2. Move boss HP to the top and use `boss_hp_bar_frame_v05.png` as backing.
3. Move main/tactical preview queues to the far left using `vertical_orb_queue_frame_v05.png`.
4. Add a right-side boss portrait slot using `veiled_seraph_idle_v05.png`.
5. Add a bottom-left player portrait slot using `player_duelist_idle_v05.png`.
6. Replace/overlay the center core and collapse boundary with the painted v05 assets.

## UI Notes

- Avoid a large right-side debug panel.
- Keep text minimal: boss name, HP number, maybe phase/intention.
- Preview queue should use orb icons, not text codes.
- Tactical queue should remain visually separate from the main queue.
- The board remains the primary focal point; boss and UI should support, not compete.

## Follow-Up Art Needs

After layout is validated in-game:

- Simplified core-only Heartlight asset if the current core ring is too large.
- Boss charge / attack / hit / weakened variants.
- Smaller/lighter queue frame variant if the v05 queue frame feels too ornate.
- Boss HP bar fill/mask variants if implementation wants fully art-driven fill layers.
- Player damage/shield/recovery feedback near the bottom-left player portrait.

