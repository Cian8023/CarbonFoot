# -*- coding: utf-8 -*-
"""
生成演示视频的开场与结尾动画帧
风格与成片一致：暖米白纸底 + 深松绿 + 赭黄，右侧批注栏
"""
import os
from PIL import Image, ImageDraw, ImageFont

W, H = 1920, 1080
BG = (250, 245, 235)        # 暖米白 FAF5EB
DEEP = (24, 58, 42)          # 深松绿 183A2A
PRIMARY = (47, 107, 79)      # 2F6B4F
ACCENT = (184, 134, 47)      # B8862F
SECONDARY = (110, 106, 94)   # 6E6A5E
LIGHT = (200, 221, 208)      # C8DDD0
LINE = (229, 224, 212)       # E5E0D4

F_BOLD = 'C:/Windows/Fonts/msyhbd.ttc'
F_REG = 'C:/Windows/Fonts/msyh.ttc'
F_SERIF = 'C:/Windows/Fonts/simsun.ttc'

OUT = r'D:/aaaa/CarbonFootprint/output/vidframes'
os.makedirs(OUT, exist_ok=True)


def ease_out(t):
    """缓出：先快后慢"""
    return 1 - (1 - t) ** 3


def ease_in_out(t):
    return t * t * (3 - 2 * t)


def new_canvas():
    """直接创建 RGBA 画布，保证 draw 对象始终指向当前图"""
    img = Image.new('RGBA', (W, H), BG + (255,))
    return img, ImageDraw.Draw(img)


def alpha_layer():
    """带透明通道的图层，用于淡入淡出"""
    return Image.new('RGBA', (W, H), (0, 0, 0, 0))


def draw_brand_mark(d, cx, cy, size, alpha=1.0):
    """绘制圆角方块 + 碳字"""
    s = size
    x0, y0 = cx - s // 2, cy - s // 2
    r = int(s * 0.18)
    color = DEEP if alpha >= 1 else tuple(
        int(c * alpha + b * (1 - alpha)) for c, b in zip(DEEP, BG))
    d.rounded_rectangle([x0, y0, x0 + s, y0 + s], radius=r, fill=color)
    # 白字「碳」
    f = ImageFont.truetype(F_BOLD, int(s * 0.62))
    tb = d.textbbox((0, 0), '碳', font=f)
    tw, th = tb[2] - tb[0], tb[3] - tb[1]
    white = (255, 255, 255) if alpha >= 1 else tuple(
        int(255 * alpha + b * (1 - alpha)) for b in BG)
    d.text((cx - tw / 2 - tb[0], cy - th / 2 - tb[1]), '碳', font=f, fill=white)


def fade_text(base, draw_fn, alpha):
    """在独立图层绘制后按 alpha 合成"""
    layer = alpha_layer()
    ld = ImageDraw.Draw(layer)
    draw_fn(ld)
    layer.putalpha(layer.split()[3].point(lambda p: int(p * alpha)))
    base.alpha_composite(layer)


