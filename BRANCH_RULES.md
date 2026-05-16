# Branch Rules

## Branch Isolation
All development must occur on dedicated feature branches or worktrees. The `main` branch is protected and should only receive working, tested code.

## Main Branches
- `main`: The stable production-ready branch.

## Feature Branches
Format: `feature/<feature-name>`
- `feature/ui-screens`: UI placeholders and screen structure.
- `feature/audio-engine`: Audio playback and logic systems.
- `feature/theme-engine`: App styling, animations, and custom UI systems.
- `feature/optimization`: Performance tweaks and refactoring.

## Committing Rules
- Commit messages should be descriptive.
- Commit often to your feature branch.
- Ensure the project runs successfully before pushing to the remote.
