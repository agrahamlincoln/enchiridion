# Hyprland Configuration

Linux-only desktop environment config for Hyprland (compositor) and Hyprlock (lock screen). Wallpapers are handled by wpaperd, which lives in its own dotfiles package (`dotfiles/wpaperd/`).

## Config Format

Hyprland's config is **Lua** (`hyprland.lua`). The old hyprlang `.conf` format is
deprecated and support for it is removed in Hyprland 0.57. The `.conf` files are
kept for now purely as a rollback path — Hyprland prefers `hyprland.lua` whenever
it exists, and the choice of config backend is made once at compositor startup,
so switching between them requires a full restart, not `hyprctl reload`.

That rollback is not turnkey: `hyprland.conf` still `source`s the generated
`host-settings.conf`/`host-keybinds.conf`, which nothing regenerates any more.
Using it on a machine that lacks them means composing them from
`hosts/<profile>/*.conf` by hand first. The `.conf` sources are also frozen —
changes since the Lua switch land only in the `.lua` files.

API notes that aren't obvious from the wiki:

- Config keys map from the documented names by `:` → `.` and `-` → `_`, e.g.
  `input:touchpad:tap-to-click` becomes `input.touchpad.tap_to_click`.
- Selectors (`hl.dsp.pass`, `hl.dsp.focus{window=...}`) take the **legacy
  selector string**, e.g. `"class:^(discord)$"` — not a match table. Match
  tables are only for `hl.window_rule`/`hl.layer_rule`.
- `exec-once` becomes `hl.on("hyprland.start", function() hl.exec_cmd(...) end)`.
- Bind flag suffixes become options: `bindl` → `{locked=true}`, `binde` →
  `{repeating=true}`, `bindr` → `{release=true}`, `bindi` → `{ignore_mods=true}`.

### hyprctl under a Lua config

This bites external scripts, not just the config, and it fails **silently** —
`hyprctl` always exits 0, so `||` fallbacks and `2>/dev/null` hide the breakage.
Detect the backend from the reply text instead.

| Command | Under Lua |
|---|---|
| `hyprctl keyword <k> <v>` | **Rejected** — "keyword can't work with non-legacy parsers. Use eval." Use `hyprctl eval '<lua>'` |
| `hyprctl dispatch <legacy str>` | **Rejected** — rewritten to `hl.dispatch(<str>)`, which isn't valid Lua. Use `hyprctl dispatch 'hl.dsp.foo(...)'` |
| `hyprctl eval '<lua>'` | Lua only — rejected by the legacy parser |
| `reload`, `setcursor`, `monitors -j`, `clients -j` | Work on both |

Affected callers here: `hypr-scale.sh` (monitor scale) and `hypridle.conf`
(dpms). Both currently issue the Lua form *and* the legacy form so they work
either side of the cutover; drop the legacy half once `hyprland.conf` is removed.

## Host Configuration

Configuration is split across two independent axes:
- **Host type** (`~/.config/hypr/host-type`): `desktop` or `laptop` — controls gaps, touchpad, visual effects
- **Keyboard layout** (`~/.config/hypr/kb-layout`): `dvorak` or `qwerty` — controls keybinds and `kb_variant`

`hostenv.lua` reads both files on every config load and `hyprland.lua` requires
`hosts.<type>.settings` and `hosts.<layout>.keybinds` directly. Defaults to
`desktop` and `dvorak`; an unknown value falls back with a warning. There is no
generated file and no codegen step — edit the sources in `hosts/` and reload.

## Autoclick

**Opt-in per host** — `touch ~/.config/hypr/autoclick-enabled && ./setup.sh`.
The flag gates three things: `autoclick.sh` exits early without it, `setup.sh`
skips installing `ydotool` and granting evdev access, and `hostenv.autoclick`
drops the Pause bind so the key stays ordinary. It is off by default because the
feature needs read access to every input device — worth it on a gaming desktop,
not on a machine that will never use it.

`autoclick.py` repeats left-clicks while Pause is held. `autoclick.sh` (from the
`hyprland.start` handler) starts `ydotoold` and execs it. The lone `hl.bind` on
Pause only swallows the key so games don't see it.

**A hold-to-X action that synthesizes input can't use a `bind`/`bindr` pair.**
Injecting a mouse button resets Hyprland's key tracking, so the release bind
stops matching once clicking starts and the action latches on — it looks like
press-to-toggle. Hence reading evdev directly, upstream of the compositor.
Actions that inject nothing are fine with a normal bind pair.

Also avoid lock keys (Scroll Lock, Caps Lock) as hold triggers — their xkb
`LockMods` interp changes the modifier state between press and release, which
breaks release binds the same way. Check with `xkbcli compile-keymap`.

Tunable via `AUTOCLICK_KEY` (evdev keycode, default 119 = `KEY_PAUSE`),
`AUTOCLICK_INTERVAL_MS`, `AUTOCLICK_JITTER_MS`. `touch
~/.config/hypr/autoclick-debug` to trace press/release to stderr.

## Window Rules

Window rules are `hl.window_rule{name=..., match={...}, <effect>=...}`. The match
table selects windows (`class`, `title`, `xwayland`, `float`, ...) and the
remaining keys are the effects. Check the Hyprland wiki for current syntax when
adding rules -- field names change across releases.

## Testing Changes

```bash
# Parse-check a config without running it. This is the only way to test a
# change to hyprland.lua before a restart, since the backend is chosen at
# startup and `hyprctl reload` cannot switch to it.
Hyprland --verify-config -c ~/.config/hypr/hyprland.lua

hyprctl reload        # Reload hyprland config live (same backend only)
hyprctl monitors -j   # Query monitor info (JSON)
```

To verify a profile this machine doesn't use, copy the config dir elsewhere,
set `host-type`/`kb-layout` in the copy, and point `XDG_CONFIG_HOME` at it --
`hostenv.lua` reads the axes from there, so all four combinations can be
checked without touching the live session.

## Wallpapers

Wallpapers are handled by **wpaperd** (launched from `hyprland.lua`'s startup hook), configured in `dotfiles/wpaperd/dot-config/wpaperd/config.toml`. wpaperd natively cycles through a directory (`~/Images/Wallpapers`) on a timer. hyprpaper was used previously but has **no rotation feature** — it only assigns one static image per monitor — so directory cycling never worked with it. Do not reintroduce hyprpaper for rotation.

## Colors

All colors in hyprlock and other Hypr configs should use the shared palette defined in the root `CLAUDE.md`. The accent color is Arch Blue (`#1793d1`), surfaces use `#333333`, and status colors (red, green, yellow) come from the Tailwind ANSI palette.
