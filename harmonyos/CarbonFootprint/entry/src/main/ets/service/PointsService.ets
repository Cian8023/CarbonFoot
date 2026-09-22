import { DBHelper } from '../db/DBHelper';
import { PointsRepo } from '../db/Repository';
import { PointsRecord } from '../model/Models';

/**
 * 积分服务：所有积分变动统一走 addPoints，保证流水含来源、动作、增减、余额、时间。
 */
export class PointsService {
  /** 事务内使用（调用方需已 beginTx） */
  static addPointsTx(source: string, refId: number, action: string, points: number): Promise<void> {
    return (async (): Promise<void> => {
      const balance = await PointsRepo.lastBalance();
      const p: PointsRecord = {
        id: 0,
        source: source,
        refId: refId,
        action: action,
        points: points,
        balanceAfter: balance + points,
        createdAt: Date.now()
      };
      PointsRepo.insertSync(p);
    })();
  }

  /** 常规入口：自带事务 */
  static async addPoints(source: string, refId: number, action: string, points: number): Promise<void> {
    DBHelper.beginTx();
    try {
      await PointsService.addPointsTx(source, refId, action, points);
      DBHelper.commitTx();
    } catch (e) {
      DBHelper.rollbackTx();
      throw e as Error;
    }
  }

  static async getBalance(): Promise<number> {
    return await PointsRepo.lastBalance();
  }

  static async queryFlow(limit: number): Promise<PointsRecord[]> {
    return await PointsRepo.list(limit);
  }

  static async hasSourceRef(source: string, refId: number): Promise<boolean> {
    return await PointsRepo.hasSourceRef(source, refId);
  }

  static async countSource(source: string): Promise<number> {
    return await PointsRepo.countSource(source);
  }

  static async totalEarned(): Promise<number> {
    return await PointsRepo.totalEarned();
  }
}
