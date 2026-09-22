import { DBHelper } from '../db/DBHelper';
import { BehaviorRepo } from '../db/Repository';
import { PointsService } from './PointsService';
import { BadgeService } from './BadgeService';
import { bumpTick } from '../common/Constants';
import { BehaviorRecord, SubmitResult } from '../model/Models';

/**
 * 行为录入主链路：同一事务内写 t_behavior_record + t_points_record，随后触发徽章检测。
 */
export class BehaviorService {
  static async submit(type: string, subType: string, value: number, unit: string,
    factor: number, ts: number, note: string): Promise<SubmitResult> {
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
      note: note
    };
    const points = grams > 0 ? Math.max(1, Math.floor(grams / 100)) : 0;

    DBHelper.beginTx();
    try {
      const id = BehaviorRepo.insertSync(record);
      record.id = id;
      if (points > 0) {
        await PointsService.addPointsTx('behavior', id,
          `${subType} ${value}${unit}，减排${grams}g`, points);
      }
      DBHelper.commitTx();
    } catch (e) {
      DBHelper.rollbackTx();
      throw e as Error;
    }

    const newBadges: string[] = await BadgeService.checkAll();
    bumpTick();
    const result: SubmitResult = {
      recordId: record.id,
      grams: grams,
      points: points,
      newBadges: newBadges
    };
    return result;
  }

  static async deleteById(id: number): Promise<void> {
    await BehaviorRepo.deleteById(id);
    bumpTick();
  }

  static async updateNote(id: number, note: string): Promise<void> {
    await BehaviorRepo.updateNote(id, note);
    bumpTick();
  }
}
