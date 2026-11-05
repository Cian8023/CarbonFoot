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

STEPS = ["行为记录", "核算", "统计", "积分", "智能识别", "多端同步", "数据导出"]

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
        f="s01", dur=22, label="01   作品概览 · 首页全景", cur=0,
        subs=[
            (0.5, 6.5, ["本作品将日常低碳行为", "转化为可计量的碳资产。"]),
            (6.5, 12.0, ["首页集中呈现四项指标："]),
            (12.0, 17.0, ["当日减排量、本月完成度，"]),
            (17.0, 22.0, ["以及连续天数、积分余额。"]),
        ],
    ),
    dict(
        f="s02", dur=42, label="02   行为录入 · 实时核算", cur=0,
        subs=[
            (0.5, 5.5, ["单笔记录不超过十五秒。"]),
            (5.5, 12.0, ["选择大类与子类型，", "录入数值后即时换算。"]),
            (12.0, 18.0, ["骑行按每公里 180 克计，", "6 公里即 1.08 千克。"]),
            (18.0, 24.0, ["提交前已显示预估积分。"]),
            (24.0, 30.0, ["卡片底部标注系数取值，", "并注明结果为估算值。"]),
            (30.0, 36.0, ["系数出处与适用条件", "均在界面明示。"]),
            (36.0, 42.0, ["核算口径可逐项核对。"]),
        ],
    ),
    dict(
        f="s03", dur=35, label="03   积分发放 · 任务判定规则", cur=3,
        subs=[
            (0.5, 6.0, ["提交后无需手动领取积分。"]),
            (6.0, 12.5, ["单次提交触发两项结算："]),
            (12.5, 19.0, ["行为本身计 10 积分，", "任务达成再追加 10 分。"]),
            (19.0, 25.0, ["每笔流水记录来源、", "余额与发生时间。"]),
            (25.0, 30.0, ["任务每日零点重置，", "同周期仅发放一次。"]),
            (30.0, 35.0, ["规则在界面完整说明。"]),
        ],
    ),
    dict(
        f="s04", dur=24, label="04   看板联动 · 趋势图表", cur=2,
        subs=[
            (0.5, 6.0, ["返回首页，数据同步刷新。"]),
            (6.0, 12.0, ["本月累计 3.66 千克，", "完成度 12%。"]),
            (12.0, 17.0, ["趋势图支持四种周期：", "日、周、月、年。"]),
            (17.0, 24.0, ["点击任意柱体，", "可查该周期具体数值。"]),
        ],
    ),
    dict(
        f="s05", dur=33, label="05   历史记录 · 核算过程可追溯", cur=1,
        subs=[
            (0.5, 6.0, ["支持按时间、类别与关键字检索。"]),
            (6.0, 12.0, ["展开任意记录，", "可见减排量核算过程："]),
            (12.0, 18.0, ["6 公里乘以每公里 180 克，", "合计 1.08 千克。"]),
            (18.0, 24.0, ["下方说明计量口径、", "系数来源与整理年份，"]),
            (24.0, 28.0, ["并声明结果为估算值，", "不用于碳交易或认证。"]),
            (28.0, 33.0, ["核算依据可完整追溯。"]),
        ],
    ),
    dict(
        f="s06", dur=31, label="06   智能识别 · 票据批量读取", cur=4,
        subs=[
            (0.5, 5.5, ["除手动录入外，亦支持图像识别。"]),
            (5.5, 11.5, ["单次最多选取 9 张；", "行程单、电费单均可。"]),
            (11.5, 17.0, ["识别过程逐张反馈进度。"]),
            (17.0, 22.0, ["结果逐条列示：", "地铁 12.6 公里、"]),
            (22.0, 26.0, ["用电 128 千瓦时、", "光盘 1 次。"]),
            (26.0, 31.0, ["数值取自票据原文可修改，", "须确认后方可写入。"]),
        ],
    ),
    dict(
        f="s07", dur=30, label="07   家庭账户 · 多端数据合并", cur=5, dual=True,
        subs=[
            (0.5, 7.0, ["家庭账户支持各自记录、", "合并统计。"]),
            (7.0, 13.5, ["两台设备以同一组号关联，"]),
            (13.5, 19.5, ["分别上报减排量与积分，", "由服务端聚合排行。"]),
            (19.5, 25.0, ["本机 15.00 千克，", "成员 4.78 千克。"]),
            (25.0, 30.0, ["数据仅经局域网中转，", "不可达时降级缓存。"]),
        ],
    ),
    dict(
        f="s08", dur=15, label="08   双碳科普 · 离线内容专栏", cur=5,
        subs=[
            (0.5, 7.0, ["科普专栏内置 16 篇", "离线文章，"]),
            (7.0, 11.0, ["分政策解读、生活技巧、", "行业动态三类。"]),
            (11.0, 15.0, ["阅读完成后可获积分。"]),
        ],
    ),
    dict(
        f="s09", dur=22, label="09   数据备份 · 导出与恢复", cur=6,
        subs=[
            (0.5, 6.0, ["全部数据存储于本地，", "不上传云端。"]),
            (6.0, 12.5, ["备份经系统选择器指定位置，"]),
            (12.5, 17.0, ["由用户决定保存目录。"]),
            (17.0, 22.0, ["除 JSON 备份外，", "另支持 CSV 报表导出。"]),
        ],
    ),
    dict(
        f="s10", dur=28, label="10   功能闭环 · 收尾", cur=6,
        subs=[
            (0.5, 6.5, ["记录、核算、统计、积分、"]),
            (6.5, 11.5, ["识别、同步与导出，", "构成完整闭环。"]),
            (11.5, 16.5, ["系统基于 OpenHarmony", "API 12 及以上版本。"]),
            (16.5, 21.0, ["不引入第三方依赖，", "支持离线运行。"]),
            (21.0, 24.5, ["碳足迹，"]),
            (24.5, 28.0, ["让每一笔低碳行为都有据可查。"]),
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