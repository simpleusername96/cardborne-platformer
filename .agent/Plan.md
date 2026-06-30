# .agent/Plan.md

## Milestone Template

### Objective
- Build the PRD's playable vertical slice in milestone order, starting with a stable Godot project skeleton and player controller.

### Milestones

#### Milestone 1: Project Skeleton
Acceptance criteria:
- Godot project opens without missing-script errors.
- Main menu can enter Stage01.
- Player scene and basic HUD exist.
- README run instructions remain current.
Validation commands:
- `.\tools\godot.ps1 --version`
- `.\tools\godot.ps1 --path . --headless --import`

#### Milestone 2: Player Controller
Acceptance criteria:
- Player can move, jump, variable-jump, coyote-jump, buffer-jump, dash, crouch, fast-fall, take damage, and die in a test stage.
- Movement variables are exported for tuning.
Validation commands:
- `.\tools\godot.ps1 --path . --headless --import`
- Manual editor/playtest check from Stage01.
