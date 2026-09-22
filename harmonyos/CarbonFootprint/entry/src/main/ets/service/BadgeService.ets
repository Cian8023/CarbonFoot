import { BehaviorRepo, BadgeRepo, PointsRepo, TaskRepo } from '../db/Repository';
import { PointsService } from './PointsService';
import { DateUtil } from '../utils/DateUtil';
import { BadgeDef } from '../model/Models';

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
