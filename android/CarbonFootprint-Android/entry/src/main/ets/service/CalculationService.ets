/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { BehaviorCategory, SubType } from '../model/Models';
import { Constants } from '../common/Constants';

interface FactorsMeta {
  version?: string;
  source?: string;
  disclaimer?: string;
  unit?: string;
}

interface FactorsFile {
  meta?: FactorsMeta;
  categories: BehaviorCategory[];
}

/**
 * 低碳行为核算服务：加载内置因子库，按 行为×数值×因子 实时计算减排量（克 CO₂e）。
 */
export class CalculationService {
  private static categories: BehaviorCategory[] = [];
  private static meta: FactorsMeta = {};

  static async init(context: common.UIAbilityContext): Promise<void> {
    const data: Uint8Array = context.resourceManager.getRawFileContentSync('factors.json');
    const text: string = util.TextDecoder.create('utf-8').decodeToString(data);
    const file = JSON.parse(text) as FactorsFile;
    CalculationService.categories = file.categories;
    CalculationService.meta = file.meta !== undefined ? file.meta : {};
  }

  /** 因子库整体说明（来源与免责声明），用于设置页与详情页脚注 */
  static getMeta(): FactorsMeta {
    return CalculationService.meta;
  }

  static getCategories(): BehaviorCategory[] {
    return CalculationService.categories;
  }

  static findSub(type: string, subType: string): SubType | null {
    for (const cat of CalculationService.categories) {
      if (cat.name !== type) {
        continue;
      }
      for (const sub of cat.subTypes) {
        if (sub.name === subType) {
          return sub;
        }
      }
    }
    return null;
  }

  static getUnit(type: string, subType: string): string {
    const sub = CalculationService.findSub(type, subType);
    return sub !== null ? sub.unit : '';
  }

  /** 减排量（克 CO₂e），参数非法返回 0 */
  static calculate(type: string, subType: string, value: number): number {
    const sub = CalculationService.findSub(type, subType);
    if (sub === null || !isFinite(value) || value <= 0) {
      return 0;
    }
    return Math.round(value * sub.factor);
  }

  /** 减排量 -> 积分 */
  static valueToPoints(grams: number): number {
    if (grams <= 0) {
      return 0;
    }
    return Math.max(Constants.POINTS_PER_100G, Math.floor(grams / (100 / Constants.POINTS_PER_100G)));
  }
}
