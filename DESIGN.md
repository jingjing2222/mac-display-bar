---
version: alpha
name: HashiCorp-inspired RN macOS design system
description: "React Native for macOS design tokens and implementation notes for a HashiCorp-inspired dark technical UI. Tokens use React Native StyleSheet-compatible values: numeric spacing, numeric font sizes, numeric line heights, string font weights, no CSS units, no CSS selectors, no web-only layout primitives. The system keeps HashiCorp's black canvas, charcoal surfaces, restrained gray hairlines, and per-product accent colors, but expresses them through RN primitives such as View, Text, Pressable, TextInput, ScrollView, FlatList, and useWindowDimensions."

platform:
  target: react-native-macos
  primitives:
    - View
    - Text
    - Pressable
    - TextInput
    - ScrollView
    - FlatList
    - SafeAreaView
  styling:
    source: StyleSheet.create
    units: unitless device-independent pixels
    colorFormat: hex or rgba string
    fontWeight: string values
    lineHeight: absolute numeric value
    noCss:
      - px suffixes
      - rem/em
      - media queries
      - CSS grid
      - sticky positioning
      - pseudo classes
      - CSS variables
      - web hover selectors

colors:
  primary: "#000000"
  onPrimary: "#ffffff"
  accentBlue: "#2b89ff"
  ink: "#ffffff"
  inkMuted: "#b2b6bd"
  inkSubtle: "#656a76"
  canvas: "#000000"
  surface1: "#15181e"
  surface2: "#1f232b"
  surface3: "#3b3d45"
  hairline: "#3b3d45"
  hairlineSoft: "#252830"
  hairlineTranslucent: "rgba(178,182,189,0.1)"
  inverseCanvas: "#ffffff"
  inverseInk: "#000000"
  productTerraform: "#7b42bc"
  productTerraformBright: "#911ced"
  productVault: "#ffcf25"
  productConsul: "#e62b1e"
  productWaypoint: "#14c6cb"
  productWaypointDeep: "#12b6bb"
  productVagrant: "#1868f2"
  productNomad: "#00ca8e"
  productBoundary: "#f24c53"
  amber100: "#fbeabf"
  amber200: "#bb5a00"
  blue7: "#101a59"
  semanticSuccess: "#00ca8e"
  semanticWarning: "#ffcf25"
  semanticError: "#e62b1e"
  semanticVisited: "#a737ff"

typography:
  fontFamily:
    preferred: HashiCorpSans
    bundledFallback: Inter
    systemFallback: System
    rnDefault: undefined
  displayXl:
    fontSize: 80
    fontWeight: "700"
    lineHeight: 94
    letterSpacing: -2.5
  displayLg:
    fontSize: 56
    fontWeight: "700"
    lineHeight: 66
    letterSpacing: -1.6
  displayMd:
    fontSize: 40
    fontWeight: "600"
    lineHeight: 48
    letterSpacing: -1
  headline:
    fontSize: 28
    fontWeight: "600"
    lineHeight: 34
    letterSpacing: -0.6
  cardTitle:
    fontSize: 22
    fontWeight: "600"
    lineHeight: 26
    letterSpacing: -0.4
  subhead:
    fontSize: 20
    fontWeight: "600"
    lineHeight: 27
    letterSpacing: -0.2
  bodyLg:
    fontSize: 18
    fontWeight: "500"
    lineHeight: 30
    letterSpacing: 0
  body:
    fontSize: 16
    fontWeight: "500"
    lineHeight: 24
    letterSpacing: 0
  bodySm:
    fontSize: 14
    fontWeight: "500"
    lineHeight: 24
    letterSpacing: 0
  caption:
    fontSize: 13
    fontWeight: "500"
    lineHeight: 18
    letterSpacing: 0.2
  button:
    fontSize: 14
    fontWeight: "600"
    lineHeight: 18
    letterSpacing: 0
  eyebrow:
    fontSize: 12
    fontWeight: "600"
    lineHeight: 15
    letterSpacing: 0.6

radius:
  xs: 4
  sm: 6
  md: 8
  lg: 12
  xl: 16
  xxl: 24
  pill: 9999
  full: 9999

spacing:
  hair: 1
  xxs: 4
  xs: 8
  sm: 12
  md: 16
  lg: 24
  xl: 32
  xxl: 48
  section: 96

layout:
  appMinWidth: 360
  contentMaxWidth: 1280
  desktopGutter: 48
  compactGutter: 24
  mobileGutter: 16
  topBarHeight: 64
  minTouchTarget: 44

