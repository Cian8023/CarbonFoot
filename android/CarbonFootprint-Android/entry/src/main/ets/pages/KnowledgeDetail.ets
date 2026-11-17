import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants, bumpTick } from '../common/Constants';
import { Theme } from '../common/Theme';
import { Article } from '../model/Models';
import { KnowledgeService } from '../service/KnowledgeService';
import { PointsService } from '../service/PointsService';
import { BadgeService } from '../service/BadgeService';
import { BadgeUnlockOverlay } from '../components/BadgeUnlock';

@Entry
@Component
struct KnowledgeDetail {
  @StorageProp('statusBarHeightPx') statusBarHeightPx: number = 0;
  @State article: Article | null = null;
  @State reachedEnd: boolean = false;
  @State alreadyRead: boolean = false;
  @State showUnlock: boolean = false;
  @State unlockBadges: string[] = [];

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
      // 阅读路径同样触发徽章检测（如博学环保人），解锁时展示动画
      const newBadges: string[] = await BadgeService.checkAll();
      if (newBadges.length > 0) {
        this.unlockBadges = newBadges;
        this.showUnlock = true;
      }
    } catch (e) {
      promptAction.showToast({ message: '领取失败，请重试' });
    }
  }

  build() {
    Stack() {
    Column({ space: 12 }) {
      Row() {
        Text('←')
          .fontSize(Theme.FS_HERO)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('文章详情')
          .fontSize(Theme.FS_HEAD)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('')
          .width(22)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: px2vp(this.statusBarHeightPx) + 14 })

      if (this.article !== null) {
        Scroll() {
          Column({ space: 16 }) {
            Row({ space: 10 }) {
              Column()
                .width(3)
                .height(44)
                .borderRadius(2)
                .backgroundColor(Theme.PRIMARY_HOVER)
              Column({ space: 6 }) {
                Text((this.article as Article).title)
                  .fontSize(Theme.FS_HERO)
                  .fontWeight(FontWeight.Bold)
                Text(`${(this.article as Article).category} · 双碳科普`)
                  .fontSize(Theme.FS_TERTIARY)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')

            ForEach((this.article as Article).paragraphs, (p: string) => {
              Text(p)
                .fontSize(Theme.FS_TITLE)
                .lineHeight(26)
                .fontColor(Theme.TEXT)
                .width('100%')
            }, (p: string, idx: number) => '' + idx + '_' + p.substring(0, 10))

            Text('— 完 —')
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(Theme.TEXT_TERTIARY)
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

        Button(this.alreadyRead ? '已领取阅读积分' :
          this.reachedEnd ? '完成阅读，领 5 积分' : '继续阅读到底部可领积分…')
          .width('90%')
          .height(44)
          .fontSize(Theme.FS_CONTENT)
          .margin({ bottom: 12 })
          .backgroundColor(this.alreadyRead ? Theme.TEXT_TERTIARY :
            this.reachedEnd ? Theme.PRIMARY : Theme.PRIMARY_HOVER)
          .onClick(() => {
            this.claimReadPoints();
          })

        Text('把文中的技巧变成行动 → 去记录低碳行为')
          .fontSize(Theme.FS_TERTIARY)
          .fontColor(Theme.TEXT_TERTIARY)
          .margin({ bottom: 12 })
          .onClick(() => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
            router.back();
          })
      } else {
        Column({ space: 10 }) {
          Text('未找到该文章')
            .fontSize(Theme.FS_CONTENT)
          Text('文章不存在')
            .fontSize(Theme.FS_CONTENT)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.CARD)

    if (this.showUnlock) {
      BadgeUnlockOverlay({
        badges: this.unlockBadges,
        onClose: (): void => {
          this.showUnlock = false;
        }
      })
    }
    }
  }
}
