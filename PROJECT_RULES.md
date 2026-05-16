# Project Rules: S_Music

## 1. Clean Architecture Guidelines
- **Core**: Contains pure logic, utilities, extensions, and app-wide configurations.
- **Theme**: Centralized theme definitions, colors, and typography.
- **Shared**: Reusable widgets and UI components (e.g., buttons, glass containers).
- **Features**: Modular folders for each major app section. Each feature should be self-contained.

## 2. Naming Conventions
- **Folders/Files**: `snake_case`
- **Classes/Widgets**: `PascalCase`
- **Variables/Functions**: `camelCase`

## 3. Folder Ownership
- Feature folders (e.g., `features/home/`, `features/player/`) own their specific UI and local state.
- Global state or cross-feature data resides in `core/` or dedicated domain folders.

## 4. Dependency Policy
- Keep external dependencies minimal.
- All state management runs through Riverpod.
- All navigation runs through `go_router`.

## 5. Widget Conventions
- Prefer `StatelessWidget` and `ConsumerWidget` over `StatefulWidget` where possible.
- Shared widgets must be dumb (relying on passed props rather than fetching state).

## 6. Responsive Rules
- UI must be fluid and scale relative to screen width/height.
- Always handle safe areas properly.
