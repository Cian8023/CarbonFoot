"""镜头 2：录入骑行 6km。录制 + 操作按时间轴同步。"""
import ctypes
import ctypes.wintypes as wt
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HDC = r"D:/aaaa/SDK/26.0.0/toolchains/hdc.exe"
T = ["-t", "127.0.0.1:5555"]
FF = os.path.join(ROOT, "tools", "ffmpeg-9.0.2-essentials_build", "bin", "ffmpeg.exe")
OUT = os.path.join(ROOT, "raw", "s02.mp4")

u = ctypes.windll.user32


def find_emulator():
    u.SetProcessDPIAware()
    found = []

    def cb(h, _):
        if not u.IsWindowVisible(h):
            return True
        n = u.GetWindowTextLengthW(h)
        buf = ctypes.create_unicode_buffer(n + 1)
        u.GetWindowTextW(h, buf, n + 1)
        if "emulator" in buf.value.lower():
            r = wt.RECT()
            u.GetWindowRect(h, ctypes.byref(r))
            w, hh = r.right - r.left, r.bottom - r.top
            if w > 200 and hh > 200:
                found.append((w * hh, h))
        return True

    proc = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)(cb)
    u.EnumWindows(proc, 0)
    found.sort(reverse=True)
    return found[0][1] if found else 0


def hdc(cmd):
    subprocess.run([HDC] + T + ["shell", cmd], capture_output=True)


def main():
    os.makedirs(os.path.join(ROOT, "raw"), exist_ok=True)

    # 强制重启，确保表单与数据都是干净的初始态
    hdc("aa force-stop com.carbon.footprint")
    time.sleep(1)
    hdc("aa start -a EntryAbility -b com.carbon.footprint")
    time.sleep(7)

    hwnd = find_emulator()
    if not hwnd:
        print("emulator window not found")
        sys.exit(1)
    u.SetForegroundWindow(hwnd)
    u.ShowWindow(hwnd, 9)
    time.sleep(0.6)
    r = wt.RECT()
    u.GetWindowRect(hwnd, ctypes.byref(r))
    print("window:", r.left, r.top, r.right - r.left, r.bottom - r.top)

    cmd = [
        FF, "-hide_banner", "-loglevel", "error",
        "-f", "gdigrab", "-framerate", "30",
        "-offset_x", str(r.left), "-offset_y", str(r.top),
        "-video_size", "400x795", "-i", "desktop",
        "-t", "42", "-vf", "scale=400:796",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        "-pix_fmt", "yuv420p", "-y", OUT,
    ]
    p = subprocess.Popen(cmd)
    time.sleep(1.5)
    t0 = time.time()

    def at(sec):
        d = sec - (time.time() - t0)
        if d > 0:
            time.sleep(d)

    at(3.0);  hdc("uitest uiInput click 210 1626")
    at(5.5);  hdc("uitest uiInput click 555 718")
    at(8.5);  hdc("uitest uiInput click 632 1326")
    at(9.5);  hdc("uitest uiInput inputText 632 1326 6")
    at(11.5); hdc("uitest uiInput click 1325 1818")
    at(18.0); hdc("uitest uiInput swipe 700 2000 700 1850 500")
    at(31.0); hdc("uitest uiInput click 720 2391")
    p.wait()
    print("saved:", OUT)


if __name__ == "__main__":
    main()
