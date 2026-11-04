# -*- coding: utf-8 -*-
"""把 10 段素材合成横屏成片：左演示画面 + 右字幕，浅米色背景。

用法:
    python tools/build.py            # 全部渲染并拼接
    python tools/build.py s02        # 只渲染某个镜头（调试用）
"""

import os
import subprocess
import sys

from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FF = os.path.join(ROOT, "tools", "ffmpeg-9.0.2-essentials_build", "bin", "ffmpeg.exe")
FONT = "tools/msyh.ttc"
BUILD = os.path.join(ROOT, "build")

W, H = 1920, 1080
BG = "0xF7F4EC"
INK = "0x2E2A24"
MUTED = "0x9C9384"
GREEN = "0x2D6A4F"
LINE = "0xE0D8C8"
DIM = "0xB8B0A0"

STEPS = ["记录", "计算", "统计", "积分", "AI 识别", "同步", "导出"]

# 单设备画面框
BOX_W, BOX_H, BOX_X, BOX_Y = 452, 900, 130, 90

# 双设备：原始 780x764（两屏各 390x764）。拆成两半各自套圆角遮罩再并排，
# 中间留 GAP 像素浅米色间隙 —— 否则两块屏幕底部圆角在接缝处相向拼出箭头状缺口。
DUAL_H, DUAL_GAP = 770, 18
DUAL_HW = round(DUAL_H * 390 / 764)          # 每一半的显示宽度
DUAL_W = DUAL_HW * 2 + DUAL_GAP
DUAL_X, DUAL_Y = 120, 100                    # 左边界与单画面(130)基本齐平
DUAL_SUB_X = DUAL_X + DUAL_W + 40            # 双设备时字幕列左边界
DUAL_NAV_W = 1920 - DUAL_SUB_X - 60

SUB_X = 712
NAV_X = 712
NAV_W = 1078
SUB_Y = 470
SUB_LH = 88
SUB_SIZE = 56

SHOTS = [
    dict(
        f="s01", dur=22, label="01   开场 · 首页全景", cur=0,
        subs=[
            (0.5, 7.0, ["这是一个把日常低碳行为", "记成「碳账本」的鸿蒙应用。"]),
            (7.0, 12.5, ["首页一眼就能看到："]),
            (12.5, 17.5, ["今天减排多少、本月目标走到哪、"]),
            (17.5, 22.0, ["连续坚持几天、手里有多少碳积分。"]),
        ],
    ),
    dict(
        f="s02", dur=42, label="02   录入一条行为", cur=0,
        subs=[
            (0.5, 5.5, ["记一笔不超过 15 秒。"]),
            (5.5, 13.0, ["选大类、选子类型、输数值，", "减排量实时算出来。"]),
            (13.0, 21.0, ["骑行按每公里 180 克算，", "6 公里就是 1.08 公斤。"]),
            (21.0, 28.0, ["还没提交，右下角已经显示", "这笔能拿 +10 积分。"]),
            (28.0, 34.5, ["按 180 g/km 系数估算，", "结果是估算值。"]),
            (34.5, 42.0, ["因子出处，界面上都写清楚了。"]),
        ],
    ),
    dict(
        f="s03", dur=35, label="03   积分双发放 · 任务规则", cur=3,
        subs=[
            (0.5, 6.5, ["提交后不用手动领奖。"]),
            (6.5, 14.0, ["这一笔同时触发两件事：", "行为本身给 10 积分，"]),
            (14.0, 22.0, ["「每日骑行 5 公里」任务达标，", "再给 10 积分。"]),
            (22.0, 28.5, ["每笔积分都记了来源、动作、", "余额和时间。"]),
            (28.5, 35.0, ["任务每天零点重置，", "同一任务每期只发一次。"]),
        ],
    ),
    dict(
        f="s04", dur=24, label="04   看板联动 · 趋势图", cur=2,
        subs=[
            (0.5, 6.5, ["回到首页，今日减排被刷新，", "打卡天数也跟着走。"]),
            (6.5, 12.0, ["本月 3.66 公斤，完成度 12%，", "进度条同步上移。"]),
            (12.0, 18.0, ["趋势图支持日、周、月、年四档，"]),
            (18.0, 24.0, ["点任意一根柱子，", "就能看到那天的具体数值。"]),
        ],
    ),
    dict(
        f="s05", dur=33, label="05   历史记录 · 算法透明", cur=1,
        subs=[
            (0.5, 6.0, ["历史记录可以按时间、类别、", "关键字查。"]),
            (6.0, 12.5, ["点开任意一条，", "能看到这笔减排怎么算的："]),
            (12.5, 20.0, ["6 公里乘每公里 180 克，", "等于 1.08 公斤。"]),
            (20.0, 27.0, ["下面还写了「1 公里」指什么、", "系数从哪来、哪一年整理的，"]),
            (27.0, 33.0, ["以及「这是估算值，", "不用于碳交易或认证」。"]),
        ],
    ),
    dict(
        f="s06", dur=31, label="06   AI 批量识别", cur=4,
        subs=[
            (0.5, 6.0, ["不想手输，可以拍照识别。"]),
            (6.0, 13.0, ["一次最多选 9 张，", "行程单、电费单、外卖单都行。"]),
            (13.0, 19.5, ["识别时逐张显示进度，", "不会让你干等。"]),
            (19.5, 25.0, ["结果逐条列出：地铁 12.6 公里、", "用电 128 度、光盘一次，"]),
            (25.0, 31.0, ["数字取自票据原文，每条都能改；", "但要你点「全部录入」才入库。"]),
        ],
    ),
    dict(
        f="s07", dur=30, label="07   家庭多端同步", cur=5, dual=True,
        subs=[
            (0.5, 8.0, ["家庭账户让一家人各自记录、", "合并看。"]),
            (8.0, 15.0, ["两台设备用同一个组号，", "各自上报减排和积分，"]),
            (15.0, 22.5, ["服务端合并后显示排行：", "我 15.00，妈妈 4.78。"]),
            (22.5, 30.0, ["数据只在局域网内的服务里中转，", "走不通就降级到本地缓存。"]),
        ],
    ),
    dict(
        f="s08", dur=15, label="08   双碳科普专栏", cur=5,
        subs=[
            (0.5, 7.5, ["科普专栏内置 16 篇离线文章，", "政策解读、"]),
            (7.5, 15.0, ["生活技巧、行业动态三类，", "读完能拿积分。"]),
        ],
    ),
    dict(
        f="s09", dur=22, label="09   数据备份与导出", cur=6,
        subs=[
            (0.5, 7.0, ["数据全在手机本地，不上传云端。"]),
            (7.0, 14.0, ["备份走系统文件选择器，", "存哪个目录你决定。"]),
            (14.0, 22.0, ["除了 JSON 备份，", "还能导出 CSV 报表。"]),
        ],
    ),
    dict(
        f="s10", dur=28, label="10   闭环 · 收尾", cur=6,
        subs=[
            (0.5, 8.0, ["记录、核算、看板、积分、", "AI 识别、家庭同步、导出，"]),
            (8.0, 15.0, ["形成闭环。全部基于", "OpenHarmony API 12 以上开发，"]),
            (15.0, 21.0, ["不依赖第三方库，本地离线可用。"]),
            (21.0, 28.0, ["碳足迹，", "让每一笔低碳行为都有据可查。"]),
        ],
    ),
]


