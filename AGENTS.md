# AGENTS.md

## Project
- This repository exists to build the Godot 4.x GDScript MVP described in `docs/product/2d_platform_action_card_game_prd.md`.
- Treat that PRD as the active product specification unless the user explicitly supersedes it.
- The MVP target is a compact playable vertical slice: three platform-action stages, one 3-card reward flow after normal stages, and one telegraphed two-phase boss fight.
- Prioritize player-controller reliability before adding broad content. Movement feel, damage response, and no-soft-lock stage flow are the highest-risk areas.
- Use placeholder shapes, simple sprites, and editor-friendly exported values. Do not add external asset dependencies for the MVP unless the user asks.

## Operating Model
- Use Godot 4.7 stable when available. The standard GDScript build is enough; do not switch to C#/.NET without explicit user direction.
- Prefer `.\tools\godot.ps1` for local Godot commands so future agents use the same runtime resolution path.
- Work milestone by milestone from the PRD. For moderate or larger implementation work, start with the relevant `.agent/*` context and create an ExecPlan only when `.agent/PLANS.md` says one is warranted.
- Keep gameplay systems responsibility-shaped:
  - player movement/combat belongs under `scripts/player/`
  - damage helpers belong under `scripts/combat/`
  - enemy behavior belongs under `scripts/enemies/`
  - boss patterns belong under `scripts/bosses/`
  - card data/effects belong under `scripts/cards/` and `data/cards/`
  - stage flow belongs under `scripts/stages/`
  - UI belongs under `scripts/ui/`
  - global run state/autoloads belong under `scripts/autoload/`
- Do not hard-code cards directly into UI or player code. Card data and effect application should stay separate.
- Every damaging boss attack needs a visible startup warning, active damage window, and recovery, even with placeholder rectangles.

## Living Guidance
- This file is project-specific operating guidance.
- Its contents may be added, edited, reorganized, or removed as user requests and project conditions change.
- Keep only durable repo-wide instructions here when they do not need a separate workflow trigger.
- Prefer folder and file names that reveal purpose and function instead of explaining the whole structure in root `AGENTS.md`.
- Do not treat current folder structure, temporary placement decisions, or subtree names as a root-level contract unless the user explicitly wants that contract.

## Preflight
<!-- Fixed section. Keep this block exactly as defined by agent-governor. -->
### General
- Add short, truthful docstrings or inline comments when they materially clarify intent, responsibility, invariants, non-obvious constraints, or future handoff points for humans and agents.
- Prefer append-first updates that preserve prior intent and newly discovered constraints, but rewrite or remove comments when they become stale, redundant, or too long to stay trustworthy.
- If a commented class, function, or code block is deleted or its behavior changes, update or delete the attached comment in the same change.
- If the user's intended outcome is materially ambiguous and the ambiguity could change the implementation, output, or conclusion, ask a concise follow-up question with explicit options before proceeding.
- Do not ask follow-up questions when a reasonable, low-risk default is already clear from the request and local context.
- Prefer responsibility-shaped files and modules over large catch-all scripts; before expanding a large file, identify its owned responsibility, what it should not absorb, and whether local boundaries already cover the change.

### FE
- Prefer a component-driven UI so design and behavior stay consistent.
- Check alignment, typography, spacing, and padding/gap explicitly.
- Check overflow and clipping explicitly; no child element should be visibly cut off or exceed its container at supported browser viewport sizes.
- Avoid unnecessary explanatory or guideline text.
- Keep non-essential elements visually restrained.

### BE
- Remove obsolete legacy code once the replacement is clearly in place.
- Design for reuse when the boundary is clear.
- Add logging where operational visibility matters, and persist it when the workflow depends on it.

### DB
- Ask before running broad or intensive database reads unless the need is already explicit.

## Project Memory
- Before broad, risky, or multi-file governance work, read the relevant files under `.agent/`.
- Use an ExecPlan only for work that matches the ExecPlan Standard in `.agent/PLANS.md`; do not create one for simple questions, single-note judgments, or small one-file edits.
- Use `.agent/*` for durable project memory, evolving plans, workflow notes, and recurring gotchas that do not need a separate skill.
- Keep transient discoveries and in-progress status there instead of in root `AGENTS.md`.

## Documentation Lifecycle
- For agent-relevant Markdown that may guide future work, use `$doc-lifecycle-steward` to classify lifecycle `type` and `status`.
- Add lifecycle frontmatter only to agent-relevant `policy`, `spec`, `plan`, `handoff`, `evidence`, or `record` documents.
- Do not frontmatter-stamp protected instruction files such as `AGENTS.md`; audit them and propose minimal changes instead.

## Local Skills
- Repo-local skills may exist under `.agent/skills/`.
- Use them when the task matches their workflow boundary.
- If the repo actually has stable local skills worth surfacing repeatedly, record:
  - the skill name
  - what workflow it governs
  - when it should trigger
  - what validation or artifact contract it enforces

## Placement Rules
- Put stable repo-wide guidance in this file.
- Put subtree-specific placement or operating rules in the nearest local `AGENTS.md`.
- Put durable supporting memory and evolving notes in `.agent/*`.
- Prefer purpose-revealing naming over root-level structure prose where naming can carry the meaning.
- Create a repo-local skill only when a workflow repeats and needs its own trigger, stop conditions, or artifact contract.
- Do not fill root `AGENTS.md` with directory maps, transient inventories, or guidance that only describes the current layout.
- Do not create separate files whose only purpose is to mirror root guidance.
