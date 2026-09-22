import router from '@ohos.router';
import { AppInit } from '../common/AppInit';
import { Constants, categoryIcon } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BehaviorRecord, TaskProgress } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import { TaskService } from '../service/TaskService';
import { PointsService } from '../service/PointsService';
import { BadgeService } from '../service/BadgeService';
import { StatsService, TrendKind } from '../service/StatsService';
import { DateUtil } from '../utils/DateUtil';
import { LineChart, PieChart, ChartPoint, PieItem } from '../components/Chart';
import { EmptyState } from '../components/EmptyState';
import { RecordView } from './Record';
import { HistoryView } from './History';
import { TasksView } from './Tasks';
import { MineView } from './Settings';

@Entry
@Component
struct Index {
  @StorageLink('mainTab') @Watch('onMainTabChanged') mainTab: number = 0;
  tabsController: TabsController = new TabsController();

  onMainTabChanged(): void {
    // AppStorage 驱动切 Tab（首页快捷入口、提交后跳转等场景）
    this.tabsController.changeIndex(this.mainTab);
  }

  @Builder
  tabItem(label: string, icon: string, index: number) {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(20)
      Text(label)
        .fontSize(10)
        .fontColor(this.mainTab === index ? Theme.PRIMARY : Theme.TEXT_SUB)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.mainTab, controller: this.tabsController }) {
      TabContent() {
        HomeView()
      }
      .tabBar(this.tabItem('首页', '🏠', Constants.TAB_HOME))

      TabContent() {
        RecordView()
      }
      .tabBar(this.tabItem('录入', '✏️', Constants.TAB_RECORD))

      TabContent() {
        HistoryView()
      }
      .tabBar(this.tabItem('历史', '📋', Constants.TAB_HISTORY))

      TabContent() {
        TasksView()
      }
      .tabBar(this.tabItem('任务', '🎯', Constants.TAB_TASKS))

      TabContent() {
        MineView()
      }
      .tabBar(this.tabItem('我的', '👤', Constants.TAB_MINE))
    }
    .scrollable(false)
    .barHeight(56)
    .backgroundColor(Theme.BG)
    .onChange((index: number) => {
      this.mainTab = index;
    })
  }
}

@Component
struct HomeView {
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State loading: boolean = true;
  @State todayG: number = 0;
  @State balance: number = 0;
  @State pending: number = 0;
  @State streak: number = 0;
  @State trendKind: TrendKind = 'day7';
  @State trend: ChartPoint[] = [];
  @State pie: PieItem[] = [];
  @State pendingTasks: TaskProgress[] = [];

