# AGENTS.md

## Project
- Cardborne is a Godot 4.7 GDScript top-down vehicle action shooter.
- The current product is the connected five-stage run defined in `docs/product/vehicle_game_spec.md`.
- Preserve manual aim, uniform held primary fire, dash, passive seekers, EMP, authored encounters, map pickups, card upgrades, and quota-gated stage bosses.
- Korean is the default language; Korean and English must remain complete on every user-facing surface.
- Before substantial user-facing interface work, load `$uiux-gate` and read `.agents/design/DESIGN.md` to resolve product intent, authority order, preserved experience contracts, and runtime owners.
- For every Cardborne visual task, use `$cardborne-visual-authority` before creating, editing, generating, reviewing, approving, promoting, or switching any asset, UI, HUD, world visual, actor, projectile, effect, mockup, sheet, or workbench candidate. Read `docs/design/VISUAL_SYSTEM.md` completely and inspect
  `docs/design/cardborne-universal-art-style-reference.png` at original detail;
  the sheet is a mandatory style reference, never asset approval.
- Treat familiar science fiction as the visual baseline. Do not introduce a named material, cultural, marine, or ritual theme without explicit user approval.
- Prioritize first-clear readability, fair pressure, responsive control, target priority, and reliable performance before adding content breadth.

## Operating Model
- Use Godot 4.7 stable and GDScript. Do not switch engines or add production dependencies without explicit user direction.
- Prefer `./tools/godot.ps1` for local Godot commands.
- Keep stage definitions, enemy roles, encounter coordination, card data, combat state, UI, settings, and audio in their existing responsibility owners.
- Keep card behavior out of UI code and keep visual geometry independent from collision truth.
- Run the focused validators under `tools/validation/` after relevant changes. Run the Web export before handing off broad runtime changes.
- Run `./tools/validation/validate_cardborne_visual_authority.ps1` whenever the visual authority pair, its workflow, or an active visual plan/workbench surface changes.

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
- Check overflow and clipping explicitly; no child element should be visibly cut off or exceed its container at supported desktop/mobile widths.
- Avoid unnecessary explanatory or guideline text.
- Keep non-essential elements visually restrained.

### BE
- Remove obsolete legacy code once the replacement is clearly in place.
- Design for reuse when the boundary is clear.
- Add logging where operational visibility matters, and persist it when the workflow depends on it.

### DB
- Ask before running broad or intensive database reads unless the need is already explicit.

## Project Memory
- Before broad, risky, or multi-file governance work, read the relevant files under `.agents/`.
- Use an ExecPlan only for work that matches the ExecPlan Standard in `.agents/PLANS.md`; do not create one for simple questions, single-note judgments, or small one-file edits.
- Use `.agents/*` for durable project memory, evolving plans, workflow notes, recurring gotchas, and repo-local skills.
- Keep transient discoveries and in-progress status there instead of in root `AGENTS.md`.

## Documentation Lifecycle
- For agent-relevant Markdown that may guide future work, use `$doc-lifecycle-steward` to classify lifecycle `type` and `status`.
- Add lifecycle frontmatter only to agent-relevant `policy`, `spec`, `plan`, `handoff`, `evidence`, or `record` documents.
- Do not frontmatter-stamp protected instruction files such as `AGENTS.md`; audit them and propose minimal changes instead.

## Local Skills
- Repo-local skills live under `.agents/skills/`, where Codex can discover them natively.
- Use them when the task matches their workflow boundary.
- `$cardborne-visual-authority` governs every player-facing visual task. It enforces the canonical document-and-sheet preflight, raster/ImageGen reference input, provenance evidence, and rejection of ungrounded visual output.
- If the repo actually has stable local skills worth surfacing repeatedly, record:
  - the skill name
  - what workflow it governs
  - when it should trigger
  - what validation or artifact contract it enforces

## Placement Rules
- Put stable repo-wide guidance in this file.
- Put subtree-specific placement or operating rules in the nearest local `AGENTS.md`.
- Put durable supporting memory and evolving notes in `.agents/*`.
- Prefer purpose-revealing naming over root-level structure prose where naming can carry the meaning.
- Create a repo-local skill only when a workflow repeats and needs its own trigger, stop conditions, or artifact contract.
- Do not fill root `AGENTS.md` with directory maps, transient inventories, or guidance that only describes the current layout.
- Do not create separate files whose only purpose is to mirror root guidance.