breakpoints:
  desktopXl: 1440
  desktop: 1280
  tablet: 1024
  compact: 768
  mobile: 480

components:
  buttonPrimary:
    backgroundColor: "{colors.inverseCanvas}"
    color: "{colors.inverseInk}"
    typography: "{typography.button}"
    borderRadius: "{radius.md}"
    minHeight: 40
    paddingVertical: 10
    paddingHorizontal: 18
  buttonPrimaryPressed:
    backgroundColor: "#e8eaed"
    color: "{colors.inverseInk}"
  buttonSecondary:
    backgroundColor: "{colors.surface2}"
    color: "{colors.ink}"
    typography: "{typography.button}"
    borderRadius: "{radius.md}"
    minHeight: 40
    paddingVertical: 10
    paddingHorizontal: 18
  buttonSecondaryPressed:
    backgroundColor: "{colors.surface3}"
    color: "{colors.ink}"
  buttonTertiary:
    backgroundColor: "{colors.canvas}"
    color: "{colors.ink}"
    typography: "{typography.button}"
    borderRadius: "{radius.md}"
    minHeight: 40
    paddingVertical: 10
    paddingHorizontal: 18
  buttonProductTerraform:
    backgroundColor: "{colors.productTerraform}"
    color: "{colors.ink}"
    typography: "{typography.button}"
    borderRadius: "{radius.md}"
    minHeight: 40
    paddingVertical: 10
    paddingHorizontal: 18
  buttonProductVault:
    backgroundColor: "{colors.productVault}"
    color: "{colors.inverseInk}"
    typography: "{typography.button}"
    borderRadius: "{radius.md}"
    minHeight: 40
    paddingVertical: 10
    paddingHorizontal: 18
  buttonProductWaypoint:
    backgroundColor: "{colors.productWaypoint}"
    color: "{colors.inverseInk}"
    typography: "{typography.button}"
    borderRadius: "{radius.md}"
    minHeight: 40
    paddingVertical: 10
    paddingHorizontal: 18
  surfaceCard:
    backgroundColor: "{colors.surface1}"
    borderColor: "{colors.hairlineTranslucent}"
    borderWidth: 1
    borderRadius: "{radius.lg}"
    padding: 24
  productCardTerraform:
    backgroundColor: "{colors.productTerraform}"
    color: "{colors.ink}"
    borderRadius: "{radius.lg}"
    padding: 24
  productCardVault:
    backgroundColor: "{colors.productVault}"
    color: "{colors.inverseInk}"
    borderRadius: "{radius.lg}"
    padding: 24
  productCardWaypoint:
    backgroundColor: "{colors.productWaypoint}"
    color: "{colors.inverseInk}"
    borderRadius: "{radius.lg}"
    padding: 24
  resourceCard:
    backgroundColor: "{colors.surface1}"
    borderColor: "{colors.hairlineTranslucent}"
    borderWidth: 1
    borderRadius: "{radius.lg}"
    padding: 16
  textInput:
    backgroundColor: "{colors.surface1}"
    color: "{colors.ink}"
    placeholderTextColor: "{colors.inkSubtle}"
    typography: "{typography.body}"
    borderColor: "{colors.hairlineTranslucent}"
    borderWidth: 1
    borderRadius: "{radius.md}"
    minHeight: 44
    paddingVertical: 10
    paddingHorizontal: 14
  textInputFocused:
    borderColor: "{colors.accentBlue}"
    borderWidth: 1
  productPill:
    backgroundColor: "{colors.surface1}"
    color: "{colors.inkMuted}"
    typography: "{typography.caption}"
    borderRadius: "{radius.pill}"
    minHeight: 24
    paddingVertical: 4
    paddingHorizontal: 10
  topBar:
    backgroundColor: "{colors.canvas}"
    height: 64
    borderBottomColor: "{colors.hairlineSoft}"
    borderBottomWidth: 1
  footerPanel:
    backgroundColor: "{colors.canvas}"
    color: "{colors.inkMuted}"
    typography: "{typography.caption}"
    paddingVertical: 64
    paddingHorizontal: 32
---

## Overview

This file is RN/macOS version of original web-oriented `DESIGN.md`. Visual language stays same: black canvas, charcoal surfaces, 1px muted borders, compact 8px CTA radius, and product-specific accent colors. Implementation model changes: no HTML sections, no CSS grid, no media queries, no sticky nav, no `px` strings.

Use this document as source for React Native `StyleSheet.create` tokens and app components.

**Key RN changes:**

