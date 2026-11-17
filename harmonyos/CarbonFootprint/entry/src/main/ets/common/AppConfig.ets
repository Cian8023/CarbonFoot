/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import preferences from '@ohos.data.preferences';
import { AppInit } from './AppInit';
import { SecureStore } from './SecureStore';

const STORE_NAME: string = 'app_config';

/**
 * 应用配置中心：网络服务地址、AI 密钥等可配置项，统一走 preferences 持久化。
 */
export class AppConfig {
  private static async getStore(): Promise<preferences.Preferences> {
    const ctx = AppInit.getContext();
    return await preferences.getPreferences(ctx, STORE_NAME);
  }

  private static async getString(key: string, def: string): Promise<string> {
    try {
      const store = await AppConfig.getStore();
      const v = await store.get(key, def);
      return v as string;
    } catch (e) {
      return def;
    }
  }

  private static async setString(key: string, value: string): Promise<void> {
    const store = await AppConfig.getStore();
    await store.put(key, value);
    await store.flush();
  }

  /**
   * AI 视觉识别：OpenAI 兼容接口地址。
   * 默认值用 DeepSeek 官方端点，模型名默认 deepseek-flash。
   * deepseek-flash（DeepSeek V4.1 Flash）是原生多模态，支持图片输入；
   * 而早期的 deepseek-chat / deepseek-reasoner 是纯文本模型，
   * 收到图片参数会直接报错——换模型时务必确认它支不支持图像。
   */
  static getAiBaseUrl(): Promise<string> {
    return AppConfig.getString('ai_base_url', 'https://api.deepseek.com/v1/chat/completions');
  }

  static setAiBaseUrl(v: string): Promise<void> {
    return AppConfig.setString('ai_base_url', v);
  }

  /** AI 模型名（默认 deepseek-flash，原生多模态） */
  static getAiModel(): Promise<string> {
    return AppConfig.getString('ai_model', 'deepseek-flash');
  }

  static setAiModel(v: string): Promise<void> {
    return AppConfig.setString('ai_model', v);
  }

  /** AI API Key（空 = 不启用在线识别） */
  /** AI API Key：优先读安全存储（Asset Store），旧版存在 preferences 的自动迁移 */
  static async getAiApiKey(): Promise<string> {
    const secure = await SecureStore.load();
    if (secure !== '') {
      return secure;
    }
    const legacy = await AppConfig.getString('ai_api_key', '');
    if (legacy !== '') {
      const ok = await SecureStore.save(legacy);
      if (ok) {
        await AppConfig.setString('ai_api_key', '');
      }
    }
    return legacy;
  }

  /** 写入 API Key：安全存储成功则清掉明文副本；不可用时退回 preferences */
  static async setAiApiKey(v: string): Promise<void> {
    const ok = await SecureStore.save(v);
    if (ok) {
      await AppConfig.setString('ai_api_key', '');
    } else {
      await AppConfig.setString('ai_api_key', v);
    }
  }

  /** 城市碳普惠平台地址（不可达 = 使用内置 Mock 模式） */
  static getInclusiveBaseUrl(): Promise<string> {
    return AppConfig.getString('inclusive_base_url', 'http://127.0.0.1:8080');
  }

  static setInclusiveBaseUrl(v: string): Promise<void> {
    return AppConfig.setString('inclusive_base_url', v);
  }

  /** 家庭同步服务地址（空 = 自动尝试 10.0.2.2 / 127.0.0.1 的 8081 端口） */
  static getSyncBaseUrl(): Promise<string> {
    return AppConfig.getString('sync_base_url', '');
  }

  static setSyncBaseUrl(v: string): Promise<void> {
    return AppConfig.setString('sync_base_url', v);
  }
}