def gen_open(total_frames=54):
    """开场：48~54 帧（1.8 秒 @30fps）"""
    for i in range(total_frames):
        t = i / (total_frames - 1)
        img, d = new_canvas()

        # ---- 阶段 1（0~0.35）：赭黄细线横向展开 ----
        if t < 0.42:
            p = ease_out(t / 0.42)
            line_w = int(560 * p)
            y = H // 2 - 60
            d.line([(W // 2 - line_w // 2, y), (W // 2 + line_w // 2, y)],
                   fill=ACCENT, width=3)

        # ---- 阶段 2（0.15~0.7）：标识淡入放大 ----
        if t > 0.15:
            p = ease_out(min(1, (t - 0.15) / 0.55))
            size = int(96 + 44 * p)
            alpha = p

            def _mark(ld, size=size):
                draw_brand_mark(ld, W // 2, H // 2 - 150, size)

            fade_text(img, _mark, alpha)

        # ---- 阶段 3（0.3~0.8）：主标题滑入 ----
        if t > 0.3:
            p = ease_out(min(1, (t - 0.3) / 0.5))
            offset = int(30 * (1 - p))

            def _title(ld, offset=offset):
                f = ImageFont.truetype(F_BOLD, 76)
                txt = '碳足迹'
                tb = ld.textbbox((0, 0), txt, font=f)
                tw = tb[2] - tb[0]
                ld.text((W // 2 - tw // 2 - tb[0], H // 2 - 20 + offset),
                        txt, font=f, fill=DEEP)

            fade_text(img, _title, p)

        # ---- 阶段 4（0.5~0.95）：副标题 ----
        if t > 0.5:
            p = ease_out(min(1, (t - 0.5) / 0.45))

            def _sub(ld):
                f = ImageFont.truetype(F_REG, 34)
                txt = '全民绿色生活碳积分与减排指南'
                tb = ld.textbbox((0, 0), txt, font=f)
                tw = tb[2] - tb[0]
                ld.text((W // 2 - tw // 2 - tb[0], H // 2 + 110),
                        txt, font=f, fill=SECONDARY)

            fade_text(img, _sub, p)

        # ---- 阶段 5（0.65~1.0）：底部技术栈 ----
        if t > 0.65:
            p = ease_out(min(1, (t - 0.65) / 0.35))

            def _tag(ld):
                f = ImageFont.truetype(F_REG, 22)
                txt = 'HarmonyOS  ·  API 12+  ·  零第三方依赖'
                tb = ld.textbbox((0, 0), txt, font=f)
                tw = tb[2] - tb[0]
                ld.text((W // 2 - tw // 2 - tb[0], H // 2 + 200),
                        txt, font=f, fill=ACCENT)

            fade_text(img, _tag, p)

        # 四角细框（随进度收拢）
        if t > 0.55:
            p = ease_out(min(1, (t - 0.55) / 0.4))
            m = int(80 + 40 * (1 - p))
            d.rectangle([m, m, W - m, H - m], outline=LINE, width=2)

        img.convert('RGB').save(f'{OUT}/open_{i:03d}.png', quality=95)

    print(f'开场帧 {total_frames} 张')


def gen_end(total_frames=54):
    """结尾：54 帧（1.8 秒）"""
    for i in range(total_frames):
        t = i / (total_frames - 1)
        img, d = new_canvas()

        # 标识（持续显示）
        draw_brand_mark(d, W // 2, H // 2 - 200, 100)

        # 主标题
        def _title(ld):
            f = ImageFont.truetype(F_BOLD, 72)
            txt = '感谢聆听'
            tb = ld.textbbox((0, 0), txt, font=f)
            tw = tb[2] - tb[0]
            ld.text((W // 2 - tw // 2 - tb[0], H // 2 - 70),
                    txt, font=f, fill=DEEP)

        fade_text(img, _title, ease_out(min(1, t / 0.4)))

        # 赭黄短线
        if t > 0.25:
            p = ease_out(min(1, (t - 0.25) / 0.35))
            lw = int(240 * p)
            d.line([(W // 2 - lw // 2, H // 2 + 54),
                    (W // 2 + lw // 2, H // 2 + 54)], fill=ACCENT, width=3)

        # 副标题
        if t > 0.35:
            p = ease_out(min(1, (t - 0.35) / 0.4))

            def _sub(ld):
                f = ImageFont.truetype(F_REG, 32)
                txt = '恳请各位评委老师批评指正'
                tb = ld.textbbox((0, 0), txt, font=f)
                tw = tb[2] - tb[0]
                ld.text((W // 2 - tw // 2 - tb[0], H // 2 + 92),
                        txt, font=f, fill=SECONDARY)

            fade_text(img, _sub, p)

        # 结束语
        if t > 0.55:
            p = ease_out(min(1, (t - 0.55) / 0.45))

            def _end(ld):
                f = ImageFont.truetype(F_SERIF, 26)
                txt = '让每一笔低碳行为都有据可查'
                tb = ld.textbbox((0, 0), txt, font=f)
                tw = tb[2] - tb[0]
                ld.text((W // 2 - tw // 2 - tb[0], H // 2 + 185),
                        txt, font=f, fill=PRIMARY)

            fade_text(img, _end, p)

        img.convert('RGB').save(f'{OUT}/end_{i:03d}.png', quality=95)

    print(f'结尾帧 {total_frames} 张')


if __name__ == '__main__':
    gen_open()
    gen_end()