import preferences from '@ohos.data.preferences';
import { AppInit } from './AppInit';

const STORE_NAME: string = 'user_prefs';
const KEY_NICKNAME: string = 'nickname';
const KEY_CERT_DATE: string = 'cert_date';
const KEY_MONTH_GOAL_KG: string = 'month_goal_kg';
const KEY_HOME_LAYOUT: string = 'home_layout';

/** 首页可排序卡片的默认顺序 */
export const DEFAULT_HOME_LAYOUT: string[] = ['goal', 'quick', 'trend', 'pie', 'weekly', 'rec', 'tasks'];

export class PrefsService {
  private static async getStore(): Promise<preferences.Preferences> {
    const ctx = AppInit.getContext();
    return await preferences.getPreferences(ctx, STORE_NAME);
  }

  static async getNickname(): Promise<string> {
    try {
      const store = await PrefsService.getStore();
      const v = await store.get(KEY_NICKNAME, '绿色生活家');
      return v as string;
    } catch (e) {
      return '绿色生活家';
    }
  }

  static async setNickname(name: string): Promise<void> {
    const store = await PrefsService.getStore();
    await store.put(KEY_NICKNAME, name);
    await store.flush();
  }

  /** 植树证书兑换时间，0 表示未兑换 */
  static async getCertDate(): Promise<number> {
    try {
      const store = await PrefsService.getStore();
      const v = await store.get(KEY_CERT_DATE, 0);
      return v as number;
    } catch (e) {
      return 0;
    }
  }

  static async setCertDate(ts: number): Promise<void> {
    const store = await PrefsService.getStore();
    await store.put(KEY_CERT_DATE, ts);
    await store.flush();
  }

  /** 本月减排目标（kg），默认 30kg */
  static async getMonthlyGoalKg(): Promise<number> {
    try {
      const store = await PrefsService.getStore();
      const v = await store.get(KEY_MONTH_GOAL_KG, 30);
      const n = v as number;
      return n > 0 ? n : 30;
    } catch (e) {
      return 30;
    }
  }

  static async setMonthlyGoalKg(kg: number): Promise<void> {
    const store = await PrefsService.getStore();
    await store.put(KEY_MONTH_GOAL_KG, kg);
    await store.flush();
  }

  /** 首页卡片顺序（仅含显示中的卡片），读取时校验并补齐新增卡片 */
  static async getHomeLayout(): Promise<string[]> {
    let saved: string[] = [];
    try {
      const store = await PrefsService.getStore();
      const v = await store.get(KEY_HOME_LAYOUT, '');
      if (v !== '') {
        saved = JSON.parse(v as string) as string[];
      }
    } catch (e) {
      saved = [];
    }
    const valid: string[] = [];
    for (const k of saved) {
      if (DEFAULT_HOME_LAYOUT.indexOf(k) >= 0 && valid.indexOf(k) < 0) {
        valid.push(k);
      }
    }
    for (const k of DEFAULT_HOME_LAYOUT) {
      if (valid.indexOf(k) < 0) {
        valid.push(k);
      }
    }
    return valid;
  }

  static async setHomeLayout(keys: string[]): Promise<void> {
    const store = await PrefsService.getStore();
    await store.put(KEY_HOME_LAYOUT, JSON.stringify(keys));
    await store.flush();
  }

  static homeCardTitle(key: string): string {
    if (key === 'goal') {
      return '本月目标环';
    } else if (key === 'quick') {
      return '快捷入口';
    } else if (key === 'trend') {
      return '减排趋势图';
    } else if (key === 'pie') {
      return '分类占比图';
    } else if (key === 'weekly') {
      return '减排周报';
    } else if (key === 'rec') {
      return '智能推荐';
    } else if (key === 'tasks') {
      return '待完成任务';
    }
    return key;
  }
}
