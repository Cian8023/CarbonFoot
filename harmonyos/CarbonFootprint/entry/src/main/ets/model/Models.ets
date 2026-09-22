export interface SubType {
  name: string;
  unit: string;
  /** 每单位减排量（克 CO₂e） */
  factor: number;
  /** 单次录入上限 */
  max: number;
  note?: string;
}

export interface BehaviorCategory {
  name: string;
  icon: string;
  subTypes: SubType[];
}

export interface BehaviorRecord {
  id: number;
  type: string;
  subType: string;
  value: number;
  unit: string;
  factor: number;
  /** 减排量（克 CO₂e） */
  reductionG: number;
  /** 时间戳（毫秒） */
  createdAt: number;
  note: string;
}

export interface PointsRecord {
  id: number;
  source: string;
  refId: number;
  action: string;
  points: number;
  balanceAfter: number;
  createdAt: number;
}

export interface TaskCheck {
  subTypes: string[];
  target: number;
  unit: string;
  /** sum: 按数值累加；count: 按记录笔数 */
  matchType: string;
}

export interface TaskDef {
  id: number;
  code: string;
  title: string;
  description: string;
  points: number;
  /** daily / weekly */
  period: string;
  checkJson: string;
  enabled: boolean;
}

export interface TaskProgress {
  task: TaskDef;
  progress: number;
  target: number;
  done: boolean;
}

export interface BadgeDef {
  id: number;
  code: string;
  name: string;
  icon: string;
  conditionType: string;
  conditionValue: number;
  description: string;
  unlocked: boolean;
  unlockedAt: number;
}

export interface Article {
  id: number;
  title: string;
  category: string;
  icon: string;
  summary: string;
  paragraphs: string[];
}

export interface SubmitResult {
  recordId: number;
  grams: number;
  points: number;
  newBadges: string[];
}

/** 积分来源中文映射 */
export function sourceLabel(source: string): string {
  if (source === 'behavior') {
    return '低碳行为';
  } else if (source === 'task') {
    return '任务奖励';
  } else if (source === 'read') {
    return '阅读奖励';
  } else if (source === 'exchange') {
    return '积分兑换';
  }
  return '其他';
}
