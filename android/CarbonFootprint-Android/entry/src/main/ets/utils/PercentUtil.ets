/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
/**
 * 百分比取整（最大余数法）。
 *
 * 逐项 toFixed(0) 会让合计出现 99% 或 101%——例如 51.1% / 39.5% / 9.4%
 * 各自四舍五入得 51 / 40 / 9 是对的，但 51.1 / 39.4 / 9.5 会得 51 / 39 / 10，
 * 视觉上总和可能差 1 个点，被评审当成算错。
 *
 * 做法：先向下取整，再把 100 与取整和的差额按小数部分从大到小逐项补 1，
 * 保证整数标签之和恒等于 100。
 * 大于 0 但不足 1% 的项标记为 small，由调用方显示「<1%」，不参与整数份额分配。
 */
export interface PctShare {
  /** 整数百分比 */
  num: number;
  /** 原值 >0 但不足 1%，应显示「<1%」 */
  small: boolean;
}

export class PercentUtil {
  static split(values: number[]): PctShare[] {
    const n = values.length;
    let sum = 0;
    for (const v of values) {
      sum += v;
    }
    const nums: number[] = [];
    const fracs: number[] = [];
    const smalls: boolean[] = [];
    let assigned = 0;
    for (let i = 0; i < n; i++) {
      const raw = sum > 0 ? values[i] / sum * 100 : 0;
      const small = values[i] > 0 && raw < 1;
      const f = small ? 0 : Math.floor(raw);
      nums.push(f);
      // small 项的小数部分记为 -1，排序时永远排最后，不会被补 1
      fracs.push(small ? -1 : raw - f);
      smalls.push(small);
      assigned += f;
    }
    const rest = 100 - assigned;
    if (rest > 0) {
      const order: number[] = [];
      for (let i = 0; i < n; i++) {
        if (!smalls[i]) {
          order.push(i);
        }
      }
      order.sort((a: number, b: number) => fracs[b] - fracs[a]);
      for (let k = 0; k < rest && k < order.length; k++) {
        nums[order[k]] += 1;
      }
    }
    const out: PctShare[] = [];
    for (let i = 0; i < n; i++) {
      out.push({ num: nums[i], small: smalls[i] });
    }
    return out;
  }

  /** 直接产出标签文本：`51%` 或 `<1%` */
  static text(values: number[]): string[] {
    const shares = PercentUtil.split(values);
    const out: string[] = [];
    for (const s of shares) {
      out.push(s.small ? '<1%' : s.num + '%');
    }
    return out;
  }
}
