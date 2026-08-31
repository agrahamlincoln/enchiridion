#!/usr/bin/env python3
"""Hold the trigger key (Pause) to repeat left-clicks at the cursor.

Reads the key from evdev rather than a Hyprland bind: injecting a mouse button
resets Hyprland's key tracking, so a `bindr` release stops matching as soon as
clicking starts and the clicker latches on. evdev is upstream of the compositor.

Needs the `input` group to read evdev and a running ydotoold to inject clicks;
setup.sh arranges both.
"""

import os
import random
import re
import select
import struct
import subprocess
import sys
import time

# struct input_event: timeval (two longs) + type + code + value.
EVENT_FORMAT = "llHHi"
EVENT_SIZE = struct.calcsize(EVENT_FORMAT)
EV_KEY = 0x01
RELEASE, PRESS = 0, 1  # 2 is autorepeat, which we ignore

TRIGGER_KEY = int(os.environ.get("AUTOCLICK_KEY", 119))  # KEY_PAUSE
INTERVAL_MS = float(os.environ.get("AUTOCLICK_INTERVAL_MS", 100))
JITTER_MS = float(os.environ.get("AUTOCLICK_JITTER_MS", 15))
RESCAN_SECONDS = 5.0  # so a replugged keyboard is picked up

DEBUG = os.path.exists(os.path.expanduser("~/.config/hypr/autoclick-debug"))


def trace(message):
    if DEBUG:
        print(f"{time.strftime('%H:%M:%S')} {message}", file=sys.stderr, flush=True)


def devices_with_key(code):
    """Paths of the /dev/input/eventN devices that can emit `code`."""
    paths = []
    try:
        blocks = open("/proc/bus/input/devices").read().split("\n\n")
    except OSError as exc:
        trace(f"cannot enumerate devices: {exc}")
        return paths

    for block in blocks:
        name = re.search(r'N: Name="([^"]*)"', block)
        handlers = re.search(r"H: Handlers=(.*)", block)
        keybits = re.search(r"B: KEY=(.*)", block)
        if not (handlers and keybits):
            continue
        if name and "ydotoold" in name.group(1):
            continue  # our own injector; watching it would feed back
        # B: KEY= is a bitmap of hex longs, most significant word first.
        bitmap = 0
        for index, word in enumerate(reversed(keybits.group(1).split())):
            bitmap |= int(word, 16) << (64 * index)
        node = re.search(r"\bevent(\d+)\b", handlers.group(1))
        if node and (bitmap >> code) & 1:
            paths.append(f"/dev/input/event{node.group(1)}")
    return paths


def click():
    # 0xC0 = down (0x40) | up (0x80) | LEFT (0x00). One invocation per click, so
    # the button is never left down if we stop mid-sequence.
    subprocess.run(["ydotool", "click", "0xC0"],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


def next_delay():
    """Seconds until the next click, jittered so the cadence isn't exact."""
    return max(0.0, (INTERVAL_MS + random.uniform(-JITTER_MS, JITTER_MS)) / 1000.0)


class Watcher:
    def __init__(self):
        self.fds = {}          # fd -> path
        self.holding = set()   # paths with the key down; one key can hit several
        self.click_at = None   # monotonic time of the next click, None when idle
        self.last_scan = 0.0

    def scan(self):
        self.last_scan = time.monotonic()
        for path in set(devices_with_key(TRIGGER_KEY)) - set(self.fds.values()):
            try:
                self.fds[os.open(path, os.O_RDONLY | os.O_NONBLOCK)] = path
            except OSError as exc:
                trace(f"cannot open {path}: {exc}")
            else:
                trace(f"watching {path}")

    def drop(self, fd):
        self.holding.discard(self.fds.pop(fd, None))
        try:
            os.close(fd)
        except OSError:
            pass

    def read_events(self, fd):
        """Apply pending events. Returns False if the device went away."""
        while True:
            try:
                data = os.read(fd, EVENT_SIZE * 64)
            except BlockingIOError:
                return True
            except OSError:
                return False
            if not data:
                return True
            for off in range(0, len(data) - EVENT_SIZE + 1, EVENT_SIZE):
                _, _, etype, code, value = struct.unpack(
                    EVENT_FORMAT, data[off:off + EVENT_SIZE])
                if etype == EV_KEY and code == TRIGGER_KEY:
                    self.set_held(self.fds[fd], value)

    def set_held(self, path, value):
        if value == PRESS and path not in self.holding:
            if not self.holding:
                self.click_at = time.monotonic()  # first click fires immediately
                trace("press -> clicking")
            self.holding.add(path)
        elif value == RELEASE:
            self.holding.discard(path)
            if not self.holding:
                self.click_at = None
                trace("release -> stopped")

    def run(self):
        self.scan()
        if not self.fds:
            print(f"autoclick: no device reports key {TRIGGER_KEY} "
                  "(is this user in the 'input' group?)", file=sys.stderr)

        while True:
            idle = self.click_at is None
            timeout = RESCAN_SECONDS if idle else max(0.0, self.click_at - time.monotonic())
            for fd in select.select(list(self.fds), [], [], timeout)[0]:
                if fd in self.fds and not self.read_events(fd):
                    self.drop(fd)

            now = time.monotonic()
            if self.click_at is not None and now >= self.click_at:
                click()
                self.click_at = now + next_delay()
            elif idle and now - self.last_scan > RESCAN_SECONDS:
                self.scan()


if __name__ == "__main__":
    try:
        Watcher().run()
    except KeyboardInterrupt:
        pass
