/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import preferences from '@ohos.data.preferences';
import { AppInit } from '../common/AppInit';
import { AppConfig } from '../common/AppConfig';
import { HttpClient } from '../network/HttpClient';
import { PointsService } from './PointsService';

export interface Benefit {
  id: string;
  name: string;
  icon: string;
  cost: number;
  stock: number;
  desc: string;
}

export interface Entitlement {
  name: string;
  icon: string;
  time: number;
  from: string;
}

interface BenefitFile {
  benefits: Benefit[];
}
interface RemoteBenefitResp {
  code: number;
  data: Benefit[];
}

/**
 * 城市碳普惠接口服务（创新拓展 3）：
 * 优先请求真实碳普惠平台 HTTP 接口（可配置地址，配合本地 Node Mock 服务）；
 * 平台不可达时自动降级为内置 Mock 权益池，积分互通与权益兑换链路完整可演示。
 */
export class InclusiveService {
  private static benefits: Benefit[] = [];
  private static remoteMode: boolean = false;
  /** 模拟权益的会话内库存（兑换递减，卖完显示已兑完） */
  private static stockMap: Map<string, number> = new Map();
  /** 本次实际连通的基地址；兑换复用同一地址，避免"列表走 A、兑换走 B" */
  private static activeBaseUrl: string = '';

  /**
   * 模拟器是独立虚拟机，它自己的 127.0.0.1 指向模拟器内部，
   * 必须用 QEMU 固定的宿主机别名 10.0.2.2 才能访问电脑上跑的服务。
   */
  private static readonly EMULATOR_HOST: string = 'http://10.0.2.2:8080';
  /** 真机 / 服务与应用同机时的回环地址 */
  private static readonly LOOPBACK_HOST: string = 'http://127.0.0.1:8080';

  /** 候选地址：用户配置 → 模拟器宿主别名 → 本机回环，去空去重 */
  private static candidates(configured: string): string[] {
    const raw: string[] = [configured.trim(), InclusiveService.EMULATOR_HOST, InclusiveService.LOOPBACK_HOST];
    const out: string[] = [];
    for (const u of raw) {
      if (u !== '' && out.indexOf(u) < 0) {
        out.push(u);
      }
    }
    return out;
  }

  /** 拉取可兑换权益：按候选地址依次尝试，第一个通的就用；全失败降级内置 Mock */
  static async fetchBenefits(): Promise<string> {
    const configured = await AppConfig.getInclusiveBaseUrl();
    const list = InclusiveService.candidates(configured);
    for (const base of list) {
      try {
        const resp = await HttpClient.getJson(base + '/api/benefits', {}, 2500);
        if (resp.code === 200) {
          const parsed = JSON.parse(resp.body) as RemoteBenefitResp;
          if (parsed.data !== undefined && parsed.data.length > 0) {
            InclusiveService.benefits = parsed.data;
            InclusiveService.remoteMode = true;
            InclusiveService.activeBaseUrl = base;
            return '已连接城市碳普惠平台';
          }
        }
      } catch (e) {
        // 该候选不可达，换下一个
      }
    }
    InclusiveService.activeBaseUrl = '';
    InclusiveService.benefits = InclusiveService.mockBenefits();
    InclusiveService.remoteMode = false;
    for (const b of InclusiveService.benefits) {
      if (!InclusiveService.stockMap.has(b.id)) {
        InclusiveService.stockMap.set(b.id, b.stock);
      }
      b.stock = InclusiveService.stockMap.get(b.id) as number;
    }
    return '碳普惠平台未连通，当前为内置模拟模式';
  }

  static isRemoteMode(): boolean {
    return InclusiveService.remoteMode;
  }

  /** 实际连通的基地址；空串表示当前为内置模拟模式 */
  static getActiveBaseUrl(): string {
    return InclusiveService.activeBaseUrl;
  }

  static getBenefits(): Benefit[] {
    return InclusiveService.benefits;
  }

