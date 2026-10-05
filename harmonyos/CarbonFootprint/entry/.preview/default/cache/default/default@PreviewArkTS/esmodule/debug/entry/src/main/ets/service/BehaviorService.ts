import { DBHelper } from "@normalized:N&&&entry/src/main/ets/db/DBHelper&";
import { BehaviorRepo } from "@normalized:N&&&entry/src/main/ets/db/Repository&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { BadgeService } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import { TaskService } from "@normalized:N&&&entry/src/main/ets/service/TaskService&";
import { CalculationService } from "@normalized:N&&&entry/src/main/ets/service/CalculationService&";
import { bumpTick } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import type { BehaviorRecord, SubmitResult } from '../model/Models';
/**
 * 行为录入主链路：同一事务内写 t_behavior_record + t_points_record，随后触发徽章检测。
 */
export class BehaviorService {
    static async submit(type: string, subType: string, value: number, unit: string, factor: number, ts: number, note: string): Promise<SubmitResult> {
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
        const points = CalculationService.valueToPoints(grams);
        DBHelper.beginTx();
        try {
            const id = BehaviorRepo.insertSync(record);
            record.id = id;
            if (points > 0) {
                await PointsService.addPointsTx('behavior', id, `${subType} ${value}${unit}，减排${grams}g`, points);
            }
            DBHelper.commitTx();
        }
        catch (e) {
            DBHelper.rollbackTx();
            throw e as Error;
        }
        // 先评估任务达标，再统一检测徽章（单次调用覆盖行为与任务两类触发，动画名单完整）
        await TaskService.evaluateAll();
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
                await PointsService.addPointsTx('behavior', id, `删除记录：${rec.subType} ${rec.value}${rec.unit}，冲减积分`, -points);
            }
            // 该记录参与的任务若因此不再达标，撤销完成记录并扣回任务积分
            await TaskService.revokeUnmetTasks(rec);
            DBHelper.commitTx();
        }
        catch (e) {
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
     */
    static async updateRecord(id: number, newValue: number, newTs: number): Promise<void> {
        const rec = await BehaviorRepo.getById(id);
        if (rec === null) {
            return;
        }
        const newG = CalculationService.calculate(rec.type, rec.subType, newValue);
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
                await PointsService.addPointsTx('behavior', id, `修改记录：${rec.subType} ${newValue}${rec.unit}，积分${diff > 0 ? '补发' : '扣回'}`, diff);
            }
            DBHelper.commitTx();
        }
        catch (e) {
            DBHelper.rollbackTx();
            throw e as Error;
        }
        bumpTick();
    }
}
