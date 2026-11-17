/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { TaskRepo, BadgeRepo } from '../db/Repository';
import { TaskCheck } from '../model/Models';

interface TaskSeedFile {
  tasks: TaskSeedItem[];
}
interface TaskSeedItem {
  code: string;
  title: string;
  description: string;
  points: number;
  period: string;
  check: TaskCheck;
}
interface BadgeSeedFile {
  badges: BadgeSeedItem[];
}
interface BadgeSeedItem {
  code: string;
  name: string;
  icon: string;
  conditionType: string;
  conditionValue: number;
  description: string;
}

/**
 * 首次启动预置：任务定义、徽章定义（按 code 幂等插入）。
 */
export class SeedService {
  static async seed(context: common.UIAbilityContext): Promise<void> {
    const taskData: Uint8Array = context.resourceManager.getRawFileContentSync('tasks.json');
    const taskText: string = util.TextDecoder.create('utf-8').decodeToString(taskData);
    const tasks = JSON.parse(taskText) as TaskSeedFile;
    for (const t of tasks.tasks) {
      await TaskRepo.insertIfAbsent(t.code, t.title, t.description, t.points, t.period,
        JSON.stringify(t.check));
    }

    const badgeData: Uint8Array = context.resourceManager.getRawFileContentSync('badges.json');
    const badgeText: string = util.TextDecoder.create('utf-8').decodeToString(badgeData);
    const badges = JSON.parse(badgeText) as BadgeSeedFile;
    for (const b of badges.badges) {
      await BadgeRepo.insertIfAbsent(b.code, b.name, b.icon, b.conditionType,
        b.conditionValue, b.description);
    }
  }
}
