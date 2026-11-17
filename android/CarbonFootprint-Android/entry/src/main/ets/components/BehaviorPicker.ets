/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import { BehaviorCategory, SubType } from '../model/Models';
import { Theme } from '../common/Theme';

@Component
export struct BehaviorPicker {
  @Prop categories: BehaviorCategory[] = [];
  @Link selType: string;
  @Link selSub: string;

  /** 由 selType 派生子类型列表，不在构建期改状态 */
  private subList(): SubType[] {
    for (const cat of this.categories) {
      if (cat.name === this.selType) {
        return cat.subTypes;
      }
    }
    return [];
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        ForEach(this.categories, (cat: BehaviorCategory) => {
          Text(cat.name)
            .fontSize(Theme.FS_CONTENT)
            .fontColor(cat.name === this.selType ? '#FFFFFF' : Theme.TEXT)
            .backgroundColor(cat.name === this.selType ? Theme.PRIMARY : Theme.BG_GRAY)
            .borderRadius(18)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => {
              this.selType = cat.name;
              const subs = this.subList();
              if (subs.length > 0) {
                this.selSub = subs[0].name;
              }
            })
        }, (cat: BehaviorCategory) => cat.name)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.subList(), (sub: SubType) => {
          Text(sub.name)
            .fontSize(Theme.FS_BODY)
            .fontColor(this.selSub === sub.name ? '#FFFFFF' : Theme.TEXT)
            .width('23.5%')
            .margin({ right: '1.5%', bottom: 8 })
            .padding({ top: 12, bottom: 12 })
            .textAlign(TextAlign.Center)
            .borderRadius(12)
            .backgroundColor(this.selSub === sub.name ? Theme.PRIMARY : Theme.BG_GRAY)
            .border({ width: 1, color: this.selSub === sub.name ? Theme.PRIMARY : Theme.BG_GRAY })
            .onClick(() => {
              this.selSub = sub.name;
            })
        }, (sub: SubType) => sub.name)
      }
      .width('100%')
    }
    .width('100%')
  }
}
