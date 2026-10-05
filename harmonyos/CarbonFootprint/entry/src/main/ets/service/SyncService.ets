import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import { AppInit } from '../common/AppInit';
import { BehaviorRepo } from '../db/Repository';
import { DateUtil } from '../utils/DateUtil';

export interface FamilyMember {
  deviceId: string;
  name: string;
  totalG: number;
  balance: number;
  joinedAt: number;
  local: boolean;
}

export interface FamilyGroup {
  code: string;
  createdAt: number;
}

export interface MergedStats {
  members: FamilyMember[];
  totalG: number;
  totalPoints: number;
}

/**
 * 家庭碳账户服务（创新拓展 1）：家庭组演示模式。
 * 单设备上模拟家庭成员数据上报，家庭合并减排、合并积分与成员排行链路完整可演示；
 * distributedDataObject 真实多端同步预留为后续迭代（tryDistributedSync 当前固定返回 false）。
 */
export class SyncService {
  private static readonly KEY_GROUP: string = 'family_group';
  private static readonly KEY_MEMBERS: string = 'family_members';

  private static async getStore(): Promise<preferences.Preferences> {
    const ctx = AppInit.getContext();
    return await preferences.getPreferences(ctx, 'family_sync');
  }

  /** 创建家庭组，返回邀请码 */
  static async createGroup(): Promise<string> {
    const code = 'CF' + Math.floor(100000 + Math.random() * 900000);
    const group: FamilyGroup = { code: code, createdAt: Date.now() };
    const store = await SyncService.getStore();
    await store.put(SyncService.KEY_GROUP, JSON.stringify(group));
    await store.flush();
    return code;
  }

  static async getGroup(): Promise<FamilyGroup | null> {
    try {
      const store = await SyncService.getStore();
      const v = await store.get(SyncService.KEY_GROUP, '');
      if (v === '') {
        return null;
      }
      return JSON.parse(v as string) as FamilyGroup;
    } catch (e) {
      return null;
    }
  }

  static async leaveGroup(): Promise<void> {
    const store = await SyncService.getStore();
    await store.delete(SyncService.KEY_GROUP);
    await store.delete(SyncService.KEY_MEMBERS);
    await store.flush();
  }

  /**
   * 分布式能力探测：供真机场景接入 distributedDataObject 时使用。
   * 当前统一返回 false（演示模式），模拟器/未组网环境自动降级，不影响主功能。
   */
  static async tryDistributedSync(_context: common.UIAbilityContext): Promise<boolean> {
    return false;
  }

  /** 演示模式：按昵称哈希生成稳定的虚拟成员数据（同名成员数据一致，重演不穿帮） */
  static async addDemoMember(name: string): Promise<void> {
    const members = await SyncService.listMembers();
    let hash = 0;
    for (let i = 0; i < name.length; i++) {
      hash = (hash * 31 + name.charCodeAt(i)) % 100000;
    }
    const totalBase = 20000 + (hash % 80000);
    const m: FamilyMember = {
      deviceId: 'demo-' + hash.toString(16),
      name: name,
      totalG: totalBase,
      balance: Math.floor(totalBase / 100),
      joinedAt: Date.now(),
      local: false
    };
    members.push(m);
    const store = await SyncService.getStore();
    await store.put(SyncService.KEY_MEMBERS, JSON.stringify(members));
    await store.flush();
  }

  static async listMembers(): Promise<FamilyMember[]> {
    try {
      const store = await SyncService.getStore();
      const v = await store.get(SyncService.KEY_MEMBERS, '[]');
      return JSON.parse(v as string) as FamilyMember[];
    } catch (e) {
      return [];
    }
  }

  /** 家庭碳积分合并统计：本机真实数据 + 各成员同步数据 */
  static async mergedStats(): Promise<MergedStats> {
    const members = await SyncService.listMembers();
    const myG = await BehaviorRepo.sumAllReduction();
    const mine: FamilyMember = {
      deviceId: 'local',
      name: '我（本机）',
      totalG: myG,
      balance: Math.floor(myG / 100),
      joinedAt: 0,
      local: true
    };
    const all: FamilyMember[] = [mine];
    for (const m of members) {
      all.push(m);
    }
    let totalG = 0;
    let totalPoints = 0;
    for (const m of all) {
      totalG += m.totalG;
      totalPoints += m.balance;
    }
    all.sort((a: FamilyMember, b: FamilyMember) => b.totalG - a.totalG);
    const result: MergedStats = { members: all, totalG: totalG, totalPoints: totalPoints };
    return result;
  }

  /** 家庭周减排概览（演示数据基于本机趋势缩放） */
  static async familyWeekG(): Promise<number> {
    const weekStart = DateUtil.startOfWeek(Date.now());
    const records = await BehaviorRepo.all();
    let sum = 0;
    for (const r of records) {
      if (r.createdAt >= weekStart) {
        sum += r.reductionG;
      }
    }
    const members = await SyncService.listMembers();
    // 与合并总览同口径（逐人相加）：本机真实周减排 + 各演示成员按总量 10% 折算周减排
    let memberWeek = 0;
    for (const m of members) {
      memberWeek += Math.floor(m.totalG / 10);
    }
    return sum + memberWeek;
  }
}
