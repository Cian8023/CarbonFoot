/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
/**
 * 减排量的具象换算。
 *
 * 克这个单位对人没有体感，首页把当日减排折成"少开多少公里车 / 省几度电"，
 * 累计减排折成"种了几棵树"，让数字有参照系。
 *
 * 换算基准与因子库保持一致：私家车 180 g/km、用电 785 g/kWh；
 * 树木固碳按常见口径 12 kg/年（单株乔木年均固碳量，取中位值）。
 */
export class EcoUtil {
  /** 单株乔木年均固碳量（克） */
  static readonly TREE_G_PER_YEAR: number = 12000;
  /** 私家车每公里排放（克），与因子库出行基线一致 */
  static readonly CAR_G_PER_KM: number = 180;
  /** 每度电排放（克），与因子库节电因子一致 */
  static readonly POWER_G_PER_KWH: number = 785;

  private static fmt(n: number): string {
    if (n >= 100) {
      return '' + Math.round(n);
    }
    if (n >= 10) {
      return n.toFixed(0);
    }
    return n.toFixed(1);
  }

  /**
   * 当日量级换算：优先用"公里车"，不足半公里时改用"度电"。
   * 返回空串表示无有效减排，调用方据此决定是否显示。
   */
  static dailyText(g: number): string {
    if (!isFinite(g) || g <= 0) {
      return '';
    }
    const km = g / EcoUtil.CAR_G_PER_KM;
    if (km >= 0.5) {
      return `≈ 少开 ${EcoUtil.fmt(km)} 公里车`;
    }
    const kwh = g / EcoUtil.POWER_G_PER_KWH;
    if (kwh >= 0.1) {
      return `≈ 省下 ${EcoUtil.fmt(kwh)} 度电`;
    }
    return `≈ 少开 ${EcoUtil.fmt(km)} 公里车`;
  }

  /** 累计量级换算：不足 0.1 棵树时退回公里表达，避免出现"0.0 棵树" */
  static totalText(g: number): string {
    if (!isFinite(g) || g <= 0) {
      return '';
    }
    const trees = g / EcoUtil.TREE_G_PER_YEAR;
    if (trees < 0.1) {
      return `≈ 少开 ${EcoUtil.fmt(g / EcoUtil.CAR_G_PER_KM)} 公里车`;
    }
    return `≈ 种下 ${EcoUtil.fmt(trees)} 棵树`;
  }
}
