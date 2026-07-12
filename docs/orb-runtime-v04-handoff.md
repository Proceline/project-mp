# Orb Runtime v04 Handoff

Last updated: 2026-07-12

This pass replaces the darker high-contrast v03 look with a lighter handmade watercolor / colored pencil / gouache direction based on the approved reference sheets. The assets are intended for actual Godot runtime use, not only concept review.

## Preview Files

```text
assets/art/source/generated_raw/orb_runtime_v04_contact_sheet.png
assets/art/source/generated_raw/orb_runtime_v04_tangency_preview.png
```

## Style Notes

- Handmade watercolor and colored pencil texture.
- Lower contrast and lighter value range than v03.
- No decorative protruding borders.
- Body sprites are round and aligned to the runtime physics radius.
- Color orbs use subtle central marks rather than busy full-sphere patterns.
- Tactical orbs use a shared pale mint / warm ivory base and differ mainly by icon.
- Eclipse warning and danger follow the approved crescent and red-black eclipse concepts.

## Runtime Body Assets

Use these for `OrbNode` body sprites:

```text
assets/art/orbs/star/star_orb_red_body_v04.png
assets/art/orbs/star/star_orb_blue_body_v04.png
assets/art/orbs/star/star_orb_gold_body_v04.png
assets/art/orbs/star/star_orb_green_body_v04.png

assets/art/orbs/combat/combat_orb_attack_body_v04.png
assets/art/orbs/combat/combat_orb_shield_body_v04.png
assets/art/orbs/combat/combat_orb_recover_body_v04.png

assets/art/orbs/eclipse/eclipse_orb_warning_body_v04.png
assets/art/orbs/eclipse/eclipse_orb_danger_body_v04.png
```

## Optional Glow Assets

The glow layers are intentionally very subtle. They can be drawn behind the body sprite and alpha-modulated or pulsed in Godot.

```text
assets/art/orbs/star/star_orb_red_glow_v04.png
assets/art/orbs/star/star_orb_blue_glow_v04.png
assets/art/orbs/star/star_orb_gold_glow_v04.png
assets/art/orbs/star/star_orb_green_glow_v04.png

assets/art/orbs/combat/combat_orb_attack_glow_v04.png
assets/art/orbs/combat/combat_orb_shield_glow_v04.png
assets/art/orbs/combat/combat_orb_recover_glow_v04.png

assets/art/orbs/eclipse/eclipse_orb_warning_glow_v04.png
assets/art/orbs/eclipse/eclipse_orb_danger_glow_v04.png
```

## Suggested Mapping

Color orbs:

```text
red   -> assets/art/orbs/star/star_orb_red_body_v04.png
blue  -> assets/art/orbs/star/star_orb_blue_body_v04.png
gold  -> assets/art/orbs/star/star_orb_gold_body_v04.png
green -> assets/art/orbs/star/star_orb_green_body_v04.png
```

Combat orbs:

```text
attack  -> assets/art/orbs/combat/combat_orb_attack_body_v04.png
shield  -> assets/art/orbs/combat/combat_orb_shield_body_v04.png
recover -> assets/art/orbs/combat/combat_orb_recover_body_v04.png
```

Eclipse orbs:

```text
warning -> assets/art/orbs/eclipse/eclipse_orb_warning_body_v04.png
danger  -> assets/art/orbs/eclipse/eclipse_orb_danger_body_v04.png
```

## Source Files

Raw generated chroma-key sources are preserved here:

```text
assets/art/source/generated_raw/*_body_v04_chroma.png
```

Do not use the chroma-key sources in-game.

## Implementation Notes

- Prefer v04 over v03 if the goal is the lighter watercolor look.
- Do not add runtime scale compensation for padding; these bodies were normalized to the physical sprite footprint.
- Keep numeric orb values as Godot text overlays.
- If the gold orb center mark feels too faint in-game, adjust only that mark or regenerate only the gold body rather than changing the whole set.

