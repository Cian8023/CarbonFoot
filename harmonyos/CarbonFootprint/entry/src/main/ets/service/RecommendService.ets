import { BehaviorRepo, TaskCheckUtil } from '../db/Repository';
import { TaskService } from './TaskService';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorRecord, TaskProgress } from '../model/Models';

export interface Suggestion {
  title: string;
  detail: string;
}

interface ScoredTask {
  progress: TaskProgress;
  score: number;
}

/**
 * 智能服务（创新拓展 4）：基于用户历史行为数据做个性化任务推荐与生活建议。
 * 规则引擎：统计近 14 天各子类型的频次与减排量，
 *  - 高频强项 -> 推荐加码挑战（保持习惯）
 *  - 低频弱项 -> 推荐补短任务（引导养成）
 */
export class RecommendService {
  /** 个性化任务推荐：返回排序后的任务进度列表（强项任务在前） */
  static async recommendTasks(): Promise<TaskProgress[]> {
    const all: TaskProgress[] = await TaskService.listProgress();
    const records = await RecommendService.recentRecords(14);
    const score = await RecommendService.subTypeScores(records);
    const scored: ScoredTask[] = [];
    for (const p of all) {
      if (p.done) {
        continue;
      }
      const check = TaskCheckUtil.parse(p.task.checkJson);
      let s = 0;
      for (const st of check.subTypes) {
        s += score.get(st) !== undefined ? score.get(st) as number : 0;
      }
      const item: ScoredTask = { progress: p, score: s };
      scored.push(item);
    }
    scored.sort((a: ScoredTask, b: ScoredTask) => b.score - a.score);
    const top: TaskProgress[] = [];
    for (let i = 0; i < scored.length && i < 3; i++) {
      top.push(scored[i].progress);
    }
    return top;
  }

  /** 生活建议：强项鼓励 + 弱项引导 */
  static async suggestions(): Promise<Suggestion[]> {
    const records = await RecommendService.recentRecords(14);
    const scores = await RecommendService.subTypeScores(records);
    const out: Suggestion[] = [];

    // 找强项与弱项
    let bestKey = '';
    let bestV = -1;
    let weakKey = '';
    let weakV = Number.MAX_VALUE;
    const keys: string[] = [];
    scores.forEach((v: number, k: string) => {
      keys.push(k);
      if (v > bestV) {
        bestV = v;
        bestKey = k;
      }
      if (v >= 0 && v < weakV) {
        weakV = v;
        weakKey = k;
      }
    });

    const tips: Record<string, string> = {
      '骑行': '你的骑行频率很高，保持每周 3 次以上，一年可减排约 300kg！',
      '步行': '步行是你的强项，试试把 3 公里内的出行都换成步行。',
      '公交': '公交出行记录不错，通勤日坚持公交 + 地铁组合更低碳。',
      '地铁': '地铁是长距离出行的最优解，继续保持！',
      '拼车': '可以尝试和同事拼车通勤，分摊排放更环保。',
      '节水': '节水习惯已养成，洗菜水冲厕、淘米水浇花都是好方法。',
      '节电': '节电表现稳定，夏天空调调高 1℃ 还能再进一步。',
      '关空调': '适度少用空调既减排又健康，早晚开窗通风替代。',
      '纸类': '纸类回收做得好，快递纸箱别忘压扁投放。',
      '塑料': '塑料回收有基础，自带购物袋能从源头减塑。',
      '玻璃': '玻璃瓶可以重复利用，也可以投入可回收物分类。',
      '衣物': '旧衣物捐赠或回收，每公斤可减排 3.3kg！',
      '电子': '闲置电子产品别闲置，正规渠道回收价值高。',
      '早餐': '光盘从早餐开始，好习惯！',
      '午餐': '午餐光盘记录稳定，按需点餐继续坚持。',
      '晚餐': '晚餐光盘还可以更多，试试少量多次盛取。',
      '私家车': '你的私家车出行占比较高，短途试试骑行或公交替代。'
    };

    if (bestKey !== '' && tips[bestKey] !== undefined) {
      const s1: Suggestion = {
        title: `强项保持：${bestKey}`,
        detail: tips[bestKey]
      };
      out.push(s1);
    }
    if (weakKey !== '' && weakKey !== bestKey && tips[weakKey] !== undefined) {
      const s2: Suggestion = {
        title: `潜力提升：${weakKey}`,
        detail: `近 14 天你的「${weakKey}」记录较少。${tips[weakKey]}`
      };
      out.push(s2);
    }
    if (records.length === 0) {
      const s3: Suggestion = {
        title: '从第一笔记录开始',
        detail: '先记录一次步行或光盘行动，我会根据你的习惯给出专属建议。'
      };
      out.push(s3);
    }
    return out;
  }

  /** 子类型活跃度评分：近 N 天记录笔数加权减排量 */
  private static async subTypeScores(records: BehaviorRecord[]): Promise<Map<string, number>> {
    const scores = new Map<string, number>();
    for (const r of records) {
      const prev = scores.get(r.subType);
      const v = (prev !== undefined ? prev : 0) + 1 + r.reductionG / 1000;
      scores.set(r.subType, v);
    }
    return scores;
  }

  private static async recentRecords(days: number): Promise<BehaviorRecord[]> {
    const start = DateUtil.startOfDay(Date.now()) - (days - 1) * DateUtil.DAY_MS;
    return await BehaviorRepo.query(start, Date.now() + DateUtil.DAY_MS, '全部');
  }
}
