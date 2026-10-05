import preferences from "@ohos:data.preferences";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
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
        }
        catch (e) {
            return def;
        }
    }
    private static async setString(key: string, value: string): Promise<void> {
        const store = await AppConfig.getStore();
        await store.put(key, value);
        await store.flush();
    }
    /** AI 视觉识别：OpenAI 兼容接口地址 */
    static getAiBaseUrl(): Promise<string> {
        return AppConfig.getString('ai_base_url', 'https://api.deepseek.com/v1/chat/completions');
    }
    static setAiBaseUrl(v: string): Promise<void> {
        return AppConfig.setString('ai_base_url', v);
    }
    /** AI 模型名 */
    static getAiModel(): Promise<string> {
        return AppConfig.getString('ai_model', 'deepseek-chat');
    }
    static setAiModel(v: string): Promise<void> {
        return AppConfig.setString('ai_model', v);
    }
    /** AI API Key（空 = 使用离线演示识别） */
    static getAiApiKey(): Promise<string> {
        return AppConfig.getString('ai_api_key', '');
    }
    static setAiApiKey(v: string): Promise<void> {
        return AppConfig.setString('ai_api_key', v);
    }
    /** 城市碳普惠平台地址（不可达 = 使用内置 Mock 模式） */
    static getInclusiveBaseUrl(): Promise<string> {
        return AppConfig.getString('inclusive_base_url', 'http://127.0.0.1:8080');
    }
    static setInclusiveBaseUrl(v: string): Promise<void> {
        return AppConfig.setString('inclusive_base_url', v);
    }
}
