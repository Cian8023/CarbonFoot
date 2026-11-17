/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import preferences from '@ohos.data.preferences';
import { AppInit } from './AppInit';

/** 桌面卡片所需的数据快照 */
export interface CardData {
  /** 今日减排（克） */
  todayG: number;
  /** 本月目标完成度（0-100 整数） */
  monthPct: number;
  /** 连续打卡天数 */
  streak: number;
  /** 当前碳积分余额 */
  balance: number;
  updatedAt: number;
}

/**
 * 卡片快照。
 *
 * 桌面卡片运行在 FormExtensionAbility 里，直接查数据库需要自己初始化连接，
 * 且卡片渲染有严格的时间限制。这里改成"主应用算好、写一份快照、卡片只读快照"，
 * 两边彻底解耦：应用内数据一变就刷新快照，卡片下次渲染拿到的就是新值。
 */
export class CardSnapshot {
  static readonly STORE: string = 'card_snapshot';
  static readonly KEY: string = 'data';
  /** 上次写入的业务值，避免每次全局刷新都重复写盘 */
  private static lastKey: string = '';

  static async save(d: CardData): Promise<void> {
    const key = `${d.todayG}|${d.monthPct}|${d.streak}|${d.balance}`;
    if (key === CardSnapshot.lastKey) {
      return;
    }
    CardSnapshot.lastKey = key;
    try {
      const ctx = AppInit.getContext();
      const store = await preferences.getPreferences(ctx, CardSnapshot.STORE);
      await store.put(CardSnapshot.KEY, JSON.stringify(d));
      await store.flush();
    } catch (e) {
      // 快照写入失败不影响主流程，卡片继续显示上一次的数据
    }
  }
}
