import { DBHelper } from '../db/DBHelper';
import { BehaviorRepo } from '../db/Repository';
import { PointsService } from './PointsService';
import { BadgeService } from './BadgeService';
import { TaskService } from './TaskService';
import { CalculationService } from './CalculationService';
import { bumpTick } from '../common/Constants';
import { SyncService } from './SyncService';
import { BehaviorRecord, SubmitResult } from '../model/Models';

/**
 * 行为录入主链路：同一事务内写 t_behavior_record + t_points_record，随后触发徽章检测。
 */
export class BehaviorService {
  static async submit(type: string, subType: string, value: number, unit: string,
    factor: number, ts: number, note: string, source: string = 'manual'): Promise<SubmitResult> {
    // 统一防御校验：录入页与 AI 识别链路都经过这里，任何入口都不可绕过上限
    const sub = CalculationService.findSub(type, subType);
    if (sub === null) {
      throw new Error('未知的行为类型');
    }
    if (!isFinite(value) || value <= 0) {
      throw new Error('数值必须大于 0');
    }
    if (value > sub.max) {
      throw new Error(`超出单次上限：最多 ${sub.max} ${sub.unit}`);
    }
    const grams: number = Math.round(value * factor);
    const record: BehaviorRecord = {
      id: 0,
      type: type,
      subType: subType,
      value: value,
      unit: unit,
      factor: factor,
      reductionG: grams,
      createdAt: ts,
      note: note,
      source: source
    };
    const points = CalculationService.valueToPoints(grams);

    DBHelper.beginTx();
    try {
      const id = BehaviorRepo.insertSync(record);
      record.id = id;
      if (points > 0) {
        // 单位与图表、首页保持一致，统一用 kg（内部仍按克存储）
        await PointsService.addPointsTx('behavior', id,
          `${subType} ${value}${unit}，减排${(grams / 1000).toFixed(2)}kg`, points);
      }
      DBHelper.commitTx();
    } catch (e) {
      DBHelper.rollbackTx();
      throw e as Error;
    }

    // 先评估任务达标，再统一检测徽章（单次调用覆盖行为与任务两类触发，动画名单完整）
    await TaskService.evaluateAll();
    const newBadges: string[] = await BadgeService.checkAll();
    bumpTick();
    // 已加入家庭组的话，异步把最新快照推给同步服务（800ms 内合并，失败静默）
    SyncService.scheduleReport();
    const result: SubmitResult = {
      recordId: record.id,
      grams: grams,
      points: points,
      newBadges: newBadges
    };
    return result;
  }

  static async deleteById(id: number): Promise<void> {
    // 同一事务内删除记录并冲减该笔行为发放过的积分，保持积分账与减排账一致
    const rec = await BehaviorRepo.getById(id);
    if (rec === null) {
      return;
    }
    DBHelper.beginTx();
    try {
      await BehaviorRepo.deleteById(id);
      const points = CalculationService.valueToPoints(rec.reductionG);
      if (points > 0) {
        await PointsService.addPointsTx('behavior', id,
          `删除记录：${rec.subType} ${rec.value}${rec.unit}，冲减积分`, -points);
      }
      // 该记录参与的任务若因此不再达标，撤销完成记录并扣回任务积分
      await TaskService.revokeUnmetTasks(rec);
      DBHelper.commitTx();
    } catch (e) {
      DBHelper.rollbackTx();
      throw e as Error;
    }
    bumpTick();
  }

  static async updateNote(id: number, note: string): Promise<void> {
    await BehaviorRepo.updateNote(id, note);
    bumpTick();
  }

  /**
   * 修改记录数值/时间：同一事务内更新记录，并按积分差额补正流水
   * （数值调大补发差额、调小扣回差额，避免"删了重录"产生冗余流水）。
   * newTs <= 0 表示不修改时间。
   *
   * 校验与任务回退口径与 submit / deleteById 保持一致：
   *  - 上限与未来时间在此统一拦截，历史页修改入口不可绕过；
   *  - 数值调小导致任务不再达标时，撤销完成记录并扣回任务积分（同删除逻辑）。
   */
  static async updateRecord(id: number, newValue: number, newTs: number): Promise<void> {
    const rec = await BehaviorRepo.getById(id);
    if (rec === null) {
      return;
    }
    if (!isFinite(newValue) || newValue <= 0) {
      throw new Error('数值必须大于 0');
    }
    const sub = CalculationService.findSub(rec.type, rec.subType);
    if (sub !== null && newValue > sub.max) {
      throw new Error(`超出单次上限：最多 ${sub.max} ${sub.unit}`);
    }
    if (newTs > Date.now()) {
      throw new Error('时间不能晚于当前时刻');
    }
    // 用记录内因子快照重算：因子库后续修订或子类型下架不影响历史记录修订
    const newG = Math.round(newValue * rec.factor);
    const oldPoints = CalculationService.valueToPoints(rec.reductionG);
    const newPoints = CalculationService.valueToPoints(newG);
    DBHelper.beginTx();
    try {
      await BehaviorRepo.updateValue(id, newValue, newG);
      if (newTs > 0 && newTs !== rec.createdAt) {
        await BehaviorRepo.updateTime(id, newTs);
      }
      const diff = newPoints - oldPoints;
      if (diff !== 0) {
        await PointsService.addPointsTx('behavior', id,
          `修改记录：${rec.subType} ${newValue}${rec.unit}，积分${diff > 0 ? '补发' : '扣回'}`, diff);
      }
      // 该记录参与的任务若因数值调小不再达标，撤销完成记录并扣回任务积分
      await TaskService.revokeUnmetTasks(rec);
      DBHelper.commitTx();
    } catch (e) {
      DBHelper.rollbackTx();
      throw e as Error;
    }
    // 数值调大可能让任务新达标：事务外补发（evaluateAll 自带事务，不可嵌套）
    await TaskService.evaluateAll();
    bumpTick();
  }
}
