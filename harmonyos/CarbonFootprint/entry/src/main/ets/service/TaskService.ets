/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import { BehaviorRepo, TaskRepo, TaskCheckUtil } from '../db/Repository';
import { PointsService } from './PointsService';
import { bumpTick } from '../common/Constants';
import { DateUtil } from '../utils/DateUtil';
import { TaskDef, TaskProgress, TaskCheck, BehaviorRecord } from '../model/Models';

/**
 * 任务服务：基于行为记录自动判定完成情况，达标即自动发积分（周期内只发一次）。
 */
export class TaskService {
  /**
   * 删除行为记录后回退不达标任务（须在删除事务内调用，积分走 addPointsTx）：
   * 仅处理判定子类型包含该记录子类型的任务；删除后重新核算进度，
   * 周期内已有完成记录但进度不再达标时，撤销完成记录并写负向积分流水。
   */
  static async revokeUnmetTasks(rec: BehaviorRecord): Promise<void> {
    const defs: TaskDef[] = await TaskRepo.list();
    const now = Date.now();
    for (const t of defs) {
      if (!t.enabled) {
        continue;
      }
      const check = TaskCheckUtil.parse(t.checkJson);
      if (check.subTypes.indexOf(rec.subType) < 0) {
        continue;
      }
      if (check.matchType === 'sum' && check.unit !== rec.unit) {
        continue;
      }
      const start = TaskService.periodStart(t.period);
      const done = await TaskRepo.completionsBetween(t.id, start, now);
      if (done === 0) {
        continue;
      }
      const progress = await TaskService.progressFor(check, start, now);
      if (progress < check.target) {
        await TaskRepo.deleteCompletionsBetween(t.id, start, now);
        await PointsService.addPointsTx('task', t.id,
          `任务回退：${t.title}（删除行为后不再达标）`, -t.points);
      }
    }
  }

  /** 本周完成的任务次数（跨全部任务，含周任务与日任务） */
  static async weekCompletedCount(): Promise<number> {
    const start = TaskService.periodStart('weekly');
    return await TaskRepo.countCompletionsBetween(start, Date.now());
  }

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
