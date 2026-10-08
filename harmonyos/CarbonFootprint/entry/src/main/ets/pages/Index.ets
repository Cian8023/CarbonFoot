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
  tabItem(label: string, icon: Resource, index: number) {
    Column({ space: 2 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([this.mainTab === index ? Theme.PRIMARY : Theme.TEXT_TERTIARY])
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
      .tabBar(this.tabItem('首页', $r('sys.symbol.house'), Constants.TAB_HOME))

      TabContent() {
        RecordView()
      }
      .tabBar(this.tabItem('录入', $r('sys.symbol.plus'), Constants.TAB_RECORD))

      TabContent() {
        HistoryView()
      }
      .tabBar(this.tabItem('历史', $r('sys.symbol.clock'), Constants.TAB_HISTORY))

      TabContent() {
        TasksView()
      }
      .tabBar(this.tabItem('任务', $r('sys.symbol.calendar'), Constants.TAB_TASKS))

      TabContent() {
        MineView()
      }
      .tabBar(this.tabItem('我的', $r('sys.symbol.person'), Constants.TAB_MINE))
    }
    .scrollable(false)
    .barHeight(64)
    .barBackgroundColor('#FFFFFF')
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
  @State displayG: number = 0;
  @State heroScale: number = 1;
  @State homeReady: boolean = false;
  @State nickname: string = '绿色生活家';
  private countTimer: number = -1;

  private todayLabel(): string {
    const w: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return DateUtil.formatMD(Date.now()) + ' ' + w[new Date().getDay()];
  }

  private greeting(): string {
    const h = new Date().getHours();
    if (h < 11) {
      return '早上好';
    } else if (h < 14) {
      return '中午好';
    } else if (h < 18) {
      return '下午好';
    }
    return '晚上好';
  }

  async aboutToAppear(): Promise<void> {
    // 内容层入场淡入上浮
    setTimeout((): void => {
      this.homeReady = true;
    }, 60);
    await this.refresh();
  }

  aboutToDisappear(): void {
    if (this.countTimer >= 0) {
      clearInterval(this.countTimer);
      this.countTimer = -1;
    }
  }

  /** hero 数字滚动动画（大厂 CountUp），落定后轻弹一次 */
  private animateHero(target: number): void {
    if (this.countTimer >= 0) {
      clearInterval(this.countTimer);
      this.countTimer = -1;
    }
    const start = this.displayG;
    const diff = target - start;
    if (Math.abs(diff) < 0.0001) {
      this.displayG = target;
      return;
    }
    let i = 0;
    const steps = 24;
    this.countTimer = setInterval((): void => {
      i++;
      this.displayG = start + diff * i / steps;
      if (i >= steps) {
        this.displayG = target;
        clearInterval(this.countTimer);
        this.countTimer = -1;
        animateTo({ duration: 130, curve: Curve.EaseOut }, (): void => {
          this.heroScale = 1.1;
        });
        setTimeout((): void => {
          animateTo({ duration: 200, curve: Curve.EaseInOut }, (): void => {
            this.heroScale = 1;
          });
        }, 130);
      }
    }, 16);
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
      this.animateHero(todaySum);
      this.balance = await PointsService.getBalance();
      this.pending = await TaskService.pendingCount();
      this.streak = await BadgeService.currentStreak();
      this.trend = StatsService.trend(records, this.trendKind);
      this.pie = StatsService.categoryShare(records, StatsService.rangeStart(this.trendKind));
      this.monthG = StatsService.monthSum(records);
      this.weekly = StatsService.weekReport(records);
      this.monthGoalKg = await PrefsService.getMonthlyGoalKg();
      this.cardOrder = await PrefsService.getHomeLayout();
      this.nickname = await PrefsService.getNickname();
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

  /** 首页核心大卡：今日减排大数字 + 本月目标环 + 底部统计条（运动健康步数卡式） */
  @Builder
  statCard() {
    Column() {
      Row() {
        Text('本月减排目标')
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('修改目标 >')
          .fontSize(12)
          .fontColor(Theme.PRIMARY)
          .onClick(() => {
            router.pushUrl({ url: 'pages/SettingsDetail', params: { focus: 'goal' } });
          })
      }
      .width('100%')

      Row() {
        Column({ space: 6 }) {
          Text('今日减排')
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
          Row({ space: 4 }) {
            Text(DateUtil.gramsToKg(this.displayG))
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.PRIMARY)
              .scale({ x: this.heroScale, y: this.heroScale })
            Text('kg CO₂e')
              .fontSize(13)
              .fontColor(Theme.TEXT_TERTIARY)
              .margin({ bottom: 7 })
          }
          .alignItems(VerticalAlign.Bottom)

          // 本月进度迷你条：填补左列留白，与子类型对比条同语言
          Column({ space: 5 }) {
            Row() {
              Text(`本月 ${DateUtil.gramsToKg(this.monthG)} / ${this.monthGoalKg} kg`)
                .fontSize(11)
                .fontColor(Theme.TEXT_TERTIARY)
              Blank()
              Text(this.monthGoalKg > 0 ? Math.round(this.monthG / (this.monthGoalKg * 1000) * 100) + '%' : '0%')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.monthG >= this.monthGoalKg * 1000 ? '#F7BA1E' : Theme.PRIMARY)
            }
            .width('100%')

            Stack({ alignContent: Alignment.Start }) {
              Column()
                .width('100%')
                .height(6)
                .borderRadius(3)
                .backgroundColor(Theme.BG_GRAY)
              Column()
                .width(this.monthGoalKg > 0 ? Math.min(100, Math.round(this.monthG / (this.monthGoalKg * 1000) * 100)) + '%' : '0%')
                .height(6)
                .borderRadius(3)
                .backgroundColor(this.monthG >= this.monthGoalKg * 1000 ? '#F7BA1E' : Theme.PRIMARY)
            }
            .width('100%')
          }
          .width('100%')
          .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        GoalRing({
          progress: this.monthGoalKg > 0 ? this.monthG / (this.monthGoalKg * 1000) : 0,
          centerText: (this.monthG / 1000).toFixed(1) + 'kg',
          subText: '目标 ' + this.monthGoalKg + 'kg'
        })
          .width(150)
      }
      .width('100%')
      .margin({ top: 4 })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color(Theme.DIVIDER_LIGHT)
        .margin({ top: 10 })

      Row() {
        Column({ space: 2 }) {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.flame'))
              .fontSize(15)
              .fontColor(['#FF7D00'])
            Text(`${this.streak} 天`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.TEXT)
          }
          .alignItems(VerticalAlign.Center)

          Text('连续打卡')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(26)
          .color(Theme.DIVIDER_LIGHT)

        Column({ space: 2 }) {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.star'))
              .fontSize(15)
              .fontColor(['#F7BA1E'])
            Text(`${this.balance}`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.TEXT)
          }
          .alignItems(VerticalAlign.Center)

          Text('碳积分')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Divider()
          .vertical(true)
          .height(26)
          .color(Theme.DIVIDER_LIGHT)

        Column({ space: 2 }) {
          Row({ space: 4 }) {
            SymbolGlyph($r('sys.symbol.checkmark_circle'))
              .fontSize(15)
              .fontColor(['#3491FA'])
            Text(`${this.pending}`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.TEXT)
          }
          .alignItems(VerticalAlign.Center)

          Text('待办任务')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .borderRadius(Theme.R_LARGE)
    .linearGradient({
      angle: 180,
      colors: [['#E7F6EE', 0.0], ['#FFFFFF', 0.5]]
    })
    .shadow(Theme.CARD_SHADOW)
  }

  @Builder
  quickEntry(icon: Resource, label: string, sub: string, bgColor: string, action: () => void) {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .borderRadius(14)
        .backgroundColor(bgColor)
        .opacity(0.12)

      Column({ space: 4 }) {
        SymbolGlyph(icon)
          .fontSize(20)
          .fontColor([bgColor])

        Text(label)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.TEXT)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .layoutWeight(1)
    .height(72)
    .borderRadius(14)
    .backgroundColor(Theme.CARD)
    .shadow(Theme.CARD_SHADOW)
    .onClick(() => {
      action();
    })
  }

  @Builder
  quickSection() {
    Column({ space: 5 }) {
      Row({ space: 5 }) {
        this.quickEntry($r('sys.symbol.square_and_pencil'), '行为录入', '记录低碳行为', '#00B96B', (): void => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
        })
        this.quickEntry($r('sys.symbol.clock'), '历史记录', '查询与筛选', '#722ED1', (): void => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_HISTORY);
        })
        this.quickEntry($r('sys.symbol.calendar'), '任务中心', '积分与徽章', '#F7BA1E', (): void => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
        })
        this.quickEntry($r('sys.symbol.doc_text'), '双碳科普', '政策与技巧', '#3491FA', (): void => {
          router.pushUrl({ url: 'pages/Knowledge' });
        })
      }
      .width('100%')
      // 创新拓展功能入口
      Row({ space: 5 }) {
        this.quickEntry($r('sys.symbol.camera'), '拍照识别', 'AI 自动录入', '#3491FA', (): void => {
          router.pushUrl({ url: 'pages/AiRecognize' });
        })
        this.quickEntry($r('sys.symbol.gift'), '碳普惠', '积分兑权益', '#FF7D00', (): void => {
          router.pushUrl({ url: 'pages/Inclusive' });
        })
        this.quickEntry($r('sys.symbol.person'), '家庭账户', '多端合并', '#14C9C9', (): void => {
          router.pushUrl({ url: 'pages/Family' });
        })
        this.quickEntry($r('sys.symbol.share'), '成果分享', '生成海报', '#722ED1', (): void => {
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
    .borderRadius(Theme.R_LARGE)
    .backgroundColor(Theme.CARD)
    .shadow(Theme.CARD_SHADOW)
  }

  /** 图例过滤 0 值分类（未产生记录的大类不占位，避免"0%"误导） */
  private pieShown(): PieItem[] {
    return this.pie.filter((p: PieItem) => p.value > 0);
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
            // key 带上档位 + 名称 + 四舍五入后的百分比，确保切换档位（日/周/月/年）或排序变化时
            // 不会被 ForEach 错误复用成上一次渲染的行（避免名称与占比错位残留）。
            ForEach(this.pieShown(), (item: PieItem) => {
              Row({ space: 8 }) {
                Circle({ width: 14, height: 14 }).fill(item.color)
                Text(item.name)
                  .fontSize(16)
                  .maxLines(1)
                  .fontColor(Theme.TEXT)
                Blank()
                Text(`${item.pct.toFixed(0)}%`)
                  .fontSize(16)
                  .fontColor(Theme.TEXT_SECONDARY)
              }
              .width('100%')
            }, (item: PieItem) => this.trendKind + '_' + item.name + '_' + item.pct.toFixed(0))
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
    .borderRadius(Theme.R_LARGE)
    .backgroundColor(Theme.CARD)
    .shadow(Theme.CARD_SHADOW)
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
    .borderRadius(Theme.R_LARGE)
    .backgroundColor(Theme.CARD)
    .shadow(Theme.CARD_SHADOW)
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
    .borderRadius(Theme.R_LARGE)
    .backgroundColor(Theme.CARD)
    .shadow(Theme.CARD_SHADOW)
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
    .borderRadius(Theme.R_LARGE)
    .backgroundColor(Theme.CARD)
    .shadow(Theme.CARD_SHADOW)
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 顶部浅绿晕染：给标题区一点颜色，不抢白卡
      Column()
        .width('100%')
        .height(190)
        .linearGradient({
          angle: 180,
          colors: [['#D9F1E4', 0.0], ['#ECF6F0', 0.62], [Theme.BG, 1.0]]
        })

      Scroll() {
        Column({ space: 12 }) {
          Row() {
            Column({ space: 3 }) {
              Row({ space: 8 }) {
                Text('碳足迹')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                Text('低碳每一天')
                  .fontSize(11)
                  .fontColor(Theme.PRIMARY)
                  .backgroundColor(Theme.PRIMARY_BG)
                  .borderRadius(10)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              }
              .alignItems(VerticalAlign.Center)

              Text(`${this.greeting()}，${this.nickname}，今天也要低碳哦`)
                .fontSize(12)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text(this.todayLabel())
              .fontSize(13)
              .fontColor(Theme.TEXT_TERTIARY)
          }
          .width('100%')

          this.statCard()

        // 卡片顺序可自定义（我的 > 首页布局）
        ForEach(this.cardOrder, (key: string) => {
          if (key === 'quick') {
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
      .padding({ left: 14, right: 14, top: 8, bottom: 14 })
      .opacity(this.homeReady ? 1 : 0)
      .translate({ y: this.homeReady ? 0 : 24 })
      .animation({ duration: 380, curve: Curve.EaseOut })
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
  }
}
