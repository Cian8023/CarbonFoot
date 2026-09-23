/**
 * 设计令牌 v3.0 - 现代简约风格
 * 参考 Arco Design 视觉规范
 */
export class Theme {
  // === 品牌色系（科技绿） ===
  static readonly PRIMARY: string = '#00B96B';
  static readonly PRIMARY_HOVER: string = '#23C77C';
  static readonly PRIMARY_LIGHT: string = '#AFF0D4';
  static readonly PRIMARY_BG: string = '#E8FFEA';
  
  // === 功能色 ===
  static readonly SUCCESS: string = '#00B96B';
  static readonly WARNING: string = '#FF7D00';
  static readonly ERROR: string = '#F53F3F';
  static readonly INFO: string = '#3491FA';
  static readonly POINTS: string = '#F7BA1E';
  
  // === 中性色 ===
  static readonly BG: string = '#F7F8FA';
  static readonly BG_GRAY: string = '#F2F3F5';
  static readonly CARD: string = '#FFFFFF';
  static readonly CARD_HOVER: string = '#FAFAFA';
  
  // === 文字色 ===
  static readonly TEXT: string = '#1D2129';
  static readonly TEXT_SECONDARY: string = '#4E5969';
  static readonly TEXT_TERTIARY: string = '#86909C';
  static readonly TEXT_DISABLED: string = '#C9CDD4';
  
  // === 边框与分割线 ===
  static readonly BORDER: string = '#E5E6EB';
  static readonly DIVIDER: string = '#E5E6EB';
  static readonly DIVIDER_LIGHT: string = '#F2F3F5';
  
  // === 圆角规范 ===
  static readonly R_LARGE: number = 20;
  static readonly R_MEDIUM: number = 16;
  static readonly R_SMALL: number = 12;
  static readonly R_MINI: number = 8;
  static readonly R_ROUND: number = 999;
  
  // === 间距规范 ===
  static readonly SPACE_MINI: number = 4;
  static readonly SPACE_SMALL: number = 8;
  static readonly SPACE_MEDIUM: number = 12;
  static readonly SPACE_LARGE: number = 16;
  static readonly SPACE_XLARGE: number = 20;
  static readonly SPACE_XXLARGE: number = 24;
  
  // === 阴影 ===
  static readonly SHADOW_CARD: string = '0 2px 8px 0 rgba(0, 0, 0, 0.08)';
  static readonly SHADOW_HOVER: string = '0 4px 16px 0 rgba(0, 0, 0, 0.12)';
  static readonly SHADOW_FLOAT: string = '0 8px 24px 0 rgba(0, 0, 0, 0.16)';
  
  // === 图表配色（柔和渐进） ===
  static readonly CHART_COLORS: string[] = [
    '#00B96B', '#14C9C9', '#3491FA', '#722ED1', 
    '#F7BA1E', '#FF7D00', '#F53F3F', '#F77234'
  ];
  
  // === 渐变色 ===
  static readonly GRADIENT_PRIMARY: string = 'linear-gradient(135deg, #00B96B 0%, #14C9C9 100%)';
  static readonly GRADIENT_SUCCESS: string = 'linear-gradient(135deg, #00B96B 0%, #7BE188 100%)';
  static readonly GRADIENT_WARM: string = 'linear-gradient(135deg, #F7BA1E 0%, #FF7D00 100%)';
  
  // === 背景渐变（柔和） ===
  static readonly BG_GRADIENT_GREEN: string = 'linear-gradient(135deg, #E8FFEA 0%, #F7F8FA 100%)';
  static readonly BG_GRADIENT_BLUE: string = 'linear-gradient(135deg, #E8F7FF 0%, #F7F8FA 100%)';
  
  // === 兼容旧令牌别名 ===
  static readonly REDUCE: string = '#00B96B';
  static readonly WARN: string = '#FF7D00';
}
