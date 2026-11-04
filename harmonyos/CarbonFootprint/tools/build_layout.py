"""生成横屏版式样板：左手机画面 + 右字幕（按配音时间轴逐句切换）。"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FF = os.path.join(ROOT, "tools", "ffmpeg-9.0.2-essentials_build", "bin", "ffmpeg.exe")
FONT = "tools/msyh.ttc"

BG = "0xF7F4EC"
INK = "0x2E2A24"
MUTED = "0x9C9384"
GREEN = "0x2D6A4F"
LINE = "0xE0D8C8"
DIM = "0xB8B0A0"

STEPS = ["记录", "计算", "统计", "积分", "AI", "同步", "导出"]
CUR = 0

# (起, 止, [行1, 行2])
SUBS = [
    (0, 3, ["记一笔不超过 15 秒。"]),
    (3, 9, ["选大类、选子类型、输数值，", "减排量实时算出来。"]),
    (9, 19, ["骑行按每公里 180 克二氧化碳当量算，", "6 公里就是 1.08 公斤。"]),
    (19, 24, ["输入的时候就知道能拿多少积分。"]),
    (24, 31, ["因子出处和「这是估算值」的说明，", "界面上都有标注。"]),
]

LABEL = "02   录入一条行为"
SUB_Y = 480
SUB_LH = 88
SUB_SIZE = 56

with open(os.path.join(ROOT, "tools", "t_label.txt"), "w", encoding="utf-8") as f:
    f.write(LABEL)

sub_files = []
for i, (_, _, lines) in enumerate(SUBS):
    for j, line in enumerate(lines):
        name = "sub_%d_%d.txt" % (i, j)
        with open(os.path.join(ROOT, "tools", name), "w", encoding="utf-8") as f:
            f.write(line)
        sub_files.append((i, j, name))


def dt(textfile=None, text=None, size=46, color=INK, x=700, y=450, enable=None):
    src = "textfile=tools/%s" % textfile if textfile else "text=%s" % text
    s = "drawtext=fontfile=%s:%s:fontsize=%d:fontcolor=%s:x=%d:y=%d" % (
        FONT, src, size, color, x, y
    )
    if enable:
        s += ":enable='%s'" % enable
    return s


parts = [
    "[0:v]scale=452:900,format=rgba[p]",
    "[p][1:v]alphamerge[ph]",
    "[2:v][ph]overlay=130:90[v0]",
    "[v0]drawbox=x=700:y=188:w=6:h=38:color=%s:t=fill[v1]" % GREEN,
    "[v1]" + dt("t_label.txt", size=28, color=MUTED, x=728, y=190) + "[v2]",
]

prev = "v2"
for i, (s, e, lines) in enumerate(SUBS):
    # 单行字幕整体下移，使视觉中心与多行一致
    y0 = SUB_Y + (0 if len(lines) > 1 else 60)
    for j, line in enumerate(lines):
        out = "u%d_%d" % (i, j)
        parts.append(
            "[%s]" % prev
            + dt(
                "sub_%d_%d.txt" % (i, j),
                size=SUB_SIZE,
                x=700,
                y=y0 + j * SUB_LH,
                enable="between(t,%d,%d)" % (s, e),
            )
            + "[%s]" % out
        )
        prev = out

parts.append("[%s]drawbox=x=700:y=910:w=1100:h=1:color=%s:t=fill[v6]" % (prev, LINE))
prev = "v6"
for i, name in enumerate(STEPS):
    x = 700 + i * 158
    mark = "●" if i == CUR else "○"
    color = GREEN if i == CUR else DIM
    out = "s%d" % i
    parts.append(
        "[%s]" % prev
        + dt(text="%s %s" % (mark, name), size=22, color=color, x=x, y=944)
        + "[%s]" % out
    )
    prev = out

parts.append("[%s]format=yuv420p[out]" % prev)

cmd = [
    FF, "-hide_banner", "-loglevel", "error",
    "-i", "raw/s02.mp4",
    "-i", "tools/mask.png",
    "-f", "lavfi", "-i", "color=c=%s:s=1920x1080:d=42" % BG,
    "-filter_complex", ";".join(parts),
    "-map", "[out]", "-t", "42",
    "-c:v", "libx264", "-crf", "18", "-preset", "medium",
    "-y", "tools/sample_layout.mp4",
]
print("running...")
r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
if r.returncode != 0:
    print("FFMPEG FAILED")
    print(r.stderr[-3000:])
    sys.exit(1)
print("ok -> tools/sample_layout.mp4")
