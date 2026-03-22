# wlogout Configuration

Linux-only power menu (lock, logout, suspend/hibernate, reboot, shutdown).

## Hibernate Support

The suspend button checks `~/.config/hypr/use-hibernate` at runtime. If the flag file exists, it runs `systemctl hibernate` instead of `systemctl suspend`. This is a workaround for an s2idle bug on Framework 13 AMD Ryzen AI 300 — see `docs/suspend-resume-issue.md`.

## Key Files

- `dot-config/wlogout/layout` - Button definitions
- `dot-config/wlogout/style.css` - Styling (Arch Blue theme, transparent backgrounds)
- `dot-config/wlogout/icons/` - Custom SVG icons themed to match the shared palette

## Custom Icons

The `icons/` directory contains hand-crafted SVG icons (lock, logout, suspend, reboot, shutdown) using `currentColor` for theming. The CSS `background-image` references these with a fallback to system icons at `/usr/share/wlogout/icons/`.

## Colors

Uses the shared palette: Arch Blue (`#1793d1`) for hover/active states, `#333333` for button backgrounds. See root `CLAUDE.md` for the full palette.
