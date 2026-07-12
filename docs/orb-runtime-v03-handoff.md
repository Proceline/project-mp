# Orb Runtime v03 Handoff

Last updated: 2026-07-12

This v03 pass fixes the remaining runtime issue where v02 orb bodies still looked visually separated when physics circles touched. The main change is stricter body alpha coverage: the orb body now reaches almost the full `512x512` texture diameter, and the semi-opaque body edge is also near the texture edge.

## Why v03 Exists

Godot maps the whole orb texture to the physical orb diameter. v02 had good alpha bounds, but some visible edges were still soft enough that two physically touching orbs looked like they had a gap. v03 treats the body texture as the physical orb surface:

- `*_body_v03.png` contains the orb body only.
- `*_glow_v03.png` contains aura/glow only and should be drawn separately behind the body.
- Body saturation and brightness are reduced so the board reads less noisy in-game.
- No numbers or text are baked into the images.

## Preview Files

```text
assets/art/source/generated_raw/orb_runtime_v03_contact_sheet.png
assets/art/source/generated_raw/orb_runtime_v03_tangency_preview.png
```

## Body Assets

| Role | Body File | Size | Alpha > 128 Footprint |
|---|---|---:|---:|
| Red Star Orb | `assets/art/orbs/star/star_orb_red_body_v03.png` | 512x512 | 506x512 |
| Blue Star Orb | `assets/art/orbs/star/star_orb_blue_body_v03.png` | 512x512 | 506x511 |
| Gold Star Orb | `assets/art/orbs/star/star_orb_gold_body_v03.png` | 512x512 | 506x512 |
| Green Star Orb | `assets/art/orbs/star/star_orb_green_body_v03.png` | 512x512 | 506x512 |
| Attack Combat Orb | `assets/art/orbs/combat/combat_orb_attack_body_v03.png` | 512x512 | 506x511 |
| Shield Combat Orb | `assets/art/orbs/combat/combat_orb_shield_body_v03.png` | 512x512 | 506x511 |
| Recover Combat Orb | `assets/art/orbs/combat/combat_orb_recover_body_v03.png` | 512x512 | 506x511 |
| Eclipse Warning Orb | `assets/art/orbs/eclipse/eclipse_orb_warning_body_v03.png` | 512x512 | 511x506 |
| Eclipse Danger Orb | `assets/art/orbs/eclipse/eclipse_orb_danger_body_v03.png` | 512x512 | 507x506 |

These are the recommended runtime body textures for `OrbNode`.

## Glow Assets

| Role | Glow File |
|---|---|
| Red Star Orb | `assets/art/orbs/star/star_orb_red_glow_v03.png` |
| Blue Star Orb | `assets/art/orbs/star/star_orb_blue_glow_v03.png` |
| Gold Star Orb | `assets/art/orbs/star/star_orb_gold_glow_v03.png` |
| Green Star Orb | `assets/art/orbs/star/star_orb_green_glow_v03.png` |
| Attack Combat Orb | `assets/art/orbs/combat/combat_orb_attack_glow_v03.png` |
| Shield Combat Orb | `assets/art/orbs/combat/combat_orb_shield_glow_v03.png` |
| Recover Combat Orb | `assets/art/orbs/combat/combat_orb_recover_glow_v03.png` |
| Eclipse Warning Orb | `assets/art/orbs/eclipse/eclipse_orb_warning_glow_v03.png` |
| Eclipse Danger Orb | `assets/art/orbs/eclipse/eclipse_orb_danger_glow_v03.png` |

Glow textures are intentionally muted. They can be alpha-modulated, scaled, or pulsed in Godot, but they should not affect gameplay radius.

## Suggested Mapping

Use v03 body textures for board orbs and preview icons:

```text
red   -> assets/art/orbs/star/star_orb_red_body_v03.png
blue  -> assets/art/orbs/star/star_orb_blue_body_v03.png
gold  -> assets/art/orbs/star/star_orb_gold_body_v03.png
green -> assets/art/orbs/star/star_orb_green_body_v03.png
```

Combat orbs:

```text
attack  -> assets/art/orbs/combat/combat_orb_attack_body_v03.png
shield  -> assets/art/orbs/combat/combat_orb_shield_body_v03.png
recover -> assets/art/orbs/combat/combat_orb_recover_body_v03.png
```

Eclipse orbs:

```text
warning -> assets/art/orbs/eclipse/eclipse_orb_warning_body_v03.png
danger  -> assets/art/orbs/eclipse/eclipse_orb_danger_body_v03.png
```

## Implementation Notes

- Prefer v03 body textures over v01/v02 for runtime display.
- Do not add code-side scale compensation for orb body size.
- If glow is used, draw it behind the body sprite using the same center point.
- Keep number/value text as a Godot overlay above the body.
- If the body now feels too large in a dense board, reduce the physical/rendered orb diameter consistently rather than switching back to padded textures.

