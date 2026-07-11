# Design Session Brief

Last updated checkpoint: `6b4383a fix: allow fast drop for hazard orbs`

This document is for starting a separate design-focused session. It summarizes the current game concept, implemented prototype behavior, open design areas, and a copy-paste prompt for the new session.

Note: older spec/plan files under `docs/superpowers/` contain useful historical context, but some details are now outdated. In particular, hazard orbs now enter the shared preview queue and can be fast-dropped.

## Project Identity

- Working repository: `https://github.com/Proceline/project-mp.git`
- Engine: Godot 4.7 Mono.
- Current prototype genre: single-player PvE circular orb-combat boss battle.
- Reference inspiration: the abstract feel of Mario Party's Stick and Spin, especially circular orb attraction, free-form orb piling, rotating control, chain clearing, and numbered orb interactions.
- Copyright direction: keep the design original. Do not use Nintendo-owned names, characters, art style, UI language, music, sounds, conveyor belt presentation, or the exact disk/conveyor visual framing.

## Core Game Concept

The player fights a boss through a circular orb board.

The board has:

- A central HP/core display.
- A core isolation ring that blocks orbs from entering the HP center.
- A circular play area with a red danger boundary.
- A free-form pile of orbs, not a grid.
- A shared preview queue of upcoming orbs.
- A separate boss panel showing boss HP, action bar, and prototype boss body.

Incoming orbs fly in from outside the board toward the center. They slide around the core or existing pile until they settle or continue moving. The player rotates the board/pile with `A` and `D` to control where incoming orbs land.

## Current Controls

- `A`: rotate left.
- `D`: rotate right.
- `Space`: fast drop.

Current `Space` behavior:

- Accelerates currently falling orbs, including hazard orbs.
- Immediately releases the current preview-head orb, including hazard orbs.
- Does not teleport or instantly settle the current falling orb.

## Orb Types

### Color Orbs

- Have one of several colors.
- Same-color connected groups of 5 or more start flashing.
- Flashing groups later clear.
- During the flashing window, nearby numbered orbs are affected.
- The desired long-term feel is that players can continue adding same-color orbs during the flashing window to extend/strengthen the chain.

### Combat Orbs

Current prototype types:

- Attack.
- Shield.
- Heal.

Rules:

- Combat orbs start at value `0`.
- Nearby flashing color chains increase their value.
- A combat orb near multiple flashing chains receives stacked value from all of them.
- When the chain resolves, touched combat orbs trigger and are removed.
- Attack damages the boss.
- Shield adds player shield.
- Heal restores player HP.

### Hazard Orbs

Hazard orbs are boss attacks, but they now use the same shared preview queue.

Rules:

- Boss events insert hazard orbs into the preview queue instead of placing them directly on the board.
- Hazard insert index is tunable.
- Hazard entry angle, distance, warning duration, and value are tunable.
- Hazard orbs can be fast-dropped and released by `Space` just like other queue entries.
- Hazard orbs have a warning phase and danger phase.
- Warning-phase clear: removed without player damage.
- Danger-phase clear: removed and deals player damage.
- If an on-board hazard crosses/exceeds the danger boundary, it explodes, is removed, and deals damage.
- Falling hazards should not deal boundary damage before contacting/attaching to the board.

## Board State Semantics

These terms are important for design discussions because they affect what the rules can safely assume:

- `settled`: the orb is physically locked/stable.
- `board_attached`: the orb has contacted the board structure or orb pile and rotates with the board.
- `is_on_board()`: `settled or board_attached`.
- Pure falling orbs are not settled and not board-attached.

Gameplay rules generally use `is_on_board()`, not only `settled`, because an orb can be sliding on the board and still be part of chain/hazard logic.

## Current Prototype Implementation Notes

Current systems:

