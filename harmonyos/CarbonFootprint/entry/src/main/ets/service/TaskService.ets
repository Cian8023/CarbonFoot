import { BehaviorRepo, TaskRepo, TaskCheckUtil } from '../db/Repository';
import { PointsService } from './PointsService';
import { BadgeService } from './BadgeService';
import { bumpTick } from '../common/Constants';
import { DateUtil } from '../utils/DateUtil';
import { TaskDef, TaskProgress, TaskCheck } from '../model/Models';

/**
 * 任务服务：基于行为记录自动判定完成情况，达标即自动发积分（周期内只发一次）。
 */
export class TaskService {
  static periodStart(period: string): number {
    const now = Date.now();
    return period === 'weekly' ? DateUtil.startOfWeek(now) : DateUtil.startOfDay(now);
  }

  static async progressFor(check: TaskCheck, startTs: number, endTs: number): Promise<number> {
    if (check.matchType === 'sum') {
      return await BehaviorRepo.sumBySubTypes(check.subTypes, startTs, endTs, check.unit);
    }
    return await BehaviorRepo.countBySubTypes(check.subTypes, startTs, endTs);
  }

  /** 刷新所有任务进度，达标的自动发积分，返回本轮新完成的任务标题 */
  static async evaluateAll(): Promise<string[]> {
    const defs: TaskDef[] = await TaskRepo.list();
    const awarded: string[] = [];
    const now = Date.now();
    for (const t of defs) {
      if (!t.enabled) {
        continue;
      }
      const start = TaskService.periodStart(t.period);
      const done = await TaskRepo.completionsBetween(t.id, start, now);
      if (done > 0) {
        continue;
      }
      const check = TaskCheckUtil.parse(t.checkJson);
      const progress = await TaskService.progressFor(check, start, now);
      if (progress >= check.target) {
        await TaskRepo.insertCompletion(t.id, now);
        await PointsService.addPoints('task', t.id, `完成任务：${t.title}`, t.points);
        awarded.push(t.title);
      }
    }
    if (awarded.length > 0) {
      await BadgeService.checkAll();
      bumpTick();
    }
    return awarded;
  }

  /** 任务列表（含进度与完成状态） */
  static async listProgress(): Promise<TaskProgress[]> {
    const defs: TaskDef[] = await TaskRepo.list();
    const now = Date.now();
    const list: TaskProgress[] = [];
    for (const t of defs) {
      const start = TaskService.periodStart(t.period);
      const done = (await TaskRepo.completionsBetween(t.id, start, now)) > 0;
      const check = TaskCheckUtil.parse(t.checkJson);
      const progress = done
        ? check.target
        : await TaskService.progressFor(check, start, now);
      const tp: TaskProgress = {
        task: t,
        progress: Math.min(progress, check.target),
        target: check.target,
        done: done
      };
      list.push(tp);
    }
    // 日任务在前，周任务在后；同周期内未完成的在前
    list.sort((a: TaskProgress, b: TaskProgress): number => {
      const pa = a.task.period === 'daily' ? 0 : 1;
      const pb = b.task.period === 'daily' ? 0 : 1;
      if (pa !== pb) {
        return pa - pb;
      }
      if (a.done !== b.done) {
        return a.done ? 1 : -1;
      }
      return a.task.id - b.task.id;
    });
    return list;
  }

  /** 待完成任务数（今日视角：日任务未完成数 + 周任务未完成数） */
  static async pendingCount(): Promise<number> {
    const list = await TaskService.listProgress();
    let n = 0;
    for (const p of list) {
      if (!p.done) {
        n++;
      }
    }
    return n;
  }
}
