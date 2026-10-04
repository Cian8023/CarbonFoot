import { BehaviorRepo, BadgeRepo, PointsRepo, TaskRepo } from '../db/Repository';
import { PointsService } from './PointsService';
import { DateUtil } from '../utils/DateUtil';
import { BadgeDef } from '../model/Models';

/** 单枚徽章的进度数据（cur 与条件同量纲，减排类为克） */
export interface BadgeProgressData {
  cur: number;
  target: number;
  /** 格式化进度文本，如 "3.2/10kg"、"4/7 天" */
  label: string;
  /** 0-100 */
  pct: number;
}

/**
 * 徽章服务：在行为录入、任务完成、文章阅读等动作后统一检测解锁条件。
 */
export class BadgeService {
  static async checkAll(): Promise<string[]> {
    const badges: BadgeDef[] = await BadgeRepo.list();
    const totalG = await BehaviorRepo.sumAllReduction();
    const recordCount = await BehaviorRepo.countAll();
    const streak = await BadgeService.currentStreak();
    const pointsTotal = await PointsService.totalEarned();
    const tasksDone = await TaskRepo.countCompletions();
    const articlesRead = await PointsService.countSource('read');

    const newly: string[] = [];
    const now = Date.now();
    for (const b of badges) {
      if (b.unlocked) {
        continue;
      }
      let ok = false;
      if (b.conditionType === 'reduction_total') {
        ok = totalG >= b.conditionValue;
      } else if (b.conditionType === 'record_count') {
        ok = recordCount >= b.conditionValue;
      } else if (b.conditionType === 'streak_days') {
        ok = streak >= b.conditionValue;
      } else if (b.conditionType === 'points_total') {
        ok = pointsTotal >= b.conditionValue;
      } else if (b.conditionType === 'tasks_done') {
        ok = tasksDone >= b.conditionValue;
      } else if (b.conditionType === 'articles_read') {
        ok = articlesRead >= b.conditionValue;
      }
      if (ok) {
        await BadgeRepo.setUnlocked(b.id, now);
        newly.push(b.name);
      }
    }
    return newly;
  }

  static async list(): Promise<BadgeDef[]> {
    return await BadgeRepo.list();
  }

  /** 批量计算徽章进度（与入参顺序一一对应），聚合值只查一次 */
  static async progressList(badges: BadgeDef[]): Promise<BadgeProgressData[]> {
    const totalG = await BehaviorRepo.sumAllReduction();
    const recordCount = await BehaviorRepo.countAll();
    const streak = await BadgeService.currentStreak();
    const pointsTotal = await PointsService.totalEarned();
    const tasksDone = await TaskRepo.countCompletions();
    const articlesRead = await PointsService.countSource('read');
    const list: BadgeProgressData[] = [];
    for (const b of badges) {
      let cur = 0;
      let label = '';
      if (b.conditionType === 'reduction_total') {
        cur = totalG;
        label = DateUtil.gramsToKg(cur) + '/' + DateUtil.gramsToKg(b.conditionValue) + 'kg';
      } else if (b.conditionType === 'record_count') {
        cur = recordCount;
        label = cur + '/' + b.conditionValue + ' 笔';
      } else if (b.conditionType === 'streak_days') {
        cur = streak;
        label = cur + '/' + b.conditionValue + ' 天';
      } else if (b.conditionType === 'points_total') {
        cur = pointsTotal;
        label = cur + '/' + b.conditionValue + ' 分';
      } else if (b.conditionType === 'tasks_done') {
        cur = tasksDone;
        label = cur + '/' + b.conditionValue + ' 次';
      } else if (b.conditionType === 'articles_read') {
        cur = articlesRead;
        label = cur + '/' + b.conditionValue + ' 篇';
      }
      const pct = b.conditionValue > 0 ? Math.min(100, Math.round(cur / b.conditionValue * 100)) : 0;
      const d: BadgeProgressData = {
        cur: cur,
        target: b.conditionValue,
        label: label,
        pct: pct
      };
      list.push(d);
    }
    return list;
  }

  static async countUnlocked(): Promise<number> {
    return await BadgeRepo.countUnlocked();
  }

  /** 连续打卡天数：含今天或昨天起向前连续有行为记录的天数 */
  static async currentStreak(): Promise<number> {
    const days = await BehaviorRepo.distinctDays();
    if (days.length === 0) {
      return 0;
    }
    const today = DateUtil.startOfDay(Date.now());
    const first = days[0];
    if (first !== today && first !== today - DateUtil.DAY_MS) {
      return 0;
    }
    let streak = 1;
    let expected = first;
    for (let i = 1; i < days.length; i++) {
      if (days[i] === expected - DateUtil.DAY_MS) {
        streak++;
        expected = days[i];
      } else {
        break;
      }
    }
    return streak;
  }
}
