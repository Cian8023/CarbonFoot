import relationalStore from '@ohos.data.relationalStore';
import { DBHelper } from './DBHelper';
import {
  BehaviorRecord,
  PointsRecord,
  TaskDef,
  BadgeDef,
  TaskCheck
} from '../model/Models';

function rowToBehavior(rs: relationalStore.ResultSet): BehaviorRecord {
  const noteVal: string = rs.getString(rs.getColumnIndex('note'));
  const r: BehaviorRecord = {
    id: rs.getLong(rs.getColumnIndex('id')),
    type: rs.getString(rs.getColumnIndex('type')),
    subType: rs.getString(rs.getColumnIndex('sub_type')),
    value: rs.getDouble(rs.getColumnIndex('value')),
    unit: rs.getString(rs.getColumnIndex('unit')),
    factor: rs.getDouble(rs.getColumnIndex('factor')),
    reductionG: rs.getLong(rs.getColumnIndex('reduction_g')),
    createdAt: rs.getLong(rs.getColumnIndex('created_at')),
    note: noteVal ? noteVal : ''
  };
  return r;
}

function rowToPoints(rs: relationalStore.ResultSet): PointsRecord {
  const p: PointsRecord = {
    id: rs.getLong(rs.getColumnIndex('id')),
    source: rs.getString(rs.getColumnIndex('source')),
    refId: rs.getLong(rs.getColumnIndex('ref_id')),
    action: rs.getString(rs.getColumnIndex('action')),
    points: rs.getLong(rs.getColumnIndex('points')),
    balanceAfter: rs.getLong(rs.getColumnIndex('balance_after')),
    createdAt: rs.getLong(rs.getColumnIndex('created_at'))
  };
  return p;
}

export class BehaviorRepo {
  static bucket(r: BehaviorRecord): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {
      'type': r.type,
      'sub_type': r.subType,
      'value': r.value,
      'unit': r.unit,
      'factor': r.factor,
      'reduction_g': r.reductionG,
      'created_at': r.createdAt,
      'note': r.note
    };
    return bucket;
  }

  static insertSync(r: BehaviorRecord): number {
    return DBHelper.get().insertSync('t_behavior_record', BehaviorRepo.bucket(r));
  }

  static async deleteById(id: number): Promise<void> {
    const pred = new relationalStore.RdbPredicates('t_behavior_record');
    pred.equalTo('id', id);
    await DBHelper.get().delete(pred);
  }

  static async updateNote(id: number, note: string): Promise<void> {
    const pred = new relationalStore.RdbPredicates('t_behavior_record');
    pred.equalTo('id', id);
    const bucket: relationalStore.ValuesBucket = { 'note': note };
    await DBHelper.get().update(bucket, pred);
  }

  /** startTs ~ endTs 区间，可按大类过滤，时间倒序 */
  static async getById(id: number): Promise<BehaviorRecord | null> {
    const pred = new relationalStore.RdbPredicates('t_behavior_record');
    pred.equalTo('id', id);
    const rs = await DBHelper.get().query(pred);
    let rec: BehaviorRecord | null = null;
    if (rs.goToNextRow()) {
      rec = rowToBehavior(rs);
    }
    rs.close();
    return rec;
  }

  static async query(startTs: number, endTs: number, type: string): Promise<BehaviorRecord[]> {
    const pred = new relationalStore.RdbPredicates('t_behavior_record');
    pred.between('created_at', startTs, endTs).orderByDesc('created_at');
    if (type !== '全部') {
      pred.equalTo('type', type);
    }
    const rs = await DBHelper.get().query(pred);
    const list: BehaviorRecord[] = [];
    while (rs.goToNextRow()) {
      list.push(rowToBehavior(rs));
    }
    rs.close();
    return list;
  }

  static async all(): Promise<BehaviorRecord[]> {
    return BehaviorRepo.query(0, Date.now() + 86400000, '全部');
  }

  static async countAll(): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_behavior_record');
    const rs = await DBHelper.get().query(pred);
    const n = rs.rowCount;
    rs.close();
    return n;
  }

  static async sumAllReduction(): Promise<number> {
    const list = await BehaviorRepo.all();
    let sum = 0;
    for (const r of list) {
      sum += r.reductionG;
    }
    return sum;
  }

  static async sumBySubTypes(subTypes: string[], startTs: number, endTs: number, unit: string = ''): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_behavior_record');
    pred.between('created_at', startTs, endTs);
    if (subTypes.length > 0) {
      pred.in('sub_type', subTypes);
    }
    if (unit !== '') {
      pred.equalTo('unit', unit);
    }
    const rs = await DBHelper.get().query(pred);
    let sum = 0;
    while (rs.goToNextRow()) {
      sum += rs.getDouble(rs.getColumnIndex('value'));
    }
    rs.close();
    return sum;
  }

  static async countBySubTypes(subTypes: string[], startTs: number, endTs: number): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_behavior_record');
    pred.between('created_at', startTs, endTs);
    if (subTypes.length > 0) {
      pred.in('sub_type', subTypes);
    }
    const rs = await DBHelper.get().query(pred);
    const n = rs.rowCount;
    rs.close();
    return n;
  }

  static async distinctDays(): Promise<number[]> {
    const list = await BehaviorRepo.all();
    const set = new Set<number>();
    for (const r of list) {
      const d = new Date(r.createdAt);
      d.setHours(0, 0, 0, 0);
      set.add(d.getTime());
    }
    const arr: number[] = [];
    set.forEach((v: number) => {
      arr.push(v);
    });
    arr.sort((a: number, b: number) => b - a);
    return arr;
  }
}

