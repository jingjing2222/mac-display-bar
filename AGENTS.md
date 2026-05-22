# AGENTS.md

## Scope

These instructions apply to this repository.

## Required Context

- Read `DESIGN.md` before any UI, layout, styling, component, or visual change.
- Treat `DESIGN.md` as the source of truth for React Native macOS design tokens and UI behavior.
- If a UI request conflicts with `DESIGN.md`, follow the user request and note the design deviation.

## Project

- App: macOS-only display control app scaffolded with React Native for macOS.
- No iOS or Android targets are expected.
- Use React Native primitives (`View`, `Text`, `Pressable`, `TextInput`, `ScrollView`, `FlatList`) instead of web DOM assumptions.

## Design Rules

- Use `StyleSheet.create` or central typed token objects for colors, spacing, radius, and typography.
- Use numeric RN values, not CSS strings like `"24px"`, `rem`, `var(...)`, or `calc(...)`.
- Use `useWindowDimensions()` for responsive behavior.
- Use `Pressable` state callbacks for pressed, hovered, and focused styles.
- Use surface lift and 1px borders for depth; avoid dark drop shadows unless explicitly requested.
- Keep the default app surface dark according to `DESIGN.md`.

## Commands

- Install: `yarn install`
- Native deps: `pod install --project-directory=macos`
- Metro: `yarn start`
- Run macOS app: `yarn macos`
- Build macOS app: `yarn build:macos`
- Lint: `yarn lint`
- Format check: `yarn format:check`
- Tests: `yarn test`

## Validation

- For code changes, run the narrowest relevant command first.
- For UI changes, verify the app renders on macOS when feasible.
- For design-token or documentation-only changes, at least validate markdown/front matter where practical.
