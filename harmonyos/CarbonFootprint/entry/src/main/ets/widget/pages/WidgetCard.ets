let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('todayKg') todayKg: string = '0.00';
  @LocalStorageProp('monthPct') monthPct: number = 0;
  @LocalStorageProp('streak') streak: number = 0;
  @LocalStorageProp('equiv') equiv: string = '今天还没有记录';

  build() {
    Column() {
      Row() {
        Text('碳足迹')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F6B4F')
        Blank()
        Text('今日减排')
          .fontSize(11)
          .fontColor('#847F72')
      }
      .width('100%')

      Row({ space: 3 }) {
        Text(this.todayKg)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#33312B')
        Text('kg')
          .fontSize(12)
          .fontColor('#847F72')
          .margin({ bottom: 6 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)
      .margin({ top: 4 })

      Text(this.equiv)
        .fontSize(10)
        .fontColor('#847F72')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 2 })

      Stack({ alignContent: Alignment.Start }) {
        Column()
          .width('100%')
          .height(5)
          .borderRadius(3)
          .backgroundColor('#F0EDE4')
        Column()
          .width(this.monthPct + '%')
          .height(5)
          .borderRadius(3)
          .backgroundColor('#2F6B4F')
      }
      .width('100%')
      .margin({ top: 8 })

      Row() {
        Text('本月 ' + this.monthPct + '%')
          .fontSize(10)
          .fontColor('#6E6A5E')
        Blank()
        Text('连续 ' + this.streak + ' 天')
          .fontSize(10)
          .fontColor('#847F72')
      }
      .width('100%')
      .margin({ top: 5 })
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(18)
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: 'EntryAbility',
        params: {
          targetPage: 'pages/Index'
        }
      });
    })
  }
}
