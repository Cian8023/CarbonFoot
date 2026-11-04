"""通用镜头录制：按时间轴执行 hdc 操作并同步录屏。

用法: python tools/rec.py s01
"""
import ctypes
import ctypes.wintypes as wt
import json
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HDC = r"D:/aaaa/SDK/26.0.0/toolchains/hdc.exe"
T = ["-t", "127.0.0.1:5555"]
FF = os.path.join(ROOT, "tools", "ffmpeg-9.0.2-essentials_build", "bin", "ffmpeg.exe")

SHOTS = {
    "s01": {
        "dur": 22,
        "ops": [],
    },
    "s02": {
        "dur": 42,
        "ops": [
            [3.0, "click 210 1626"],
            [5.5, "click 555 718"],
            [8.5, "click 632 1326"],
            [9.5, "inputText 632 1326 6"],
            [11.5, "click 1325 1818"],
            [18.0, "swipe 700 2000 700 1850 500"],
            [30.5, "click 720 2391"],
        ],
    },
    "s03": {
        "dur": 35,
        "ops": [
            [15.0, "swipe 700 1800 700 1620 500"],
            [22.0, "click 210 722"],
        ],
    },
    "s04": {
        "dur": 24,
        "ops": [
            [2.0, "click 105 2665"],
            [12.0, "swipe 700 2200 700 900 900"],
            [16.0, "click 1037 1800"],
            [20.0, "click 1037 1800"],
        ],
    },
    "s05": {
        "dur": 33,
        "ops": [
            [2.0, "click 137 525"],
            [6.0, "click 341 525"],
            [10.0, "click 621 1068"],
        ],
    },
    "s06": {
        "dur": 46,
        "ops": [
            [2.0, "click 1065 1012"],
            [6.5, "click 668 926"],
            [7.5, "click 1049 926"],
            [8.5, "click 1428 926"],
            [9.5, "click 1257 2538"],
            [32.0, "click 946 1593"],
            [34.0, "keyEvent 2055"],
            [34.4, "keyEvent 2055"],
            [34.8, "keyEvent 2055"],
            [35.2, "keyEvent 2055"],
            [36.0, "inputText 946 1593 8"],
            [38.0, "click 1331 1814"],
            [40.5, "click 997 2147"],
        ],
    },
    "s08": {
        "dur": 15,
        "ops": [
            [1.5, "click 455 703"],
            [6.5, "swipe 700 2100 700 1050 700"],
            [9.0, "swipe 700 2100 700 1050 700"],
            [11.5, "swipe 700 2100 700 1150 700"],
        ],
    },
    "s09": {
        "dur": 22,
        "ops": [
            [5.5, "click 325 1499"],
            [8.5, "click 1328 256"],
            [13.5, "click 308 1905"],
            [16.0, "click 1310 253"],
        ],
    },
    "s10": {
        "dur": 28,
        "ops": [
            [3.0, "click 1296 2665"],
            [13.0, "swipe 700 2100 700 1500 800"],
            [22.0, "swipe 700 1600 700 1900 800"],
        ],
    },
    # 双设备镜头：ops 三元组 [秒, "A|B", "动作"]，gdigrab 同时抓两块屏
    # 起点：A 已停在"家庭碳账户"页，B 停在首页。
    # 动线：B 立刻点"家庭账户"进家庭页（早于字幕最优点）→ A 点"立即同步"→ B 也点同步
    "s07": {
        "dur": 30,
        "dual": True,
        "ops": [
            [1.2, "B", "click 890 1896"],
            [9.0, "A", "click 1233 554"],
            [20.0, "B", "click 1233 554"],
        ],
    },
}

u = ctypes.windll.user32


def find_windows():
    """枚举所有模拟器窗口，返回 [(left, top, w, h, hwnd)]，按 left 升序。"""
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
                found.append((r.left, r.top, w, hh, h))
        return True

    proc = ctypes.WINFUNCTYPE(ctypes.c_bool, wt.HWND, wt.LPARAM)(cb)
    u.EnumWindows(proc, 0)
    found.sort()
    return found


def find_emulator(want="A"):
    """want=A 取最左窗口（127.0.0.1:5555），want=B 取最右窗口（:5557）。"""
    wins = find_windows()
    if not wins:
        return 0
    return wins[0][4] if want.upper() == "A" else wins[-1][4]


