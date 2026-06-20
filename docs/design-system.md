# Design System

Canonical reference for colors, semantic roles, and visual tokens shared across every config. The always-on invariants (Arch Blue is the only accent, normal states invisible, amber-not-yellow for warnings) live in `CLAUDE.md` under UX Cohesion; this file holds the full tables you need when doing color or visual work.

## Color Palette

All configs share a unified palette derived from Tailwind CSS colors. The canonical source is `kitty.conf`. When adding or modifying colors in any config, use values from this palette — do not introduce one-off hex values.

| Role     | Normal  | Bright  |
|----------|---------|---------|
| Black    | #292524 | #525252 |
| Red      | #f43f5e | #fb7185 |
| Green    | #22c55e | #4ade80 |
| Yellow   | #fcd34d | #fde68a |
| Blue     | #3b82f6 | #60a5fa |
| Magenta  | #e879f9 | #f0abfc |
| Cyan     | #06b6d4 | #22d3ee |
| White    | #d4d4d8 | #e7e5e4 |

Additional shared values:
- **Background**: `#0a0a0a`
- **Foreground**: `#d6d3d1`
- **Accent (Arch Blue)**: `#1793d1`
- **Amber (Warning)**: `#d97706`
- **Surface**: `#333333`
- **Alt Surface**: `#444444`

## Semantic Color Roles

| Color | Role |
|---|---|
| Arch Blue `#1793d1` | Active/selected states, interactive borders, focus rings |
| Red `#f43f5e` | Errors, critical alerts, muted/disconnected |
| Green `#22c55e` | Transient success confirmations (auth passed, connected). Never for "normal/good" steady states — normal should be invisible (default text color) |
| Amber `#d97706` | Warnings in persistent UI (battery mid, high resource use). Lower luminance than yellow to avoid outshining red alerts |
| Yellow `#fcd34d` | High-visibility lock indicators (caps lock, num lock on lock screen) |
| Surface `#333333` | Container backgrounds, inactive borders, default notification borders |
| Alt Surface `#444444` | Hover states, secondary surfaces |

## Attention Hierarchy Principles

Saturated color on dark backgrounds triggers involuntary pre-attentive orienting (pop-out effect). Use it sparingly:

- **Normal/good states should be invisible.** Don't color the battery green when it's fine. Use the default text color. Color only appears when attention is needed.
- **Warning (amber) must not outshine critical (red).** Yellow #fcd34d has 3x the perceived luminance of red #f43f5e (Helmholtz-Kohlrausch effect). Use the lower-luminance amber #d97706 for warnings so red remains the most urgent signal.
- **Notification borders reflect urgency.** Low → #525252 (invisible), Normal → #525252 (quiet), Critical → #f43f5e (demands attention). Don't use the accent color for routine notifications.

## Visual Design Tokens

Used consistently across all UI components. Do not deviate without updating all components listed in the cross-cutting checklist in `CLAUDE.md`.

| Token | Value |
|---|---|
| Border radius (standard) | `10px` |
| Border radius (tight) | `6px` |
| Border width | `2px` |
| Transition duration | `0.3s ease` |
| Font (UI) | `Inter` |
| Font (GTK apps) | `Inter 11` |
| Cursor size | `32` |
| Icon theme | `Papirus-Dark` |
