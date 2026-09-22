import { Theme } from './Theme';

export class Constants {
  static readonly APP_NAME: string = '碳足迹';
  static readonly VERSION: string = '1.0.0';

  // 每 100g 减排量兑换 1 积分
  static readonly POINTS_PER_100G: number = 1;
  // 阅读完整科普文章奖励积分
  static readonly READ_POINTS: number = 5;
  // 植树证书兑换所需积分
  static readonly CERT_COST: number = 2000;

  // 主页面 Tab 序号
  static readonly TAB_HOME: number = 0;
  static readonly TAB_RECORD: number = 1;
  static readonly TAB_HISTORY: number = 2;
  static readonly TAB_TASKS: number = 3;
  static readonly TAB_MINE: number = 4;

  // AppStorage Key
  static readonly KEY_MAIN_TAB: string = 'mainTab';
  static readonly KEY_TASKS_SEGMENT: string = 'tasksSegment';
  static readonly KEY_TICK: string = 'tick';

  // 饼图各分类固定配色（与 Theme.PIE_COLORS 对应）
  private static readonly CATEGORY_ORDER: string[] = ['出行', '节水节电', '旧物回收', '光盘行动'];

  /** 按大类取饼图配色 */
  static categoryColor(type: string): string {
    const idx = Constants.CATEGORY_ORDER.indexOf(type);
    if (idx >= 0 && idx < Theme.PIE_COLORS.length) {
      return Theme.PIE_COLORS[idx];
    }
    return Theme.PRIMARY_LIGHT;
  }
}

/** 数据变化后调用，各页面监听该事件刷新 */
export function bumpTick(): void {
  AppStorage.setOrCreate(Constants.KEY_TICK, Date.now());
}

/** 跳转到主 Tab 的指定页 */
export function gotoTab(index: number): void {
  AppStorage.setOrCreate(Constants.KEY_MAIN_TAB, index);
}

/** 按大类取图标 */
export function categoryIcon(type: string): string {
  if (type === '出行') {
    return '🚴';
  } else if (type === '节水节电') {
    return '💡';
  } else if (type === '旧物回收') {
    return '♻️';
  } else if (type === '光盘行动') {
    return '🍚';
  }
  return '🌿';
}