export class PointsRepo {
  static bucket(p: PointsRecord): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {
      'source': p.source,
      'ref_id': p.refId,
      'action': p.action,
      'points': p.points,
      'balance_after': p.balanceAfter,
      'created_at': p.createdAt
    };
    return bucket;
  }

  static insertSync(p: PointsRecord): number {
    return DBHelper.get().insertSync('t_points_record', PointsRepo.bucket(p));
  }

  /** 最新余额 = 最近一笔流水的 balance_after */
  static async lastBalance(): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_points_record');
    pred.limitAs(1).orderByDesc('id');
    const rs = await DBHelper.get().query(pred);
    let balance = 0;
    if (rs.goToNextRow()) {
      balance = rs.getLong(rs.getColumnIndex('balance_after'));
    }
    rs.close();
    return balance;
  }

  static async list(limit: number): Promise<PointsRecord[]> {
    const pred = new relationalStore.RdbPredicates('t_points_record');
    pred.orderByDesc('id').limitAs(limit);
    const rs = await DBHelper.get().query(pred);
    const list: PointsRecord[] = [];
    while (rs.goToNextRow()) {
      list.push(rowToPoints(rs));
    }
    rs.close();
    return list;
  }

  static async listAll(): Promise<PointsRecord[]> {
    const pred = new relationalStore.RdbPredicates('t_points_record');
    pred.orderByAsc('id');
    const rs = await DBHelper.get().query(pred);
    const list: PointsRecord[] = [];
    while (rs.goToNextRow()) {
      list.push(rowToPoints(rs));
    }
    rs.close();
    return list;
  }

  static async hasSourceRef(source: string, refId: number): Promise<boolean> {
    const pred = new relationalStore.RdbPredicates('t_points_record');
    pred.equalTo('source', source).equalTo('ref_id', refId);
    const rs = await DBHelper.get().query(pred);
    const n = rs.rowCount;
    rs.close();
    return n > 0;
  }

  static async countSource(source: string): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_points_record');
    pred.equalTo('source', source);
    const rs = await DBHelper.get().query(pred);
    const n = rs.rowCount;
    rs.close();
    return n;
  }

  static async totalEarned(): Promise<number> {
    const list = await PointsRepo.listAll();
    let sum = 0;
    for (const p of list) {
      if (p.points > 0) {
        sum += p.points;
      }
    }
    return sum;
  }
}

export class TaskRepo {
  static async list(): Promise<TaskDef[]> {
    const pred = new relationalStore.RdbPredicates('t_task');
    pred.equalTo('enabled', 1).orderByAsc('id');
    const rs = await DBHelper.get().query(pred);
    const list: TaskDef[] = [];
    while (rs.goToNextRow()) {
      const t: TaskDef = {
        id: rs.getLong(rs.getColumnIndex('id')),
        code: rs.getString(rs.getColumnIndex('code')),
        title: rs.getString(rs.getColumnIndex('title')),
        description: rs.getString(rs.getColumnIndex('description')),
        points: rs.getLong(rs.getColumnIndex('points')),
        period: rs.getString(rs.getColumnIndex('period')),
        checkJson: rs.getString(rs.getColumnIndex('check_json')),
        enabled: rs.getLong(rs.getColumnIndex('enabled')) === 1
      };
      list.push(t);
    }
    rs.close();
    return list;
  }