- Token names use camelCase so they can become JS object keys directly.
- Size values are numbers, not `"80px"` strings.
- `lineHeight` is absolute number because RN does not use CSS line-height multipliers.
- Buttons are `Pressable` + `Text`; pressed/hovered/focused state comes from `Pressable` render callback or state.
- Layout responsiveness comes from `useWindowDimensions()`, not media queries.
- Grid behavior uses flex rows, `FlatList` `numColumns`, or computed item width.
- Focus outlines become `borderColor` / `borderWidth` changes; RN has no CSS outline.
- Gradients need an added dependency such as `react-native-linear-gradient`; default tokens avoid mandatory gradients.

## Colors

### Brand & Accent

- `colors.canvas` / `colors.primary`: app root background and large panels.
- `colors.ink`: primary text on dark surfaces.
- `colors.inkMuted`: secondary text and metadata.
- `colors.inkSubtle`: tertiary text, placeholders, timestamps.
- `colors.accentBlue`: links and focus borders.
- `colors.inverseCanvas` / `colors.inverseInk`: primary button surface and text.

### Surface

- `colors.surface1`: default card and input background.
- `colors.surface2`: emphasized card, secondary button, selected tab.
- `colors.surface3`: pressed/hover surface where platform supports pointer hover.
- `colors.hairlineTranslucent`: default card border.
- `colors.hairlineSoft`: dividers and separators.

### Product Identity

Per-product accents are identity tokens, not decoration. Use one product accent per screen or section.

- Terraform: `colors.productTerraform`
- Vault: `colors.productVault`
- Consul: `colors.productConsul`
- Waypoint: `colors.productWaypoint`
- Vagrant: `colors.productVagrant`
- Nomad: `colors.productNomad`
- Boundary: `colors.productBoundary`

## Typography

RN text styles should be defined as reusable objects, then spread into `Text` styles. Prefer one font family across app. If HashiCorpSans is not bundled, use system font or bundled Inter.

```ts
export const type = {
  displayXl: {
    fontSize: 80,
    fontWeight: '700',
    lineHeight: 94,
    letterSpacing: -2.5,
  },
  body: {
    fontSize: 16,
    fontWeight: '500',
    lineHeight: 24,
    letterSpacing: 0,
  },
} as const;
```

### Hierarchy

| Token | RN size | Weight | Line height | Use |
|---|---:|---|---:|---|
| `typography.displayXl` | 80 | `"700"` | 94 | Hero or top-level app title |
| `typography.displayLg` | 56 | `"700"` | 66 | Section title |
| `typography.displayMd` | 40 | `"600"` | 48 | Subsection title |
| `typography.headline` | 28 | `"600"` | 34 | Panel title |
| `typography.cardTitle` | 22 | `"600"` | 26 | Card title |
| `typography.subhead` | 20 | `"600"` | 27 | Lead text |
| `typography.bodyLg` | 18 | `"500"` | 30 | Prominent body |
| `typography.body` | 16 | `"500"` | 24 | Default body |
| `typography.bodySm` | 14 | `"500"` | 24 | Dense body |
| `typography.caption` | 13 | `"500"` | 18 | Metadata |
| `typography.button` | 14 | `"600"` | 18 | Button labels |
| `typography.eyebrow` | 12 | `"600"` | 15 | Uppercase section labels |

### RN Font Rules

- RN `fontWeight` should be string (`"500"`, `"600"`, `"700"`).
- RN `lineHeight` should be numeric absolute line height, not ratio.
- On macOS, custom fonts require native bundling before `fontFamily` is reliable.
- Keep display tight and body relaxed; this is core visual rhythm.
- Avoid separate display/body font pairs unless design direction changes.

## Layout

### Spacing

Spacing uses 4/8-based numbers:

- `spacing.xxs`: 4
- `spacing.xs`: 8
- `spacing.sm`: 12
- `spacing.md`: 16
- `spacing.lg`: 24
- `spacing.xl`: 32
- `spacing.xxl`: 48
- `spacing.section`: 96

RN uses these directly:

```ts
container: {
  flex: 1,
  backgroundColor: colors.canvas,
  paddingHorizontal: spacing.lg,
}
```

### Responsive Strategy

Use `useWindowDimensions()` and branch in component code:

```ts
const {width} = useWindowDimensions();
const isCompact = width < breakpoints.compact;
const columns = width >= breakpoints.tablet ? 3 : width >= breakpoints.compact ? 2 : 1;
```

Recommended gutters:

- `width >= 1280`: 48
- `768 <= width < 1280`: 24
- `width < 768`: 16

Recommended content max width:

