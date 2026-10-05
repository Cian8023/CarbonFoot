import fs from '@ohos.file.fs';
import util from '@ohos.util';
import preferences from '@ohos.data.preferences';
import { bumpTick } from '../common/Constants';
import { AppInit } from '../common/AppInit';
import { DBHelper } from '../db/DBHelper';
import { BehaviorRepo, PointsRepo, TaskRepo, BadgeRepo } from '../db/Repository';
import { PrefsService } from '../common/PrefsService';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorRecord, PointsRecord, TaskCompletionRecord, BadgeUnlockRecord } from '../model/Models';

interface BackupFile {
  version: string;
  exportedAt: number;
  behaviors: BehaviorRecord[];
  points: PointsRecord[];
  completions?: TaskCompletionRecord[];
  badges?: BadgeUnlockRecord[];
}

interface MonthStat {
  count: number;
  grams: number;
  points: number;
}

/**
 * 本地数据管理：JSON 备份 / CSV 月度报表导出（应用沙箱目录）/ 清空数据。
 */
export class ExportService {
  private static ensureDir(dir: string): void {
    if (!fs.accessSync(dir)) {
      fs.mkdirSync(dir, true);
    }
  }

  /** 一键备份到 files/backup/，返回文件路径 */
  static async backupJson(): Promise<string> {
    const ctx = AppInit.getContext();
    const dir = ctx.filesDir + '/backup';
    ExportService.ensureDir(dir);
    const data: BackupFile = {
      version: '1.1.0',
      exportedAt: Date.now(),
      behaviors: await BehaviorRepo.all(),
      points: await PointsRepo.listAll(),
      completions: await TaskRepo.listAllCompletions(),
      badges: (await BadgeRepo.list())
        .filter((b) => b.unlocked)
        .map((b): BadgeUnlockRecord => ({ code: b.code, unlockedAt: b.unlockedAt }))
    };
    const path = dir + '/carbon_backup_' + DateUtil.formatYMD(Date.now()).replace(/-/g, '') +
      '_' + DateUtil.formatHM(Date.now()).replace(/:/g, '') + '.json';
    const f = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    fs.writeSync(f.fd, JSON.stringify(data, null, 2));
    fs.closeSync(f.fd);
    return path;
  }

  /** 导出月度减排汇总 CSV 到 files/export/，返回文件路径 */
  static async exportCsv(): Promise<string> {
    const ctx = AppInit.getContext();
    const dir = ctx.filesDir + '/export';
    ExportService.ensureDir(dir);
    const records = await BehaviorRepo.all();
    const points = await PointsRepo.listAll();

    const monthly = new Map<string, MonthStat>();
    for (const r of records) {
      const key = DateUtil.formatYM(r.createdAt);
      let stat = monthly.get(key);
      if (stat === undefined) {
        stat = { count: 0, grams: 0, points: 0 };
        monthly.set(key, stat);
      }
      stat.count += 1;
      stat.grams += r.reductionG;
    }
    for (const p of points) {
      if (p.source === 'behavior') {
        const key = DateUtil.formatYM(p.createdAt);
        let stat = monthly.get(key);
        if (stat === undefined) {
          stat = { count: 0, grams: 0, points: 0 };
          monthly.set(key, stat);
        }
        stat.points += p.points;
      }
    }

    const keys: string[] = [];
    monthly.forEach((_v: MonthStat, k: string) => {
      keys.push(k);
    });
    keys.sort();

    let csv = '\uFEFF月份,行为记录数,减排量(g),减排量(kg),行为积分合计\n';
    for (const k of keys) {
      const stat = monthly.get(k);
      if (stat === undefined) {
        continue;
      }
      csv += `${k},${stat.count},${stat.grams},${(stat.grams / 1000).toFixed(2)},${stat.points}\n`;
    }

    // 第二段：分类月度汇总
    const catMonthly = new Map<string, number>();
    for (const r of records) {
      if (r.reductionG <= 0) {
        continue;
      }
      const key = DateUtil.formatYM(r.createdAt) + '|' + r.type;
      const prev = catMonthly.get(key);
      catMonthly.set(key, (prev !== undefined ? prev : 0) + r.reductionG);
    }
    const catKeys: string[] = [];
    catMonthly.forEach((_v: number, k: string) => {
      catKeys.push(k);
    });
    catKeys.sort();
    csv += '\n月份,大类,减排量(g),减排量(kg)\n';
    for (const ck of catKeys) {
      const grams = catMonthly.get(ck) !== undefined ? catMonthly.get(ck) as number : 0;
      const parts = ck.split('|');
      csv += `${parts[0]},${parts[1]},${grams},${(grams / 1000).toFixed(2)}\n`;
    }

    const path = dir + '/carbon_report_' + DateUtil.formatYMD(Date.now()).replace(/-/g, '') + '.csv';
    const f = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    fs.writeSync(f.fd, csv);
    fs.closeSync(f.fd);
    return path;
  }

