#!/usr/bin/env python3
"""
Wayland-native ambilight via ext-image-copy-capture-v1.
Works on Hyprland >= 0.41 (and any other wlroots compositor that implements the protocol).
Requires: python-pywayland (pacman -S python-pywayland)
"""
import gc
import json
import mmap
import os
import select
import socket
import struct
import sys
import time
import urllib.request

import numpy as np
from pywayland.client import Display
from pywayland.protocol.wayland import WlShm, WlOutput
from pywayland.protocol.ext_image_copy_capture_v1 import (
    ExtImageCopyCaptureManagerV1,
    ExtImageCopyCaptureSessionV1,
    ExtImageCopyCaptureFrameV1,
)
from pywayland.protocol.ext_image_capture_source_v1 import (
    ExtOutputImageCaptureSourceManagerV1,
    ExtImageCaptureSourceV1,
)

# Connector name of the output to mirror. If it is missing (monitor off) the
# strip is turned off and the script exits — it never mirrors another output.
TARGET_OUTPUT = os.environ.get("AMBILIGHT_OUTPUT", "").strip() or "DP-1"

WLED_IP       = "192.168.1.52"
WLED_PORT     = 4048
FPS           = 20        # capture rate. 30 → 20: direct 33% CPU reduction
OUT_FPS       = 60        # LED update rate; fades are interpolated between captures
STRIDE        = 4         # sample 1-in-N pixels per axis (16× fewer ops, invisible quality loss)

# ── Colour tuning ────────────────────────────────────────────────────────────
# Colour of the wall the light lands on, as sRGB hex. The wall tints whatever
# is projected on it, so each channel is attenuated by how strongly the wall
# reflects it. "#ffffff" = neutral wall, no correction.
WALL_COLOR    = "#ffffff"
WALL_STRENGTH = 1.0       # 0 = ignore wall colour, 1 = full compensation

CAPTURE_DEPTH = 0.14      # how far into the picture each LED looks, fraction of screen height
EDGE_FALLOFF  = 0.7       # 0 = whole depth counts equally, 1 = only pixels at the very edge

# Dominant colour: each LED shows the colour most of its region agrees on,
# instead of an average that turns red next to green into brown.
HUE_BINS      = 24        # hue resolution of the vote
GREY_CHROMA   = 0.04      # Oklab chroma below which a pixel votes as grey, not as a hue
GREY_WEIGHT   = 1 / 3     # a white pixel's vote next to a fully coloured one (blue sky beats clouds)
DOMINANCE     = 3.0       # how hard the winning hue shuts the others out (0 = plain average)
DARK_SUPPORT  = 0.5       # 0 = a small bright object lights its LED fully, 1 = only by its share of the region
ZONE_BLUR     = 1.5       # LEDs; neighbours vote together so the strip reads as soft zones

SATURATION    = 1.6       # chroma gain in Oklab (1 = unchanged)
BRIGHTNESS    = 1.0       # linear gain; highlights are scaled down, never clipped to white
LIFT          = 0.55      # <1 brightens dim and mid colours towards full, hue untouched (1 = faithful)
FLOOR         = 0.012     # linear luminance the LEDs never drop below, so dark scenes keep a faint glow

# Adaptive smoothing in Oklab: small changes ease slowly (no flicker), big ones snap.
# An LED that saw a cut stays fast for CUT_HOLD so it lands instead of crawling in.
# The eye catches brightness steps sooner than colour steps, so lightness moves slower.
TAU_SLOW      = 0.25      # seconds, colour time constant for subtle changes
TAU_FAST      = 0.06      # seconds, colour time constant for scene cuts
LIGHT_SLOWDOWN = 1.7      # lightness time constant = colour time constant × this
DELTA_SLOW    = 0.03      # per-LED Oklab distance still treated as subtle
DELTA_FAST    = 0.25      # per-LED Oklab distance treated as a cut
CUT_HOLD      = 0.4       # seconds

