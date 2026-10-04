import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants } from '../common/Constants';
import { Theme } from '../common/Theme';
import { TaskProgress, PointsRecord, BehaviorRecord, sourceLabel } from '../model/Models';
import { TaskService } from '../service/TaskService';
import { PointsService } from '../service/PointsService';
import { BehaviorRepo, TaskCheckUtil } from '../db/Repository';
import { TaskCheck } from '../model/Models';
import { DateUtil } from '../utils/DateUtil';
import { EmptyState } from '../components/EmptyState';
import { BadgeService } from '../service/BadgeService';
import { BadgeUnlockOverlay } from '../components/BadgeUnlock';

const SOURCES: string[] = ['全部', 'behavior', 'task', 'read', 'exchange'];

@Component
export struct TasksView {
  @StorageLink('tasksSegment') @Watch('refresh') segment: number = 0;
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State tasks: TaskProgress[] = [];
  @State flow: PointsRecord[] = [];
  @State balance: number = 0;
  @State loaded: boolean = false;
  @State weekDone: number = 0;
  @State totalDone: number = 0;
  @State weekDaysLeft: number = 7;
  @State flowSource: string = '全部';
  @State flowLimit: number = 50;
  @State detailTask: TaskProgress | null = null;
  @State showDetail: boolean = false;
  @State detailRule: string = '';
  @State detailRemain: string = '';
  @State detailRecords: BehaviorRecord[] = [];
  @State detailTotal: number = 0;
  @State showUnlock: boolean = false;
  @State unlockBadges: string[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      // 达标任务自动发积分（提交行为时也会评估，此处兜底）
      const awarded: string[] = await TaskService.evaluateAll();
      if (awarded.length > 0 && this.loaded) {
        promptAction.showToast({
          message: `完成任务：${awarded.join('、')}，积分已到账`,
          duration: 2500
        });
      }
      // 任务路径解锁的徽章在此展示动画
      const newBadges: string[] = await BadgeService.checkAll();
      if (newBadges.length > 0) {
        this.unlockBadges = newBadges;
        this.showUnlock = true;
      }
      this.tasks = await TaskService.listProgress();
      this.balance = await PointsService.getBalance();
      this.weekDone = await TaskService.weekCompletedCount();
      this.totalDone = await PointsService.countSource('task');
      const weekStart = DateUtil.startOfWeek(Date.now());
      this.weekDaysLeft = Math.ceil((weekStart + 7 * DateUtil.DAY_MS - Date.now()) / DateUtil.DAY_MS);
      await this.loadFlow();
      this.loaded = true;
    } catch (e) {
      console.error('TasksView refresh error: ' + JSON.stringify(e));
    }
  }

  private async loadFlow(): Promise<void> {
    this.flow = await PointsService.listPaged(this.flowSource, this.flowLimit);
  }

  private async changeSource(src: string): Promise<void> {
    this.flowSource = src;
    this.flowLimit = 50;
    await this.loadFlow();
  }

  private async loadMore(): Promise<void> {
    this.flowLimit += 50;
    await this.loadFlow();
  }

  private sourceChipLabel(code: string): string {
    if (code === '全部') {
      return '全部';
    }
    return sourceLabel(code);
  }

  private async openDetail(p: TaskProgress): Promise<void> {
    this.detailTask = p;
    this.detailRule = '统计中…';
    this.detailRemain = '';
    this.detailRecords = [];
    this.detailTotal = 0;
    this.showDetail = true;
    const check: TaskCheck = TaskCheckUtil.parse(p.task.checkJson);
    const rule = check.matchType === 'sum'
      ? `判定规则：${check.subTypes.join('、')} 按单位（${check.unit}）数值累加`
      : `判定规则：${check.subTypes.join('、')} 按记录笔数累加`;
    this.detailRule = `${rule}，达到 ${check.target}${check.unit} 即完成。`;
    this.detailRemain = p.done ? '本期已达成，积分已发放' : `还差 ${(p.target - p.progress) > 0 ? (p.target - p.progress) : 0}${check.unit} 达标`;
    try {
      const start = TaskService.periodStart(p.task.period);
      const all = await BehaviorRepo.query(start, Date.now(), '全部');
      const contrib: BehaviorRecord[] = [];
      for (const r of all) {
        if (check.subTypes.indexOf(r.subType) >= 0) {
          if (check.matchType === 'sum' && r.unit !== check.unit) {
            continue;
          }
          contrib.push(r);
        }
      }
      this.detailTotal = contrib.length;
      const top: BehaviorRecord[] = [];
      for (let i = 0; i < contrib.length && i < 20; i++) {
        top.push(contrib[i]);
      }
      this.detailRecords = top;
    } catch (e) {
      console.error('openDetail error: ' + JSON.stringify(e));
    }
  }

  @Builder
  taskCard(p: TaskProgress) {
    Column({ space: 8 }) {
      Row({ space: 10 }) {
        Column({ space: 3 }) {
          Row({ space: 8 }) {
            Text(p.task.title)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
            Text(p.task.period === 'daily' ? '每日' : '每周')
              .fontSize(10)
              .fontColor(Theme.PRIMARY)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            if (p.task.period === 'weekly') {
              Text(`剩${this.weekDaysLeft}天`)
                .fontSize(10)
                .fontColor('#FF7D00')
                .backgroundColor('#FFF3E8')
                .borderRadius(4)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            }
            if (p.done) {
              Text('已完成')
                .fontSize(10)
                .fontColor(Theme.TEXT_TERTIARY)
              Blank()
            }
          }
          Text(p.task.description)
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
            .maxLines(2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(`+${p.task.points}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.POINTS)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row({ space: 10 }) {
        Progress({ value: p.progress, total: p.target, type: ProgressType.Linear })
          .layoutWeight(1)
          .color(p.done ? Theme.PRIMARY_HOVER : Theme.PRIMARY)
        Text(p.done ? '已达成' : `${p.progress}/${p.target}`)
          .fontSize(12)
          .fontColor(p.done ? Theme.TEXT_TERTIARY : Theme.TEXT)
          .width(70)
          .textAlign(TextAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .borderRadius(Theme.R_MEDIUM)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
    .onClick(() => {
      this.openDetail(p);
    })
  }

  @Builder
  detailSheet() {
    Column({ space: 12 }) {
      Row() {
        Text('任务详情')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('×')
          .fontSize(16)
          .fontColor(Theme.TEXT_TERTIARY)
          .onClick(() => {
            this.showDetail = false;
          })
      }
      .width('100%')

      if (this.detailTask !== null) {
        Row({ space: 10 }) {
          Text((this.detailTask as TaskProgress).task.title)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
          Text(`+${(this.detailTask as TaskProgress).task.points} 积分`)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.POINTS)
        }
        .width('100%')

        Text(this.detailRule)
          .fontSize(12)
          .fontColor(Theme.TEXT_SECONDARY)
          .width('100%')

        Text(this.detailRemain)
          .fontSize(13)
          .fontColor((this.detailTask as TaskProgress).done ? Theme.TEXT_TERTIARY : Theme.PRIMARY)
          .width('100%')

        Text(`本期贡献记录（${this.detailTotal} 笔${this.detailTotal > 20 ? '，仅显示最近 20 笔' : ''}）`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .width('100%')

        if (this.detailRecords.length === 0) {
          Text('本期还没有相关记录，去录入页完成行为吧')
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
        }
      }

      ForEach(this.detailRecords, (r: BehaviorRecord) => {
        Row({ space: 10 }) {
          Column({ space: 3 }) {
            Text(`${r.subType} ${r.value}${r.unit}`)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
            Text(DateUtil.formatMDHM(r.createdAt))
              .fontSize(11)
              .fontColor(Theme.TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`-${(r.reductionG / 1000).toFixed(2)}kg`)
            .fontSize(12)
            .fontColor(Theme.REDUCE)
        }
        .width('100%')
        .padding(10)
        .borderRadius(Theme.R_SMALL)
        .backgroundColor(Theme.BG)
      }, (r: BehaviorRecord) => '' + r.id + '_' + r.value)
    }
    .width('100%')
    .padding(16)
  }

  @Builder
  flowRow(p: PointsRecord) {
    Row({ space: 10 }) {
      Text(p.points >= 0 ? '+' : '−')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(p.points >= 0 ? Theme.PRIMARY : Theme.WARN)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .backgroundColor(Theme.BG)
        .borderRadius(14)
      Column({ space: 3 }) {
        Text(p.action)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
        Text(`${sourceLabel(p.source)} · ${DateUtil.formatMDHM(p.createdAt)}`)
          .fontSize(11)
          .fontColor(Theme.TEXT_TERTIARY)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Column({ space: 3 }) {
        Text(`${p.points >= 0 ? '+' : ''}${p.points}`)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(p.points >= 0 ? Theme.PRIMARY : Theme.WARN)
        Text(`余额 ${p.balanceAfter}`)
          .fontSize(10)
          .fontColor(Theme.TEXT_TERTIARY)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(12)
    .borderRadius(Theme.R_SMALL)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  build() {
    Stack() {
    Column({ space: 12 }) {
      Text('任务与积分')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 14, top: 14 })

      // 余额 + 徽章入口
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('碳积分余额')
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
          Text('' + this.balance)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.PRIMARY)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Button('徽章墙与证书')
          .fontSize(13)
          .fontColor(Theme.PRIMARY)
          .backgroundColor(Theme.CARD)
          .border({ width: 1, color: Theme.PRIMARY, radius: 18 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/Badges' });
          })
      }
      .width('100%')
      .padding(16)
      .borderRadius(Theme.R_MEDIUM)
      .backgroundColor(Theme.CARD)
      .border({ width: 1, color: Theme.DIVIDER })
      .margin({ left: 14, right: 14 })

      // 分段切换
      Row({ space: 8 }) {
        Text('低碳任务')
          .fontSize(14)
          .fontColor(this.segment === 0 ? '#FFFFFF' : Theme.TEXT)
          .backgroundColor(this.segment === 0 ? Theme.PRIMARY : Theme.CARD)
          .borderRadius(16)
          .padding({ left: 16, right: 16, top: 7, bottom: 7 })
          .onClick(() => {
            this.segment = 0;
          })
        Text('积分流水')
          .fontSize(14)
          .fontColor(this.segment === 1 ? '#FFFFFF' : Theme.TEXT)
          .backgroundColor(this.segment === 1 ? Theme.PRIMARY : Theme.CARD)
          .borderRadius(16)
          .padding({ left: 16, right: 16, top: 7, bottom: 7 })
          .onClick(() => {
            this.segment = 1;
          })
        Blank()
      }
      .width('100%')
      .padding({ left: 14, right: 14 })

      if (this.segment === 0) {
        // 任务完成统计
        Row({ space: 12 }) {
          Text(`本周完成 ${this.weekDone} 次`)
            .fontSize(12)
            .fontColor(Theme.TEXT)
          Text(`累计完成 ${this.totalDone} 次`)
            .fontSize(12)
            .fontColor(Theme.TEXT)
          Blank()
          Text(`周任务剩 ${this.weekDaysLeft} 天`)
            .fontSize(11)
            .fontColor('#FF7D00')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
        .borderRadius(Theme.R_SMALL)
        .backgroundColor(Theme.CARD)
        .border({ width: 1, color: Theme.DIVIDER })
        .margin({ left: 14, right: 14 })

        List({ space: 10 }) {
          ForEach(this.tasks, (p: TaskProgress) => {
            ListItem() {
              this.taskCard(p)
            }
          }, (p: TaskProgress) => p.task.code + '_' + (p.done ? '1' : '0') + '_' + p.progress)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 14 })
      } else {
        // 来源筛选
        Row({ space: 6 }) {
          ForEach(SOURCES, (s: string) => {
            Text(this.sourceChipLabel(s))
              .fontSize(11)
              .fontColor(this.flowSource === s ? '#FFFFFF' : Theme.TEXT)
              .backgroundColor(this.flowSource === s ? Theme.PRIMARY : Theme.CARD)
              .borderRadius(12)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .onClick(() => {
                this.changeSource(s);
              })
          }, (s: string) => s)
          Blank()
        }
        .width('100%')
        .padding({ left: 14, right: 14 })

        List({ space: 8 }) {
          ForEach(this.flow, (p: PointsRecord) => {
            ListItem() {
              this.flowRow(p)
            }
          }, (p: PointsRecord) => '' + p.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 14, right: 14 })

        if (this.flow.length === this.flowLimit) {
          Text('加载更多（已显示 ' + this.flow.length + ' 条）')
            .fontSize(12)
            .fontColor(Theme.PRIMARY)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 4, bottom: 10 })
            .onClick(() => {
              this.loadMore();
            })
        }
      }

      if (this.segment === 0 && this.tasks.length === 0 && this.loaded) {
        EmptyState({ icon: '', title: '暂无任务' })
      }
      if (this.segment === 1 && this.flow.length === 0 && this.loaded) {
        EmptyState({
          icon: '',
          title: '还没有积分流水',
          desc: '记录低碳行为、完成任务、阅读科普都可以获得积分',
          buttonText: '去录入',
          onButton: (): void => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet(this.showDetail, this.detailSheet(), {
      height: 560,
      showClose: false,
      onDisappear: () => {
        this.showDetail = false;
      }
    })

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