- Use wrapper `View` with `width: '100%'`, `maxWidth: 1280`, `alignSelf: 'center'`.
- RN supports `maxWidth`; avoid CSS-style `margin: auto`. Use `alignSelf`.

### Grids

No CSS grid. Use one of:

- `FlatList` with `numColumns={columns}` for uniform card grids.
- Flex row with `flexWrap: 'wrap'` and computed `width`.
- Single-column `ScrollView` on compact layouts.

## Elevation & Depth

Dark UI uses surface lift, not shadow:

| Level | RN treatment | Use |
|---|---|---|
| 0 | `backgroundColor: colors.canvas` | App root, large sections |
| 1 | `surface1` + `borderWidth: 1` | Cards, inputs, resource tiles |
| 2 | `surface2` + `borderWidth: 1` | Featured cards, selected tabs |
| 3 | Product accent background | Product identity cards |

Avoid drop shadows on dark cards. macOS shadows can look muddy on black and add visual noise. Use `backgroundColor`, `borderColor`, and product color.

## Shapes

| Token | Value | Use |
|---|---:|---|
| `radius.xs` | 4 | badges |
| `radius.sm` | 6 | tags |
| `radius.md` | 8 | buttons, inputs |
| `radius.lg` | 12 | cards |
| `radius.xl` | 16 | large tiles |
| `radius.xxl` | 24 | CTA panels |
| `radius.pill` | 9999 | chips |

Keep CTA buttons at 8px radius. Avoid pill CTAs unless component is a chip.

## Components

### Button

Use `Pressable` so pressed and hover/focus states can be handled in one place.

```tsx
<Pressable
  accessibilityRole="button"
  style={({pressed, hovered, focused}) => [
    styles.buttonPrimary,
    (pressed || hovered) && styles.buttonPrimaryPressed,
    focused && styles.focusRing,
  ]}
>
  <Text style={styles.buttonPrimaryText}>Start</Text>
</Pressable>
```

Base RN styles:

```ts
buttonPrimary: {
  minHeight: 40,
  paddingVertical: 10,
  paddingHorizontal: 18,
  borderRadius: radius.md,
  backgroundColor: colors.inverseCanvas,
  alignItems: 'center',
  justifyContent: 'center',
},
buttonPrimaryText: {
  ...typography.button,
  color: colors.inverseInk,
},
buttonPrimaryPressed: {
  backgroundColor: '#e8eaed',
},
focusRing: {
  borderWidth: 1,
  borderColor: colors.accentBlue,
},
```

### Cards

Use `View` for static cards and `Pressable` for interactive cards.

```ts
surfaceCard: {
  backgroundColor: colors.surface1,
  borderColor: colors.hairlineTranslucent,
  borderWidth: 1,
  borderRadius: radius.lg,
  padding: spacing.lg,
},
```

Product cards replace surface with accent:

```ts
terraformCard: {
  backgroundColor: colors.productTerraform,
  borderRadius: radius.lg,
  padding: spacing.lg,
},
```

### Text Input

RN `TextInput` needs placeholder color via prop, not style.

```tsx
<TextInput
  placeholderTextColor={colors.inkSubtle}
  style={[styles.textInput, isFocused && styles.textInputFocused]}
/>
```

```ts
textInput: {
  minHeight: 44,
  paddingVertical: 10,
  paddingHorizontal: 14,
  borderRadius: radius.md,
  borderWidth: 1,
  borderColor: colors.hairlineTranslucent,
  backgroundColor: colors.surface1,
  color: colors.ink,
  ...typography.body,
},
textInputFocused: {
  borderColor: colors.accentBlue,
},
```

### Product Pill

Use `View` + `Text`; do not make pill a button unless interactive.

```ts
productPill: {
  minHeight: 24,
  paddingVertical: 4,
  paddingHorizontal: 10,
  borderRadius: radius.pill,
  backgroundColor: colors.surface1,
  alignSelf: 'flex-start',
},
productPillText: {
  ...typography.caption,
  color: colors.inkMuted,
},
```

### Top Bar

Web sticky nav becomes app top bar. Keep it inside root layout. Do not rely on `position: sticky`.

```ts
topBar: {
  height: layout.topBarHeight,
  backgroundColor: colors.canvas,
  borderBottomWidth: 1,
  borderBottomColor: colors.hairlineSoft,
  flexDirection: 'row',
  alignItems: 'center',
  paddingHorizontal: spacing.lg,
},
```

For compact width, swap center links for icon button or segmented control in component logic.

## React Native Token Starter

