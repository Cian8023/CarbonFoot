import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants } from '../common/Constants';
import { Theme } from '../common/Theme';
import { TaskProgress, PointsRecord, sourceLabel } from '../model/Models';
import { TaskService } from '../service/TaskService';
import { PointsService } from '../service/PointsService';
import { DateUtil } from '../utils/DateUtil';
import { EmptyState } from '../components/EmptyState';

@Component
export struct TasksView {
  @StorageLink('tasksSegment') @Watch('refresh') segment: number = 0;
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State tasks: TaskProgress[] = [];
  @State flow: PointsRecord[] = [];
  @State balance: number = 0;
  @State loaded: boolean = false;

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      // 达标任务自动发积分
      const awarded: string[] = await TaskService.evaluateAll();
      if (awarded.length > 0 && this.loaded) {
        promptAction.showToast({
          message: `完成任务：${awarded.join('、')}，积分已到账`,
          duration: 2500
        });
      }
      this.tasks = await TaskService.listProgress();
      this.flow = await PointsService.queryFlow(100);
      this.balance = await PointsService.getBalance();
      this.loaded = true;
    } catch (e) {
      console.error('TasksView refresh error: ' + JSON.stringify(e));
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
            if (p.done) {
              Text('已完成')
                .fontSize(10)
                .fontColor(Theme.TEXT_SUB)
              Blank()
            }
          }
          Text(p.task.description)
            .fontSize(12)
            .fontColor(Theme.TEXT_SUB)
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
          .color(p.done ? Theme.PRIMARY_LIGHT : Theme.PRIMARY)
        Text(p.done ? '已达成' : `${p.progress}/${p.target}`)
          .fontSize(12)
          .fontColor(p.done ? Theme.TEXT_SUB : Theme.TEXT)
          .width(70)
          .textAlign(TextAlign.End)
      }
      .width('100%')
    }
    .width('100%')
    .padding(14)
    .borderRadius(Theme.R_CARD)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
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
          .fontColor(Theme.TEXT_SUB)
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
          .fontColor(Theme.TEXT_SUB)
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(12)
    .borderRadius(Theme.R_ITEM)
    .backgroundColor(Theme.CARD)
    .border({ width: 1, color: Theme.DIVIDER })
  }

  build() {
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
            .fontColor(Theme.TEXT_SUB)
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
      .borderRadius(Theme.R_CARD)
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
        List({ space: 8 }) {
          ForEach(this.flow, (p: PointsRecord) => {
            ListItem() {
              this.flowRow(p)
            }
          }, (p: PointsRecord) => '' + p.id)
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 14 })
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
  }
}