# Letterbox / pillarbox detection: black bars are skipped so LEDs follow the picture.
BAR_THRESHOLD = 10        # 0..255, a pixel at or below this in every channel is black
BAR_MAX       = 0.25      # bars deeper than this fraction of the screen are ignored
BAR_MIN       = 0.02      # bars thinner than this fraction are ignored
BAR_GROW_S    = 1.0       # bars must hold this long before they are skipped
BAR_SHRINK_S  = 0.15      # picture showing up inside a skipped bar is followed this fast

# sRGB → linear LUT (0..1) for working in linear light
_c = np.arange(256, dtype=np.float32) / 255
GAMMA_LUT = np.where(_c <= 0.04045, _c / 12.92, ((_c + 0.055) / 1.055) ** 2.4).astype(np.float32)

# linear sRGB ↔ Oklab
OK_M1 = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                  [0.2119034982, 0.6806995451, 0.1073969566],
                  [0.0883024619, 0.2817188376, 0.6299787005]], dtype=np.float32)
OK_M2 = np.array([[0.2104542553,  0.7936177850, -0.0040720468],
                  [1.9779984951, -2.4285922050,  0.4505937099],
                  [0.0259040371,  0.7827717662, -0.8086757660]], dtype=np.float32)
OK_M1_INV = np.linalg.inv(OK_M1).astype(np.float32)
OK_M2_INV = np.linalg.inv(OK_M2).astype(np.float32)
LUMA = np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)


# Drive levels (R, G, B) at which this strip on this wall matches the monitor's
# white. Found by eye, comparing candidate whites side by side; at equal drive
# the strip is far too green-blue and drags every colour that way.
LED_WHITE = (1.0, 0.5, 0.3)


def to_oklab(rgb):
    return np.cbrt(rgb @ OK_M1.T) @ OK_M2.T


def from_oklab(lab):
    return ((lab @ OK_M2_INV.T) ** 3) @ OK_M1_INV.T


def _led_matrix():
    """Linear sRGB → WS2812B drive levels.

    The strip's red, green and blue are not the monitor's (its green is far
    purer), so a screen colour sent as-is lands on a different hue. Going
    through CIE XYZ with the LED primaries fixes the mix. The primaries are
    WS2812B datasheet typicals; how bright each one is comes from LED_WHITE,
    the drive levels that were matched to screen white by eye."""
    srgb = np.array([[0.4124, 0.3576, 0.1805],
                     [0.2126, 0.7152, 0.0722],
                     [0.0193, 0.1192, 0.9505]])
    xy = ((0.69, 0.31), (0.17, 0.70), (0.13, 0.07))    # ~625 nm, ~525 nm, ~470 nm
    prim = np.array([[x / y, 1.0, (1 - x - y) / y] for x, y in xy]).T
    mix = np.linalg.inv(prim) @ srgb                   # how much of each primary a colour needs
    return (mix / mix.sum(axis=1, keepdims=True) * np.array(LED_WHITE)[:, None]).astype(np.float32)


LED_MATRIX = _led_matrix()


def _vote_luts():
    """For every 15-bit RGB colour: which hue bin it votes in (HUE_BINS = grey)
    and how much its vote counts. Black counts for nothing."""
    v = (np.arange(32) * 8 + 4)
    r, g, b = np.meshgrid(v, v, v, indexing="ij")          # key = r5<<10 | g5<<5 | b5
    lab = to_oklab(GAMMA_LUT[np.stack([r, g, b], axis=-1).reshape(-1, 3)])
    chroma = np.hypot(lab[:, 1], lab[:, 2])
    hue = np.arctan2(lab[:, 2], lab[:, 1]) % (2 * np.pi)
    grey = chroma < GREY_CHROMA
    bins = np.where(grey, HUE_BINS, np.minimum((hue / (2 * np.pi) * HUE_BINS).astype(int), HUE_BINS - 1))
    mass = np.where(grey, lab[:, 0] * GREY_WEIGHT, chroma / 0.15)
    return bins.astype(np.int64), mass.astype(np.float32)


BIN_LUT, MASS_LUT = _vote_luts()

# TV strip — output 0, 113 LEDs
RIGHT_LEDS  = 20
TOP_LEDS    = 35
LEFT_LEDS   = 20
BOTTOM_LEDS = 37
TV_TOTAL    = 113

