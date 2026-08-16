---
type: evidence
status: active
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
topic: Player-facing Korean and English names for Cardborne upgrade category slots
scope: Antigravity consultation, repository verification, selected labels, descriptions, and terminology boundaries
related:
  - ../../execplans/2026-08-13-evidence-category-slots-and-scalable-swarm.md
  - ../../../docs/product/vehicle_upgrade_catalog.md
  - ../../../docs/design/VISUAL_SYSTEM.md
---

# Upgrade Category Language Review

## Purpose

Preserve the reusable evidence and selected language boundary for player-facing upgrade categories.

## Sources

The requested Antigravity model label `Gemini 3.7 Flash (High)` was tested first with Antigravity
CLI `1.1.11`. The installed model registry rejected it as unknown. The same read-only question was
then completed with `Gemini 3.6 Flash (High)`.

- Failed 3.7 job: `20260814T001636669Z-54094afe-31ff-416a-9502-b81ad1724079`
- Completed 3.6 job: `20260814T002903650Z-ba2df583-a5d2-40d2-8fbb-562ad9d8f949`
- Consultation mode: read-only `ask`; no repository edits

The external review correctly identified three important ambiguities:

- `보조무장 / Secondary Weapons` can sound manually fired even though these weapons fire
  automatically.
- `액티브 장비 / Active Weapon` does not clearly say that the player presses the action button.
- `전투 조건 / Combat Conditions` can sound like a stage rule instead of a conditional player
  benefit.

It proposed `자동 무장`, `Active Skill`, and `전술 특성 / Combat Perks` as clearer concepts. It
also proposed `원소 속성 / Element`, but that recommendation was based on the supplied conceptual
description and requires correction against the live catalog.

## Repository Verification

The live 28-card catalog uses stable internal IDs:

`primary`, `secondary`, `element`, `activated`, `chassis`, and `combat`.

Those IDs own compatibility and must not be renamed merely to improve UI copy. Player-facing names
are a localization contract and may differ from internal IDs.

The actual `element` group is not purely elemental. It contains Thermal Burst, Bio Toxin, Cryo Slow,
and Shock Disruption, with one damage slot and one utility slot. `원소 속성 / Element` would make
Bio Toxin and the damage/utility split less obvious. `공격 효과 / Attack Effects` describes the
shared player-facing behavior: these cards add an effect to eligible attacks.

The actual `activated` group contains one manually used EMP replacement plus shared cooldown and
damage enhancements. The Korean heading should therefore state the interaction, while the English
heading can use the established genre term `Active Skill`.

## Findings

The selected player-facing set and rejected alternatives below reflect the repository verification and consultation evidence.

## Selected Player-facing Set

| Internal ID | Korean heading | English heading | Accessible description |
| --- | --- | --- | --- |
| `primary` | `주무장` | `Main Gun` | Changes the held-fire main gun. |
| `secondary` | `자동 무장` | `Auto Weapons` | Weapons that fire automatically, plus their shared enhancements. |
| `element` | `공격 효과` | `Attack Effects` | Adds damage or control effects to eligible attacks. |
| `activated` | `직접 발동` | `Active Skill` | Replaces EMP with a skill used by pressing the action button. |
| `chassis` | `차체 강화` | `Chassis` | Movement, durability, collection, barrier, and recovery upgrades. |
| `combat` | `전술 특성` | `Combat Perks` | Passive benefits triggered by combat conditions. |

The visible grid uses the short headings. The descriptions belong in accessibility/tooltip metadata
and documentation, not as six permanent paragraphs that crowd the build rail.

## Rejected or Deferred Labels

- `보조무장 / Secondary Weapons`: familiar but does not distinguish automatic behavior from the
  manually activated category.
- `원소 속성 / Element`: short, but inaccurate for Bio Toxin and less clear about attack ownership.
- `액티브 장비 / Active Weapon`: mixes gear and weapon terms and does not communicate direct input.
- `특수 모듈 / Active Skill`: the Korean and English meanings do not align.
- `전투 조건 / Combat Conditions`: can be read as mission restrictions or stage modifiers.
- `서브`, `액티브`, and `특성` alone: compact but depend too heavily on genre jargon and surrounding
  context.

## Terminology Contract

- Internal category IDs and card compatibility remain unchanged.
- The category descriptor owner supplies localization keys, capacity, semantic positions, and the
  accessible description. UI code does not infer meaning from the visible heading.
- `slot` in this surface means a presentation position for one acquired card. It does not mean an
  equipment limit, an unequip action, or a saved inventory position.
- Upgrade and Result use the same descriptor set and the same frozen build snapshot.
