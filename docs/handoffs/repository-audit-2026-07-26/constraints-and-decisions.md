# Constraints And Decisions

## Must Preserve

- Godot 4.7 stable and GDScript; no engine migration or new production
  dependency is in scope.
- Manual aim, held primary fire, the one-second Breach Shot, dash, passive
  seekers, EMP, authored encounter pressure, map pickups, card upgrades,
  optional field bosses, and stage bosses.
- The connected five-stage run and one run-selected persistent field.
- Korean as default and complete Korean/English parity.
- The flat-color Sunken Ceramic Fresco visual system.
- Card behavior outside UI code and collision truth independent from visual
  geometry.
- Reliable performance, fair telegraphs, first-clear readability, and
  deterministic validation ahead of content breadth.

## Review Boundaries

- Read-only: do not edit, generate patches, install packages, run destructive
  commands, or change repository state.
- Do not recommend a rewrite solely because a file is large.
- Do not treat the canonical specs as automatically correct; verify claims
  against code and validators.
- Do not treat passing tests as proof of fun, complete runtime coverage, or
  correct visual output.
- Do not suggest generic architecture patterns without naming the concrete
  current responsibility, failure mode, and relevant files.
- Separate correctness defects from maintainability debt and speculative
  product ideas.

## Source Of Truth Hierarchy

1. Current local code, resources, and executable tests
2. `AGENTS.md`
3. Canonical product and visual specifications
4. This orientation package
5. Claude's external feedback

## Known Deliberate Decisions

- The project remains a vehicle shooter rather than returning to humanoid
  sprite-heavy action.
- Exploration puzzles, a separate base stage, and unconstrained procedural map
  topology are non-goals for the current executable.
- The field is reused across stages while tactical cover, stationary threats,
  items, crates, and support fields vary deterministically.
- Routine boss hits cannot stun-lock; Breach cancellation applies only to
  approved signature startup states.
- Runtime labels, stats, cooldowns, focus, selection, localization, and
  discovery state remain live UI, not rasterized assets.