T_B = ["-t", "127.0.0.1:5557"]


def hdc(cmd, dev="A"):
    target = T if dev == "A" else T_B
    subprocess.run([HDC] + target + ["shell", "uitest uiInput " + cmd], capture_output=True)


def main_dual(name, cfg):
    wins = find_windows()
    if len(wins) < 2:
        print("need 2 emulator windows, found %d" % len(wins))
        sys.exit(1)
    out = os.path.join(ROOT, "raw", name + ".mp4")
    ax, ay, aw, ah, ahwnd = wins[0]
    bx, by, bw, bh, bhwnd = wins[-1]
    u.SetForegroundWindow(ahwnd)
    time.sleep(0.5)

    # 只抓手机屏幕本体：窗口内 x=7..396, y=16..781（390x765）
    cw, chh = 390, 764
    ox, oy = 7, 16
    filt = (
        "[0:v]crop=%d:%d:%d:%d,scale=-2:%d[a];"
        "[1:v]crop=%d:%d:%d:%d,scale=-2:%d[b];"
        "[a][b]hstack=inputs=2[out]"
        % (cw, chh, ox, oy, chh, cw, chh, ox, oy, chh)
    )
    from subprocess import DEVNULL
    cmd = [
        FF, "-hide_banner", "-loglevel", "error",
        "-f", "gdigrab", "-framerate", "30",
        "-offset_x", str(ax), "-offset_y", str(ay),
        "-video_size", "%dx%d" % (aw, ah), "-i", "desktop",
        "-f", "gdigrab", "-framerate", "30",
        "-offset_x", str(bx), "-offset_y", str(by),
        "-video_size", "%dx%d" % (bw, bh), "-i", "desktop",
        "-filter_complex", filt, "-map", "[out]",
        "-t", str(cfg["dur"]),
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        "-pix_fmt", "yuv420p", "-y", out,
    ]
    print("recording %s dual (%ds, %d ops)..." % (name, cfg["dur"], len(cfg["ops"])))
    p = subprocess.Popen(cmd, stdout=DEVNULL, stderr=DEVNULL)
    time.sleep(1.5)
    t0 = time.time()

    for at_sec, dev, action in cfg["ops"]:
        d = at_sec - (time.time() - t0)
        if d > 0:
            time.sleep(d)
        hdc(action, dev)
        print("  %.1fs [%s] %s" % (at_sec, dev, action))

    p.wait()
    print("saved:", out)


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in SHOTS:
        print("usage: python tools/rec.py <%s>" % "|".join(SHOTS))
        sys.exit(1)
    name = sys.argv[1]
    cfg = SHOTS[name]
    os.makedirs(os.path.join(ROOT, "raw"), exist_ok=True)
    if cfg.get("dual"):
        main_dual(name, cfg)
        return
    out = os.path.join(ROOT, "raw", name + ".mp4")

    # 可选第二个参数指定设备：A（左窗 5555）/ B（右窗 5557），默认 A
    want = (sys.argv[2] if len(sys.argv) > 2 else "A").upper()
    hwnd = find_emulator(want)
    if not hwnd:
        print("emulator window not found")
        sys.exit(1)
    u.SetForegroundWindow(hwnd)
    u.ShowWindow(hwnd, 9)
    time.sleep(0.6)
    r = wt.RECT()
    u.GetWindowRect(hwnd, ctypes.byref(r))

    cmd = [
        FF, "-hide_banner", "-loglevel", "error",
        "-f", "gdigrab", "-framerate", "30",
        "-offset_x", str(r.left), "-offset_y", str(r.top),
        "-video_size", "400x795", "-i", "desktop",
        "-t", str(cfg["dur"]), "-vf", "scale=400:796",
        "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
        "-pix_fmt", "yuv420p", "-y", out,
    ]
    print("recording %s (%ds, %d ops)..." % (name, cfg["dur"], len(cfg["ops"])))
    p = subprocess.Popen(cmd)
    time.sleep(1.5)
    t0 = time.time()

    for at_sec, action in cfg["ops"]:
        d = at_sec - (time.time() - t0)
        if d > 0:
            time.sleep(d)
        hdc(action)
        print("  %.1fs %s" % (at_sec, action))

    p.wait()
    print("saved:", out)


if __name__ == "__main__":
    main()
