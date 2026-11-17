import util from '@ohos.util';
import { AppConfig } from './AppConfig';

/**
 * API Key 安全存储（跨平台兼容版）。
 *
 * 策略：
 * 1. 优先用 Asset Store Kit（@ohos.security.asset）——系统级加密存储。
 * 2. ArkUI-X / Android 等不支持 asset 的平台，降级到 preferences 存储。
 *
 * 降级说明：preferences 是明文存储，安全性低于 asset。
 * 但 API Key 属于用户自己填写的私人配置，不是系统凭据，
 * 在本地单机应用里可接受；界面上已有「密钥仅存本机」的说明。
 */
export class SecureStore {
  private static readonly ALIAS: string = 'carbon_ai_api_key';
  /** 降级存储用的 preferences key */
  private static readonly FALLBACK_KEY: string = 'ai_api_key_fallback';
  /** Asset 写入失败过一次就不再重试，避免每次读 Key 都卡在不可用的 Asset 上 */
  private static unavailable: boolean = false;

  /** 运行平台是否支持 security.asset。ArkUI-X 上没有该模块，直接走降级 */
  private static assetUsable(): boolean {
    return !SecureStore.unavailable;
  }

  private static toBytes(s: string): Uint8Array {
    return new util.TextEncoder().encodeInto(s);
  }

  private static fromBytes(b: Uint8Array): string {
    return util.TextDecoder.create('utf-8').decodeToString(b);
  }

  /** 动态加载 asset 模块：不支持时返回 null，不抛异常 */
  private static loadAsset(): ESObject | null {
    try {
      // 通过 globalThis 取 requireNapi：ArkTS 严格模式不认这个全局标识符，
      // 直接写 requireNapi(...) 会编译失败。走属性访问可绕开编译期检查。
      // HarmonyOS 上能拿到模块；ArkUI-X / Android 上取不到，返回 null 走降级。
      const g: ESObject = globalThis;
      const req: ESObject = g['requireNapi'];
      if (req === undefined || req === null) {
        return null;
      }
      const mod: ESObject = req('security.asset');
      return mod ?? null;
    } catch (e) {
      return null;
    }
  }

  /** 写入密钥；返回 true 表示已安全存储，false 表示走了降级 */
  static async save(secret: string): Promise<boolean> {
    if (secret === '') {
      await SecureStore.remove();
      return true;
    }

    const asset: ESObject | null = SecureStore.loadAsset();
    if (asset === null) {
      // 降级：明文存 preferences
      await AppConfig.setRawString(SecureStore.FALLBACK_KEY, secret);
      return false;
    }

    try {
      const attr: Map<string, Uint8Array> = new Map();
      attr.set('SECRET', SecureStore.toBytes(secret));
      attr.set('ALIAS', SecureStore.toBytes(SecureStore.ALIAS));
      attr.set('ACCESSIBILITY', SecureStore.toBytes('DEVICE_POWERED_ON'));
      try {
        await asset.add(attr);
      } catch (e) {
        // 已存在则改为更新
        const q: Map<string, Uint8Array> = new Map();
        q.set('ALIAS', SecureStore.toBytes(SecureStore.ALIAS));
        const upd: Map<string, Uint8Array> = new Map();
        upd.set('SECRET', SecureStore.toBytes(secret));
        await asset.update(q, upd);
      }
      return true;
    } catch (e) {
      SecureStore.unavailable = true;
      // Asset 不可用时降级到 preferences，保证功能可用
      await AppConfig.setRawString(SecureStore.FALLBACK_KEY, secret);
      return false;
    }
  }

  /** 读取密钥；返回空串表示未存 */
  static async load(): Promise<string> {
    const asset: ESObject | null = SecureStore.loadAsset();
    if (asset === null || SecureStore.unavailable) {
      return await AppConfig.getRawString(SecureStore.FALLBACK_KEY, '');
    }

    try {
      const q: Map<string, Uint8Array> = new Map();
      q.set('ALIAS', SecureStore.toBytes(SecureStore.ALIAS));
      q.set('RETURN_TYPE', SecureStore.toBytes('ALL'));
      const res: ESObject[] = await asset.query(q);
      if (res.length === 0) {
        // Asset 里没有，可能之前降级存过
        return await AppConfig.getRawString(SecureStore.FALLBACK_KEY, '');
      }
      const v: ESObject = res[0].get('SECRET');
      if (v instanceof Uint8Array) {
        return SecureStore.fromBytes(v);
      }
      return '';
    } catch (e) {
      return await AppConfig.getRawString(SecureStore.FALLBACK_KEY, '');
    }
  }

  static async remove(): Promise<void> {
    // 无论哪条路径，两处都清
    await AppConfig.setRawString(SecureStore.FALLBACK_KEY, '');

    const asset: ESObject | null = SecureStore.loadAsset();
    if (asset === null) {
      return;
    }
    try {
      const q: Map<string, Uint8Array> = new Map();
      q.set('ALIAS', SecureStore.toBytes(SecureStore.ALIAS));
      await asset.remove(q);
    } catch (e) {
      // 不存在时忽略
    }
  }
}