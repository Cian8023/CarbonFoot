/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
/**
 * 设计令牌 v4.1 - 账本质感
 *
 * 暖米白纸底、深松绿主色、赭黄强调。卡片用 1px 细边框而不是阴影，
 * 圆角按用途分化（数据卡小圆角、按钮药丸形），刻意不做成统一样式。
 * 避开两类容易显得廉价的东西：一是高饱和草绿配蓝紫渐变，
 * 二是清一色的大圆角加半透明黑阴影。
 *
 * 维护约定：只保留被引用或作为规范基数使用的令牌，
 * 新增样式前先查是否已有语义化令牌可用，不要再写裸数字。
 */
export class Theme {
  // === 品牌色系（深松绿，低饱和） ===
  static readonly PRIMARY: string = '#2F6B4F';
  static readonly PRIMARY_HOVER: string = '#3E8763';
  static readonly PRIMARY_LIGHT: string = '#C8DDD0';
  static readonly PRIMARY_BG: string = '#EDF2ED';

  /** 积分/达成态：赭黄（目标达成、徽章点亮） */
  static readonly POINTS: string = '#B8862F';
  /** 警示色：降饱和的赭红（ Toast、负向流水） */
  static readonly WARN: string = '#C2410C';

  // === 中性色（暖米白纸底） ===
  /** 页面底色 */
  static readonly BG: string = '#FAF8F3';
  /** 次级底：输入框、chip、进度轨道 */
  static readonly BG_GRAY: string = '#F0EDE4';
  /** 卡片底 */
  static readonly CARD: string = '#FFFFFF';
  /** 卡片描边：替代阴影做层级，与米白底同色温 */
  static readonly CARD_BORDER: string = '#E5E0D4';

  // === 文字色（暖黑） ===
  static readonly TEXT: string = '#33312B';
  static readonly TEXT_SECONDARY: string = '#6E6A5E';
  static readonly TEXT_TERTIARY: string = '#847F72';

  // === 分割线 ===
  static readonly DIVIDER: string = '#E5E0D4';
  static readonly DIVIDER_LIGHT: string = '#EFEBE1';

  // === 圆角规范 ===
  /** 数据卡 */
  static readonly R_LARGE: number = 12;
  /** 次级容器（chip、内嵌块） */
  static readonly R_SMALL: number = 8;
  /** 药丸形按钮 */
  static readonly R_ROUND: number = 999;

  // === 间距规范 ===
  static readonly SPACE_MINI: number = 4;
  static readonly SPACE_SMALL: number = 8;
  static readonly SPACE_MEDIUM: number = 12;
  static readonly SPACE_LARGE: number = 16;
  static readonly SPACE_XLARGE: number = 20;

  // === 字号规范（fp）===
  // 语义化阶梯，正文整体升一档提高可读性。
  // FS_MICRO 用于角标/徽章计数，FS_CAPTION 用于输入框，
  // FS_BODY 是正文基准，FS_TITLE 是卡片标题，FS_HEAD 是页面标题，
  // FS_DISPLAY 及以上用于首页大数字与年度报告。
  static readonly FS_MICRO: number = 10;
  static readonly FS_CAPTION: number = 11;
  static readonly FS_SECONDARY: number = 12;
  static readonly FS_TERTIARY: number = 13;
  static readonly FS_BODY: number = 14;
  /** 正文主体 */
  static readonly FS_CONTENT: number = 15;
  /** 卡片标题 */
  static readonly FS_TITLE: number = 16;
  /** 页面标题 */
  static readonly FS_HEAD: number = 19;
  /** 首页核心大数字 */
  static readonly FS_HERO: number = 22;
  /** 年度报告特大数字 */
  static readonly FS_DISPLAY: number = 30;

  // === 兼容旧令牌别名 ===
  /** 减排量语义色（旧命名，历史页面仍在用，等同 PRIMARY） */
  static readonly REDUCE: string = '#2F6B4F';

  // === 图表配色（自然色系 8 色，去蓝紫与荧光色） ===
  static readonly CHART_COLORS: string[] = [
    '#2F6B4F', '#B8862F', '#5B7C99', '#A8562F',
    '#7A8B5A', '#4A4A42', '#8C5A3C', '#9A8A6B'
  ];
}