def make_mask(w, h, r, path):
    """生成圆角矩形遮罩（白=显示）。"""
    ss = 4
    img = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w * ss - 1, h * ss - 1], radius=r * ss, fill=255)
    img = img.resize((w, h), Image.LANCZOS)
    img.convert("RGB").save(path)
    return path


def write_text(text, path):
    full = os.path.join(ROOT, "tools", "txt", path)
    with open(full, "w", encoding="utf-8") as f:
        f.write(text)
    return path


def dt(textfile, size, color, x, y, enable=None):
    s = ("drawtext=fontfile=%s:textfile=tools/txt/%s:expansion=none"
         ":fontsize=%d:fontcolor=%s:x=%d:y=%d" % (
             FONT, textfile, size, color, x, y))
    if enable:
        s += ":enable='%s'" % enable
    return s


def render(shot):
    name = shot["f"]
    dur = shot["dur"]
    dual = bool(shot.get("dual"))
    os.makedirs(os.path.join(ROOT, "tools", "txt"), exist_ok=True)

    if dual:
        sub_x = DUAL_SUB_X
        nav_x = DUAL_SUB_X
        nav_w = DUAL_NAV_W
    else:
        sub_x, nav_x, nav_w = SUB_X, NAV_X, NAV_W

    tag = write_text(shot["label"], "tag_%s.txt" % name)

    if dual:
        # 左右两半各自缩放到同一尺寸，各自套圆角，中间留浅米色间隙
        x2 = DUAL_X + DUAL_HW + DUAL_GAP
        parts = [
            "[0:v]scale=780:764,format=rgba,split=2[sa][sb]",
            "[sa]crop=390:764:0:0,scale=%d:%d[rl]" % (DUAL_HW, DUAL_H),
            "[sb]crop=390:764:390:0,scale=%d:%d[rr]" % (DUAL_HW, DUAL_H),
            "[1:v]split=2[ma][mb]",
            "[rl][ma]alphamerge[pl]",
            "[rr][mb]alphamerge[pr]",
            "[2:v][pl]overlay=%d:%d[v0a]" % (DUAL_X, DUAL_Y),
            "[v0a][pr]overlay=%d:%d[v0]" % (x2, DUAL_Y),
        ]
    else:
        parts = [
            "[0:v]scale=%d:%d,format=rgba[p]" % (BOX_W, BOX_H),
            "[p][1:v]alphamerge[ph]",
            "[2:v][ph]overlay=%d:%d[v0]" % (BOX_X, BOX_Y),
        ]

    parts += [
        "[v0]drawbox=x=%d:y=188:w=6:h=38:color=%s:t=fill[v1]" % (nav_x, GREEN),
        "[v1]" + dt(tag, 28, MUTED, nav_x + 28, 190) + "[v2]",
    ]
    prev = "v2"

    # 字幕
    for i, (s0, s1, lines) in enumerate(shot["subs"]):
        y0 = SUB_Y if len(lines) > 1 else SUB_Y + 44
        for j, line in enumerate(lines):
            fn = "sub_%s_%d_%d.txt" % (name, i, j)
            write_text(line, fn)
            out = "u%d_%d" % (i, j)
            parts.append(
                "[%s]" % prev
                + dt(fn, SUB_SIZE, INK, sub_x, y0 + j * SUB_LH,
                     "between(t,%.2f,%.2f)" % (s0, s1))
                + "[%s]" % out
            )
            prev = out

    # 分隔线 + 步骤导航
    parts.append("[%s]drawbox=x=%d:y=910:w=%d:h=1:color=%s:t=fill[v6]"
                 % (prev, nav_x, nav_w, LINE))
    prev = "v6"
    step_gap = nav_w // len(STEPS)
    for i, step in enumerate(STEPS):
        mark = "●" if i == shot["cur"] else "○"
        color = GREEN if i == shot["cur"] else DIM
        fn = "step_%s_%d.txt" % (name, i)
        write_text("%s %s" % (mark, step), fn)
        out = "s%d%s" % (i, name)
        parts.append(
            "[%s]" % prev + dt(fn, 22, color, nav_x + i * step_gap, 944) + "[%s]" % out
        )
        prev = out

    parts.append("[%s]format=yuv420p[out]" % prev)

    out_path = os.path.join(BUILD, "c%s.mp4" % name[1:])
    cmd = [
        FF, "-hide_banner", "-loglevel", "error",
        "-i", "raw/%s.mp4" % name,
        "-i", "tools/mask_%s.png" % ("dual" if dual else "single"),
        "-f", "lavfi", "-i", "color=c=%s:s=%dx%d:d=%d" % (BG, W, H, dur),
        "-filter_complex", ";".join(parts),
        "-map", "[out]", "-t", str(dur),
        "-r", "30",
        "-c:v", "libx264", "-crf", "19", "-preset", "medium",
        "-pix_fmt", "yuv420p", "-y", out_path,
    ]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("FAILED %s" % name)
        print(r.stderr[-2500:])
        sys.exit(1)
    print("  ok %s (%ds) -> %s" % (name, dur, os.path.basename(out_path)))
    return out_path