  /** 积分兑换权益：本地扣积分 + 上报/记录权益（任一步失败回滚模拟库存） */
  static async exchange(benefit: Benefit): Promise<void> {
    const balance = await PointsService.getBalance();
    if (balance < benefit.cost) {
      throw new Error(`积分不足，还差 ${benefit.cost - balance} 分`);
    }
    const localStock = !InclusiveService.remoteMode;
    if (localStock) {
      const left = InclusiveService.stockMap.get(benefit.id);
      if (left !== undefined) {
        if (left <= 0) {
          throw new Error('该权益已兑完');
        }
        InclusiveService.stockMap.set(benefit.id, left - 1);
      }
    }
    let deducted = false;
    try {
      if (InclusiveService.remoteMode) {
        // 优先复用列表拉取时命中的地址，避免配置值不可达但候选地址可用时兑换失败
        let base = InclusiveService.activeBaseUrl;
        if (base === '') {
          base = await AppConfig.getInclusiveBaseUrl();
        }
        const body = JSON.stringify({ benefitId: benefit.id, cost: benefit.cost });
        const resp = await HttpClient.postJson(base + '/api/exchange', body, {}, 5000);
        if (resp.code !== 200) {
          throw new Error('平台兑换失败：HTTP ' + resp.code);
        }
      }
      // 本地记账：扣积分 + 权益入库
      await PointsService.addPoints('exchange', 0, `碳普惠兑换：${benefit.name}`, -benefit.cost);
      deducted = true;
      const ent: Entitlement = {
        name: benefit.name,
        icon: benefit.icon,
        time: Date.now(),
        from: InclusiveService.remoteMode ? '城市碳普惠平台' : '内置模拟平台'
      };
      await InclusiveService.saveEntitlement(ent);
    } catch (e) {
      // 积分已扣但权益没落库时把积分补回去，避免"扣了分却没拿到东西"
      if (deducted) {
        try {
          await PointsService.addPoints('exchange', 0, `兑换回滚：${benefit.name}`, benefit.cost);
        } catch (e2) {
          // 补回失败只能记日志，不掩盖原始错误
        }
      }
      // 平台请求或本地记账失败时把先前扣掉的模拟库存还回去，避免"没兑成功却少了一件"
      if (localStock) {
        const cur = InclusiveService.stockMap.get(benefit.id);
        if (cur !== undefined) {
          InclusiveService.stockMap.set(benefit.id, cur + 1);
        }
      }
      throw e as Error;
    }
  }

  static async listEntitlements(): Promise<Entitlement[]> {
    try {
      const ctx = AppInit.getContext();
      const store = await preferences.getPreferences(ctx, 'entitlements');
      const v = await store.get('list', '[]');
      return JSON.parse(v as string) as Entitlement[];
    } catch (e) {
      return [];
    }
  }

  private static async saveEntitlement(ent: Entitlement): Promise<void> {
    const list = await InclusiveService.listEntitlements();
    list.unshift(ent);
    const ctx = AppInit.getContext();
    const store = await preferences.getPreferences(ctx, 'entitlements');
    await store.put('list', JSON.stringify(list));
    await store.flush();
  }

  /** 内置 Mock 权益池（对照真实碳普惠平台的权益形态） */
  private static mockBenefits(): Benefit[] {
    const file: BenefitFile = {
      benefits: [
        { id: 'mock_bus', name: '公交电子券（2次）', icon: '乘', cost: 100, stock: 999, desc: '城市公交 2 次免费乘坐' },
        { id: 'mock_metro', name: '地铁 5 折券', icon: '铁', cost: 150, stock: 999, desc: '地铁乘车 5 折优惠 1 次' },
        { id: 'mock_bag', name: '环保帆布袋', icon: '袋', cost: 200, stock: 999, desc: '可降解棉帆布购物袋 1 个' },
        { id: 'mock_seed', name: '云认养树苗', icon: '苗', cost: 500, stock: 999, desc: '认养沙棘树苗 1 株，获电子证书' },
        { id: 'mock_coffee', name: '自带杯咖啡券', icon: '饮', cost: 300, stock: 999, desc: '合作咖啡店自带杯减免券' },
        { id: 'mock_ticket', name: '植物园门票 8 折', icon: '园', cost: 400, stock: 999, desc: '城市植物园门票 8 折优惠' }
      ]
    };
    return file.benefits;
  }
}