Preferred implementation shape:

```ts
export const colors = {
  canvas: '#000000',
  surface1: '#15181e',
  surface2: '#1f232b',
  surface3: '#3b3d45',
  ink: '#ffffff',
  inkMuted: '#b2b6bd',
  inkSubtle: '#656a76',
  accentBlue: '#2b89ff',
  inverseCanvas: '#ffffff',
  inverseInk: '#000000',
  hairlineTranslucent: 'rgba(178,182,189,0.1)',
  productTerraform: '#7b42bc',
  productVault: '#ffcf25',
  productWaypoint: '#14c6cb',
} as const;

export const spacing = {
  xxs: 4,
  xs: 8,
  sm: 12,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
  section: 96,
} as const;

export const radius = {
  xs: 4,
  sm: 6,
  md: 8,
  lg: 12,
  xl: 16,
  xxl: 24,
  pill: 9999,
} as const;
```

## Do

- Use `StyleSheet.create` or typed token objects; keep tokens central.
- Use numeric values for size, spacing, radius, and line height.
- Use `useWindowDimensions()` for responsive branches.
- Use `Pressable` state callbacks for pressed/hovered/focused style.
- Keep dark canvas as default app background.
- Use one product accent at a time.
- Use `borderWidth: 1` and surface changes for hierarchy.
- Keep minimum pointer/touch targets at 40-44.

## Don't

- Don't use CSS syntax in RN styles (`"24px"`, `var(...)`, `calc(...)`, `rem`, selectors).
- Don't depend on CSS grid or media queries.
- Don't use web-only pseudo states (`:hover`, `:active`, `:focus`).
- Don't use product accent colors as random decoration.
- Don't add dark drop shadows as primary elevation.
- Don't ship a light variant unless separate tokens are defined.
- Don't mix font families across headline/body without intentional redesign.

## Agent Prompt Guide

Use this section when asking an AI coding agent to build or change UI in this repo.

### Quick Reference

- Platform: React Native for macOS, not web.
- Root surface: `colors.canvas` black.
- Main text: `colors.ink`; secondary text: `colors.inkMuted`; placeholder/helper text: `colors.inkSubtle`.
- Cards/inputs: `colors.surface1`, `borderWidth: 1`, `borderColor: colors.hairlineTranslucent`, `borderRadius: radius.lg` for cards or `radius.md` for inputs.
- Buttons: `Pressable` + `Text`, 8px radius, minimum 40px height, pressed state from `Pressable` render callback.
- Layout: `useWindowDimensions()`, `ScrollView`, `FlatList`, flex wrap, computed widths.
- Avoid: CSS syntax, DOM assumptions, media queries, CSS grid, browser-only states.

### Ready-To-Use Prompts

```txt
Build this React Native macOS screen using DESIGN.md. Use StyleSheet-compatible numeric tokens, Pressable for buttons, and useWindowDimensions for responsive layout. Do not use web CSS syntax.
```

```txt
Refactor this component to match DESIGN.md. Keep behavior unchanged. Replace ad hoc colors, spacing, radius, and text styles with the documented RN tokens.
```

```txt
Add a new dark surface card following DESIGN.md. Use surface lift instead of shadow, 1px hairline border, radius.lg, and typography.body/bodySm for dense content.
```

### Review Checklist For Agents

- Did UI code read `DESIGN.md` before choosing colors/type/spacing?
- Are all numeric style values RN-compatible?
- Are pressed/focused states implemented without CSS pseudo selectors?
- Does compact layout use runtime width, not media queries?
- Is product accent color used as identity, not decoration?

## Migration Checklist

1. Convert all token names from kebab-case to camelCase.
2. Remove every `px` suffix; keep values numeric.
3. Convert line-height ratios into absolute RN `lineHeight` values.
4. Replace CSS states with `Pressable` render-state styles.
5. Replace media-query behavior with `useWindowDimensions()`.
6. Replace CSS grid with `FlatList`, flex wrap, or computed widths.
7. Move placeholder color from style object to `TextInput.placeholderTextColor`.
8. Keep focus state as border color because RN has no CSS outline.
9. Add native font bundling before relying on custom `fontFamily`.
10. Run `yarn lint` and `yarn test` after token/module changes.

## Known Gaps

- HashiCorpSans is proprietary; this repo must bundle an allowed font or use system/Inter.
- RN core has no gradient primitive. Add dependency before implementing gradient cards.
- macOS pointer hover support depends on RN macOS `Pressable` behavior; verify in app.
- Accessibility color contrast should be checked once real copy and controls exist.
