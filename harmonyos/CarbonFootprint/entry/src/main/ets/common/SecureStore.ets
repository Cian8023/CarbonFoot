import asset from '@ohos.security.asset';
import util from '@ohos.util';

/**
 * API Key 安全存储：优先用 Asset Store Kit（系统级加密存储）。
 * 不可用时返回失败，由调用方回退到 preferences（功能可用但安全性降低）。
 */
export class SecureStore {
  private static readonly ALIAS: string = 'carbon_ai_api_key';
  /** 写入失败过一次就不再重试，避免每次读 Key 都卡在不可用的 Asset 上 */
  private static unavailable: boolean = false;

  private static toBytes(s: string): Uint8Array {
    return new util.TextEncoder().encodeInto(s);
  }

  private static fromBytes(b: Uint8Array): string {
    return util.TextDecoder.create('utf-8').decodeToString(b);
  }

  /** 写入密钥；返回 true 表示已安全存储 */
  static async save(secret: string): Promise<boolean> {
    if (secret === '') {
      await SecureStore.remove();
      return true;
    }
    if (SecureStore.unavailable) {
      return false;
    }
    try {
      const attr: asset.AssetMap = new Map();
      attr.set(asset.Tag.SECRET, SecureStore.toBytes(secret));
      attr.set(asset.Tag.ALIAS, SecureStore.toBytes(SecureStore.ALIAS));
      attr.set(asset.Tag.ACCESSIBILITY, asset.Accessibility.DEVICE_POWERED_ON);
      try {
        await asset.add(attr);
      } catch (e) {
        // 已存在则改为更新
        const q: asset.AssetMap = new Map();
        q.set(asset.Tag.ALIAS, SecureStore.toBytes(SecureStore.ALIAS));
        const upd: asset.AssetMap = new Map();
        upd.set(asset.Tag.SECRET, SecureStore.toBytes(secret));
        await asset.update(q, upd);
      }
      return true;
    } catch (e) {
      SecureStore.unavailable = true;
      return false;
    }
  }

  /** 读取密钥；返回空串表示未存或安全存储不可用 */
  static async load(): Promise<string> {
    if (SecureStore.unavailable) {
      return '';
    }
    try {
      const q: asset.AssetMap = new Map();
      q.set(asset.Tag.ALIAS, SecureStore.toBytes(SecureStore.ALIAS));
      q.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL);
      const res = await asset.query(q);
      if (res.length === 0) {
        return '';
      }
      const v = res[0].get(asset.Tag.SECRET);
      if (v instanceof Uint8Array) {
        return SecureStore.fromBytes(v);
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static async remove(): Promise<void> {
    try {
      const q: asset.AssetMap = new Map();
      q.set(asset.Tag.ALIAS, SecureStore.toBytes(SecureStore.ALIAS));
      await asset.remove(q);
    } catch (e) {
      // 不存在时忽略
    }
  }
}
