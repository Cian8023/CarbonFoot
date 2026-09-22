import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants, bumpTick } from '../common/Constants';
import { Theme } from '../common/Theme';
import { Article } from '../model/Models';
import { KnowledgeService } from '../service/KnowledgeService';
import { PointsService } from '../service/PointsService';

@Entry
@Component
struct KnowledgeDetail {
  @State article: Article | null = null;
  @State reachedEnd: boolean = false;
  @State alreadyRead: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      await AppInit.ensure();
      const params = router.getParams() as Record<string, number>;
      const id = params !== undefined && params['id'] !== undefined ? params['id'] : -1;
      const a = KnowledgeService.byId(id);
      if (a !== undefined) {
        this.article = a;
      }
      this.alreadyRead = await PointsService.hasSourceRef('read', id);
    } catch (e) {
      console.error('KnowledgeDetail load error: ' + JSON.stringify(e));
    }
  }

  private async claimReadPoints(): Promise<void> {
    if (this.article === null) {
      return;
    }
    const a = this.article as Article;
    if (this.alreadyRead) {
      promptAction.showToast({ message: '本文已领取过阅读积分' });
      return;
    }
    if (!this.reachedEnd) {
      promptAction.showToast({ message: '请阅读到文章末尾再领取哦' });
      return;
    }
    try {
      await PointsService.addPoints('read', a.id, `阅读文章：${a.title}`, Constants.READ_POINTS);
      this.alreadyRead = true;
      bumpTick();
      promptAction.showToast({ message: `阅读完成，+${Constants.READ_POINTS} 积分！` });
    } catch (e) {
      promptAction.showToast({ message: '领取失败，请重试' });
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('文章详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('')
          .width(22)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14 })

      if (this.article !== null) {
        Scroll() {
          Column({ space: 16 }) {
            Row({ space: 10 }) {
              Text((this.article as Article).icon)
                .fontSize(34)
              Column({ space: 6 }) {
                Text((this.article as Article).title)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                Text(`${(this.article as Article).category} · 双碳科普`)
                  .fontSize(12)
                  .fontColor(Theme.TEXT_SUB)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            ForEach((this.article as Article).paragraphs, (p: string) => {
              Text(p)
                .fontSize(15)
                .lineHeight(26)
                .fontColor(Theme.TEXT)
                .width('100%')
            }, (p: string, idx: number) => '' + idx + '_' + p.substring(0, 10))

            Text('— 完 —')
              .fontSize(12)
              .fontColor(Theme.TEXT_SUB)
              .margin({ top: 10 })
          }
          .width('100%')
          .padding(16)
        }
        .scrollBar(BarState.Auto)
        .layoutWeight(1)
        .onReachEnd(() => {
          this.reachedEnd = true;
        })

        Button(this.alreadyRead ? '已领取阅读积分 ✓' :
          this.reachedEnd ? '完成阅读，领 5 积分' : '继续阅读到底部可领积分…')
          .width('90%')
          .height(44)
          .fontSize(14)
          .margin({ bottom: 12 })
          .backgroundColor(this.alreadyRead ? Theme.TEXT_SUB :
            this.reachedEnd ? Theme.PRIMARY : Theme.PRIMARY_LIGHT)
          .onClick(() => {
            this.claimReadPoints();
          })
      } else {
        Column({ space: 10 }) {
          Text('😕')
            .fontSize(48)
          Text('文章不存在')
            .fontSize(14)
            .fontColor(Theme.TEXT_SUB)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.CARD)
  }
}
