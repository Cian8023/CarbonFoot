import { BehaviorRecord } from '../model/Models';
import { ChartPoint, PieItem } from '../components/Chart';
import { DateUtil } from '../utils/DateUtil';
import { PercentUtil } from '../utils/PercentUtil';
import { Theme } from '../common/Theme';
import { Constants } from '../common/Constants';

export type TrendKind = 'day7' | 'week8' | 'month12' | 'year5';

/** 减排周报数据 */
export interface WeeklyReport {
  /** 本周减排（克） */
  weekG: number;
  /** 上周减排（克） */
  lastWeekG: number;
  /** 环比百分比；上周无数据时为 -999 */
  deltaPct: number;
  /** 本周最强子类型 */
  topSub: string;
  topSubG: number;
  /** 本周有记录的天数 */
  days: number;
  slogan: string;
}

/**
 * 看板统计：趋势折线、分类占比、子类型对比。
 */
export class StatsService {
  /** 本月（自然月至今）累计减排（克） */
  static monthSum(records: BehaviorRecord[]): number {
    const start = DateUtil.startOfMonth(Date.now());
    let sum = 0;
    for (const r of records) {
      if (r.createdAt >= start) {
        sum += r.reductionG;
      }
    }
    return sum;
  }

  /** 减排周报：本周/上周对比、最强子类型、打卡天数 */
  static weekReport(records: BehaviorRecord[]): WeeklyReport {
    const now = Date.now();
    const weekStart = DateUtil.startOfWeek(now);
    const lastStart = weekStart - 7 * DateUtil.DAY_MS;
    let weekG = 0;
    let lastG = 0;
    const days = new Set<number>();
    const subs = new Map<string, number>();
    for (const r of records) {
      if (r.createdAt >= weekStart) {
        weekG += r.reductionG;
        days.add(DateUtil.startOfDay(r.createdAt));
        if (r.reductionG > 0) {
          const prev = subs.get(r.subType);
          subs.set(r.subType, (prev !== undefined ? prev : 0) + r.reductionG);
        }
      } else if (r.createdAt >= lastStart) {
        lastG += r.reductionG;
      }
    }
    let topSub = '';
    let topSubG = 0;
    subs.forEach((v: number, k: string) => {
      if (v > topSubG) {
        topSubG = v;
        topSub = k;
      }
    });
    let deltaPct = -999;
    if (lastG > 0) {
      deltaPct = Math.round((weekG - lastG) / lastG * 100);
    }
    let slogan = '本周还没有记录，从一件小事开始吧';
    if (weekG > 0) {
      if (lastG === 0) {
        slogan = '本周已开启减排，保持节奏！';
      } else if (deltaPct >= 0) {
        slogan = `比上周多减 ${deltaPct}%，继续保持！`;
      } else {
        slogan = `比上周少了 ${-deltaPct}%，动起来追上去！`;
      }
    }
    const rep: WeeklyReport = {
      weekG: weekG,
      lastWeekG: lastG,
      deltaPct: deltaPct,
      topSub: topSub,
      topSubG: topSubG,
      days: days.size,
      slogan: slogan
    };
    return rep;
  }

  static kindLabel(kind: TrendKind): string {
    if (kind === 'day7') {
      return '近7天';
    } else if (kind === 'week8') {
      return '近4周';
    } else if (kind === 'month12') {
      return '近6月';
    }
    return '近5年';
  }

  static shortLabel(kind: TrendKind): string {
    if (kind === 'day7') {
      return '日';
    } else if (kind === 'week8') {
      return '周';
    } else if (kind === 'month12') {
      return '月';
    }
    return '年';
  }

  /** 趋势档位短标签（日/周/月/年），用于首页切换 chip */
  static rangeStart(kind: TrendKind): number {
    const now = Date.now();
    if (kind === 'day7') {
      return DateUtil.startOfDay(now) - 6 * DateUtil.DAY_MS;
    } else if (kind === 'week8') {
      return DateUtil.startOfWeek(now) - 3 * DateUtil.DAY_MS * 7;
    } else if (kind === 'month12') {
      const d = new Date(DateUtil.startOfMonth(now));
      d.setMonth(d.getMonth() - 5);
      return d.getTime();
    }
    const dy = new Date(DateUtil.startOfYear(now));
    dy.setFullYear(dy.getFullYear() - 4);
    return dy.getTime();
  }

