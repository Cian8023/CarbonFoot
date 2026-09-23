import router from '@ohos.router';
import { AppInit } from '../common/AppInit';
import { Theme } from '../common/Theme';
import { Article } from '../model/Models';
import { KnowledgeService } from '../service/KnowledgeService';
import { PointsService } from '../service/PointsService';
import { EmptyState } from '../components/EmptyState';

const CATEGORIES: string[] = ['全部', '政策解读', '生活技巧', '行业动态'];

@Entry
@Component
struct Knowledge {
  @State articles: Article[] = [];
  @State category: string = '全部';
  @State readIds: number[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      this.articles = KnowledgeService.list(this.category);
      const ids: number[] = [];
      for (const a of KnowledgeService.list('全部')) {
        if (await PointsService.hasSourceRef('read', a.id)) {
          ids.push(a.id);
        }
      }
      this.readIds = ids;
    } catch (e) {
      console.error('Knowledge refresh error: ' + JSON.stringify(e));
    }
  }

  private isRead(id: number): boolean {
    return this.readIds.indexOf(id) >= 0;
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
        Text('双碳科普专栏')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('')
          .width(22)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14 })

      // 分类筛选
      Row({ space: 8 }) {
        ForEach(CATEGORIES, (c: string) => {
          Text(c)
            .fontSize(12)
            .fontColor(this.category === c ? '#FFFFFF' : Theme.TEXT)
            .backgroundColor(this.category === c ? Theme.PRIMARY : Theme.CARD)
            .borderRadius(14)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onClick(() => {
              this.category = c;
              this.refresh();
            })
        }, (c: string) => c)
        Blank()
      }
      .width('100%')
      .padding({ left: 14, right: 14 })

      List({ space: 10 }) {
        ForEach(this.articles, (a: Article) => {
          ListItem() {
            Row({ space: 12 }) {
              Column()
                .width(3)
                .height(44)
                .borderRadius(2)
                .backgroundColor(Theme.PRIMARY_LIGHT)
              Column({ space: 5 }) {
                Text(a.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .maxLines(2)
                Text(a.summary)
                  .fontSize(12)
                  .fontColor(Theme.TEXT_SUB)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row({ space: 8 }) {
                  Text(a.category)
                    .fontSize(10)
                    .fontColor(Theme.PRIMARY)
                    .backgroundColor(Theme.PRIMARY_BG)
                    .borderRadius(8)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                  if (this.isRead(a.id)) {
                    Text('已读 +5 分')
                      .fontSize(10)
                      .fontColor(Theme.TEXT_SUB)
                  } else {
                    Text('阅读得 5 分 >')
                      .fontSize(10)
                      .fontColor(Theme.POINTS)
                  }
                }
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
            }
            .width('100%')
            .padding(12)
            .borderRadius(Theme.R_ITEM)
            .backgroundColor(Theme.CARD)
            .border({ width: 1, color: Theme.DIVIDER })
            .onClick(() => {
              router.pushUrl({ url: 'pages/KnowledgeDetail', params: { id: a.id } });
            })
          }
        }, (a: Article) => '' + a.id + '_' + (this.isRead(a.id) ? 'r' : 'n'))
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 14, right: 14, bottom: 14 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.BG)
  }
}
