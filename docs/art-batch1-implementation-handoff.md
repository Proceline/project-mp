# Art Batch 1 Implementation Handoff

Last updated: 2026-07-12

This handoff summarizes the first generated **Astral Resonance** art batch for implementation work. It is meant to be passed to an implementation-focused thread so the assets can be wired into the Godot prototype without guessing file roles.

## Batch Summary

Theme: **Celestial Instrument / Astral Resonance**

Primary visual shift:

- The playfield should read as a **Resonance Astrolabe**, not a mechanical or magnetic disk.
- The center should read as a **Heartlight Core** for HP and shield feedback.
- The outer danger limit should read as a **Collapse Boundary**.
- Color orbs should read as glassy **Star Orbs**.
- Boss hazard orbs should read as **Eclipse Orbs** with clear warning and danger states.

Preview contact sheet:

```text
assets/art/source/generated_raw/batch1_contact_sheet_v01.png
```

Prompt record:

```text
assets/art/source/prompts/batch1_prompts_v01.md
```

Art direction document:

```text
docs/astral-resonance-art-package.md
```

## Runtime Asset Map

| Gameplay Role | File | Size | Type | Suggested Use |
|---|---:|---:|---|---|
| Battle background | `assets/art/backgrounds/battle/astral_battle_background_v01.png` | 1920x1080 | RGB PNG | Full-screen or root background behind board and boss area. |
| Resonance Astrolabe base | `assets/art/board/astrolabe/resonance_astrolabe_base_v01.png` | 1024x1024 | RGBA PNG | Replace or layer under the circular board visual. |
| Heartlight Core HP center | `assets/art/board/core/heartlight_core_hp_v01.png` | 1024x1024 | RGBA PNG | Center HP/core visual. Likely scale down inside board center. |
| Shield ring segments | `assets/art/board/shield/shield_ring_segments_v01.png` | 1024x1024 | RGBA PNG | Overlay around Heartlight Core for shield feedback. |
| Collapse Boundary | `assets/art/board/boundary/collapse_boundary_v01.png` | 1024x1024 | RGBA PNG | Outer danger boundary overlay. Can pulse/tint later. |
| Red Star Orb | `assets/art/orbs/star/star_orb_red_v01.png` | 512x512 | RGBA PNG | Color orb sprite for red color id. |
| Blue Star Orb | `assets/art/orbs/star/star_orb_blue_v01.png` | 512x512 | RGBA PNG | Color orb sprite for blue color id. |
| Gold Star Orb | `assets/art/orbs/star/star_orb_gold_v01.png` | 512x512 | RGBA PNG | Color orb sprite for yellow/gold color id. |
| Green Star Orb | `assets/art/orbs/star/star_orb_green_v01.png` | 512x512 | RGBA PNG | Color orb sprite for green color id. |
| Attack Combat Orb | `assets/art/orbs/combat/combat_orb_attack_v01.png` | 512x512 | RGBA PNG | Combat attack orb sprite. |
| Shield Combat Orb | `assets/art/orbs/combat/combat_orb_shield_v01.png` | 512x512 | RGBA PNG | Combat shield orb sprite. |
| Recover Combat Orb | `assets/art/orbs/combat/combat_orb_recover_v01.png` | 512x512 | RGBA PNG | Combat heal/recover orb sprite. |
| Eclipse Orb warning | `assets/art/orbs/eclipse/eclipse_orb_warning_v01.png` | 512x512 | RGBA PNG | Hazard orb warning phase sprite. |
| Eclipse Orb danger | `assets/art/orbs/eclipse/eclipse_orb_danger_v01.png` | 512x512 | RGBA PNG | Hazard orb danger phase sprite. |

## Suggested Godot Integration

### Board Layers

Recommended visual stacking from back to front:

1. `astral_battle_background_v01.png`
2. `resonance_astrolabe_base_v01.png`
3. Falling and on-board orb sprites
4. `heartlight_core_hp_v01.png`
5. `shield_ring_segments_v01.png`
6. `collapse_boundary_v01.png`
7. Existing text/debug overlays, if still needed

