@Component
export struct EmptyState {
  icon: string = '🌱';
  title: string = '暂无数据';
  desc: string = '';
  buttonText: string = '';
  onButton: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text(this.icon)
        .fontSize(52)
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1F2933')
      if (this.desc !== '') {
        Text(this.desc)
          .fontSize(13)
          .fontColor('#7A8B99')
          .textAlign(TextAlign.Center)
      }
      if (this.buttonText !== '') {
        Button(this.buttonText)
          .backgroundColor('#2E7D32')
          .fontSize(14)
          .onClick(() => {
            this.onButton();
          })
      }
    }
    .width('100%')
    .padding({ top: 48, bottom: 48, left: 24, right: 24 })
  }
}