  async aboutToAppear(): Promise<void> {
    await this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      const records: BehaviorRecord[] = await BehaviorRepo.all();
      const todayStart = DateUtil.startOfDay(Date.now());
      let todaySum = 0;
      for (const r of records) {
        if (r.createdAt >= todayStart) {
          todaySum += r.reductionG;
        }
      }
      this.todayG = todaySum;
      this.balance = await PointsService.getBalance();
      this.pending = await TaskService.pendingCount();
      this.streak = await BadgeService.currentStreak();
      this.trend = StatsService.trend(records, this.trendKind);
      this.pie = StatsService.categoryShare(records, StatsService.rangeStart(this.trendKind));
      const all = await TaskService.listProgress();
      const top: TaskProgress[] = [];
      for (const p of all) {
        if (!p.done && top.length < 3) {
          top.push(p);
        }
      }
      this.pendingTasks = top;
      this.loading = false;
    } catch (e) {
      console.error('HomeView refresh error: ' + JSON.stringify(e));
      this.loading = false;
    }
  }

  @Builder
  statCard() {
    Column({ space: 6 }) {
      Row() {
        Text('今日减排')
          .fontSize(13)
          .fontColor('#E8F5E9')
        Blank()
        Text(`连续打卡 ${this.streak} 天 🔥`)
          .fontSize(12)
          .fontColor('#C8E6C9')
      }
      .width('100%')

      Row({ space: 4 }) {
        Text(DateUtil.gramsToKg(this.todayG))
          .fontSize(44)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('kg CO₂e')
          .fontSize(15)
          .fontColor('#C8E6C9')
          .margin({ bottom: 8 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Bottom)

      Row({ space: 24 }) {
        Text(`碳积分 ${this.balance}`)
          .fontSize(13)
          .fontColor('#E8F5E9')
        Text(`待完成任务 ${this.pending}`)
          .fontSize(13)
          .fontColor('#E8F5E9')
        Blank()
      }
      .width('100%')
    }
    .width('100%')
    .padding(18)
    .borderRadius(16)
    .linearGradient({
      angle: 135,
      colors: [['#43A047', 0], ['#2E7D32', 1]]
    })
  }

  @Builder
  quickEntry(icon: string, label: string, action: () => void) {
    Column({ space: 6 }) {
      Text(icon)
        .fontSize(26)
      Text(label)
        .fontSize(12)
        .fontColor(Theme.TEXT)
    }
    .layoutWeight(1)
    .padding({ top: 14, bottom: 14 })
    .borderRadius(12)
    .backgroundColor(Theme.CARD)
    .onClick(() => {
      action();
    })
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        this.statCard()

        Row({ space: 10 }) {
          this.quickEntry('✏️', '行为录入', (): void => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
          })
          this.quickEntry('📋', '历史记录', (): void => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_HISTORY);
          })
          this.quickEntry('🎯', '任务中心', (): void => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
          })
          this.quickEntry('📚', '双碳科普', (): void => {
            router.pushUrl({ url: 'pages/Knowledge' });
          })
        }
        .width('100%')

        // 趋势折线图
        Column({ space: 10 }) {
          Row() {
            Text('减排趋势')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
            Blank()
          }
          .width('100%')

          Row({ space: 8 }) {
            ForEach(['day7', 'week8', 'month12', 'year5'], (kind: string) => {
              Text(StatsService.kindLabel(kind as TrendKind))
                .fontSize(11)
                .fontColor(this.trendKind === kind ? '#FFFFFF' : Theme.TEXT_SUB)
                .backgroundColor(this.trendKind === kind ? Theme.PRIMARY : Theme.BG)
                .borderRadius(10)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .onClick(() => {
                  this.trendKind = kind as TrendKind;
                  this.refresh();
                })
            }, (kind: string) => kind)
            Blank()
          }
          .width('100%')

          LineChart({ points: this.trend })
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor(Theme.CARD)

        // 分类饼图
        Column({ space: 10 }) {
          Text(`${StatsService.kindLabel(this.trendKind)}分类占比`)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row({ space: 8 }) {
            PieChart({ items: this.pie })
              .layoutWeight(1)
            Column({ space: 8 }) {
              ForEach(this.pie, (item: PieItem) => {
                Row({ space: 6 }) {
                  Circle({ width: 8, height: 8 }).fill(item.color)
                  Text(item.name)
                    .fontSize(12)
                    .fontColor(Theme.TEXT)
                  Blank()
                  Text(`${item.pct.toFixed(0)}%`)
                    .fontSize(12)
                    .fontColor(Theme.TEXT_SUB)
                }
                .width('100%')
              }, (item: PieItem) => item.name)
            }
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.pie.length === 0) {
            Text('还没有减排记录，去录入一笔吧！')
              .fontSize(12)
              .fontColor(Theme.TEXT_SUB)
          }
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor(Theme.CARD)

        // 待完成任务
        Column({ space: 10 }) {
          Row() {
            Text('待完成任务')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
            Blank()
            Text('全部 >')
              .fontSize(12)
              .fontColor(Theme.PRIMARY)
              .onClick(() => {
                AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
              })
          }
          .width('100%')

          if (this.pendingTasks.length === 0) {
            Text('太棒了，本期任务都完成啦 🎉')
              .fontSize(12)
              .fontColor(Theme.TEXT_SUB)
              .width('100%')
          }
          ForEach(this.pendingTasks, (p: TaskProgress) => {
            Row({ space: 10 }) {
              Text(categoryIcon(''))
                .fontSize(16)
              Text(p.task.title)
                .fontSize(13)
                .fontColor(Theme.TEXT)
                .layoutWeight(1)
              Text(`+${p.task.points}分`)
                .fontSize(12)
                .fontColor(Theme.POINTS)
            }
            .width('100%')
            .padding(10)
            .borderRadius(10)
            .backgroundColor(Theme.BG)
          }, (p: TaskProgress) => p.task.code)
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor(Theme.CARD)

        if (!this.loading && this.todayG === 0) {
          EmptyState({
            icon: '🌍',
            title: '今天还没有低碳记录',
            desc: '步行、光盘、节电……每一件小事都在改变世界',
            buttonText: '立即记录',
            onButton: (): void => {
              AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
            }
          })
        }
      }
      .width('100%')
      .padding(14)
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }
}
