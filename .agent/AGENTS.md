# .agent/AGENTS.md

## How We Work Here
- This folder stores durable project memory, evolving plans, and reusable workflow notes.
- For broad, risky, or multi-file governance work, read the relevant `.agent/*` files before implementation.
- Create an ExecPlan only when the work matches `.agent/PLANS.md`; simple questions, single-note judgments, and small one-file edits do not need one.
- Keep diffs scoped and validation explicit.
- Treat root `AGENTS.md` as the stable repo-wide operating contract.
- Treat the nearest local `AGENTS.md` as the source of truth for subtree-specific placement or operating rules.

## Customization
- Install repo-local skills only when they map to a real workflow boundary.
- Prefer one clear local skill per workflow over many generic checklists.
- Move repeated user instructions or repeated agent mistakes into the right durable layer.
- Keep transient discoveries in `.agent/*` instead of turning root `AGENTS.md` into a structure map.
