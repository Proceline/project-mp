# Orb Runtime v02 Handoff

Last updated: 2026-07-12

This document summarizes the v02 orb runtime assets created after discovering that the Batch 1 orb PNGs had too much transparent padding and baked glow for direct physics-radius rendering in Godot.

## Goal

`OrbNode` maps the whole sprite texture to the physical orb diameter. Therefore each runtime orb body texture must fill most of its `512x512` canvas. v02 separates each orb into:

- `*_body_v02.png`: the gameplay body texture, aligned to physical radius.
- `*_glow_v02.png`: optional visual aura drawn behind the body, not used for collision, clicking, or rules.

The original v01 files are preserved as concept/source-style assets.

## Preview

```text
assets/art/source/generated_raw/orb_runtime_v02_contact_sheet.png
```

## Runtime Body Assets

| Role | Body File | Size | Notes |
|---|---|---:|---|
| Red Star Orb | `assets/art/orbs/star/star_orb_red_body_v02.png` | 512x512 | Body footprint about 479x488px. |
| Blue Star Orb | `assets/art/orbs/star/star_orb_blue_body_v02.png` | 512x512 | Body footprint about 480x488px. |
| Gold Star Orb | `assets/art/orbs/star/star_orb_gold_body_v02.png` | 512x512 | Body footprint about 475x488px. |
| Green Star Orb | `assets/art/orbs/star/star_orb_green_body_v02.png` | 512x512 | Body footprint about 477x488px. |
| Attack Combat Orb | `assets/art/orbs/combat/combat_orb_attack_body_v02.png` | 512x512 | Body footprint about 471x488px. |
| Shield Combat Orb | `assets/art/orbs/combat/combat_orb_shield_body_v02.png` | 512x512 | Body footprint about 477x488px. |
| Recover Combat Orb | `assets/art/orbs/combat/combat_orb_recover_body_v02.png` | 512x512 | Body footprint about 472x488px. |
| Eclipse Warning Orb | `assets/art/orbs/eclipse/eclipse_orb_warning_body_v02.png` | 512x512 | Body footprint about 486x475px. |
| Eclipse Danger Orb | `assets/art/orbs/eclipse/eclipse_orb_danger_body_v02.png` | 512x512 | Body footprint about 477x476px. |

All body assets are transparent PNGs. Their visible alpha footprints are approximately `92% - 95%` of the canvas, so they should visually match the physical orb radius much more closely than the v01 concept sprites.

## Glow Assets

| Role | Glow File | Suggested Use |
|---|---|---|
| Red Star Orb | `assets/art/orbs/star/star_orb_red_glow_v02.png` | Optional subtle glow behind body. |
| Blue Star Orb | `assets/art/orbs/star/star_orb_blue_glow_v02.png` | Optional subtle glow behind body. |
| Gold Star Orb | `assets/art/orbs/star/star_orb_gold_glow_v02.png` | Optional subtle glow behind body. |
| Green Star Orb | `assets/art/orbs/star/star_orb_green_glow_v02.png` | Optional subtle glow behind body. |
| Attack Combat Orb | `assets/art/orbs/combat/combat_orb_attack_glow_v02.png` | Recommended; can pulse when charged. |
| Shield Combat Orb | `assets/art/orbs/combat/combat_orb_shield_glow_v02.png` | Recommended; can pulse when charged. |
| Recover Combat Orb | `assets/art/orbs/combat/combat_orb_recover_glow_v02.png` | Recommended; can pulse when charged. |
| Eclipse Warning Orb | `assets/art/orbs/eclipse/eclipse_orb_warning_glow_v02.png` | Recommended; slow warning pulse. |
| Eclipse Danger Orb | `assets/art/orbs/eclipse/eclipse_orb_danger_glow_v02.png` | Strongly recommended; urgent danger pulse. |

Glow assets are transparent PNGs and may touch the canvas edge. They should be drawn behind the body sprite, optionally at the same texture scale or slightly larger. They should not affect physics radius.

## Suggested Godot Mapping

For runtime board orbs and preview icons, prefer body v02:

```text
red   -> assets/art/orbs/star/star_orb_red_body_v02.png
blue  -> assets/art/orbs/star/star_orb_blue_body_v02.png
gold  -> assets/art/orbs/star/star_orb_gold_body_v02.png
green -> assets/art/orbs/star/star_orb_green_body_v02.png
```

Combat orbs:

```text
attack  -> assets/art/orbs/combat/combat_orb_attack_body_v02.png
shield  -> assets/art/orbs/combat/combat_orb_shield_body_v02.png
recover -> assets/art/orbs/combat/combat_orb_recover_body_v02.png
```

Eclipse hazard orbs:

```text
warning -> assets/art/orbs/eclipse/eclipse_orb_warning_body_v02.png
danger  -> assets/art/orbs/eclipse/eclipse_orb_danger_body_v02.png
```

Optional glow layer:

```text
body sprite: texture mapped to physical orb diameter
glow sprite: drawn behind body, same center, independent alpha/scale/pulse
number text: drawn above body, never baked into texture
```

## Implementation Notes

- Do not use code scale hacks to compensate for v01 padding.
- Do not bake numeric values into orb images.
- Keep v01 files available for comparison, but new runtime visual theme mappings should use `*_body_v02.png`.
- If using glow layers, combat and Eclipse glows should be more visually important than Star Orb glows.
- Eclipse warning and danger still use different shape language, but their body radius is normalized to the same runtime scale as the other orbs.