# Desk strip — output 1, 120 LEDs, right to left
DESK_LEDS = 120
DESK_ON   = False   # False keeps the desk strip dark and lights only the TV strip

# SHM formats where memory layout is [B, G, R, X/A] (compatible with existing sampling code)
BGR_FORMATS = {0, 1}   # ARGB8888=0, XRGB8888=1


def build_regions(w, h, bars):
    """Return [(x1, y1, x2, y2, side)] for all 232 sampled LEDs (112 TV + 120 desk),
    laid out inside the picture left after removing `bars` = (top, bottom, left, right) px."""
    top, bottom, left, right = bars
    x0, y0, x1, y1 = left, top, w - right, h - bottom
    cw, ch = x1 - x0, y1 - y0
    d = max(1, min(int(CAPTURE_DEPTH * h), cw // 2, ch // 2))
    regions = []
    rh = ch / RIGHT_LEDS
    for i in range(RIGHT_LEDS):
        regions.append((x1 - d, int(y1 - (i+1)*rh), x1, int(y1 - i*rh), "right"))
    tw = cw / TOP_LEDS
    for j in range(TOP_LEDS):
        regions.append((int(x1 - (j+1)*tw), y0, int(x1 - j*tw), y0 + d, "top"))
    lh = ch / LEFT_LEDS
    for k in range(LEFT_LEDS):
        regions.append((x0, int(y0 + k*lh), x0 + d, int(y0 + (k+1)*lh), "left"))
    bw = cw / BOTTOM_LEDS
    for m in range(BOTTOM_LEDS):
        regions.append((int(x0 + m*bw), y1 - d, int(x0 + (m+1)*bw), y1, "bottom"))
    # Desk strip runs right to left under the bottom edge
    dw = cw / DESK_LEDS
    for m in range(DESK_LEDS):
        regions.append((int(x0 + (DESK_LEDS - 1 - m)*dw), y1 - d,
                        int(x0 + (DESK_LEDS - m)*dw), y1, "bottom"))
    return regions, d


def hex_to_linear(hex_color):
    v = hex_color.lstrip("#")
    return GAMMA_LUT[[int(v[i:i+2], 16) for i in (0, 2, 4)]]


def blur_leds(a, sigma, wrap):
    """Gaussian blur along the LED axis (axis 0). wrap: the strip is a closed loop."""
    r = int(np.ceil(sigma * 2.5))
    if sigma <= 0 or len(a) <= 2 * r:
        return a
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    pad = np.pad(a, [(r, r)] + [(0, 0)] * (a.ndim - 1), mode="wrap" if wrap else "edge")
    return sum(k[i] * pad[i:i + len(a)] for i in range(2 * r + 1))


class ColorEngine:
    """Turns captured frames into LED colours.

    Per capture: every sampled pixel votes for a hue, weighted by how colourful
    it is and how close to the edge → each LED takes its dominant colour →
    saturation / brightness lift / floor → that becomes the target.
    Per LED update: ease towards the target in Oklab, then map to the strip's
    own primaries."""

    def __init__(self, w, h, bgr_layout):
        self.w, self.h = w, h
        self.bgr = bgr_layout
        self.chan = [2, 1, 0] if bgr_layout else [0, 1, 2]   # memory order → RGB
        wall = np.maximum(hex_to_linear(WALL_COLOR), 0.05)
        self.gain = ((wall.min() / wall) ** WALL_STRENGTH).astype(np.float32)
        self.bars = (0, 0, 0, 0)
        self.bar_cand, self.bar_since = self.bars, 0.0
        self.target = None      # where the LEDs are heading, Oklab
        self.state = None       # where they are now, Oklab
        self.out = None         # last frame sent, 0..255 with TV padding
        self.cut = 0.0          # per-LED 0..1, how much of a cut it is riding out
        self.last_t = 0.0
        self.settled = True
        self._build()

    def _build(self):
        regions, depth = build_regions(self.w, self.h, self.bars)
        idx, wgt, base = [], [], []
        for led, (x1, y1, x2, y2, side) in enumerate(regions):
            # Into the picture every other sample is plenty: colours change
            # slower that way than along the edge.
            sx, sy = (STRIDE * 2, STRIDE) if side in ("left", "right") else (STRIDE, STRIDE * 2)
            xs = np.arange(x1, max(x2, x1 + 1), sx)
            ys = np.arange(y1, max(y2, y1 + 1), sy)
            dist = {"right": (x2 - 1 - xs)[None, :], "left": (xs - x1)[None, :],
                    "top": (ys - y1)[:, None], "bottom": (y2 - 1 - ys)[:, None]}[side]
            fall = 1.0 - EDGE_FALLOFF * dist / depth
            idx.append((ys[:, None] * self.w + xs[None, :]).ravel())
            wgt.append(np.broadcast_to(fall, (len(ys), len(xs))).ravel())
            base.append(np.full(len(ys) * len(xs), led * (HUE_BINS + 1)))
        self.n_led = len(regions)
        self.idx   = np.concatenate(idx)
        self.wgt   = np.concatenate(wgt).astype(np.float32)
        self.base  = np.concatenate(base)    # first vote cell of each sample's LED

    def _detect_bars(self, px, now):
        """Find black bars on each side and re-lay the regions once they hold."""
        w, h = self.w, self.h
        mv, mh = int(h * BAR_MAX), int(w * BAR_MAX)
        cols = [w // 4, w // 2, 3 * w // 4]
        rows = [h // 4, h // 2, 3 * h // 4]

        def depth(lines, limit):   # lines: (n, 3 probes, 3 channels), scanning inward by 2 px
            lit = lines.max(axis=(1, 2)) > BAR_THRESHOLD
            i = int(lit.argmax()) * 2
            # nothing lit within reach → dark scene, not a bar
            return i if lit.any() and i >= limit * BAR_MIN / BAR_MAX else 0

        cand = (depth(px[0:mv:2][:, cols, :3], mv),
                depth(px[h-1:h-1-mv:-2][:, cols, :3], mv),
                depth(px[rows][:, 0:mh:2, :3].transpose(1, 0, 2), mh),
                depth(px[rows][:, w-1:w-1-mh:-2, :3].transpose(1, 0, 2), mh))

        if max(abs(a - b) for a, b in zip(cand, self.bar_cand)) > 4:
            self.bar_cand, self.bar_since = cand, now
        if max(abs(a - b) for a, b in zip(self.bar_cand, self.bars)) <= 4:
            return
        shrinking = any(a < b - 4 for a, b in zip(self.bar_cand, self.bars))
        if now - self.bar_since >= (BAR_SHRINK_S if shrinking else BAR_GROW_S):
            self.bars = self.bar_cand
            self._build()

    def _sample(self, px):
        """Dominant colour per LED in linear light → (232, 3) RGB, 0..1."""
        raw32 = px.view(np.uint32).reshape(-1).take(self.idx)
        # 15-bit colour key r5 g5 b5 for the vote tables
        if self.bgr:
            key = (raw32 & 0xF80000) >> 9 | (raw32 & 0xF800) >> 6 | (raw32 & 0xF8) >> 3
        else:
            key = (raw32 & 0xF8) << 7 | (raw32 & 0xF800) >> 6 | (raw32 & 0xF80000) >> 19
        raw = raw32.view(np.uint8).reshape(-1, 4)

        # Tally per (LED, hue bin): vote mass, pixel weight and summed colour.
        cell = self.base + BIN_LUT.take(key)
        n = self.n_led * (HUE_BINS + 1)
        tally = np.stack(
            [np.bincount(cell, self.wgt * MASS_LUT.take(key), n), np.bincount(cell, self.wgt, n)]
            + [np.bincount(cell, self.wgt * GAMMA_LUT.take(raw[:, i]), n) for i in self.chan],
            axis=1).reshape(self.n_led, HUE_BINS + 1, 5)
        # The TV strip is a closed loop around the screen; the desk strip is a line.
        n_tv = TV_TOTAL - 1
        tally = np.concatenate([blur_leds(tally[:n_tv], ZONE_BLUR, True),
                                blur_leds(tally[n_tv:], ZONE_BLUR, False)])
        mass, weight, rgb = tally[:, :, 0], tally[:, :, 1], tally[:, :, 2:]

        # A hue rarely falls in one bin, so neighbouring bins back each other up.
        hues = mass[:, :HUE_BINS]
        votes = np.concatenate([hues + 0.5 * (np.roll(hues, 1, axis=1) + np.roll(hues, -1, axis=1)),
                                mass[:, HUE_BINS:]], axis=1)
        # Soft winner-takes-all: a clear winner shuts the rest out, a near tie
        # blends, so two rival colours never make the LED flip back and forth.
        keep = (votes / np.maximum(votes.max(axis=1, keepdims=True), 1e-9)) ** DOMINANCE
        kept = np.maximum((keep * weight).sum(axis=1), 1e-9)
        color = (keep[:, :, None] * rgb).sum(axis=1) / kept[:, None]
        # A small bright object in a dark region colours its LED but only
        # lights it part-way, by the share of the region it actually covers.
        share = kept / np.maximum(weight.sum(axis=1), 1e-9)
        return (color * (share ** DARK_SUPPORT)[:, None]).astype(np.float32)

    def _grade(self, rgb):
        """Linear RGB (N, 3) → the colour the wall should show, linear RGB 0..1."""
        if SATURATION != 1.0:
            lab = to_oklab(rgb)
            lab[:, 1:] *= SATURATION
            vivid = from_oklab(lab)
            # Colours already at the edge of what the LEDs can show would be
            # pushed past it and come back with a different hue (orange → red),
            # so each LED is boosted only as far as it stays displayable.
            lo_in, lo_out = rgb.min(axis=1), vivid.min(axis=1)
            reach = np.where(lo_out < 0, lo_in / np.maximum(lo_in - lo_out, 1e-9), 1.0)
            rgb = np.maximum(rgb + reach[:, None] * (vivid - rgb), 0.0)

        # Light on a wall reads much dimmer than the same colour on screen, so
        # each LED is scaled up until its strongest channel sits on the lift curve.
        peak = np.maximum(rgb.max(axis=1), 1e-6)
        rgb = rgb * (BRIGHTNESS * peak ** (LIFT - 1.0))[:, None]
        rgb = rgb + np.maximum(FLOOR - rgb @ LUMA, 0.0)[:, None]
        rgb = rgb * self.gain
        # Out-of-range colours are dimmed as a whole, which keeps their hue.
        return rgb / np.maximum(rgb.max(axis=1), 1.0)[:, None]

    def process(self, px, now):
        """px: uint8 (H, W, 4) capture buffer. Returns the frame to send."""
        self._detect_bars(px, now)
        self.target = to_oklab(self._grade(self._sample(px)))
        return self.advance(now)

    def advance(self, now):
        """Ease towards the current target. Runs at OUT_FPS, with or without a
        new capture, so fades are continuous and a screen that goes static
        mid-fade still lands on its colour."""
        if self.state is None:
            self.state = self.target.copy()
        else:
            dt = min(now - self.last_t, 0.5)
            diff = self.target - self.state
            dist = np.sqrt((diff * diff).sum(axis=1))
            cut = np.clip((dist - DELTA_SLOW) / (DELTA_FAST - DELTA_SLOW), 0.0, 1.0)
            self.cut = np.maximum(cut, self.cut - dt / CUT_HOLD)
            tau = TAU_SLOW * (TAU_FAST / TAU_SLOW) ** self.cut
            self.state[:, 0]  += (1.0 - np.exp(-dt / (tau * LIGHT_SLOWDOWN))) * diff[:, 0]
            self.state[:, 1:] += (1.0 - np.exp(-dt / tau))[:, None] * diff[:, 1:]
        self.last_t = now
        self.settled = float(np.abs(self.target - self.state).max()) < 0.002
        if self.settled:
            self.state = self.target.copy()

        rgb = np.maximum(from_oklab(self.state), 0.0)
        led = np.maximum(rgb @ LED_MATRIX.T, 0.0)
        # The matrix only re-mixes the channels; the drive level stays the colour's own.
        led *= (rgb.max(axis=1) / np.maximum(led.max(axis=1), 1e-9))[:, None]
        out = np.rint(np.minimum(led, 1.0) * 255)
        n_tv = TV_TOTAL - 1
        if not DESK_ON:
            out[n_tv:] = 0
        self.out = np.vstack([out[:n_tv], out[n_tv-1:n_tv], out[n_tv:]])   # pad to TV_TOTAL
        return self.out


def create_shm_buffer(wl_shm, w, h, fmt):
    """Allocate a memfd-backed WlShmPool+WlBuffer and return (wl_buffer, mmap)."""
    size = w * h * 4
    fd = os.memfd_create("ambilight", os.MFD_CLOEXEC)
    os.ftruncate(fd, size)
    shm_map = mmap.mmap(fd, size, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE)
    pool = wl_shm.create_pool(fd, size)
    os.close(fd)
    wl_buf = pool.create_buffer(0, w, h, w * 4, fmt)
    pool.destroy()
    return wl_buf, shm_map


def wled_state(state):
    """Post to WLED's JSON state API. Best effort."""
    req = urllib.request.Request(
        f"http://{WLED_IP}/json/state",
        data=json.dumps(state).encode(),
        headers={"Content-Type": "application/json"},
        method="POST")
    try:
        urllib.request.urlopen(req, timeout=1).close()
    except Exception as e:
        print(f"WLED {state}: {e}", file=sys.stderr)


def wled_power(on):
    """Turn the WLED strip on/off."""
    # No "tt": 0 here: this firmware keeps a one-off zero transition around,
    # and static colours then snap instead of fading until something resets it.
    wled_state({"on": on})


def dispatch_until(display, fd, pred, timeout=5.0):
    """Dispatch Wayland events until pred() is True or timeout expires."""
    t0 = time.monotonic()
    while not pred():
        display.flush()
        remaining = timeout - (time.monotonic() - t0)
        if remaining <= 0:
            raise TimeoutError("Timed out waiting for Wayland event")
        r, _, _ = select.select([fd], [], [], min(remaining, 0.05))
        if r:
            # block=True → wl_display_dispatch(): reads from socket then dispatches.
            # block=False → wl_display_dispatch_pending(): never reads, so events
            # sit unread in the socket buffer forever.
            display.dispatch(block=True)


def main():
    wayland_display = os.environ.get("WAYLAND_DISPLAY")
    if not wayland_display:
        sys.exit("WAYLAND_DISPLAY is not set. Start the service from within a Hyprland session.")

    display = Display()
    display.connect()
    fd = display.get_fd()

    # --- Discover globals ---
    registry = display.get_registry()
    found = {}
    output_globals = []   # every wl_output, in registry order

    def on_global(registry, name, interface, version):
        found[interface] = (name, version)
        if interface == WlOutput.name:
            output_globals.append((name, version))

    output_state = {"global": None, "gone": False}

    def on_global_remove(registry, name):
        if name == output_state["global"]:
            output_state["gone"] = True

    registry.dispatcher["global"] = on_global
    registry.dispatcher["global_remove"] = on_global_remove
    display.roundtrip()

    required = {
        WlShm.name,
        WlOutput.name,
        ExtImageCopyCaptureManagerV1.name,
        ExtOutputImageCaptureSourceManagerV1.name,
    }
    missing = required - found.keys()
    if missing:
        sys.exit(
            f"Compositor is missing required Wayland globals: {missing}\n"
            "Hyprland >= 0.41 is required for ext-image-copy-capture-v1."
        )

    def bind(cls, max_ver=1):
        name, ver = found[cls.name]
        return registry.bind(name, cls, min(ver, max_ver))

    wl_shm      = bind(WlShm)
    capture_mgr = bind(ExtImageCopyCaptureManagerV1)
    source_mgr  = bind(ExtOutputImageCaptureSourceManagerV1)

    # Bind every output to learn its connector name, then pick TARGET_OUTPUT.
    outputs = []
    for gname, gver in output_globals:
        proxy = registry.bind(gname, WlOutput, min(gver, 4))
        info = {"global": gname, "proxy": proxy, "name": None, "w": 0, "h": 0}

        def _mode(_o, flags, w, h, refresh, _info=info):
            if flags & 0x1:            # WL_OUTPUT_MODE_CURRENT
                _info["w"], _info["h"] = w, h

        def _name(_o, name, _info=info):
            _info["name"] = name

        proxy.dispatcher["mode"] = _mode
        proxy.dispatcher["name"] = _name
        outputs.append(info)
    display.roundtrip()

    chosen = next((o for o in outputs if o["name"] == TARGET_OUTPUT), None)
    if chosen is None:
        print(f"{TARGET_OUTPUT} not available — turning strip off.", file=sys.stderr)
        wled_power(False)
        display.disconnect()
        return
    wl_output = chosen["proxy"]
    output_state["global"] = chosen["global"]
    print(f"Mirroring output {TARGET_OUTPUT} ({chosen['w']}x{chosen['h']})", file=sys.stderr)
    wled_power(True)

    # --- Create output source & capture session ---
    source = source_mgr.create_source(wl_output)

    sess_state = {"w": 0, "h": 0, "formats": [], "done": False, "stopped": False}
    # options=0: no cursor painted into the capture
    session = capture_mgr.create_session(source, 0)

    session.dispatcher["buffer_size"] = lambda _s, w, h: sess_state.update({"w": w, "h": h})
    session.dispatcher["shm_format"]  = lambda _s, fmt: sess_state["formats"].append(fmt)
    session.dispatcher["done"]        = lambda _s: sess_state.update({"done": True})
    session.dispatcher["stopped"]     = lambda _s: sess_state.update({"stopped": True})
    display.flush()

    dispatch_until(display, fd, lambda: sess_state["done"])

    w, h = sess_state["w"], sess_state["h"]
    if not w or not h or not sess_state["formats"]:
        sys.exit("Failed to negotiate capture session (no buffer_size / shm_format received).")

    # Prefer XRGB8888 (1) or ARGB8888 (0) — [B,G,R,X] memory layout matches existing code
    preferred = [f for f in (1, 0) if f in sess_state["formats"]]
    fmt = preferred[0] if preferred else sess_state["formats"][0]
    is_bgr_layout = fmt in BGR_FORMATS

    print(f"Capture: {w}×{h}  shm_format={fmt:#x}  bgr_layout={is_bgr_layout}", file=sys.stderr)

    wl_buf, shm_map = create_shm_buffer(wl_shm, w, h, fmt)
    display.flush()

    # Zero-copy persistent view of shared memory. mmap.mmap exposes the buffer
    # protocol, so np.frombuffer creates a direct view with no copy. After each
    # frame.ready event the compositor has finished writing; arr_full reflects
    # the new pixels immediately without any shm_map.read() call.
    arr_full = np.frombuffer(shm_map, dtype=np.uint8).reshape(h, w, 4)
    engine   = ColorEngine(w, h, is_bgr_layout)

    sock     = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    interval = 1.0 / FPS
    tick     = 1.0 / OUT_FPS
    seq      = 1
    sent_at  = 0.0

    print(f"Ambilight running: capture {FPS} FPS, LEDs {OUT_FPS} FPS, stride={STRIDE}. "
          "Send SIGINT to stop.", file=sys.stderr)

    def send_frame(colors):
        """Push one 233-LED frame to WLED over DDP."""
        nonlocal seq, sent_at
        sent_at = time.monotonic()
        payload = colors.clip(0, 255).astype(np.uint8).tobytes()
        header  = struct.pack(">BBBBIH", 0x41, seq, 0x01, 0x01, 0, len(payload))
        sock.sendto(header + payload, (WLED_IP, WLED_PORT))
        seq = (seq % 15) + 1

    idle_timeouts = 0

    try:
        # Never request a frame once the output is gone: Hyprland 0.56 segfaults
        # creating a capture frame for a removed monitor.
        while not (sess_state["stopped"] or output_state["gone"]):
            t0 = time.monotonic()

            # --- Capture one frame ---
            frame_state = {"ready": False, "failed": False}
            frame = session.create_frame()
            frame.attach_buffer(wl_buf)
            frame.damage_buffer(0, 0, w, h)
            frame.capture()

            frame.dispatcher["ready"]  = lambda _f: frame_state.update({"ready": True})
            frame.dispatcher["failed"] = lambda _f, r: frame_state.update({"failed": True, "reason": r})
            display.flush()

            try:
                # While a fade is still in flight, keep the LEDs moving at
                # OUT_FPS until the frame shows up — also when it never does
                # because the screen stopped changing.
                while True:
                    try:
                        dispatch_until(display, fd,
                                       lambda: frame_state["ready"] or frame_state["failed"],
                                       timeout=2.0 if engine.settled
                                       else max(0.001, sent_at + tick - time.monotonic()))
                        break
                    except TimeoutError:
                        if engine.settled:
                            raise
                        send_frame(engine.advance(time.monotonic()))
            except TimeoutError:
                try:
                    frame.destroy()
                except Exception:
                    pass
                # A wlroots screencopy frame only arrives when the output has
                # damage. A perfectly static screen (paused game, idle desktop)
                # legitimately produces nothing — that must not kill the service
                # and trigger the systemd restart loop. Hold the last colour so
                # WLED keeps its realtime lock instead of falling back to its
                # own effect.
                idle_timeouts += 1
                if idle_timeouts == 1 or idle_timeouts % 15 == 0:
                    print(f"No frame from compositor ({idle_timeouts}x) — "
                          "output idle, holding last colour.", file=sys.stderr)
                if engine.out is not None:
                    send_frame(engine.out)
                time.sleep(interval)
                continue
            idle_timeouts = 0

            if frame_state["failed"]:
                if frame_state.get("reason") == 2:   # failure_reason.stopped
                    sess_state["stopped"] = True
                    frame.destroy()
                    continue
                print("Frame capture failed — retrying.", file=sys.stderr)
                frame.destroy()
                time.sleep(0.1)
                continue

            frame.destroy()

            # --- Sample and send ---
            # arr_full is already up-to-date (live view of shm_map, no read needed).
            send_frame(engine.process(arr_full, time.monotonic()))

            # Until the next capture is due, interpolate the fade at OUT_FPS.
            while True:
                now = time.monotonic()
                due = sent_at + tick
                if engine.settled or due >= t0 + interval:
                    time.sleep(max(0.0, t0 + interval - now))
                    break
                time.sleep(max(0.0, due - now))
                send_frame(engine.advance(time.monotonic()))

        # Output disappeared (monitor off / unplugged): strip off, exit cleanly.
        print(f"{TARGET_OUTPUT} went away — turning strip off.", file=sys.stderr)
        wled_power(False)

    except KeyboardInterrupt:
        pass
    finally:
        # Hand the strip back right away; otherwise WLED keeps showing the last
        # ambilight frame until its realtime timeout runs out.
        wled_state({"live": False})
        # Drop every NumPy view into the shm mapping *before* closing it.
        # np.frombuffer() keeps the mmap exported; calling mmap.close() while
        # that export is alive raises BufferError ("cannot close exported
        # pointers exist"), and the half-torn-down state then segfaults the
        # interpreter as it destroys the Wayland proxies — which is what put
        # the service into a core-dump / restart loop.
        arr_full = None
        gc.collect()
        for label, step in (
            ("wl_buf.destroy",     lambda: wl_buf.destroy()),
            ("shm_map.close",      lambda: shm_map.close()),
            ("session.destroy",    lambda: session.destroy()),
            ("source.destroy",     lambda: source.destroy()),
            ("display.disconnect", lambda: display.disconnect()),
        ):
            try:
                step()
            except Exception as e:
                print(f"cleanup {label}: {e}", file=sys.stderr)


def _on_sigterm(_signum, _frame):
    # systemd stops the unit with SIGTERM — turn it into KeyboardInterrupt so
    # the same graceful teardown as Ctrl-C runs and WLED drops realtime at once.
    raise KeyboardInterrupt


if __name__ == "__main__":
    import signal
    signal.signal(signal.SIGTERM, _on_sigterm)
    main()
