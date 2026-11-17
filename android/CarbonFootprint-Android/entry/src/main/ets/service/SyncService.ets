/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import preferences from '@ohos.data.preferences';
import { AppInit } from '../common/AppInit';
import { AppConfig } from '../common/AppConfig';
import { BehaviorRepo } from '../db/Repository';
import { PointsService } from './PointsService';
import { DateUtil } from '../utils/DateUtil';
import { HttpClient, HttpResponse } from '../network/HttpClient';

export interface FamilyMember {
  deviceId: string;
  name: string;
  totalG: number;
  balance: number;
  weekG: number;
  /** 该成员快照的服务器时间 */
  updatedAt: number;
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

interface RemoteMember {
  deviceId: string;
  name: string;
  totalG: number;
  balance: number;
  weekG: number;
  updatedAt: number;
}

interface MembersResp {
  code: number;
  data: RemoteMember[];
}

/**
 * 家庭碳账户服务（创新拓展 1）：应用层多端同步。
 *
 * 两台设备（模拟器或真机）都连宿主机上的 sync/server.js，
 * 通过 HTTP 交换成员快照，实现真实的跨设备数据合并。
 * 服务不可达时自动用本地缓存展示，功能不中断。
 *
 * 注：分布式软总线（distributedDataObject）在模拟器上受 NAT 隔离与同账号互信限制不可用，
 * 故采用应用层同步。
 */
export class SyncService {
  private static readonly KEY_GROUP: string = 'family_group';
  private static readonly KEY_MEMBERS: string = 'family_members';
  private static readonly KEY_DEVICE: string = 'device_id';
  private static readonly KEY_NICK: string = 'device_nick';

  private static readonly EMULATOR_HOST: string = 'http://10.0.2.2:8081';
  private static readonly LOOPBACK_HOST: string = 'http://127.0.0.1:8081';

  private static online: boolean = false;
  private static lastSyncAt: number = 0;

  private static async getStore(): Promise<preferences.Preferences> {
    const ctx = AppInit.getContext();
    return await preferences.getPreferences(ctx, 'family_sync');
  }

  /** 设备唯一标识：首次生成后持久化，用于区分"我"和"别人" */
  static async deviceId(): Promise<string> {
    const store = await SyncService.getStore();
    let id = await store.get(SyncService.KEY_DEVICE, '') as string;
    if (id === '') {
      id = 'dev-' + Date.now().toString(36) + '-' + Math.floor(Math.random() * 1000000).toString(36);
      await store.put(SyncService.KEY_DEVICE, id);
      await store.flush();
    }
    return id;
  }

  static async getNickname(): Promise<string> {
    const store = await SyncService.getStore();
    const v = await store.get(SyncService.KEY_NICK, '') as string;
    return v === '' ? '我的设备' : v;
  }

  static async setNickname(v: string): Promise<void> {
    const store = await SyncService.getStore();
    await store.put(SyncService.KEY_NICK, v);
    await store.flush();
  }

  static isOnline(): boolean {
    return SyncService.online;
  }

  static lastSyncTime(): number {
    return SyncService.lastSyncAt;
  }

  /** 同步服务候选地址：配置 → 模拟器宿主别名 → 本机回环 */
  private static candidates(configured: string): string[] {
    const raw: string[] = [configured.trim(), SyncService.EMULATOR_HOST, SyncService.LOOPBACK_HOST];
    const out: string[] = [];
    for (const u of raw) {
      if (u !== '' && out.indexOf(u) < 0) {
        out.push(u);
      }
    }
    return out;
  }

  private static async callPost(path: string, body: string): Promise<HttpResponse | null> {
    const configured = await AppConfig.getSyncBaseUrl();
    const list = SyncService.candidates(configured);
    for (const base of list) {
      try {
        return await HttpClient.postJson(base + path, body, {}, 4000);
      } catch (e) {
        // 换下一个候选地址
      }
    }
    return null;
  }

  private static async callGet(path: string): Promise<HttpResponse | null> {
    const configured = await AppConfig.getSyncBaseUrl();
    const list = SyncService.candidates(configured);
    for (const base of list) {
      try {
        return await HttpClient.getJson(base + path, {}, 4000);
      } catch (e) {
        // 换下一个候选地址
      }
    }
    return null;
  }

