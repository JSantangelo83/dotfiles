#!/usr/bin/env python3
"""
Wayland-native ambilight via ext-image-copy-capture-v1.
Works on Hyprland >= 0.41 (and any other wlroots compositor that implements the protocol).
Requires: python-pywayland (pacman -S python-pywayland)
"""
import mmap
import os
import select
import socket
import struct
import sys
import time

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

WLED_IP       = "192.168.1.52"
WLED_PORT     = 4048
CAPTURE_DEPTH = 100
FPS           = 20        # 30 → 20: direct 33% CPU reduction
SMOOTHING     = 0.35
STRIDE        = 4         # sample 1-in-N pixels per axis (16× fewer ops, invisible quality loss)

# sRGB → linear LUT for perceptually correct colour averaging
GAMMA_LUT = (np.arange(256, dtype=np.float32) / 255) ** 2.2 * 255

# TV strip — output 0, 113 LEDs
RIGHT_LEDS  = 20
TOP_LEDS    = 35
LEFT_LEDS   = 20
BOTTOM_LEDS = 37
TV_TOTAL    = 113

# Desk strip — output 1, 120 LEDs, right to left
DESK_LEDS = 120

# SHM formats where memory layout is [B, G, R, X/A] (compatible with existing sampling code)
BGR_FORMATS = {0, 1}   # ARGB8888=0, XRGB8888=1


def build_tv_regions(w, h):
    regions = []
    rh = h / RIGHT_LEDS
    for i in range(RIGHT_LEDS):
        regions.append((w - CAPTURE_DEPTH, int(h - (i+1)*rh), w, int(h - i*rh)))
    tw = w / TOP_LEDS
    for j in range(TOP_LEDS):
        regions.append((int(w - (j+1)*tw), 0, int(w - j*tw), CAPTURE_DEPTH))
    lh = h / LEFT_LEDS
    for k in range(LEFT_LEDS):
        regions.append((0, int(k*lh), CAPTURE_DEPTH, int((k+1)*lh)))
    bw = w / BOTTOM_LEDS
    for m in range(BOTTOM_LEDS):
        regions.append((int(m*bw), h - CAPTURE_DEPTH, int((m+1)*bw), h))
    return regions  # 112 regions


def build_desk_regions(w, h):
    regions = []
    dw = w / DESK_LEDS
    for m in range(DESK_LEDS):
        x1 = int((DESK_LEDS - 1 - m) * dw)
        x2 = int((DESK_LEDS - m) * dw)
        regions.append((x1, h - CAPTURE_DEPTH, x2, h))
    return regions


def sample_regions(arr_bgr3, regions, stride):
    """Return float32 (N, 3) in RGB order, averaged in linear light.
    arr_bgr3: uint8 array (H, W, 3) with channels [B, G, R].
    stride: spatial downsample factor — reduces work by stride² with no visible loss."""
    out = np.empty((len(regions), 3), dtype=np.float32)
    for i, (x1, y1, x2, y2) in enumerate(regions):
        patch  = arr_bgr3[y1:y2:stride, x1:x2:stride]  # strided uint8 view, no copy
        linear = GAMMA_LUT[patch]                         # float32 linearised
        avg    = linear.mean(axis=(0, 1))                 # [B_mean, G_mean, R_mean]
        out[i, 0] = avg[2]  # R
        out[i, 1] = avg[1]  # G
        out[i, 2] = avg[0]  # B
    return out


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

    def on_global(registry, name, interface, version):
        found[interface] = (name, version)

    registry.dispatcher["global"] = on_global
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
    wl_output   = bind(WlOutput, max_ver=4)
    capture_mgr = bind(ExtImageCopyCaptureManagerV1)
    source_mgr  = bind(ExtOutputImageCaptureSourceManagerV1)
    display.roundtrip()

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

    tv_regions   = build_tv_regions(w, h)
    desk_regions = build_desk_regions(w, h)

    # Zero-copy persistent view of shared memory. mmap.mmap exposes the buffer
    # protocol, so np.frombuffer creates a direct view with no copy. After each
    # frame.ready event the compositor has finished writing; arr_full reflects
    # the new pixels immediately without any shm_map.read() call.
    arr_full = np.frombuffer(shm_map, dtype=np.uint8).reshape(h, w, 4)
    arr_bgr3 = arr_full[:, :, :3] if is_bgr_layout else None  # live view, channels [B,G,R]

    sock     = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    interval = 1.0 / FPS
    seq      = 1
    smoothed = None

    print(f"Ambilight running at {FPS} FPS, stride={STRIDE}. Send SIGINT to stop.", file=sys.stderr)

    try:
        while not sess_state["stopped"]:
            t0 = time.monotonic()

            # --- Capture one frame ---
            frame_state = {"ready": False, "failed": False}
            frame = session.create_frame()
            frame.attach_buffer(wl_buf)
            frame.damage_buffer(0, 0, w, h)
            frame.capture()

            frame.dispatcher["ready"]  = lambda _f: frame_state.update({"ready": True})
            frame.dispatcher["failed"] = lambda _f, _r: frame_state.update({"failed": True})
            display.flush()

            dispatch_until(display, fd,
                           lambda: frame_state["ready"] or frame_state["failed"],
                           timeout=2.0)

            if frame_state["failed"]:
                print("Frame capture failed — retrying.", file=sys.stderr)
                frame.destroy()
                time.sleep(0.1)
                continue

            # arr_full is already up-to-date (live view of shm_map, no read needed).
            # Non-BGR layout requires a copy with channel swap; BGR skips it entirely.
            if not is_bgr_layout:
                arr_bgr3 = arr_full[:, :, [2, 1, 0]]

            frame.destroy()

            # --- Sample and send ---
            tv_raw   = sample_regions(arr_bgr3, tv_regions, STRIDE)
            tv_raw   = np.vstack([tv_raw, tv_raw[-1:]])   # pad to TV_TOTAL
            desk_raw = sample_regions(arr_bgr3, desk_regions, STRIDE)
            combined = np.vstack([tv_raw, desk_raw])

            if smoothed is None:
                smoothed = combined.copy()
            else:
                smoothed += SMOOTHING * (combined - smoothed)

            data   = smoothed.clip(0, 255).astype(np.uint8).tobytes()
            header = struct.pack(">BBBBIH", 0x41, seq, 0x01, 0x01, 0, len(data))
            sock.sendto(header + data, (WLED_IP, WLED_PORT))
            seq = (seq % 15) + 1

            elapsed = time.monotonic() - t0
            time.sleep(max(0.0, interval - elapsed))

    except KeyboardInterrupt:
        pass
    finally:
        wl_buf.destroy()
        shm_map.close()
        session.destroy()
        source.destroy()
        display.disconnect()


if __name__ == "__main__":
    main()