  /** 清空所有数据：行为、积分流水、任务完成记录，重置徽章、植树证书与碳普惠权益记录 */
  static async clearAll(): Promise<void> {
    const store = DBHelper.get();
    await store.executeSql('DELETE FROM t_behavior_record');
    await store.executeSql('DELETE FROM t_points_record');
    await store.executeSql('DELETE FROM t_task_completion');
    await BadgeRepo.resetUnlocked();
    // 证书兑换状态与权益记录同属账务衍生数据，随清空一并重置保持口径一致
    await PrefsService.setCertDate(0);
    try {
      const ctx = AppInit.getContext();
      const pref = await preferences.getPreferences(ctx, 'entitlements');
      await pref.clear();
    } catch (e) {
      // 权益记录清理失败不阻断主流程
    }
  }

  /**
   * 从备份 JSON 恢复：覆盖当前全部行为记录、积分流水、任务完成记录与徽章解锁状态
   * （原 id 原样恢复，保证积分流水的 ref_id 引用不断链；旧版备份缺省字段时跳过对应段）。
   * 返回恢复的行为记录条数。
   */
  static async importJson(path: string): Promise<number> {
    const stat = fs.statSync(path);
    const f = fs.openSync(path, fs.OpenMode.READ_ONLY);
    const buf = new ArrayBuffer(stat.size);
    fs.readSync(f.fd, buf);
    fs.closeSync(f.fd);
    const text = util.TextDecoder.create('utf-8').decodeToString(new Uint8Array(buf));
    const data = JSON.parse(text) as BackupFile;
    if (data.behaviors === undefined || data.points === undefined ||
      !Array.isArray(data.behaviors) || !Array.isArray(data.points)) {
      throw new Error('备份文件格式不正确');
    }
    const store = DBHelper.get();
    DBHelper.beginTx();
    try {
      await store.executeSql('DELETE FROM t_behavior_record');
      await store.executeSql('DELETE FROM t_points_record');
      await store.executeSql('DELETE FROM t_task_completion');
      for (const r of data.behaviors) {
        BehaviorRepo.insertWithIdSync(r);
      }
      for (const p of data.points) {
        PointsRepo.insertWithIdSync(p);
      }
      if (data.completions !== undefined) {
        for (const c of data.completions) {
          await TaskRepo.insertCompletion(c.taskId, c.completedAt);
        }
      }
      await BadgeRepo.resetUnlocked();
      if (data.badges !== undefined) {
        const badges = await BadgeRepo.list();
        for (const b of badges) {
          for (const ub of data.badges) {
            if (ub.code === b.code && ub.unlockedAt > 0) {
              await BadgeRepo.setUnlocked(b.id, ub.unlockedAt);
            }
          }
        }
      }
      DBHelper.commitTx();
    } catch (err) {
      DBHelper.rollbackTx();
      throw err as Error;
    }
    bumpTick();
    return data.behaviors.length;
  }
}