  static async insertIfAbsent(code: string, title: string, description: string,
    points: number, period: string, checkJson: string): Promise<void> {
    const pred = new relationalStore.RdbPredicates('t_task');
    pred.equalTo('code', code);
    const rs = await DBHelper.get().query(pred);
    const exists = rs.rowCount > 0;
    rs.close();
    if (exists) {
      // 任务定义已存在时同步更新（种子数据修订后可应用到已安装环境）
      const upd: relationalStore.ValuesBucket = {
        'title': title,
        'description': description,
        'points': points,
        'check_json': checkJson
      };
      await DBHelper.get().update(upd, pred);
      return;
    }
    const bucket: relationalStore.ValuesBucket = {
      'code': code,
      'title': title,
      'description': description,
      'points': points,
      'period': period,
      'check_json': checkJson,
      'enabled': 1
    };
    await DBHelper.get().insert('t_task', bucket);
  }

  static async insertCompletion(taskId: number, ts: number): Promise<void> {
    const bucket: relationalStore.ValuesBucket = {
      'task_id': taskId,
      'completed_at': ts
    };
    await DBHelper.get().insert('t_task_completion', bucket);
  }

  static async completionsBetween(taskId: number, startTs: number, endTs: number): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_task_completion');
    pred.equalTo('task_id', taskId).between('completed_at', startTs, endTs);
    const rs = await DBHelper.get().query(pred);
    const n = rs.rowCount;
    rs.close();
    return n;
  }

  static async countCompletions(): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_task_completion');
    const rs = await DBHelper.get().query(pred);
    const n = rs.rowCount;
    rs.close();
    return n;
  }
}

export class BadgeRepo {
  static async list(): Promise<BadgeDef[]> {
    const pred = new relationalStore.RdbPredicates('t_badge');
    pred.orderByAsc('condition_value');
    const rs = await DBHelper.get().query(pred);
    const list: BadgeDef[] = [];
    while (rs.goToNextRow()) {
      const b: BadgeDef = {
        id: rs.getLong(rs.getColumnIndex('id')),
        code: rs.getString(rs.getColumnIndex('code')),
        name: rs.getString(rs.getColumnIndex('name')),
        icon: rs.getString(rs.getColumnIndex('icon')),
        conditionType: rs.getString(rs.getColumnIndex('condition_type')),
        conditionValue: rs.getLong(rs.getColumnIndex('condition_value')),
        description: rs.getString(rs.getColumnIndex('description')),
        unlocked: rs.getLong(rs.getColumnIndex('unlocked')) === 1,
        unlockedAt: rs.getLong(rs.getColumnIndex('unlocked_at'))
      };
      list.push(b);
    }
    rs.close();
    return list;
  }

  static async insertIfAbsent(code: string, name: string, icon: string,
    conditionType: string, conditionValue: number, description: string): Promise<void> {
    const pred = new relationalStore.RdbPredicates('t_badge');
    pred.equalTo('code', code);
    const rs = await DBHelper.get().query(pred);
    const exists = rs.rowCount > 0;
    rs.close();
    if (exists) {
      return;
    }
    const bucket: relationalStore.ValuesBucket = {
      'code': code,
      'name': name,
      'icon': icon,
      'condition_type': conditionType,
      'condition_value': conditionValue,
      'description': description,
      'unlocked': 0,
      'unlocked_at': 0
    };
    await DBHelper.get().insert('t_badge', bucket);
  }

  static async setUnlocked(id: number, ts: number): Promise<void> {
    const pred = new relationalStore.RdbPredicates('t_badge');
    pred.equalTo('id', id);
    const bucket: relationalStore.ValuesBucket = { 'unlocked': 1, 'unlocked_at': ts };
    await DBHelper.get().update(bucket, pred);
  }

  static async countUnlocked(): Promise<number> {
    const pred = new relationalStore.RdbPredicates('t_badge');
    pred.equalTo('unlocked', 1);
    const rs = await DBHelper.get().query(pred);
    const n = rs.rowCount;
    rs.close();
    return n;
  }

  static async resetUnlocked(): Promise<void> {
    const pred = new relationalStore.RdbPredicates('t_badge');
    const bucket: relationalStore.ValuesBucket = { 'unlocked': 0, 'unlocked_at': 0 };
    await DBHelper.get().update(bucket, pred);
  }
}

/** 任务周期判断 */
export class TaskCheckUtil {
  static parse(checkJson: string): TaskCheck {
    const fallback: TaskCheck = { subTypes: [], target: 1, unit: '次', matchType: 'count' };
    try {
      return JSON.parse(checkJson) as TaskCheck;
    } catch (e) {
      return fallback;
    }
  }
}
