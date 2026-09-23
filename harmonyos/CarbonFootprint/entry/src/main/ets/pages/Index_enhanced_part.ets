  @Builder
  statCard() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(Theme.R_MEDIUM)
        .linearGradient({
          angle: 135,
          colors: [[0xE8FFEA, 0.0], [0xFFFFFF, 0.6], [0xFFFFFF, 1.0]]
        })
      
      Column({ space: 16 }) {
        Row() {
          Text('🌱')
            .fontSize(20)
          Text('今日碳足迹')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.TEXT)
            .margin({ left: 6 })
          Blank()
          Text(DateUtil.formatYMD(Date.now()))
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')
        
        Row() {
          Column({ space: 8 }) {
            Text('减排量')
              .fontSize(12)
              .fontColor(Theme.TEXT_SECONDARY)
            Row({ space: 6 }) {
              Text(DateUtil.gramsToKg(this.todayG))
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.PRIMARY)
              Column({ space: 2 }) {
                Text('kg')
                  .fontSize(14)
                  .fontColor(Theme.TEXT_TERTIARY)
                Text('CO₂e')
                  .fontSize(11)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .margin({ bottom: 8 })
              .alignItems(HorizontalAlign.Start)
            }
            .alignItems(VerticalAlign.Bottom)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Column({ space: 12 }) {
            Row({ space: 8 }) {
              Circle({ width: 8, height: 8 }).fill(Theme.PRIMARY).opacity(0.6)
              Column({ space: 2 }) {
                Text(`${this.streak}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.TEXT)
                Text('连续天')
                  .fontSize(10)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
            }
            Row({ space: 8 }) {
              Circle({ width: 8, height: 8 }).fill(Theme.POINTS).opacity(0.6)
              Column({ space: 2 }) {
                Text(`${this.balance}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.TEXT)
                Text('碳积分')
                  .fontSize(10)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
            }
            Row({ space: 8 }) {
              Circle({ width: 8, height: 8 }).fill(Theme.INFO).opacity(0.6)
              Column({ space: 2 }) {
                Text(`${this.pending}`)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.TEXT)
                Text('待完成')
                  .fontSize(10)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
            }
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height(180)
  }
