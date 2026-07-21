---
type: spec
status: active
owner: BK
created: 2026-07-18
last_reviewed: 2026-07-22
canonical_for: Cardborne post-proof reward, upgrade, and progression ownership boundaries
scope: Future cards, materials, skills/stats, equipment, Forge, reward sources, and persistence after the Floor 1 map/enemy foundation
source: Owner direction on 2026-07-18, retained asset manifest, active isometric proof contract, and reviewed pre-pivot progression boundaries at Git 7cc069c
related:
  - ./isometric_action_rpg_product_brief.md
  - ../../.agent/execplans/2026-07-18-flooded-works-floor1-map-enemies.md
  - ../design/UI_VISUAL_SYSTEM.md
  - ../../art/ui/production/asset-manifest.json
---

# Cardborne Progression and Upgrade System Contract

## Purpose

Define how future rewards from terrain props, monsters, encounters, and bosses
become cards, materials, skills/stats, and equipment without coupling progression
to Floor 1 enemy or room code. This is an accepted future product boundary, not
authorization to implement progression during the current map/enemy plan.

## Scope

This specification covers reward-source ownership, run-local versus persistent
state, material and card roles, equipment/Forge behavior, skill/stat upgrades,
reward transactions, UI boundaries, and the reviewed concepts that may be
recovered from the retired platformer. The vehicle run-local layer is now active;
persistent materials, equipment, Forge, and mastery remain future scope.

## Requirements

### Progression layers

| Layer | Player question | State lifetime | Primary source | Primary sink/effect |
| --- | --- | --- | --- | --- |
| Run card | How does this run's combat behavior change now? | Current run | Major encounter, elite cache, boss offer | Adds or changes an action trigger; resets at run end |
| Common material | What persistent option do I unlock next? | Persistent | Encounter settlement, destructible/material cache | Forge recipes and early mastery nodes |
| Boss material | Which capstone or boss-family item becomes available? | Persistent | Boss victory only | Capstone mastery and boss equipment |
| Equipment | What starting tradeoff/tool do I bring? | Persistent ownership/loadout | Forge blueprint, authored cache, boss receipt | Changes weapon/armor behavior or constrained stats |
| Mastery | Which skill or bounded stat branch becomes permanent? | Persistent per Traveler | Forge/mastery screen | Unlocks action variants first, bounded stats second |

No two layers may provide the same cadence and the same reward. Cards are not
permanent mastery nodes; materials are not run currency; equipment is not a
strict numerical tier ladder.

### State ownership

Run-local state contains:

- selected cards and stack counts;
- health, potion charges, temporary room buffs, and current route;
- pending reward-choice transaction IDs;
- temporary Forge effects only if a later plan explicitly adds them.

Persistent profile state contains:

- material wallet;
- owned equipment and equipped loadout;
- crafted blueprints and mastery purchases;
- boss-clear unlocks;
- settings and schema version.

Floor rooms, enemy actors, props, and UI do not write either state directly.
They emit typed source/claim intents to the reward or progression owner.

### Initial material catalog

The first persistent catalog is deliberately small:

| ID | Source | Use |
| --- | --- | --- |
| `rusted_scrap` | Flooded Works ordinary-encounter settlement, waterlogged crates, authored salvage cache | Shared equipment recipes and early mastery |
| `slime_residue` | Slime-family encounters and Slime King victory | Slime/survival equipment and related mastery |
| `boss_core` | First Slime King victory transaction only | One capstone branch and one boss equipment blueprint |

Do not restore `sky_thread`, coin, XP, random affix currency, or multiple crafting
materials until another region/weapon creates a real, non-overlapping need.

### Reward-source matrix

| Source | Presentation | Reward policy |
| --- | --- | --- |
| Ordinary enemy defeat | Defeat feedback only | Contributes to the encounter settlement; does not spray an individual random drop |
| Required encounter completion | One concise settlement bundle | Fixed `rusted_scrap` range from an authored table; transaction applies once |
| Waterlogged supply crate | Small loose pickup | If potion charges are below cap, authored supply crates may produce one potion charge; otherwise their progression table may produce `rusted_scrap x1` after the upgrade system exists |
| Authored salvage cache/material node | In-world claim, then receipt | Guaranteed `rusted_scrap`; optional and never required for route completion |
| Calibration/relay/boss cache | Full three-card choice over the dimmed live field | Exactly one compatible run upgrade; mandatory and applied once per transaction |
| Optional field-boss cache | Full three-card choice with explicit leave action | One compatible run upgrade or one confirmed decline |
| Elite encounter/cache | Full reward receipt | Card, blueprint, or equipment discovery according to an authored table; never all three at once |
| Slime King defeat | Boss receipt | Guaranteed `boss_core x1`, bounded `slime_residue`, and one authored boss blueprint/unlock; no random ordinary loot burst |

Important cards, blueprints, and equipment never exist as tiny loose floor items.
Only potion charges and common material bundles use proximity pickup presentation.

### Card contract

- Cards are `Resource` definitions with stable ID, display data, compatibility,
  trigger, bounded effects, maximum stacks, and optional internal cooldown.
- UI reads card definitions and emits one choice. It never implements effects.
- The effect runtime subscribes to typed combat events and cannot trigger itself.
- The implemented 34-definition catalog permits bounded numeric foundations when
  exact previews and maximum levels are shown. Source filtering still guarantees
  visible behavior-changing geometry, element, passive, dash, or EMP choices
  during the run rather than offering only percentage accumulation.
- Burn, poison, and slow cores are mutually exclusive for a run. Prerequisites,
  exclusions, stack caps, and floors are validated before an offer or apply.
- Cards reset at run end and never modify persistent equipment definitions.

### Equipment and Forge contract

