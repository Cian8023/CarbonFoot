import { BehaviorCategory, SubType } from '../model/Models';
import { Theme } from '../common/Theme';

@Component
export struct BehaviorPicker {
  @Prop categories: BehaviorCategory[] = [];
  @Link selType: string;
  @Link selSub: string;
  @State catIndex: number = 0;

  aboutToAppear(): void {
    this.syncCatIndex();
  }

  private syncCatIndex(): void {
    for (let i = 0; i < this.categories.length; i++) {
      if (this.categories[i].name === this.selType) {
        this.catIndex = i;
        break;
      }
    }
  }

  private subList(): SubType[] {
    this.syncCatIndex();
    if (this.catIndex < 0 || this.catIndex >= this.categories.length) {
      return [];
    }
    return this.categories[this.catIndex].subTypes;
  }

  build() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        ForEach(this.categories, (cat: BehaviorCategory, idx: number) => {
          Text(cat.name)
            .fontSize(14)
            .fontColor(idx === this.catIndex ? '#FFFFFF' : Theme.TEXT)
            .backgroundColor(idx === this.catIndex ? Theme.PRIMARY : Theme.CARD)
            .borderRadius(18)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => {
              this.catIndex = idx;
              this.selType = this.categories[idx].name;
              if (this.subList().length > 0) {
                this.selSub = this.subList()[0].name;
              }
            })
        }, (cat: BehaviorCategory) => cat.name)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
        ForEach(this.subList(), (sub: SubType) => {
          Text(sub.name)
            .fontSize(13)
            .fontColor(this.selSub === sub.name && this.selType === this.categories[this.catIndex].name
              ? '#FFFFFF' : Theme.TEXT)
            .width('23%')
            .margin({ right: '2.6%', bottom: 8 })
            .padding({ top: 12, bottom: 12 })
            .textAlign(TextAlign.Center)
            .borderRadius(10)
            .backgroundColor(this.selSub === sub.name && this.selType === this.categories[this.catIndex].name
              ? Theme.PRIMARY : Theme.CARD)
            .border({ width: 1, color: this.selSub === sub.name && this.selType === this.categories[this.catIndex].name
              ? Theme.PRIMARY : Theme.DIVIDER })
            .onClick(() => {
              this.selType = this.categories[this.catIndex].name;
              this.selSub = sub.name;
            })
        }, (sub: SubType) => sub.name)
      }
      .width('100%')
    }
    .width('100%')
  }
}
