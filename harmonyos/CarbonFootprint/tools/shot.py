# -*- coding: utf-8 -*-
"""截图小工具：python tools/shot.py [A|B] [输出名]"""
import os
import subprocess
import sys

HDC = "D:/aaaa/SDK/26.0.0/toolchains/hdc.exe"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEV = {"A": "127.0.0.1:5555", "B": "127.0.0.1:5557"}


def run(args, **kw):
    return subprocess.run(args, capture_output=True, text=True, **kw)


def shot(dev="A", out=None):
    t = DEV[dev.upper()]
    remote = "/data/local/tmp/_shot.jpeg"
    out = out or os.path.join(ROOT, "tools", "now_%s.jpeg" % dev.lower())
    run([HDC, "-t", t, "shell", "snapshot_display -f " + remote])
    r = run([HDC, "-t", t, "file", "recv", remote, out])
    return out if os.path.exists(out) else None


def tap(x, y, dev="A"):
    t = DEV[dev.upper()]
    run([HDC, "-t", t, "shell", "uitest uiInput click %d %d" % (x, y)])


def key(code, dev="A"):
    t = DEV[dev.upper()]
    run([HDC, "-t", t, "shell", "uitest uiInput keyEvent %d" % code])


if __name__ == "__main__":
    d = sys.argv[1] if len(sys.argv) > 1 else "A"
    print(shot(d))