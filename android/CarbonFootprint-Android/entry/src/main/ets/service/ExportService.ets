import fs from '@ohos.file.fs';
import util from '@ohos.util';
import preferences from '@ohos.data.preferences';
import picker from '@ohos.file.picker';
import { bumpTick } from '../common/Constants';
import { AppInit } from '../common/AppInit';
import { DBHelper } from '../db/DBHelper';
import { BehaviorRepo, PointsRepo, TaskRepo, BadgeRepo } from '../db/Repository';
import { PrefsService } from '../common/PrefsService';
import { CardSnapshot } from '../common/CardSnapshot';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorRecord, PointsRecord, TaskCompletionRecord, BadgeUnlockRecord, behaviorSourceLabel } from '../model/Models';

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
  /**
   * 把内容写到用户通过文件选择器指定的位置。
   *
   * 早期版本直接写应用沙箱（files/backup、files/export），路径虽复制到剪贴板，
   * 但普通用户进不了沙箱，导入时文件选择器里也看不到这些文件——备份等于白做。
   * 改为先落沙箱缓存，再让用户选保存位置，用户取消时抛错由页面提示。
   */
  private static async saveAs(fileName: string, content: string): Promise<string> {
    const ctx = AppInit.getContext();
    const cacheDir = ctx.cacheDir + '/export_tmp';
    if (!fs.accessSync(cacheDir)) {
      fs.mkdirSync(cacheDir, true);
    }
    const tmpPath = cacheDir + '/' + fileName;
    const f = fs.openSync(tmpPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    fs.writeSync(f.fd, content);
    fs.closeSync(f.fd);

    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];
    const viewPicker = new picker.DocumentViewPicker(ctx);
    const uris = await viewPicker.save(options);
    if (uris === undefined || uris.length === 0) {
      throw new Error('未选择保存位置');
    }
    // 目标文件由选择器创建，直接整段写入
    const dest = fs.openSync(uris[0], fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
    fs.writeSync(dest.fd, content);
    fs.closeSync(dest.fd);
    return uris[0];
  }

  /** 一键备份：内容由用户选择保存位置（通常为「文件管理」目录） */
  static async backupJson(): Promise<string> {
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
    const fileName = 'carbon_backup_' + DateUtil.formatYMD(Date.now()).replace(/-/g, '') +
      '_' + DateUtil.formatHM(Date.now()).replace(/:/g, '') + '.json';
    return await ExportService.saveAs(fileName, JSON.stringify(data, null, 2));
  }

  /** 导出月度减排汇总 CSV：内容由用户选择保存位置 */
  static async exportCsv(): Promise<string> {
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

    // 第三段：数据来源分布（碳核算语境下，数据可追溯比总量更重要）
    const srcMap = new Map<string, MonthStat>();
    let totalG = 0;
    for (const r of records) {
      totalG += r.reductionG;
      const key = (r.source === undefined || r.source === null || r.source === '') ? 'manual' : r.source;
      let st = srcMap.get(key);
      if (st === undefined) {
        st = { count: 0, grams: 0, points: 0 };
        srcMap.set(key, st);
      }
      st.count += 1;
      st.grams += r.reductionG;
    }
    const srcOrder: string[] = ['manual', 'ai_ticket', 'ai_scene', 'platform'];
    csv += '\n数据来源,记录数,减排量(g),占比\n';
    for (const s of srcOrder) {
      const st = srcMap.get(s);
      if (st === undefined) {
        continue;
      }
      const pct = totalG > 0 ? Math.round(st.grams * 100 / totalG) : 0;
      csv += `${behaviorSourceLabel(s)},${st.count},${st.grams},${pct}%\n`;
    }

    const fileName = 'carbon_report_' + DateUtil.formatYMD(Date.now()).replace(/-/g, '') + '.csv';
    return await ExportService.saveAs(fileName, csv);
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
    // 桌面卡片快照也是派生数据，不清会在下次打开前继续显示旧的减排数字
    try {
      const store = await preferences.getPreferences(AppInit.getContext(), CardSnapshot.STORE);
      await store.put(CardSnapshot.KEY, '');
      await store.flush();
    } catch (e) {
      // 快照清理失败不阻断主流程
    }
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