- `BallState`: orb data and state.
- `ChainResolver`: color group detection, chain influence, combat/hazard resolution.
- `BattleState`: player HP, shield, boss HP, win/loss state.
- `SpawnQueue`: shared preview queue for player/combat/hazard orbs.
- `HazardSpawner`: creates hazard orb data from boss events.
- `Playfield`: circular board, orb nodes, rotation, entry motion, boundary checks.
- `OrbNode`: visual orb and entry movement.
- `BossController`: modular boss mechanic dispatcher.
- Boss mechanics:
  - action-bar volley,
  - HP phase mechanic,
  - burst counter mechanic.
- `OrbTuning` / `data/orb_tuning.tres`: Godot Resource used like a lightweight ScriptableObject for tunable orb parameters.

Current tunables include:

- preview size,
- player entry seconds,
- player fast-drop entry seconds,
- player spawn position,
- hazard entry seconds,
- hazard preview insert index,
- hazard entry angle,
- hazard wide-angle pattern,
- hazard entry distance,
- hazard warning seconds,
- hazard default value.

## Current Visual State

The prototype is intentionally rough.

Implemented visual ideas:

- Split-screen layout: board on the left, boss panel on the right.
- Player HP appears in the board center.
- Shield marks appear around/near the center when shield exists.
- Preview queue is rendered as orb icons rather than code text.
- Color orbs are colored circles.
- Combat orbs are purple icons with labels.
- Hazard orbs are orange/red numbered icons.
- Boss is currently a placeholder body/panel.
- The circular board currently uses prototype rings and simple colors.

Important visual direction still open:

- What is the board fiction? Examples: magic circle, resonance core, ritual seal, astral engine, alchemical astrolabe, mechanical-but-not-Nintendo device.
- What is the boss visual language?
- What is the UI style?
- How should attacks, chain clears, shields, healing, and boss reactions feel?

## Design Pillars To Preserve

1. Originality over direct imitation.
   The game may preserve the abstract feel of circular free-form orb piling and chain timing, but should avoid Nintendo-specific presentation.

2. Readability under pressure.
   The player must be able to tell what is coming in the preview queue, what is dangerous, what can be cleared, and when a chain is about to resolve.

3. PvE boss combat first.
   The board is not just a score puzzle; orb interactions should feed boss damage, defense, recovery, and boss attack pressure.

4. Skill expression through timing and positioning.
   The player should feel clever for rotating well, stacking multiple chains onto one combat/hazard orb, and using fast drop at the right time.

5. Boss mechanics must remain modular.
   Future bosses should be composable from data/mechanic modules rather than hardcoded one-off behavior.

## Known Design Questions

These are good topics for the dedicated design session:

- What is the unique fantasy/theme of the circular attraction board?
- What should replace the "magnetic disk" concept visually and narratively?
- What should the boss look like, and why is it attacking through orbs?
- How should hazard orbs be telegraphed in the preview queue and on the board?
- Should warning/danger hazard phases be shown by color, animation, iconography, sound, or board effects?
- What should the first boss's full move kit be?
- What should the player feel in a normal 30-second combat loop?
- What should a successful combo look and sound like?
- How should the center HP/shield presentation evolve beyond prototype text and marks?
- How far should the game lean fantasy, sci-fi, occult, abstract arcade, or hybrid?
- What should combat orb identities be called in-world?
- Should attack/shield/heal be the first three combat orb types, or should the design use more original verbs?
- How should danger boundary pressure be communicated?
- How should boss reactions and damage numbers appear without cluttering the board?
- What is the desired emotional tone: tense puzzle duel, ritual battle, arcade boss rush, tactical spellcraft, or something else?

## Design Session Goals

The next design session should focus on design, not implementation.

Suggested outputs:

1. A clear creative direction for the board/core.
2. A clear creative direction for the first boss.
3. A style guide for orb types, colors, shape language, and status cues.
4. A first-pass combat loop for a 2-3 minute boss fight.
5. A list of specific UI/feedback improvements for the next implementation session.
6. A shortlist of names for major in-world concepts that avoid Nintendo wording.

