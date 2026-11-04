# -*- coding: utf-8 -*-
"""抓取左右两个模拟器窗口的手机屏区域，确认左窗/右窗分别对应哪台设备。"""
import ctypes
import ctypes.wintypes as wt
import os
import subprocess

from PIL import ImageGrab

u = ctypes.windll.user32
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HDC = r"D:/aaaa/SDK/26.0.0/toolchains/hdc.exe"


def list_wins():
    u.SetProcessDPIAware()
    found = []

    def cb(h, _):
        if not u.IsWindowVisible(h):
            return True
        n = u.GetWindowTextLengthW(h)
        if n == 0:
            return True
        buf = ctypes.create_unicode_buffer(n + 1)
        u.GetWindowTextW(h, buf, n + 1)
        if "emulator" in buf.value.lower():
            r = wt.RECT()
            u.GetWindowRect(h, ctypes.byref(r))
            w, hh = r.right - r.left, r.bottom - r.top
            if w > 200 and hh > 200:
                found.append((r.left, r.top, w, hh, h))
        return True

    proc = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)(cb)
    u.EnumWindows(proc, 0)
    found.sort()
    return found


wins = list_wins()
for i, (left, top, w, h, hwnd) in enumerate(wins):
    u.SetForegroundWindow(hwnd)
    import time
    time.sleep(0.8)
    u.SetForegroundWindow(hwnd)
    time.sleep(0.6)
    # 手机屏本体：窗口内 x=7..396, y=16..781
    box = (left + 7, top + 16, left + 7 + 390, top + 16 + 764)
    img = ImageGrab.grab(bbox=box)
    p = os.path.join(ROOT, "tools", "win%d.png" % i)
    img.save(p)
    print("win%d  left=%d top=%d -> %s" % (i, left, top, p))

# 同时抓两台设备的真实画面
for tag, target in (("A", "127.0.0.1:5555"), ("B", "127.0.0.1:5557")):
    remote = "/data/local/tmp/_w.jpeg"
    subprocess.run([HDC, "-t", target, "shell", "snapshot_display -f " + remote],
                   capture_output=True)
    out = os.path.join(ROOT, "tools", "dev%s.png" % tag)
    subprocess.run([HDC, "-t", target, "file", "recv", remote, out], capture_output=True)
    if os.path.exists(out):
        im = ImageGrab
        print("dev%s -> %s" % (tag, out))