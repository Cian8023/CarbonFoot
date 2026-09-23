import router from '@ohos.router';
import { AppInit } from '../common/AppInit';
import { Constants } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BehaviorRecord, TaskProgress } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import { TaskService } from '../service/TaskService';
import { PointsService } from '../service/PointsService';
import { BadgeService } from '../service/BadgeService';
import { StatsService, TrendKind } from '../service/StatsService';
import { RecommendService, Suggestion } from '../service/RecommendService';
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
    this.tabsController.changeIndex(this.mainTab);
  }

  @Builder
  tabItem(label: string, index: number) {
    Column({ space: Theme.SPACE_MINI }) {
      Text(label)
        .fontSize(14)
        .fontWeight(this.mainTab === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.mainTab === index ? Theme.PRIMARY : Theme.TEXT_TERTIARY)
      
      if (this.mainTab === index) {
        Divider()
          .width(20)
          .height(3)
          .color(Theme.PRIMARY)
          .borderRadius(2)
      }
    }
    .width('100%')
    .height(48)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.mainTab, controller: this.tabsController }) {
      TabContent() {
        HomeView()
      }
      .tabBar(this.tabItem('首页', Constants.TAB_HOME))

      TabContent() {
        RecordView()
      }
      .tabBar(this.tabItem('录入', Constants.TAB_RECORD))

      TabContent() {
        HistoryView()
      }
      .tabBar(this.tabItem('历史', Constants.TAB_HISTORY))

      TabContent() {
        TasksView()
      }
      .tabBar(this.tabItem('任务', Constants.TAB_TASKS))

      TabContent() {
        MineView()
      }
      .tabBar(this.tabItem('我的', Constants.TAB_MINE))
    }
    .scrollable(false)
    .barHeight(56)
    .barBackgroundColor(Theme.CARD)
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
  @State totalG: number = 0;
  @State balance: number = 0;
  @State pending: number = 0;
  @State streak: number = 0;
  @State trendKind: TrendKind = 'day7';
  @State trend: ChartPoint[] = [];
  @State pie: PieItem[] = [];
  @State pendingTasks: TaskProgress[] = [];
  @State recTasks: TaskProgress[] = [];
  @State tips: Suggestion[] = [];

  async aboutToAppear(): Promise<void> {
    await this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      const records: BehaviorRecord[] = await BehaviorRepo.all();
      const todayStart = DateUtil.startOfDay(Date.now());
      let todaySum = 0;
      let totalSum = 0;
      for (const r of records) {
        totalSum += r.reductionG;
        if (r.createdAt >= todayStart) {
          todaySum += r.reductionG;
        }
      }
      this.todayG = todaySum;
      this.totalG = totalSum;
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
      this.recTasks = await RecommendService.recommendTasks();
      this.tips = await RecommendService.suggestions();
      this.loading = false;
    } catch (e) {
      console.error('HomeView refresh error: ' + JSON.stringify(e));
      this.loading = false;
    }
  }

  @Builder
  heroCard() {
    Column() {
      // 渐变背景的核心数据卡片
      Column({ space: Theme.SPACE_LARGE }) {
        Row() {
          Column({ space: Theme.SPACE_MINI }) {
            Text('今日减排')
              .fontSize(13)
              .fontColor('#FFFFFF')
              .opacity(0.9)
            
            Row({ space: 6 }) {
              Text(DateUtil.gramsToKg(this.todayG))
                .fontSize(48)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              
              Text('kg')
                .fontSize(16)
                .fontColor('#FFFFFF')
                .opacity(0.9)
                .margin({ bottom: 8 })
            }
            .alignItems(VerticalAlign.Bottom)
          }
          .alignItems(HorizontalAlign.Start)
          
          Blank()
        }
        .width('100%')
        
        Row({ space: Theme.SPACE_LARGE }) {
          Column({ space: 4 }) {
            Text(`${this.streak}`)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Text('连续天数')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .opacity(0.8)
          }
          
          Divider()
            .vertical(true)
            .height(32)
            .color('#FFFFFF')
            .opacity(0.3)
          
          Column({ space: 4 }) {
            Text(`${this.balance}`)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Text('碳积分')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .opacity(0.8)
          }
          
          Divider()
            .vertical(true)
            .height(32)
            .color('#FFFFFF')
            .opacity(0.3)
          
          Column({ space: 4 }) {
            Text(DateUtil.gramsToKg(this.totalG))
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Text('累计减排(kg)')
              .fontSize(11)
              .fontColor('#FFFFFF')
              .opacity(0.8)
          }
        }
        .width('100%')
      }
      .width('100%')
      .padding(Theme.SPACE_XXLARGE)
      .borderRadius(Theme.R_LARGE)
      .backgroundImage(Theme.GRADIENT_PRIMARY)
      .shadow({ radius: 16, color: 'rgba(0, 185, 107, 0.25)', offsetY: 8 })
    }
    .width('100%')
  }

  @Builder
  quickGrid() {
    Grid() {
      GridItem() {
        this.quickItem('录入行为', '记录低碳生活', '#00B96B', () => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
        })
      }
      
      GridItem() {
        this.quickItem('AI 识别', '拍照自动录入', '#3491FA', () => {
          router.pushUrl({ url: 'pages/AiRecognize' });
        })
      }
      
      GridItem() {
        this.quickItem('历史记录', '查询与筛选', '#722ED1', () => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_HISTORY);
        })
      }
      
      GridItem() {
        this.quickItem('任务中心', '赚取积分', '#F7BA1E', () => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
        })
      }
      
      GridItem() {
        this.quickItem('碳普惠', '兑换权益', '#FF7D00', () => {
          router.pushUrl({ url: 'pages/Inclusive' });
        })
      }
      
      GridItem() {
        this.quickItem('家庭账户', '多端同步', '#14C9C9', () => {
          router.pushUrl({ url: 'pages/Family' });
 