  private static async saveGroup(group: FamilyGroup): Promise<void> {
    const store = await SyncService.getStore();
    await store.put(SyncService.KEY_GROUP, JSON.stringify(group));
    await store.flush();
  }

  /**
   * 建组：邀请码由本机生成，服务端校验唯一。
   * 服务不可达时直接失败（避免建出别人加不进来的"幽灵组"）。
   */
  static async createGroup(): Promise<string> {
    const id = await SyncService.deviceId();
    const name = await SyncService.getNickname();
    for (let i = 0; i < 3; i++) {
      const code = 'CF' + Math.floor(100000 + Math.random() * 900000);
      const body = JSON.stringify({ code: code, deviceId: id, name: name });
      const resp = await SyncService.callPost('/api/family/create', body);
      if (resp === null) {
        throw new Error('同步服务不可达，请先在电脑上启动 node sync/server.js 8081');
      }
      if (resp.code === 200) {
        const g: FamilyGroup = { code: code, createdAt: Date.now() };
        await SyncService.saveGroup(g);
        SyncService.online = true;
        SyncService.lastSyncAt = Date.now();
        await SyncService.reportSnapshot();
        await SyncService.pullMembers();
        return code;
      }
      if (resp.code !== 409) {
        throw new Error('创建家庭组失败：HTTP ' + resp.code);
      }
    }
    throw new Error('邀请码连续冲突，请重试');
  }

  /** 加入组：返回 ok / notfound / offline / error */
  static async joinGroup(code: string, name: string): Promise<string> {
    const id = await SyncService.deviceId();
    const body = JSON.stringify({ code: code, deviceId: id, name: name });
    const resp = await SyncService.callPost('/api/family/join', body);
    if (resp === null) {
      return 'offline';
    }
    if (resp.code === 404) {
      return 'notfound';
    }
    if (resp.code !== 200) {
      return 'error';
    }
    await SyncService.setNickname(name);
    const g: FamilyGroup = { code: code, createdAt: Date.now() };
    await SyncService.saveGroup(g);
    SyncService.online = true;
    SyncService.lastSyncAt = Date.now();
    await SyncService.pullMembers();
    return 'ok';
  }

  /** 上报本机快照（减排总量、积分余额、本周减排） */
  static async reportSnapshot(): Promise<boolean> {
    const group = await SyncService.getGroup();
    if (group === null) {
      return false;
    }
    const id = await SyncService.deviceId();
    const name = await SyncService.getNickname();
    const totalG = await BehaviorRepo.sumAllReduction();
    const balance = await PointsService.getBalance();
    const weekG = await SyncService.localWeekG();
    const body = JSON.stringify({
      code: group.code, deviceId: id, name: name,
      totalG: totalG, balance: balance, weekG: weekG
    });
    const resp = await SyncService.callPost('/api/family/report', body);
    if (resp === null || resp.code !== 200) {
      SyncService.online = false;
      return false;
    }
    SyncService.online = true;
    SyncService.lastSyncAt = Date.now();
    return true;
  }

  /** 拉取组内成员快照并缓存（离线时用缓存展示） */
  static async pullMembers(): Promise<boolean> {
    const group = await SyncService.getGroup();
    if (group === null) {
      return false;
    }
    const resp = await SyncService.callGet('/api/family/members?code=' + group.code);
    if (resp === null || resp.code !== 200) {
      SyncService.online = false;
      return false;
    }
    try {
      const parsed = JSON.parse(resp.body) as MembersResp;
      const list: FamilyMember[] = [];
      if (parsed.data !== undefined && parsed.data !== null) {
        for (const r of parsed.data) {
          const m: FamilyMember = {
            deviceId: r.deviceId,
            name: r.name,
            totalG: r.totalG,
            balance: r.balance,
            weekG: r.weekG,
            updatedAt: r.updatedAt,
            local: false
          };
          list.push(m);
        }
      }
      const store = await SyncService.getStore();
      await store.put(SyncService.KEY_MEMBERS, JSON.stringify(list));
      await store.flush();
      SyncService.online = true;
      SyncService.lastSyncAt = Date.now();
      return true;
    } catch (e) {
      return false;
    }
  }

