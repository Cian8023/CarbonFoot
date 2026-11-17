/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import Want from '@ohos.app.ability.Want';
import preferences from '@ohos.data.preferences';
import { CardSnapshot, CardData } from '../common/CardSnapshot';
import { EcoUtil } from '../utils/EcoUtil';

/**
 * 桌面万能卡片（2×2）。
 *
 * 卡片不直接访问数据库：主应用在数据变化时把今日减排、本月进度、打卡天数
 * 写进 preferences 快照，这里读快照即可。这样卡片冷启动不需要初始化数据库，
 * 也不会因为建表耗时导致卡片白屏。
 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(this.readSnapshot());
  }

  onUpdateForm(formId: string): void {
    this.pushForm(formId);
  }

  private async pushForm(formId: string): Promise<void> {
    try {
      const data = formBindingData.createFormBindingData(this.readSnapshot());
      await formProvider.updateForm(formId, data);
    } catch (e) {
      // 推送失败时交给系统下次定时刷新，不影响卡片已有内容
    }
  }

  /** 读取快照，字段名与卡片侧的 @LocalStorageProp 一一对应 */
  private readSnapshot(): Record<string, Object> {
    const out: Record<string, Object> = {
      'todayKg': '0.00',
      'monthPct': 0,
      'streak': 0,
      'equiv': '今天还没有记录'
    };
    try {
      const store = preferences.getPreferencesSync(this.context, { name: CardSnapshot.STORE });
      const raw = store.getSync(CardSnapshot.KEY, '') as string;
      if (raw !== '') {
        const d = JSON.parse(raw) as CardData;
        out['todayKg'] = (d.todayG / 1000).toFixed(2);
        out['monthPct'] = d.monthPct;
        out['streak'] = d.streak;
        out['equiv'] = d.todayG > 0 ? EcoUtil.dailyText(d.todayG) : '今天还没有记录';
      }
    } catch (e) {
      // 快照缺失或损坏时返回默认值，卡片仍可正常显示
    }
    return out;
  }
}
