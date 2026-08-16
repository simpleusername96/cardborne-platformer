---
type: evidence
status: active
owner: BK
created: 2026-08-14
last_reviewed: 2026-08-14
topic: Versioned game-session logging for Cardborne performance, encounter pacing, and UI/UX diagnosis
scope: Local diagnostic capture, durable evidence promotion, event semantics, sampling, retention, comparison, privacy, and a deferred remote-telemetry boundary
related:
  - ../../cardborne-performance-engineering-policy.md
  - ../../execplans/2026-08-13-evidence-category-slots-and-scalable-swarm.md
  - ../../evidence/performance/2026-08-13-dense-enemy-stutter-evidence.md
  - ../performance/2026-08-13-enemy-arrival-and-engagement-research.md
---

# Cardborne Game Telemetry and Feedback Research

## Purpose

Synthesize reusable telemetry and feedback evidence for future Cardborne plans without creating a remote-telemetry requirement.

## Sources

The repository audit, comparable systems, and primary sources cited in the sections below form the evidence boundary.

## Findings

Cardborne should not start with an always-online analytics vendor. The first useful system is a
versioned, bounded, local diagnostic record that can be exported by the player and promoted into Git
only when it changes a decision. This gives future Codex sessions evidence for performance,
encounter pacing, and UI/UX without adding a server bill, a production dependency, or silent remote
collection.

The recommended architecture has three distinct records:

1. **Release evidence** links selected performance results, captures, builds, and validation output
   to an exact clean source commit and immutable artifact hashes.
2. **Session diagnostics** records low-cardinality lifecycle events plus bounded stage/run summaries
   under `user://diagnostics/`. It never records every frame, bullet, enemy, pointer movement, or raw
   route.
3. **Remote product analytics** is deferred. GitHub Pages and itch.io host static Web builds; they do
   not receive game telemetry by themselves. A future upload path needs an approved endpoint,
   consent, privacy policy, retention/deletion policy, cost ceiling, offline queue, and kill switch.

This separation matters. Performance evidence answers whether a build meets an engineering gate.
Session diagnostics explains what happened during a particular play session. Product analytics
would answer population-level questions. Treating them as one undifferentiated log makes comparisons
unreliable and increases cost and privacy risk.

## Current Cardborne Evidence Audit

The present answer to “are the logs saved by commit or version?” is **not consistently**.

| Evidence family | Current useful fields | Missing or non-durable facts |
| --- | --- | --- |
| Synthetic performance JSON | Scenario, seed, duration, Godot/renderer/viewport, thresholds, optional full commit and dirty flag | `build/**` is ignored; the commit can be empty; there is no durable index or artifact hash |
| Manual performance trace | Bounded buckets, slow frames, pressure, environment, full commit when the wrapper is used | Ignored local file; dirty detection currently ignores untracked source files; older traces use older schemas |
| Capture manifest | Locale, viewport, text scale, file list | No commit, build hash, seed, Godot version, timestamp, or durable storage |
| CI evidence | Full commit, Godot version, Web file count, UTC timestamp | Uploaded evidence expires after one day and is not connected to a tracked evidence ledger |
| Web build info | Release version, full commit, build time, PCK hash | Not exposed through one runtime session envelope or a tracked evidence record |
| Combat/engagement telemetry | Bounded in-memory counters and pressure samples | No persistent session/run ID, event schema, build identity, timestamp sequence, or export path |
| UI/gameplay actions | Existing panel and gameplay signals | No analytics event owner or persisted UI/UX summary |

The existing ignored files remain useful clues, but a filename, a short SHA, or an
`authoritative:true` field cannot prove provenance. A future agent must be able to reconstruct a
claim from the artifact itself or its tracked ledger entry.

## Transferable Patterns from Other Systems

These sources are used for mechanisms, not as a recommendation to adopt their SDKs.

### Stable event identity and explicit context