  /** 一键同步：先上报本机，再拉取他人 */
  static async syncNow(): Promise<string> {
    const ok = await SyncService.reportSnapshot();
    if (!ok) {
      return 'offline';
    }
    await SyncService.pullMembers();
    return 'ok';
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

  /** 退出家庭组：先通知服务端移除本机，再清本地。返回 ok / offline / error */
  static async leaveGroup(): Promise<string> {
    const group = await SyncService.getGroup();
    let remote = 'ok';
    if (group !== null) {
      const id = await SyncService.deviceId();
      const body = JSON.stringify({ code: group.code, deviceId: id });
      const resp = await SyncService.callPost('/api/family/leave', body);
      if (resp === null) {
        remote = 'offline';
      } else if (resp.code !== 200 && resp.code !== 404) {
        remote = 'error';
      }
    }
    const store = await SyncService.getStore();
    await store.delete(SyncService.KEY_GROUP);
    await store.delete(SyncService.KEY_MEMBERS);
    await store.flush();
    SyncService.online = false;
    SyncService.lastSyncAt = 0;
    return remote;
  }

  private static reporting: boolean = false;
  private static pendingReport: boolean = false;

  /**
   * 录入后触发上报。
   * 注意：不能用 setTimeout 做延迟合并——应用切到后台后定时器会被冻结，
   * 用户"录完就切到另一台设备"时上报会永远发不出去。这里改为立即上报，
   * 用 reporting 标志把并发调用合并成"进行中 + 结束后补一次"。
   */
  static scheduleReport(): void {
    if (SyncService.reporting) {
      SyncService.pendingReport = true;
      return;
    }
    SyncService.runReport();
  }

  private static async runReport(): Promise<void> {
    SyncService.reporting = true;
    try {
      const g = await SyncService.getGroup();
      if (g !== null) {
        await SyncService.reportSnapshot();
      }
    } catch (e) {
      // 静默失败：家庭页仍可手动「立即同步」
    } finally {
      SyncService.reporting = false;
      if (SyncService.pendingReport) {
        SyncService.pendingReport = false;
        SyncService.scheduleReport();
      }
    }
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

  /** 本机本周减排（真实数据） */
  private static async localWeekG(): Promise<number> {
    const weekStart = DateUtil.startOfWeek(Date.now());
    const records = await BehaviorRepo.all();
    let sum = 0;
    for (const r of records) {
      if (r.createdAt >= weekStart) {
        sum += r.reductionG;
      }
    }
    return sum;
  }

  /** 家庭合并统计：本机真实数据 + 其他设备同步来的快照 */
  static async mergedStats(): Promise<MergedStats> {
    const myId = await SyncService.deviceId();
    const cached = await SyncService.listMembers();
    const myG = await BehaviorRepo.sumAllReduction();
    // 本机积分取真实余额：含任务/阅读奖励与兑换扣减，不能再用减排量反推
    const myBalance = await PointsService.getBalance();
    // 本机显示「我（本机）」，设过昵称的话带上昵称，和对方看到的称呼对齐
    const nick = await SyncService.getNickname();
    const selfName = nick === '我的设备' ? '我（本机）' : `我（本机 · ${nick}）`;
    const mine: FamilyMember = {
      deviceId: myId,
      name: selfName,
      totalG: myG,
      balance: myBalance,
      weekG: await SyncService.localWeekG(),
      updatedAt: Date.now(),
      local: true
    };
    const all: FamilyMember[] = [mine];
    for (const m of cached) {
      // 服务端也会回传本机快照，跳过以免重复累加
      if (m.deviceId === myId) {
        continue;
      }
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

  /** 家庭本周减排：本机真实 + 各成员同步来的周数据 */
  static async familyWeekG(): Promise<number> {
    const myId = await SyncService.deviceId();
    let sum = await SyncService.localWeekG();
    const cached = await SyncService.listMembers();
    for (const m of cached) {
      if (m.deviceId !== myId) {
        sum += m.weekG;
      }
    }
    return sum;
  }
}
