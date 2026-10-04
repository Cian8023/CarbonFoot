import router from '@ohos.router';
import { AppInit } from '../common/AppInit';
import { Constants } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BehaviorRecord, TaskProgress } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import { TaskService } from '../service/TaskService';
import { PointsService } from '../service/PointsService';
import { BadgeService } from '../service/BadgeService';
import { StatsService, TrendKind, WeeklyReport } from '../service/StatsService';
import { RecommendService, Suggestion } from '../service/RecommendService';
import { PrefsService, DEFAULT_HOME_LAYOUT } from '../common/PrefsService';
import { DateUtil } from '../utils/DateUtil';
import { TrendBarChart, PieChart, GoalRing, ChartPoint, PieItem } from '../components/Chart';
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
        .fontColor(this.mainTab === index ? Theme.PRIMARY : Theme.TEXT_TERTIARY)
      Text(label)
        .fontSize(10)
        .fontWeight(this.mainTab === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.mainTab === index ? Theme.PRIMARY : Theme.TEXT_TERTIARY)
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
      .tabBar(this.tabItem('历史', '📜', Constants.TAB_HISTORY))

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
    .barHeight(60)
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
  @State recTasks: TaskProgress[] = [];
  @State tips: Suggestion[] = [];
  @State monthG: number = 0;
  @State monthGoalKg: number = 30;
  @State weekly: WeeklyReport = {
    weekG: 0, lastWeekG: 0, deltaPct: -999, topSub: '', topSubG: 0, days: 0, slogan: ''
  };
  @State cardOrder: string[] = DEFAULT_HOME_LAYOUT;

  /** 本月剩余天数（含今天） */
  private daysLeftInMonth(): number {
    const d = new Date();
    const daysInMonth = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
    return daysInMonth - d.getDate() + 1;
  }

  /** 目标节奏提示文本；已达成或无目标返回空串 */
  private paceText(): string {
    if (this.monthGoalKg <= 0 || this.monthG >= this.monthGoalKg * 1000) {
      return '';
    }
    const perDay = (this.monthGoalKg * 1000 - this.monthG) / 1000 / this.daysLeftInMonth();
    return `本月还剩 ${this.daysLeftInMonth()} 天，日均 ${perDay.toFixed(2)} kg 即可达成`;
  }

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
      this.monthG = StatsService.monthSum(records);
      this.weekly = StatsService.weekReport(records);
      this.monthGoalKg = await PrefsService.getMonthlyGoalKg();
      this.cardOrder = await PrefsService.getHomeLayout();
      const all = await TaskService.listProgress();
      const top: TaskProgress[] = [];
      for (const p of all) {
        if (!p.done && top.length < 3) {
          top.push(p);
        }
      }
      this.pendingTasks = top;
      this.recTasks = await RecommendService.recommendTasks();
      this.tips = await RecommendService.suggestions();
      this.loading = false;
    } catch (e) {
      console.error('HomeView refresh error: ' + JSON.stringify(e));
      this.loading = false;
    }
  }

  @Builder
  statCard() {
    Column({ space: 14 }) {
      Row() {
        Column({ space: 6 }) {
          Text('今日减排')
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
          Row({ space: 4 }) {
            Text(DateUtil.gramsToKg(this.todayG))
              .fontSize(38)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
            Text('kg CO₂e')
              .fontSize(13)
              .fontColor(Theme.TEXT_TERTIARY)
              .margin({ bottom: 6 })
          }
          .alignItems(VerticalAlign.Bottom)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column({ space: 10 }) {
          Row({ space: 6 }) {
            Text('连续打卡')
              .fontSize(11)
              .fontColor(Theme.TEXT_TERTIARY)
            Text(`${this.streak} 天`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.TEXT)
            Circle({ width: 7, height: 7 })
              .fill(this.todayG > 0 ? Theme.PRIMARY : Theme.DIVIDER)
          }
          Row({ space: 6 }) {
            Text('碳积分')
              .fontSize(11)
              .fontColor(Theme.TEXT_TERTIARY)
            Text(`${this.balance}`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.TEXT)
          }
          Row({ space: 6 }) {
            Text('待办任务')
              .fontSize(11)
              .fontColor(Theme.TEXT_TERTIARY)
            Text(`${this.pending}`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.TEXT)
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(18)
    .borderRadius(Theme.R_MEDIUM)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  /** 本月减排目标环（借鉴运动健康步数圆环） */
  @Builder
  goalCard() {
    Column({ space: 10 }) {
      Row() {
        Text('本月减排目标')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('修改目标 >')
          .fontSize(13)
          .fontColor(Theme.PRIMARY)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsDetail', params: { focus: 'goal' } });
          })
      }
      .width('100%')

      Row({ space: 16 }) {
        GoalRing({
          progress: this.monthGoalKg > 0 ? this.monthG / (this.monthGoalKg * 1000) : 0,
          centerText: (this.monthG / 1000).toFixed(1) + 'kg',
          subText: '目标 ' + this.monthGoalKg + 'kg'
        })

        Column({ space: 8 }) {
          Row({ space: 6 }) {
            Text('达成率')
              .fontSize(12)
              .fontColor(Theme.TEXT_TERTIARY)
            Text(this.monthGoalKg > 0 ? Math.round(this.monthG / (this.monthGoalKg * 1000) * 100) + '%' : '0%')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.monthG >= this.monthGoalKg * 1000 ? '#F7BA1E' : Theme.PRIMARY)
          }
          if (this.monthG >= this.monthGoalKg * 1000) {
            Text('目标已达成，太棒了！')
              .fontSize(13)
              .fontColor('#F7BA1E')
          } else {
            Text(`还差 ${((this.monthGoalKg * 1000 - this.monthG) / 1000).toFixed(1)} kg 达成目标`)
              .fontSize(13)
              .fontColor(Theme.TEXT_SECONDARY)
            Text(this.paceText())
              .fontSize(11)
              .fontColor(Theme.TEXT_TERTIARY)
          }
          Text('骑行通勤、光盘三餐都能攒进度')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  @Builder
  quickEntry(icon: string, label: string, sub: string, bgColor: string, action: () => void) {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(Theme.R_SMALL)
        .backgroundColor(bgColor)
        .opacity(0.08)

      Column({ space: 2 }) {
        Text(icon)
          .fontSize(18)

        Text(label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.TEXT)

        Text(sub)
          .fontSize(10)
          .fontColor(Theme.TEXT_TERTIARY)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .layoutWeight(1)
    .height(78)
    .borderRadius(Theme.R_SMALL)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
    .onClick(() => {
      action();
    })
  }

  @Builder
  quickSection() {
    Column({ space: 5 }) {
      Row({ space: 5 }) {
        this.quickEntry('✏️', '行为录入', '记录低碳行为', '#00B96B', (): void => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
        })
        this.quickEntry('📜', '历史记录', '查询与筛选', '#722ED1', (): void => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_HISTORY);
        })
        this.quickEntry('🎯', '任务中心', '积分与徽章', '#F7BA1E', (): void => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
        })
        this.quickEntry('📚', '双碳科普', '政策与技巧', '#3491FA', (): void => {
          router.pushUrl({ url: 'pages/Knowledge' });
        })
      }
      .width('100%')
      // 创新拓展功能入口
      Row({ space: 5 }) {
        this.quickEntry('📷', '拍照识别', 'AI 自动录入', '#3491FA', (): void => {
          router.pushUrl({ url: 'pages/AiRecognize' });
        })
        this.quickEntry('🎁', '碳普惠', '积分兑权益', '#FF7D00', (): void => {
          router.pushUrl({ url: 'pages/Inclusive' });
        })
        this.quickEntry('👨‍👩‍👧', '家庭账户', '多端合并', '#14C9C9', (): void => {
          router.pushUrl({ url: 'pages/Family' });
        })
        this.quickEntry('📊', '成果分享', '生成海报', '#722ED1', (): void => {
          router.pushUrl({ url: 'pages/ShareCard' });
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  /** 减排趋势（柱状图风格，当期高亮） */
  @Builder
  trendCard() {
    Column({ space: 10 }) {
      Row() {
        Text('减排趋势')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
      }
      .width('100%')

      Row({ space: 8 }) {
        ForEach(['day7', 'week8', 'month12', 'year5'], (kind: string) => {
          Text(StatsService.shortLabel(kind as TrendKind))
            .fontSize(11)
            .fontColor(this.trendKind === kind ? '#FFFFFF' : Theme.TEXT_TERTIARY)
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

      TrendBarChart({ points: this.trend })
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  /** 分类占比环形图（中心大数字为当期总量） */
  @Builder
  pieCard() {
    Column({ space: 10 }) {
      Text(`${StatsService.kindLabel(this.trendKind)}分类占比`)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .width('100%')

      if (this.pie.length > 0) {
        Row({ space: 8 }) {
          PieChart({ items: this.pie, centerSub: StatsService.kindLabel(this.trendKind) + '总量' })
            .layoutWeight(1)
          Column({ space: 10 }) {
            ForEach(this.pie, (item: PieItem) => {
              Row({ space: 8 }) {
                Circle({ width: 14, height: 14 }).fill(item.color)
                Text(item.name)
                  .fontSize(28)
                  .maxLines(1)
                  .fontColor(Theme.TEXT)
                Blank()
                Text(`${item.pct.toFixed(0)}%`)
                  .fontSize(28)
                  .fontColor(Theme.TEXT_SECONDARY)
              }
              .width('100%')
            }, (item: PieItem) => item.name)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      } else {
        Column({ space: 12 }) {
          Text('📊')
            .fontSize(48)
            .opacity(0.3)
          Text('暂无数据')
            .fontSize(14)
            .fontColor(Theme.TEXT_SECONDARY)
          Text('去录入第一笔减排记录吧')
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  /** 减排周报（借鉴运动健康周报） */
  @Builder
  weeklyCard() {
    Column({ space: 10 }) {
      Row() {
        Text('减排周报')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text(DateUtil.formatMD(DateUtil.startOfWeek(Date.now())) + ' 起')
          .fontSize(10)
          .fontColor(Theme.TEXT_TERTIARY)
      }
      .width('100%')

      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('本周减排')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
          Text(DateUtil.gramsToKg(this.weekly.weekG))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.PRIMARY)
        }
        .alignItems(HorizontalAlign.Start)

        Column({ space: 4 }) {
          Text('环比上周')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
          if (this.weekly.deltaPct === -999) {
            Text('上周无数据')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.TEXT_SECONDARY)
          } else if (this.weekly.deltaPct >= 0) {
            Text(`↑ ${this.weekly.deltaPct}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
          } else {
            Text(`↓ ${-this.weekly.deltaPct}%`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F53F3F')
          }
        }
        .alignItems(HorizontalAlign.Start)

        Column({ space: 4 }) {
          Text('本周打卡')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
          Text(`${this.weekly.days}/7 天`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.TEXT)
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      if (this.weekly.topSub !== '') {
        Text(`本周最强项：${this.weekly.topSub}（${DateUtil.gramsToKg(this.weekly.topSubG)}）`)
          .fontSize(12)
          .fontColor(Theme.TEXT_SECONDARY)
          .width('100%')
      }

      if (this.weekly.weekG > 0) {
        Text(this.weekly.slogan)
          .fontSize(12)
          .fontColor(Theme.PRIMARY)
          .backgroundColor(Theme.PRIMARY_BG)
          .borderRadius(10)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
    .onClick(() => {
      // 点击周报卡：跳历史页并预选近7天
      AppStorage.setOrCreate('historyRange', 2);
      AppStorage.setOrCreate('mainTab', Constants.TAB_HISTORY);
    })
  }

  /** 智能推荐（个性化任务 + 生活建议） */
  @Builder
  recCard() {
    Column({ space: 10 }) {
      Row({ space: 6 }) {
        Text('智能推荐')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text('基于近 14 天行为习惯')
          .fontSize(10)
          .fontColor(Theme.TEXT_TERTIARY)
        Blank()
      }
      .width('100%')

      ForEach(this.recTasks, (p: TaskProgress) => {
        Column({ space: 4 }) {
          Row({ space: 10 }) {
            Text('任务')
              .fontSize(9)
              .fontColor(Theme.PRIMARY)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(4)
              .padding({ left: 5, right: 5, top: 2, bottom: 2 })
            Text(p.task.title)
              .fontSize(13)
              .fontColor(Theme.TEXT)
              .layoutWeight(1)
            Text(`+${p.task.points} 积分`)
              .fontSize(12)
              .fontColor(Theme.POINTS)
          }
          .width('100%')
          if (p.reason !== undefined && p.reason !== '') {
            Text(p.reason)
              .fontSize(10)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(10)
        .borderRadius(Theme.R_SMALL)
        .backgroundColor(Theme.BG)
      }, (p: TaskProgress) => 'rec_' + p.task.code + '_' + (p.reason !== undefined ? p.reason : ''))

      ForEach(this.tips, (s: Suggestion) => {
        Column({ space: 4 }) {
          Text(s.title)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Text(s.detail)
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(10)
        .borderRadius(10)
        .backgroundColor(Theme.PRIMARY_BG)
      }, (s: Suggestion) => s.title)
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  /** 待完成任务 */
  @Builder
  tasksCard() {
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
        Text('太棒了，本期任务都完成啦')
          .fontSize(12)
          .fontColor(Theme.TEXT_TERTIARY)
          .width('100%')
      }
      ForEach(this.pendingTasks, (p: TaskProgress) => {
        Column({ space: 4 }) {
          Row({ space: 10 }) {
            Circle({ width: 6, height: 6 }).fill(Theme.PRIMARY_HOVER)
            Text(p.task.title)
              .fontSize(13)
              .fontColor(Theme.TEXT)
              .layoutWeight(1)
            Text(`+${p.task.points} 积分`)
              .fontSize(12)
              .fontColor(Theme.POINTS)
          }
          .width('100%')
          Progress({ value: p.progress, total: p.target, type: ProgressType.Linear })
            .width('100%')
            .height(2)
            .color(Theme.PRIMARY_HOVER)
        }
        .width('100%')
        .padding(10)
        .borderRadius(Theme.R_SMALL)
        .backgroundColor(Theme.BG)
      }, (p: TaskProgress) => p.task.code)
    }
    .width('100%')
    .padding(14)
    .borderRadius(16)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        this.statCard()

        // 卡片顺序可自定义（我的 > 首页布局）
        ForEach(this.cardOrder, (key: string) => {
          if (key === 'goal') {
            this.goalCard()
          } else if (key === 'quick') {
            this.quickSection()
          } else if (key === 'trend') {
            this.trendCard()
          } else if (key === 'pie') {
            this.pieCard()
          } else if (key === 'weekly') {
            this.weeklyCard()
          } else if (key === 'rec') {
            if (this.recTasks.length > 0 || this.tips.length > 0) {
              this.recCard()
            }
          } else if (key === 'tasks') {
            this.tasksCard()
          }
        }, (key: string) => key)

        if (!this.loading && this.todayG === 0) {
          EmptyState({
            icon: '',
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