[OpenTelemetry's event conventions](https://opentelemetry.io/docs/specs/semconv/general/events/)
define an event as a named point-in-time occurrence and require a stable event name rather than a
name containing dynamic values. Its
[stable log data model](https://opentelemetry.io/docs/specs/otel/logs/data-model/) separates event
name, timestamp, severity, resource context, and attributes. Its
[naming guidance](https://opentelemetry.io/docs/specs/semconv/general/naming/) favors precise,
namespaced, low-cardinality names and deprecation instead of silent semantic reuse.

Cardborne should therefore version the event structure, keep IDs and coordinates in attributes or
bounded summaries, and never change the meaning of an existing event version in place.

### Events should answer declared design questions

[Unity Analytics events](https://docs.unity.com/en-us/analytics/events/events) model player actions
as events with contextual parameters and recommend using them to answer questions about difficulty,
tutorial understanding, engagement, and progression. The transferable lesson is to begin with a
question and its decision rule, not to record everything and hope a useful pattern appears later.

Cardborne's first questions are concrete:

- How long until the first enemy is visible and can engage?
- How long are the longest no-visible-threat gaps, including during and after a boss?
- Which exact work coincides with slow physics ticks?
- Do category slots reduce upgrade decision time and repeated focus movement?
- Are important announcements queued, interrupted, or dropped?
- Are Anomaly outcomes revealed, activated, and useful to enough targets to justify their space?

### Sampling and aggregation are correctness and cost controls

[PlayFab event sampling](https://learn.microsoft.com/en-us/xbox/playfab/data-analytics/export-data/event-sampling-overview)
documents that sampled results require their sampling ratio for correct interpretation and that
sampling reduces storage and query cost. Its
[telemetry overview](https://learn.microsoft.com/en-us/xbox/playfab/data-analytics/ingest-data/telemetry-overview)
also shows that performance, crashes, and player behavior can share an ingestion system while still
remaining distinct event families. PlayFab pricing meters events by size, including 1 KB blocks, so
unbounded high-frequency events directly become a cost problem.

[GameAnalytics' game-event guidance](https://docs.gameanalytics.com/events-metrics-and-filtering/event-types/design-events/)
recommends consistent event hierarchies, numeric values for changing measurements, and logical
areas instead of raw coordinates. Its
[cardinality guidance](https://docs.gameanalytics.com/event-tracking-and-integrations/data-retention-and-limits/event-tracking-and-cardinality-limits/)
explicitly recommends aggregating frequent actions into session summaries and avoiding timestamps,
coordinates, random IDs, and user IDs inside event names.

Cardborne should keep every lifecycle transition and outlier receipt, aggregate routine 1 Hz state
into stage summaries, and never emit one production event per actor, projectile, hit, frame, or
pointer movement.

### Local persistence works on both native and Web builds

[Godot's data-path documentation](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html)
defines `user://` as the writable persistent location and states that Web exports map it to a
device-local virtual filesystem backed by IndexedDB. This makes bounded local capture possible on
native, GitHub Pages, and itch.io. It does not make those records remotely accessible: the player
must explicitly export or upload them through a separately approved path.

## Candidate Architectures

| Candidate | Benefit | Cost or failure mode | Decision |
| --- | --- | --- | --- |
| Unstructured text log | Simple to print | Hard to compare, ambiguous schema, no bounded cardinality, poor automated analysis | Reject as the primary record; retain console text only for human diagnostics |
| Raw per-frame/per-actor JSONL | Maximum detail | Creates CPU/I/O pressure, huge files, noisy queries, and can cause the problem being measured | Reject for normal sessions; use bounded opt-in slow-tick receipts instead |
| Local structured session ring plus explicit export | No service bill, works native/Web, privacy-preserving, immediately useful to Codex | Only sessions that the user exports can be analyzed outside the device | **Select now** |
| Direct-to-vendor client telemetry | Cross-player aggregates and dashboards | SDK/dependency, consent and deletion obligations, variable cost, client key abuse/noise | Defer pending explicit product/privacy/cost approval |
| Self-hosted ingestion and warehouse | Full control | Operational burden, security, uptime, database and retention cost | Reject for the present project size |

## Selected Data Contract

### One immutable event envelope

Every persisted event uses this logical shape. The physical JSON can be compact, but the field
meaning must remain stable.

```json
{
  "event_name": "cardborne.encounter.stage_started",
  "event_version": 1,
  "schema_version": "1.0.0",
  "sequence": 12,
  "occurred_monotonic_ms": 8342,
  "run_elapsed_ms": 2190,
  "session_id": "local-random-id",
  "run_id": "local-random-id",
  "stage_index": 1,
  "build": {
    "version": "alpha.123+abcdef0",
    "commit": "full-40-character-sha-when-known",
    "dirty": false,
    "content_fingerprint": "sha256"
  },
  "context": {
    "platform": "Web",
    "godot": "4.7.1",
    "renderer": "gl_compatibility",
    "viewport": [1280, 720],
    "locale": "ko",
    "text_scale": 1.0,
    "input_family": "keyboard_mouse",
    "reduced_motion": false
  },
  "attributes": {}
}
```

The event name is stable and low-cardinality. A category ID, card ID, outcome ID, stage, or timing
value is an attribute. Localized text is never event identity. `sequence` and monotonic time preserve
ordering without relying on the wall clock. `content_fingerprint` covers gameplay resources and
configuration so two sessions with different pacing data are not silently compared.

The recorder remains an observer. Existing performance, stage-report, encounter, Upgrade, Anomaly,
and HUD owners publish bounded receipts or finalized summaries. The session recorder must not scan
the enemy store, recompute damage, own thresholds, decide spawns, drive UI state, or feed telemetry
back into gameplay.

### Signal registry

| Family | Required events or summaries | Primary question |
| --- | --- | --- |
| Session/run | `session_started`, `run_started`, `run_ended`, `session_summary` | Which build and environment produced the record, and did the run finish normally? |
| Encounter | `stage_started`, `arrival_cued`, `first_enemy_materialized`, `first_enemy_visible`, `first_player_damage`, `quota_reached`, `boss_started`, `boss_defeated`, `stage_ended`, `encounter_stage_summary` | Is pressure visible and continuous at the intended times? |
| Visibility gaps | Aggregate start/end internally; persist count, total, longest, phase, and threshold crossings | Where does the player experience an empty map? |
| Performance | `performance_stage_summary` and bounded top-32 slow-tick receipts only in diagnostic mode | Which exact work coincides with slow frames or physics ticks? |
| Upgrade UI | `upgrade_offer_shown`, `upgrade_selected`, `upgrade_confirmed`, `upgrade_stage_summary` | How long does selection take, how much focus movement occurs, and which categories confuse players? |
| Announcements | `announcement_summary` with shown, interrupted, queued, deduplicated, and dropped counts by semantic kind | Is important information lost or competing for one text channel? |
| Anomaly Device | `anomaly_revealed`, `anomaly_activated`, `anomaly_stage_summary` with affected count and active duration | Are outcomes recognized and useful, and is an effect too short to matter? |
| UI layout diagnostics | Development-only `layout_fault` with surface ID, locale, viewport class, and text scale | Which supported configuration clips or overflows? |

Do not record raw mouse coordinates, full movement paths, free-form player text, IP addresses,
device fingerprints, or a stable cross-install player identity. For a local diagnostic heatmap, use a
bounded coarse grid and persist only cell dwell totals; keep that feature opt-in and outside default
production capture.

### Bounded sampling and storage

- Discrete lifecycle events are always retained inside the current local session.
- Visible/near/exact enemy counts are accumulated at 1 Hz into min/mean/max and threshold-duration
  summaries. They are not written as one event per second.
- The performance recorder keeps its top 32 slow physics-tick receipts and top 64 slow-frame
  receipts only while diagnostic recording is explicitly active.
- Upgrade focus changes are counted and grouped by input family. Raw hover or focus-move events are
  not persisted.
- Announcement queue behavior is summarized by semantic kind. Localized message strings are not
  logged.
- Anomaly effects retain activation count, actual active time, affected target count, and a bounded
  maximum concurrent-target value; they do not retain every affected enemy ID.
- The local ring keeps the newest 20 completed sessions subject to a hard 25 MB total limit and a
  14-day maximum age. Eviction removes the oldest completed session first and never touches save or
  settings data.
- Stage summaries stay in bounded memory. Flush happens on Result, explicit export, a settled pause
  surface, or normal exit; a continuous stage transition is not a safe write point. Nothing
  serializes or writes synchronously inside enemy, projectile, collision, rendering, or input hot
  paths.

### Export and durable promotion

Native and Web builds expose one explicit `Export Diagnostics` action from Settings/Result. It
creates a redacted bundle containing selected session JSONL, a session summary, schema registry
version, and build identity. Export is a user action; there is no background upload.

Routine session files remain local and ignored. When a session changes an engineering or product
decision, a promotion tool validates and hashes it, writes one append-only ledger entry, and copies
the redacted decision-changing summary into the tracked evidence folder. Raw routes, screenshots,
and unrelated local sessions are not promoted.

## How Future Codex Sessions Should Use the Data

Do not infer a redesign from one number. Use an explicit signal-to-hypothesis table and compare only
compatible build/content/schema cohorts.

| Observed signal | Supported hypothesis | Required confirmation before changing the game |
| --- | --- | --- |
| First visible enemy exceeds 4 seconds or first meaningful threat exceeds 8 seconds | Opening cue, birth distance, or approach is too slow | Replay/capture the same seed and inspect cue, birth, visibility, and movement timing |
| No-visible-threat gap exceeds 3 seconds during ordinary play or after a boss | Scheduler continuity or offscreen placement is failing | Separate no live actor, no visible actor, and no committed threat |
| Physics p99 aligns with schedule/aggregate/pressure scans | Repeated bookkeeping is a hot owner | Same-build tail receipt and a one-owner ablation |
| Upgrade confirm time and focus moves remain high for one category | The label, category grouping, or card description is unclear | Korean/English capture plus input-family breakdown; do not assume category popularity means comprehension |
| Announcements are dropped or repeatedly interrupted | The single message queue needs priority/dedup tuning | Inspect message kind, duration, and simultaneous triggers; do not add a second surface |
| Anomaly reveal-to-break is long and affected count is low | Outcome communication, placement, or duration is weak | Compare each outcome separately and inspect effect footprint/readability |
| Layout faults correlate with locale, viewport, or 200% text scale | Responsive containment is broken | Reproduce the exact supported configuration and capture the surface |

For performance, an improvement claim requires the same scenario, seed/fingerprint, viewport,
renderer, authority class, and sampling mode. For UI/UX, a changed label or layout starts a new
content cohort even if the code commit is close. Schema migrations must preserve old readers or
declare that the cohorts are not directly comparable.

## Privacy, Cost, and Remote-Telemetry Gate

The selected local system has no recurring service charge. GitHub Actions remains a one-day
transport, not a log archive. Selected small evidence lives in Git; the local 25 MB ring lives on
the player's device.

Remote collection is explicitly outside the current implementation. Before enabling it, the owner
must approve all of the following in one decision:

- exact questions and necessary fields;
- consent and an in-game opt-out;
- privacy notice, data access/export, and deletion flow;
- endpoint/vendor, credentials, rate limit, abuse handling, and monthly cost ceiling;
- raw and aggregate retention;
- offline retry limits, batching, sampling weights, and a remote kill switch; and
- a validation build proving that upload work cannot affect gameplay timing.

## Research Conclusion

The useful near-term log is not a larger console transcript. It is a small, versioned evidence
system that records lifecycle truth and aggregates only the signals needed to answer declared
questions. It will let Codex distinguish “few enemies exist,” “enemies exist but are offscreen,”
“the player cannot understand a UI category,” and “a particular tick did too much work” without
turning normal play into another performance problem.
