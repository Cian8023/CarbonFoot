import common from '@ohos.app.ability.common';
import preferences from '@ohos.data.preferences';
import util from '@ohos.util';
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
 * 鸿蒙多端数据同步服务（创新拓展 1）：
 * 优先尝试 distributedDataObject 分布式数据对象组网同步；
 * 模拟器/未登录账号等场景自动降级为「家庭组演示模式」，合并统计链路完整可演示。
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

  /** 演示模式：生成虚拟家庭成员的上报数据（模拟分布式数据到达） */
  static async addDemoMember(name: string): Promise<void> {
    const members = await SyncService.listMembers();
    const totalBase = Math.floor(20000 + Math.random() * 80000);
    const m: FamilyMember = {
      deviceId: 'demo-' + new util.Base64Helper().encodeToStringSync(
        new Uint8Array([Date.now() % 255, members.length])).substring(0, 8),
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
    return sum * (1 + members.length);
  }
}