The `Collapse Boundary` should probably be above the board base but below urgent UI text. If boundary damage or boss pressure is active, it can be modulated toward brighter red/magenta until a proper shader or VFX sheet exists.

### Orb Mapping

Use the four Star Orb sprites for natural main preview queue color generation:

```text
red   -> assets/art/orbs/star/star_orb_red_v01.png
blue  -> assets/art/orbs/star/star_orb_blue_v01.png
gold  -> assets/art/orbs/star/star_orb_gold_v01.png
green -> assets/art/orbs/star/star_orb_green_v01.png
```

Use combat orb sprites only for the tactical queue and inserted tactical combat orbs:

```text
attack  -> assets/art/orbs/combat/combat_orb_attack_v01.png
shield  -> assets/art/orbs/combat/combat_orb_shield_v01.png
recover -> assets/art/orbs/combat/combat_orb_recover_v01.png
```

Use Eclipse sprites for boss hazard orbs:

```text
warning phase -> assets/art/orbs/eclipse/eclipse_orb_warning_v01.png
danger phase  -> assets/art/orbs/eclipse/eclipse_orb_danger_v01.png
```

Important semantic reminder:

- Falling hazard orbs should not deal boundary damage before contacting the board.
- The visual swap from warning to danger should follow the existing hazard phase logic, not physical movement alone.

### Preview Queue

No queue frame art was generated in Batch 1. For now, the main implementation target should be:

- Replace text queue codes such as `C0` or `DMG5` with orb icon sprites.
- Use the same orb sprite map for board orbs and queue previews.
- Scale preview icons consistently, likely `32px` to `64px` depending on current UI.

Dedicated queue frame art should be generated in Batch 3.

### Heartlight Core And Shield

`heartlight_core_hp_v01.png` is visually bright. If HP text is hard to read:

- Put HP text above the core in a high-contrast color.
- Add a subtle dark radial backing behind the number.
- Or generate `heartlight_core_hp_v02_dark_readability.png` later.

`shield_ring_segments_v01.png` is a full 8-segment ring image. For the first implementation pass, it can be:

- Shown/hidden as a full shield overlay.
- Alpha-modulated based on shield value.
- Later replaced with per-segment masking or individual segment sprites.

### Collapse Boundary

`collapse_boundary_v01.png` is one danger-facing ring. For a first pass:

- Use low alpha for normal state.
- Increase alpha and red/magenta modulation for pressure or danger state.
- Add a scale pulse or shader later for boss Collapse Pressure.

## Source And Raw Files

Raw generated chroma-key images are intentionally preserved for reprocessing:

```text
assets/art/source/generated_raw/
```

Do not use raw chroma-key source images in-game. Use the categorized runtime PNGs listed above.

## Known Art Notes

- The batch reads as original celestial glass/astrolabe art and avoids toy-like party-game presentation.
- The Star Orbs are more detailed than the current greybox likely needs, but they should scale down well.
- The Attack, Shield, and Recover combat orbs have stronger internal symbols than Star Orbs, which helps tactical readability.
- Eclipse warning and danger states have clear color and silhouette separation.
- The Heartlight Core may be too bright for direct HP text without a text backing.
- The background is suitable for mood testing but may need composition adjustment once the boss sprite exists.

## Next Suggested Art Batch

Generate **Batch 2: Boss states**:

```text
assets/art/boss/eclipsing_one/sprites/eclipsing_one_idle_v01.png
assets/art/boss/eclipsing_one/sprites/eclipsing_one_charge_v01.png
assets/art/boss/eclipsing_one/sprites/eclipsing_one_attack_v01.png
assets/art/boss/eclipsing_one/sprites/eclipsing_one_hit_reaction_v01.png
assets/art/boss/eclipsing_one/sprites/eclipsing_one_weakened_v01.png
```

After that, generate **Batch 3: UI and VFX** for preview queue frames, tactical queue frames, chain lines, clear bursts, boss hit effects, shield absorb effects, player damage, and recovery.

