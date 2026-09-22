import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { Article } from '../model/Models';

interface KnowledgeFile {
  articles: Article[];
}

/**
 * 双碳科普服务：从 rawfile/knowledge.json 加载内置文章。
 */
export class KnowledgeService {
  private static articles: Article[] = [];

  static async init(context: common.UIAbilityContext): Promise<void> {
    const data: Uint8Array = context.resourceManager.getRawFileContentSync('knowledge.json');
    const text: string = util.TextDecoder.create('utf-8').decodeToString(data);
    const file = JSON.parse(text) as KnowledgeFile;
    KnowledgeService.articles = file.articles;
  }

  static list(category: string): Article[] {
    if (category === '全部') {
      return KnowledgeService.articles;
    }
    const out: Article[] = [];
    for (const a of KnowledgeService.articles) {
      if (a.category === category) {
        out.push(a);
      }
    }
    return out;
  }

  static byId(id: number): Article | undefined {
    for (const a of KnowledgeService.articles) {
      if (a.id === id) {
        return a;
      }
    }
    return undefined;
  }
}