  static trend(records: BehaviorRecord[], kind: TrendKind): ChartPoint[] {
    const now = Date.now();
    const buckets = new Map<number, number>();
    const labels = new Map<number, string>();
    let n = 0;
    let stepMs = 0;
    let bucketStart: (ts: number) => number = DateUtil.startOfDay;
    let labelFn: (ts: number) => string = DateUtil.formatMD;

    if (kind === 'day7') {
      n = 7;
      stepMs = DateUtil.DAY_MS;
      bucketStart = DateUtil.startOfDay;
      labelFn = (ts: number): string => {
        const d = new Date(ts);
        return (d.getMonth() + 1) + '.' + d.getDate();
      };
    } else if (kind === 'week8') {
      n = 4;
      stepMs = 7 * DateUtil.DAY_MS;
      bucketStart = DateUtil.startOfWeek;
      labelFn = (ts: number): string => {
        // 纯数字区间：M.D-M.D，跨月/跨年都各自带上自己的月份
        const endTs = ts + 6 * DateUtil.DAY_MS;
        const sd = new Date(ts);
        const ed = new Date(endTs);
        return (sd.getMonth() + 1) + '.' + sd.getDate() + '-' + (ed.getMonth() + 1) + '.' + ed.getDate();
      };
    } else if (kind === 'month12') {
      n = 6;
      stepMs = 30 * DateUtil.DAY_MS;
      bucketStart = DateUtil.startOfMonth;
      labelFn = (ts: number): string => {
        const d = new Date(ts);
        return d.getFullYear() + '.' + (d.getMonth() + 1);
      };
    } else {
      n = 5;
      stepMs = 365 * DateUtil.DAY_MS;
      bucketStart = DateUtil.startOfYear;
      labelFn = (ts: number): string => '' + new Date(ts).getFullYear();
    }

    // 生成从旧到新的桶
    const starts: number[] = [];
    let cur = bucketStart(now);
    for (let i = 0; i < n; i++) {
      starts.push(cur);
      if (kind === 'month12') {
        const d = new Date(cur);
        d.setDate(0);
        cur = DateUtil.startOfMonth(d.getTime());
      } else if (kind === 'year5') {
        const d = new Date(cur);
        d.setFullYear(d.getFullYear() - 1);
        cur = DateUtil.startOfYear(d.getTime());
      } else {
        cur -= stepMs;
      }
    }
    starts.reverse();
    for (const s of starts) {
      buckets.set(s, 0);
      labels.set(s, labelFn(s));
    }

    const rangeStart = starts[0];
    for (const r of records) {
      if (r.createdAt < rangeStart) {
        continue;
      }
      const key = bucketStart(r.createdAt);
      const prev = buckets.get(key);
      if (prev !== undefined) {
        buckets.set(key, prev + r.reductionG);
      }
    }

    const points: ChartPoint[] = [];
    for (const s of starts) {
      const p: ChartPoint = { label: labels.get(s) !== undefined ? labels.get(s) as string : '', value: buckets.get(s) !== undefined ? buckets.get(s) as number : 0 };
      points.push(p);
    }
    return points;
  }

  static categoryShare(records: BehaviorRecord[], startTs: number): PieItem[] {
    const totals = new Map<string, number>();
    let sum = 0;
    for (const r of records) {
      if (r.createdAt < startTs || r.reductionG <= 0) {
        continue;
      }
      const prev = totals.get(r.type);
      const v = (prev !== undefined ? prev : 0) + r.reductionG;
      totals.set(r.type, v);
      sum += r.reductionG;
    }
    const items: PieItem[] = [];
    let idx = 0;
    totals.forEach((v: number, k: string) => {
      const item: PieItem = {
        name: k,
        value: v,
        color: Constants.categoryColor(k),
        pct: sum > 0 ? (v / sum * 100) : 0
      };
      items.push(item);
      idx++;
    });
    items.sort((a: PieItem, b: PieItem) => b.value - a.value);
    // 排序后统一算整数标签：逐项 toFixed(0) 会让图例合计变成 99%/101%
    const vals: number[] = [];
    for (const it of items) {
      vals.push(it.value);
    }
    const labels = PercentUtil.text(vals);
    for (let i = 0; i < items.length; i++) {
      items[i].pctText = labels[i];
    }
    return items;
  }

  static subShare(records: BehaviorRecord[], startTs: number): PieItem[] {
    const totals = new Map<string, number>();
    for (const r of records) {
      if (r.createdAt < startTs || r.reductionG <= 0) {
        continue;
      }
      const prev = totals.get(r.subType);
      totals.set(r.subType, (prev !== undefined ? prev : 0) + r.reductionG);
    }
    const items: PieItem[] = [];
    totals.forEach((v: number, k: string) => {
      const item: PieItem = {
        name: k,
        value: v,
        color: Theme.PRIMARY,
        pct: 0
      };
      items.push(item);
    });
    items.sort((a: PieItem, b: PieItem) => b.value - a.value);
    const top: PieItem[] = [];
    for (let i = 0; i < items.length && i < 8; i++) {
      top.push(items[i]);
    }
    return top;
  }
}
