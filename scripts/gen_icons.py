#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 Skyward 应用图标 / logo 资源（构建期一次性，产物随工程提交）。

设计：品牌 teal 底 + 白色「向上箭头 + 起飞地平线」，线帽圆角与 App 内
IconView 的线性图标语言一致。minSdk 26 意味着自适应图标是主显示路径，
传统 / 圆形 PNG 为 fallback，另出一份应用内「关于」页 logo。

用法： python3 scripts/gen_icons.py
依赖： cairosvg（仅构建期；App 运行时零图片库依赖）
"""
import os
import sys

try:
    import cairosvg
except ImportError:
    sys.exit("缺少 cairosvg：pip3 install cairosvg")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "res")

BG = "#2AA6BC"        # 品牌 teal（UI 主色 #30B0C7 略压暗，保证白色图形对比）
SHADOW = "#0B4A5A"    # 极淡投影，只用在带底图标
FG = "#FFFFFF"

GLYPH_PATHS = (
    '<path d="M54 68 L54 28"/>'          # 箭杆
    '<path d="M34 46 L54 28 L74 46"/>'  # 箭头
    '<path d="M38 80 L70 80"/>'         # 起飞地平线
)


def glyph(color, extra=""):
    return ('<g %s fill="none" stroke="%s" stroke-width="8" '
            'stroke-linecap="round" stroke-linejoin="round">%s</g>'
            % (extra, color, GLYPH_PATHS))


HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" width="108" height="108" '
        'viewBox="0 0 108 108">')
TAIL = '</svg>'

# 自适应图标前景：108dp 画布、透明底，图形落在中间 66dp 安全区内
FG_SVG = HEAD + glyph(FG) + TAIL

# 传统 / 圆形 / 应用内 logo：带底，图形温和放大，加一层极淡投影做层次
SCALED = ('<g transform="translate(54 54) scale(1.12) translate(-54 -54)">'
          + glyph(SHADOW, 'opacity="0.16" transform="translate(0 2.5)"')
          + glyph(FG) + '</g>')


def with_bg(shape):
    return HEAD + shape + SCALED + TAIL


ICON_SVG = with_bg('<rect x="0" y="0" width="108" height="108" rx="24" fill="%s"/>' % BG)
ROUND_SVG = with_bg('<circle cx="54" cy="54" r="54" fill="%s"/>' % BG)

# 目录 -> (启动器图标 px, 自适应前景 px)；前景画布为 108dp
DPIS = [
    ("mipmap-mdpi",     48,  108),
    ("mipmap-hdpi",     72,  162),
    ("mipmap-xhdpi",    96,  216),
    ("mipmap-xxhdpi",  144,  324),
    ("mipmap-xxxhdpi", 192,  432),
]

ADAPTIVE = ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n')


def render(svg, path, px):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    cairosvg.svg2png(bytestring=svg.encode("utf-8"), write_to=path,
                     output_width=px, output_height=px)
    print("  %-58s %4d px  %6d B"
          % (os.path.relpath(path, ROOT), px, os.path.getsize(path)))


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    print("  %-58s %6d B" % (os.path.relpath(path, ROOT), os.path.getsize(path)))


def main():
    print("生成 Skyward 图标资源 ->", RES)
    for folder, launcher, fgsize in DPIS:
        d = os.path.join(RES, folder)
        render(ICON_SVG,  os.path.join(d, "ic_launcher.png"), launcher)
        render(ROUND_SVG, os.path.join(d, "ic_launcher_round.png"), launcher)
        render(FG_SVG,    os.path.join(d, "ic_launcher_foreground.png"), fgsize)
    render(ICON_SVG, os.path.join(RES, "drawable-nodpi", "ic_logo.png"), 256)
    v26 = os.path.join(RES, "mipmap-anydpi-v26")
    write(os.path.join(v26, "ic_launcher.xml"), ADAPTIVE)
    write(os.path.join(v26, "ic_launcher_round.xml"), ADAPTIVE)
    write(os.path.join(RES, "values", "colors.xml"),
          '<?xml version="1.0" encoding="utf-8"?>\n'
          '<resources>\n'
          '    <color name="ic_launcher_background">%s</color>\n'
          '</resources>\n' % BG)
    print("完成：背景 %s / 前景纯白 / minSdk 26 -> adaptive icon 为主显示路径。" % BG)


if __name__ == "__main__":
    main()