## Copy-Paste Prompt For New Design Session

Use this as the first message in the dedicated design session:

```text
你是一个偏游戏设计和视觉方向的协作者。我们要讨论一个 Godot 原型游戏的设计方向，不要先写代码，重点是玩法体验、视觉语言、UI/反馈、boss 机制和版权规避。

项目背景：
- 这是一个单人 PvE boss 战游戏。
- 灵感来自 Mario Party 的 Stick and Spin 的抽象手感：圆形区域、自由吸附/堆叠的球、旋转控制、5 连颜色球闪烁后消除、数字球被链影响。
- 但必须避免任天堂版权冲突：不能使用 Nintendo 名称、角色、美术风格、UI 语言、音乐音效、传送带表现、原版磁力盘/机械盘造型等。
- 当前目标是保留“圆形自由堆球 + 链式消除 + boss 战压力”的核心，而发展出自己的世界观、视觉主题和反馈系统。

当前原型状态：
- 左侧是圆形球盘，右侧是 boss 区。
- 圆心显示玩家 HP，周围可以显示护盾。
- 球进入圆盘后向中心移动，撞到核心隔离圈或球堆后滑动/停下。
- A/D 旋转圆盘和已上盘球堆。
- Space 是快落：会加速当前正在下落的球，并立刻释放预判队列头部的下一个球；伤害球也允许被快落和释放，但不会瞬移落地。
- 预判队列现在显示为小球图标，不是 C0/DMG 这种文字代码。

球类型：
- 颜色球：同色 5 个以上连接后闪烁，闪烁结束后清除；期望后续支持闪烁期间继续追加同色球来扩大效果。
- 战斗球：攻击、护盾、恢复。初始数字为 0，被附近闪烁颜色链增加数值；多个链可以叠加到同一个战斗球上。
- 伤害球：boss 攻击。boss 事件会把伤害球插入共享预判队列，轮到它才从自己的角度进入圆盘。伤害球有 warning/danger 两阶段；warning 阶段清掉无伤，danger 阶段清掉会伤害玩家；如果已上盘的伤害球越过危险边界会爆炸造成伤害。

当前重要规则语义：
- settled = 物理上稳定/锁住。
- board_attached = 已经接触圆盘/球堆，会跟着圆盘旋转。
- is_on_board = settled or board_attached。
- 纯下落中还没接触的球不参与链/边界伤害等规则。

当前需要设计讨论的重点：
1. 圆盘/核心不应叫磁力盘，也不应长得像原作。我们需要原创概念，比如魔法阵、八卦阵、星盘、共鸣核心、炼金仪式阵、量子/灵能圆环等。
2. 右侧 boss 区需要有明确视觉和反馈，比如 boss 张牙舞爪、受击、蓄力、施放攻击。
3. 预判队列、伤害球 warning/danger、快落、五连闪烁、战斗球充能、boss 受击都需要更明显的 UI/动效语言。
4. boss 机制需要可组合，方便以后做不同 boss。
5. 我希望先讨论设计，不要立刻实现。

请先帮我梳理：
- 这个游戏目前最有潜力的 3 个原创主题方向是什么？
- 每个方向的圆盘/核心、球、boss、UI 反馈会长什么样？
- 哪个方向最适合当前玩法并最能避开 Nintendo 既视感？

回答时请保持具体，可以提出命名、视觉元素、反馈方式和 boss 机制例子。
```

## Quick References For Implementation-Aware Designers

- Stable checkpoint to mention to coding agents: `6b4383a fix: allow fast drop for hazard orbs`
- Agent context file: `AGENTS.md`
- Current tuning resource: `data/orb_tuning.tres`
- Main scene: `scenes/main.tscn`
- Core controller: `src/game_controller.gd`
- Current UI: `src/ui/battle_ui.gd`, `src/ui/preview_orb_icon.gd`
- Current playfield: `src/playfield/playfield.gd`, `src/playfield/orb_node.gd`