- Persistent slots begin with Weapon, Armor, and Charm. A Relic slot remains
  locked until Boss Core content is implemented.
- Every item has stable ID, compatible actions, behavior modifiers, bounded stat
  modifiers, recipe, owned/unowned state, and presentation ID.
- New items must offer a tradeoff or play-pattern change. A strict “same weapon
  but larger damage number” is not a sufficient equipment identity.
- Forge outcomes are deterministic. Crafting or upgrading never has failure,
  destruction, downgrade, or hidden random quality.
- A recipe lists exact materials before confirmation. The transaction is applied
  once and produces an immutable receipt for UI and save recovery.
- Duplicate discoveries convert through an explicit salvage rule; UI never
  silently discards or auto-equips them.
- Retained equipment illustrations and material SVGs in
  `art/ui/production/asset-manifest.json` are approved identity assets, not proof
  that their retired stats or loadout behavior remain valid.

### Skill and stat upgrade contract

- Mastery is persistent per Traveler and is data-driven; player or UI scripts do
  not branch on node IDs.
- Every branch starts with a behavior or rule unlock, then may contain bounded
  stat support, then one conditional capstone.
- Allowed bounded stats include maximum health, guard efficiency within a hard
  cap, dash cooldown within a hard floor, potion capacity, and action-specific
  stagger. Unconditional all-damage stacking is not a branch identity.
- Node prerequisites and costs are explicit. Purchasing is deterministic and
  idempotent; a repeated transaction returns the prior receipt.
- The base Traveler remains able to clear Floor 1 without mastery purchases.
- Respec policy, exact costs, and final node counts require the separate
  progression implementation plan; this specification does not invent balance
  before the combat floor is measured.

### Reward transaction contract

Every reward source creates an idempotent key:

```text
run/session ID + room ID + source anchor ID + reward sequence
```

Resolution flow:

```text
RewardSourceContext
  -> RewardTable resolves a deterministic claim
  -> RewardTransaction is created
  -> owning run/profile service applies it once
  -> transaction key and immutable result are recorded
  -> UI receives a read-only receipt snapshot
```

- Enemy/prop/boss code references only a `reward_table_id` and source context.
- Replaying an applied transaction returns the recorded result and grants nothing
  twice.
- A room transition may wait for a mandatory card choice, but it does not apply
  the card itself.
- Common-material settlement policy and save timing must be explicit in the
  implementation plan. Boss Core cannot exist before boss-victory confirmation.

### Reuse decision for the retired implementation

Git commit `7cc069c` is a read-only design/source boundary. Future work may
re-derive these concepts after current-code review:

- `CardDefinition` and effect definitions;
- `RewardTable`, `RewardEntry`, deterministic resolution, transaction, receipt;
- equipment blueprint/catalog/resource separation;
- profile/run state separation and idempotent persistence.

Future work must not cherry-pick the retired `PlayerCardRuntime`, enemy/drop
scripts, Forge/merchant UI, save schema, platform movement triggers, card IDs
tied to jumping, or broad economy unchanged. Current 3D combat events, controls,
damage requests, and product language define the new implementation.

### UI boundary

- Card rewards and boss receipts keep the live room visible under a dim layer.
- Forge and mastery are dedicated non-combat surfaces reached from a future safe
  intermission, not popups spawned next to an NPC during active combat.
- Panels, buttons, icons, and focus remain live Godot UI using the current Theme
  and SVG masks; reward/item portraits remain raster assets.
- UI presents snapshots and sends intents. It cannot mutate run/profile state,
  resolve random rewards, deduct materials, or equip items directly.

### Audio/settings boundary

Progression screens inherit the same Master/SFX settings store defined by the
Floor 1 plan. They do not introduce their own audio schema. A Music bus is added
only with an approved music asset and implementation plan.

## Acceptance Criteria

- Each reward source resolves through a typed, deterministic, idempotent
  transaction and can be retried without duplicate application.
- Run cards reset at run end; persistent materials/equipment/mastery survive
  restart according to the later save contract.
- `rusted_scrap`, `slime_residue`, and `boss_core` have distinct sources and
  sinks; no unused currency appears in the first implementation.
- Ordinary enemies do not create random loot clutter; encounter settlements and
  authored caches remain visible and attributable.
- Vehicle reward sources can present compatible entries from the 34-definition
  catalog without card logic in UI or room code.
- Forge recipes show exact costs and outcomes, never fail randomly, and apply once.
- Base equipment and zero mastery can clear Floor 1.
- Every mastery branch begins with behavior and caps its supporting numerical gains.
- Existing asset IDs resolve through a manifest or declared fallback without
  restoring retired behavior.
- No retired platform movement, jump trigger, save schema, or economy service is
  accepted merely because it exists in Git history.
- A separate active ExecPlan, repository/current-runtime audit, migration choice,
  tests, and persistence safety review exist before implementation begins.

## Non-Goals

- Persistent material, Forge, equipment, or mastery runtime beyond the current run-local build.
- Final economy costs, drop rates, node counts, or complete equipment catalog.
- Random item rarity, procedural affixes, durability, repair, ammunition economy,
  gacha, battle pass, or online inventory.
- Restoring character-class cards tied to platform jumping or air attacks.
- Making progression mandatory for the first Floor 1 clear.
- Adding merchant or Forge NPC popups inside active combat rooms.

## Related

- [Current proof behavior](./isometric_action_rpg_product_brief.md)
- [Floor 1 map/enemy execution plan](../../.agent/execplans/2026-07-18-flooded-works-floor1-map-enemies.md)
- [UI and asset boundary](../design/UI_VISUAL_SYSTEM.md)
- [Retained production asset manifest](../../art/ui/production/asset-manifest.json)
