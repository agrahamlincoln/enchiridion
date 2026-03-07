#!/usr/bin/env python3
"""tap-indicator - Brief visual dot on touchpad clicks for Hyprland.

Shows a small dot at the cursor position that shrinks and fades out
whenever a touchpad click or tap-to-click is registered.

Uses a full-screen transparent layer-shell surface with an empty input
region so pointer events pass through without disturbing windows below.

Requirements:
  - python-gobject, python-cairo, gtk4-layer-shell, libinput-tools
  - User must be in the 'input' group (for libinput access)
"""

import math
import signal
import subprocess
import sys
import threading
from ctypes import CDLL

# Must load gtk4-layer-shell before libwayland (via GI) for the
# layer-shell shim to work.  See gtk4-layer-shell/linking.md.
CDLL("libgtk4-layer-shell.so")

import cairo  # noqa: E402
import gi  # noqa: E402

gi.require_version("Gdk", "4.0")
gi.require_version("Gtk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell

# -- Configuration -----------------------------------------------------------

DOT_SIZE = 28           # px starting diameter
COLOR = (0.7, 0.7, 0.7) # light grey
INITIAL_ALPHA = 0.5
FADE_MS = 300           # total animation duration
FADE_STEPS = 10


# -- Helpers -----------------------------------------------------------------

def find_touchpad_device():
    """Return the /dev/input/eventN path for the first touchpad, or None."""
    try:
        out = subprocess.check_output(
            ["libinput", "list-devices"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        return None

    is_touchpad = False
    for line in out.splitlines():
        stripped = line.strip()
        if stripped.startswith("Device:"):
            is_touchpad = "touchpad" in stripped.lower()
        elif stripped.startswith("Kernel:") and is_touchpad:
            return stripped.split()[-1]
    return None


def get_cursor_pos():
    """Return (x, y) from hyprctl, or None on failure."""
    try:
        r = subprocess.run(
            ["hyprctl", "cursorpos"],
            capture_output=True,
            text=True,
            timeout=0.1,
        )
        x, y = r.stdout.strip().split(", ")
        return int(x), int(y)
    except Exception:
        return None


# -- Application -------------------------------------------------------------

class TapIndicator(Gtk.Application):
    def __init__(self, touchpad_dev):
        super().__init__(application_id="com.enchiridion.tap-indicator")
        self.touchpad_dev = touchpad_dev
        self.fade_id = None
        self.win = None
        self.da = None
        self.progress = 1.0  # 0=full, 1=invisible
        self.click_x = 0
        self.click_y = 0

    def do_activate(self):
        w = Gtk.Window(application=self)

        # Full-screen transparent overlay anchored to all edges
        Gtk4LayerShell.init_for_window(w)
        Gtk4LayerShell.set_layer(w, Gtk4LayerShell.Layer.OVERLAY)
        Gtk4LayerShell.set_exclusive_zone(w, -1)
        Gtk4LayerShell.set_keyboard_mode(
            w, Gtk4LayerShell.KeyboardMode.NONE
        )
        Gtk4LayerShell.set_namespace(w, "tap-indicator")
        Gtk4LayerShell.set_anchor(w, Gtk4LayerShell.Edge.TOP, True)
        Gtk4LayerShell.set_anchor(w, Gtk4LayerShell.Edge.BOTTOM, True)
        Gtk4LayerShell.set_anchor(w, Gtk4LayerShell.Edge.LEFT, True)
        Gtk4LayerShell.set_anchor(w, Gtk4LayerShell.Edge.RIGHT, True)

        css = Gtk.CssProvider()
        css.load_from_string("window { background-color: transparent; }")
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        da = Gtk.DrawingArea()
        da.set_draw_func(self._on_draw)
        w.set_child(da)

        # Empty input region — pointer events pass through completely
        w.connect("realize", self._on_realize)

        self.win = w
        self.da = da
        w.present()

        threading.Thread(target=self._watch_clicks, daemon=True).start()

    def _on_realize(self, w):
        surface = w.get_surface()
        if surface:
            surface.set_input_region(cairo.Region())

    def _on_draw(self, _da, cr, width, height):
        cr.set_operator(cairo.OPERATOR_CLEAR)
        cr.paint()
        cr.set_operator(cairo.OPERATOR_OVER)

        if self.progress >= 1.0:
            return

        scale = 1.0 - self.progress
        alpha = INITIAL_ALPHA * scale
        radius = (DOT_SIZE / 2) * scale

        cr.set_source_rgba(*COLOR, alpha)
        cr.arc(self.click_x, self.click_y, radius, 0, 2 * math.pi)
        cr.fill()

    # -- Flash / fade --------------------------------------------------------

    def _flash(self, x, y):
        if self.fade_id:
            GLib.source_remove(self.fade_id)

        self.click_x = x
        self.click_y = y
        self.progress = 0.0
        self.da.queue_draw()

        step_ms = FADE_MS // FADE_STEPS
        self.fade_id = GLib.timeout_add(step_ms, self._animate)

    def _animate(self):
        self.progress += 1.0 / FADE_STEPS
        if self.progress >= 1.0:
            self.progress = 1.0
            self.fade_id = None
        self.da.queue_draw()
        return self.progress < 1.0

    # -- Click monitoring ----------------------------------------------------

    def _watch_clicks(self):
        """Parse libinput debug-events for POINTER_BUTTON pressed events."""
        proc = subprocess.Popen(
            ["stdbuf", "-oL",
             "libinput", "debug-events",
             "--device", self.touchpad_dev,
             "--enable-tap",
             "--set-click-method=clickfinger"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        for line in proc.stdout:
            if "POINTER_BUTTON" in line and "pressed" in line:
                pos = get_cursor_pos()
                if pos:
                    GLib.idle_add(self._flash, pos[0], pos[1])


# -- Entry point -------------------------------------------------------------

def main():
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    dev = find_touchpad_device()
    if not dev:
        print("tap-indicator: no touchpad found", file=sys.stderr)
        sys.exit(1)

    app = TapIndicator(dev)
    app.run([])


if __name__ == "__main__":
    main()
