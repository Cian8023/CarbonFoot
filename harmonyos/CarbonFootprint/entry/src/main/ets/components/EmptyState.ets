import { Theme } from '../common/Theme';

@Component
export struct EmptyState {
  @Prop icon: string = '';
  @Prop title: string = '暂无数据';
  @Prop desc: string = '';
  @Prop buttonText: string = '';
  onButton: () => void = () => {};
  @Prop secondaryButtonText: string = '';
  onSecondaryButton: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      if (this.icon !== '') {
        Text(this.icon)
          .fontSize(52)
      }
      Text(this.title)
        .fontSize(Theme.FS_TITLE)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.TEXT)
      if (this.desc !== '') {
        Text(this.desc)
          .fontSize(Theme.FS_BODY)
          .fontColor(Theme.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
      }
      if (this.buttonText !== '' || this.secondaryButtonText !== '') {
        Row({ space: 10 }) {
          if (this.buttonText !== '') {
            Button(this.buttonText)
              .backgroundColor(Theme.PRIMARY)
              .fontSize(Theme.FS_CONTENT)
              .borderWidth(1).borderColor(Theme.CARD_BORDER)
              .layoutWeight(1)
              .onClick(() => {
                this.onButton();
              })
          }
          if (this.secondaryButtonText !== '') {
            Button(this.secondaryButtonText)
              .backgroundColor(Theme.PRIMARY)
              .fontSize(Theme.FS_CONTENT)
              .borderWidth(1).borderColor(Theme.CARD_BORDER)
              .layoutWeight(1)
              .onClick(() => {
                this.onSecondaryButton();
              })
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ top: 48, bottom: 48, left: 24, right: 24 })
  }
}
