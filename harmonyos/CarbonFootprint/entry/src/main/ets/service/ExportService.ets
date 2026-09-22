import fs from '@ohos.file.fs';
import { AppInit } from '../common/AppInit';
import { DBHelper } from '../db/DBHelper';
import { BehaviorRepo, PointsRepo, TaskRepo, BadgeRepo } from '../db/Repository';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorRecord, PointsRecord } from '../model/Models';

interface BackupFile {
  version: string;
  exportedAt: number;
  behaviors: BehaviorRecord[];
  points: PointsRecord[];
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
      version: '1.0.0',
      exportedAt: Date.now(),
      behaviors: await BehaviorRepo.all(),
      points: await PointsRepo.listAll()
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

    const path = dir + '/carbon_report_' + DateUtil.formatYMD(Date.now()).replace(/-/g, '') + '.csv';
    const f = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    fs.writeSync(f.fd, csv);
    fs.closeSync(f.fd);
    return path;
  }

  /** 清空所有数据：删除行为、积分流水、任务完成记录，重置徽章与任务定义 */
  static async clearAll(): Promise<void> {
    const store = DBHelper.get();
    await store.executeSql('DELETE FROM t_behavior_record');
    await store.executeSql('DELETE FROM t_points_record');
    await store.executeSql('DELETE FROM t_task_completion');
    await BadgeRepo.resetUnlocked();
  }
}
