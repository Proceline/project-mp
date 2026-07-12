# Astral Resonance Art Package

Last updated: 2026-07-12

This document defines the first practical art package for the Godot prototype. It is focused on usable 2D assets, image-generation prompts, folder organization, and copyright-safe visual direction.

## Direction

Recommended direction: **Celestial Instrument**.

The game should feel like a boss duel conducted through a mystical astronomical instrument. The playfield is a **Resonance Astrolabe**, the center is the **Heartlight Core**, the danger ring is the **Collapse Boundary**, color orbs are **Star Orbs**, and boss hazard orbs are **Eclipse Orbs**.

Avoid any Nintendo-specific presentation, names, characters, UI language, sound language, party-board framing, toy-plastic materials, conveyor belts, magnetic disk imagery, cute mascot bosses, or cheerful party-game composition.

## Asset Folder Hierarchy

Use one dedicated art root so visual assets do not mix with logic code, scenes, tests, or tuning resources.

```text
assets/
  art/
    backgrounds/
      battle/
    board/
      astrolabe/
      boundary/
      core/
      shield/
    orbs/
      star/
      combat/
      eclipse/
    boss/
      eclipsing_one/
        concept/
        sprites/
        vfx/
    ui/
      preview_queue/
      tactical_queue/
      frames/
      icons/
    vfx/
      chain/
      boss_hit/
      player_core/
      shield/
      recovery/
    source/
      prompts/
      references/
      layered/
```

Rules:

- Runtime-ready PNGs go under the matching category folder.
- Prompt text and generation notes go under `assets/art/source/prompts/`.
- Editable layered files, if created later, go under `assets/art/source/layered/`.
- Reference images, if legally usable, go under `assets/art/source/references/`.
- Do not place generated art inside `src/`, `scenes/`, `tests/`, or `data/`.
- Keep file names lowercase with underscores.

Example file names:

```text
assets/art/board/astrolabe/resonance_astrolabe_base_v01.png
assets/art/board/core/heartlight_core_hp_v01.png
assets/art/board/shield/shield_ring_segments_v01.png
assets/art/board/boundary/collapse_boundary_states_v01.png
assets/art/orbs/star/star_orb_red_v01.png
assets/art/orbs/combat/combat_orb_attack_v01.png
assets/art/orbs/eclipse/eclipse_orb_warning_v01.png
assets/art/ui/preview_queue/main_preview_queue_frame_v01.png
assets/art/boss/eclipsing_one/sprites/eclipsing_one_idle_v01.png
assets/art/vfx/chain/chain_clear_burst_sheet_v01.png
```

## First Asset Package

Batch 1 should establish the visual language:

- Battle background, full-screen.
- Resonance Astrolabe base.
- Heartlight Core HP center.
- Shield ring and shield tick segments.
- Collapse Boundary calm, warning, and danger states.
- Four Star Orbs: red, blue, gold, green.
- Three combat orbs: attack, shield, recover.
- Eclipse Orb warning and danger states.

Batch 2 should add the boss:

- Boss idle.
- Boss charge.
- Boss attack.
- Boss hit reaction.
- Boss weakened.

Batch 3 should add UI and VFX:

- Main preview queue frame.
- Tactical queue frame.
- Color chain flash lines.
- Constellation link VFX.
- Chain clear burst.
- Boss hit impact.
- Player damage pulse.
- Shield absorb arc.
- Recovery particles.

## Godot Asset Types

- Full-screen background: PNG or WebP, `1920x1080`.
- Board rings and core: transparent PNG, `1024x1024` or `2048x2048`.
- Orbs: transparent PNG, `512x512`, scaled down in Godot.
- Boss states: transparent PNG, `1024x1024`.
- Queue UI: transparent PNG or 9-slice panel, `1024x192` and `768x192`.
- VFX: sprite sheets, usually horizontal, `128px` or `256px` per frame.
- Later shader candidates: Collapse Boundary pulse, Eclipse Orb smoke, constellation lines, boss rift distortion, shield arcs.

## Style Guide

Primary colors:

- Deep space: `#0B1024`, `#141A35`
- Star white: `#F6F0C8`, `#D7E8FF`
- Astral blue: `#78B7FF`
- Star gold: `#E8C96A`
- Danger red: `#FF3B5F`
- Collapse violet: `#8D3DFF`
- Healing green: `#5EF0A1`
- Shield cyan: `#66D9FF`

Shape language:

- Board and UI: circles, orbital paths, thin star-map lines, small tick marks, restrained cut corners.
- Star Orbs: polished glass, internal star dust, unique subtle constellation marks.
- Eclipse Orbs: black cores, broken circular shapes, sharp corona, red-violet cracks.
- Boss: non-mascot astral entity, large silhouette, rift, eclipse halo, nebula mantle.

Typography:

- Clear narrow numerals for HP and values.
- Elegant celestial display style for headings.
- Avoid rounded party fonts, bubble lettering, toy-package styling, and overly cute shapes.

Effect rhythm:

- Chains connect first, brighten second, burst third.
- Eclipse warning pulses slowly; danger flickers urgently.
- Boss attacks should show intent on the boss side before board-side effects appear.
- Successful attacks should briefly pull attention from the astrolabe to the boss with a beam, burst, or recoil.

## Prompt Baseline

Append this negative clause to generation prompts:

```text
Avoid Nintendo, Mario Party, mascot character, toy-like plastic style, conveyor belt, magnetic disk, party-game UI, cute cartoon props, copyrighted characters, cheerful toy board, rounded candy aesthetic.
```

