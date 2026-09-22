import preferences from '@ohos.data.preferences';
import { AppInit } from './AppInit';

const STORE_NAME: string = 'user_prefs';
const KEY_NICKNAME: string = 'nickname';
const KEY_CERT_DATE: string = 'cert_date';

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
}
