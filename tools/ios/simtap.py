#!/usr/bin/env python3
"""Tap/long-press/swipe the ToME simulator at ENGINE LOGICAL coordinates.

Handles the point<->logical scale (screen_zoom, dpi) and the simulator's
landscape orientation, which flips between launches. Usage:
  simtap.py UDID tap LX LY [--long]
  simtap.py UDID swipe LX1 LY1 LX2 LY2
  simtap.py UDID two LX LY            (two-finger tap)
Calibration state lives in ~/.tome-simtap.json: {"zoom":2,"dpi":3,"orient":"A"|"B",
"w":932,"h":430} (points). Orientation A: xl=yp, yl=h-xp. B: xl=w-yp, yl=xp.
Check the [IOS-INPUT] line after a tap: if it lands mirrored, flip "orient".
"""
import json, os, subprocess, sys
cfg = {"zoom": 2.0, "dpi": 3.0, "orient": "B", "w": 932, "h": 430}
p = os.path.expanduser("~/.tome-simtap.json")
if os.path.exists(p): cfg.update(json.load(open(p)))
def to_pt(lx, ly):
    xl, yl = lx * cfg["zoom"] / cfg["dpi"], ly * cfg["zoom"] / cfg["dpi"]   # landscape points
    if cfg["orient"] == "A": return cfg["h"] - yl, xl        # portrait point (xp, yp)
    return yl, cfg["w"] - xl
udid, cmd = sys.argv[1], sys.argv[2]
idb = os.path.expanduser("~/.local/bin/idb")
a = [float(v) for v in sys.argv[3:] if not v.startswith("--")]
if cmd == "tap":
    xp, yp = to_pt(a[0], a[1])
    args = [idb, "ui", "tap", str(int(xp)), str(int(yp)), "--udid", udid]
    if "--long" in sys.argv: args += ["--duration", "0.9"]
    subprocess.run(args, check=False, capture_output=True)
elif cmd == "swipe":
    x1, y1 = to_pt(a[0], a[1]); x2, y2 = to_pt(a[2], a[3])
    subprocess.run([idb, "ui", "swipe", str(int(x1)), str(int(y1)), str(int(x2)), str(int(y2)), "--duration", "0.6", "--udid", udid], check=False, capture_output=True)
elif cmd == "two":
    # two fingers: idb has no multi-touch; emulate with the accessibility api? fall back:
    # send two quick taps 40pt apart is NOT the same. Left to the HID script (see two-finger.sh).
    print("two-finger tap not supported by idb; use xcrun simctl or a HID script")
print("ok", cmd, a)