def main():
    os.makedirs(BUILD, exist_ok=True)

    # 遮罩：单设备用 452x900，双设备每一半用 DUAL_HW x DUAL_H（同原比例圆角）
    make_mask(BOX_W, BOX_H, 26, os.path.join(ROOT, "tools", "mask_single.png"))
    make_mask(DUAL_HW, DUAL_H, 24, os.path.join(ROOT, "tools", "mask_dual.png"))

    want = sys.argv[1] if len(sys.argv) > 1 else None
    targets = [s for s in SHOTS if not want or s["f"] == want]
    if want and not targets:
        print("unknown shot:", want)
        sys.exit(1)

    print("rendering %d shot(s)..." % len(targets))
    outs = [render(s) for s in targets]
    if want:
        return

    lst = os.path.join(BUILD, "list.txt")
    with open(lst, "w", encoding="utf-8") as f:
        for p in outs:
            f.write("file '%s'\n" % p.replace("\\", "/"))

    final = os.path.join(ROOT, "碳足迹-演示视频.mp4")
    cmd = [
        FF, "-hide_banner", "-loglevel", "error",
        "-f", "concat", "-safe", "0", "-i", lst,
        "-c", "copy", "-movflags", "+faststart", "-y", final,
    ]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                       encoding="utf-8", errors="replace")
    if r.returncode != 0:
        print("CONCAT FAILED")
        print(r.stderr[-2000:])
        sys.exit(1)
    size = os.path.getsize(final) / 1024 / 1024
    print("\nDONE -> %s  (%.1f MB)" % (final, size))


if __name__ == "__main__":
    main()