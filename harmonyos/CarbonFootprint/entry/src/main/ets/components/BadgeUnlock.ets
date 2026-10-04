/**
 * 勋章解锁全屏动画层（借鉴华为运动健康的成就激励）：
 * 金色徽章弹性放大 + 光环扩散 + 徽章名展示，点击任意处关闭。
 * 用法：外层用 if(show) 条件渲染，组件 aboutToAppear 时自动播放动画，关闭走 onClose 回调。
 */
@Component
export struct BadgeUnlockOverlay {
  @Prop badges: string[] = [];
  onClose: () => void = (): void => {
  };
  @State badgeScale: number = 0.2;
  @State glowScale: number = 0.5;
  @State glowOpacity: number = 0;
  @State textOpacity: number = 0;

  aboutToAppear(): void {
    this.badgeScale = 0.2;
    this.glowScale = 0.5;
    this.glowOpacity = 0;
    this.textOpacity = 0;
    // 两段式弹出：过冲 -> 回弹
    animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
      this.badgeScale = 1.18;
      this.glowScale = 1;
      this.glowOpacity = 1;
    });
    setTimeout(() => {
      animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
        this.badgeScale = 1;
      });
      animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
        this.textOpacity = 1;
      });
    }, 280);
  }

  build() {
    Stack() {
      // 半透明遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.6)')
        .onClick(() => {
          this.onClose();
        })

      Column({ space: 14 }) {
        // 光环 + 徽章
        Stack() {
          Circle({ width: 150, height: 150 })
            .fill('#F7BA1E')
            .opacity(0.18 * this.glowOpacity)
            .scale({ x: this.glowScale, y: this.glowScale })
          Circle({ width: 116, height: 116 })
            .fill('#FFF6DC')
            .opacity(this.glowOpacity)
          Circle({ width: 96, height: 96 })
            .fill('#F7BA1E')
            .opacity(0.9 * this.glowOpacity)
          Text('🏅')
            .fontSize(46)
        }
        .scale({ x: this.badgeScale, y: this.badgeScale })

        Column({ space: 6 }) {
          Text('恭喜解锁新徽章')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.badges.join('、'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#F7BA1E')
            .textAlign(TextAlign.Center)
        }
        .opacity(this.textOpacity)

        Text('点击任意处继续')
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.5)')
          .opacity(this.textOpacity)
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
}
