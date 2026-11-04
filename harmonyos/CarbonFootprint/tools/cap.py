"""按窗口标题截取物理像素画面，输出 BMP（不依赖 Pillow）。"""
import ctypes
import ctypes.wintypes as wt
import struct
import sys

u = ctypes.windll.user32
g = ctypes.windll.gdi32
try:
    u.SetProcessDPIAware()
except Exception:
    pass


def find_window(title):
    """枚举可见顶层窗口，取标题匹配且面积最大的那个。"""
    found = []

    def cb(h, _):
        if not u.IsWindowVisible(h):
            return True
        n = u.GetWindowTextLengthW(h)
        buf = ctypes.create_unicode_buffer(n + 1)
        u.GetWindowTextW(h, buf, n + 1)
        if title.lower() in buf.value.lower():
            r = wt.RECT()
            u.GetWindowRect(h, ctypes.byref(r))
            w, hh = r.right - r.left, r.bottom - r.top
            if w > 200 and hh > 200:
                found.append((w * hh, h))
        return True

    proc = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)(cb)
    u.EnumWindows(proc, 0)
    if not found:
        return 0
    found.sort(reverse=True)
    return found[0][1]


def capture(hwnd, path):
    r = wt.RECT()
    u.GetWindowRect(hwnd, ctypes.byref(r))
    x, y = r.left, r.top
    w, h = r.right - r.left, r.bottom - r.top
    hdc = u.GetDC(0)
    md = g.CreateCompatibleDC(hdc)
    bmp = g.CreateCompatibleBitmap(hdc, w, h)
    g.SelectObject(md, bmp)
    g.BitBlt(md, 0, 0, w, h, hdc, x, y, 0x00CC0020)
    bmi = ctypes.create_string_buffer(
        struct.pack("<IiiHHIIiiII", 40, w, -h, 1, 24, 0, w * h * 3, 0, 0, 0, 0), 40
    )
    buf = ctypes.create_string_buffer(w * h * 3)
    g.GetDIBits(md, bmp, 0, h, buf, bmi, 0)
    with open(path, "wb") as f:
        f.write(struct.pack("<2sIHHI", b"BM", 54 + w * h * 3, 0, 0, 54))
        f.write(bmi.raw)
        f.write(buf.raw)
    g.DeleteObject(bmp)
    g.DeleteDC(md)
    u.ReleaseDC(0, hdc)
    return x, y, w, h


if __name__ == "__main__":
    title = sys.argv[1] if len(sys.argv) > 1 else "Emulator"
    out = sys.argv[2] if len(sys.argv) > 2 else "tools/emu_win.bmp"
    hwnd = find_window(title)
    if not hwnd:
        print("window not found:", title)
        sys.exit(1)
    print("hwnd=%d rect=%s" % (hwnd, capture(hwnd, out)))
