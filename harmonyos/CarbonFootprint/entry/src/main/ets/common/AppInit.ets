/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import common from '@ohos.app.ability.common';
import { DBHelper } from '../db/DBHelper';
import { SeedService } from '../service/SeedService';
import { CalculationService } from '../service/CalculationService';
import { KnowledgeService } from '../service/KnowledgeService';

/**
 * 应用初始化器：EntryAbility 启动时 bootstrap，页面通过 ensure() 等待初始化完成（幂等）。
 */
export class AppInit {
  private static context: common.UIAbilityContext | null = null;
  private static initPromise: Promise<void> | null = null;

  static bootstrap(context: common.UIAbilityContext): void {
    AppInit.context = context;
    AppStorage.setOrCreate('mainTab', 0);
    AppStorage.setOrCreate('tasksSegment', 0);
    AppStorage.setOrCreate('tick', 0);
  }

  static getContext(): common.UIAbilityContext {
    if (AppInit.context === null) {
      throw new Error('AppInit not bootstrapped');
    }
    return AppInit.context;
  }

  static ensure(): Promise<void> {
    if (AppInit.initPromise === null) {
      const ctx = AppInit.getContext();
      AppInit.initPromise = (async (): Promise<void> => {
        await DBHelper.init(ctx);
        await SeedService.seed(ctx);
        await CalculationService.init(ctx);
        await KnowledgeService.init(ctx);
      })();
    }
    return AppInit.initPromise;
  }
}
