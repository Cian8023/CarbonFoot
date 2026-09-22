import { BehaviorRecord } from '../model/Models';
import { ChartPoint, PieItem } from '../components/Chart';
import { DateUtil } from '../utils/DateUtil';
import { Theme } from '../common/Theme';
import { Constants } from '../common/Constants';

export type TrendKind = 'day7' | 'week8' | 'month12' | 'year5';

/**
 * 看板统计：趋势折线、分类占比、子类型对比。
 */
export class StatsService {
  static kindLabel(kind: TrendKind): string {
    if (kind === 'day7') {
      return '近7天';
    } else if (kind === 'week8') {
      return '近8周';
    } else if (kind === 'month12') {
      return '近12月';
    }
    return '近5年';
  }

  static rangeStart(kind: TrendKind): number {
    const now = Date.now();
    if (kind === 'day7') {
      return DateUtil.startOfDay(now) - 6 * DateUtil.DAY_MS;
    } else if (kind === 'week8') {
      return DateUtil.startOfWeek(now) - 7 * DateUtil.DAY_MS * 7;
    } else if (kind === 'month12') {
      return DateUtil.startOfMonth(now - 11 * 31 * DateUtil.DAY_MS);
    }
    return DateUtil.startOfYear(now - 4 * 365 * DateUtil.DAY_MS);
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
      labelFn = DateUtil.formatMD;
    } else if (kind === 'week8') {
      n = 8;
      stepMs = 7 * DateUtil.DAY_MS;
      bucketStart = DateUtil.startOfWeek;
      labelFn = DateUtil.formatMD;
    } else if (kind === 'month12') {
      n = 12;
      stepMs = 30 * DateUtil.DAY_MS;
      bucketStart = DateUtil.startOfMonth;
      labelFn = (ts: number): string => DateUtil.formatYM(ts).substring(5) + '月';
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
      cur -= stepMs;
      if (kind === 'month12') {
        cur = DateUtil.startOfMonth(cur);
      } else if (kind === 'year5') {
        cur = DateUtil.startOfYear(cur);
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
      sum += v;
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
