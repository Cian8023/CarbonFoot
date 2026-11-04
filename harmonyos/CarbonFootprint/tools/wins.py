# -*- coding: utf-8 -*-
"""列出所有模拟器窗口的标题与坐标，用于确认左右顺序。"""
import ctypes
import ctypes.wintypes as wt

u = ctypes.windll.user32


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
        title = buf.value
        if "emulator" in title.lower():
            r = wt.RECT()
            u.GetWindowRect(h, ctypes.byref(r))
            w, hh = r.right - r.left, r.bottom - r.top
            if w > 200 and hh > 200:
                found.append((r.left, r.top, w, hh, h, title))
        return True

    proc = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)(cb)
    u.EnumWindows(proc, 0)
    found.sort()
    return found


for left, top, w, h, hwnd, title in list_wins():
    print("left=%-6d top=%-6d %dx%d  hwnd=%-10s  title=%r" % (left, top, w, h, hwnd, title))