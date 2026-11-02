import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { BehaviorCategory, SubType } from '../model/Models';
import { Constants } from '../common/Constants';

interface FactorsFile {
  categories: BehaviorCategory[];
}

/**
 * 低碳行为核算服务：加载内置因子库，按 行为×数值×因子 实时计算减排量（克 CO₂e）。
 */
export class CalculationService {
  private static categories: BehaviorCategory[] = [];

  static async init(context: common.UIAbilityContext): Promise<void> {
    const data: Uint8Array = context.resourceManager.getRawFileContentSync('factors.json');
    const text: string = util.TextDecoder.create('utf-8').decodeToString(data);
    const file = JSON.parse(text) as FactorsFile;
    CalculationService.categories = file.categories;
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
