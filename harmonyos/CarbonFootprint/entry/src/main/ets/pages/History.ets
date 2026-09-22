import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Theme } from '../common/Theme';
import { categoryIcon } from '../common/Constants';
import { BehaviorRecord } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import { BehaviorService } from '../service/BehaviorService';
import { StatsService } from '../service/StatsService';
import { DateUtil } from '../utils/DateUtil';
import { BarChart, PieItem } from '../components/Chart';
import { EmptyState } from '../components/EmptyState';

const RANGES: string[] = ['今日', '近7天', '近30天', '全部'];
const TYPES: string[] = ['全部', '出行', '节水节电', '旧物回收', '光盘行动'];

@Component
export struct HistoryView {
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State records: BehaviorRecord[] = [];
  @State rangeIndex: number = 1;
  @State typeFilter: string = '全部';
  @State bars: PieItem[] = [];
  @State selRecord: BehaviorRecord | null = null;
  @State showSheet: boolean = false;
  @State editNote: string = '';
  @State totalG: number = 0;

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      const now = Date.now();
      let start = 0;
      if (this.rangeIndex === 0) {
        start = DateUtil.startOfDay(now);
      } else if (this.rangeIndex === 1) {
        start = DateUtil.startOfDay(now) - 6 * DateUtil.DAY_MS;
      } else if (this.rangeIndex === 2) {
        start = DateUtil.startOfDay(now) - 29 * DateUtil.DAY_MS;
      }
      this.records = await BehaviorRepo.query(start, now, this.typeFilter);
      let sum = 0;
      for (const r of this.records) {
        sum += r.reductionG;
      }
      this.totalG = sum;
      const items = StatsService.subShare(await BehaviorRepo.all(), start === 0 ? 0 : start);
      this.bars = items;
    } catch (e) {
      console.error('HistoryView refresh error: ' + JSON.stringify(e));
    }
  }

  @Builder
  chip(label: string, selected: boolean, onSelect: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor(selected ? '#FFFFFF' : Theme.TEXT)
      .backgroundColor(selected ? Theme.PRIMARY : Theme.CARD)
      .borderRadius(14)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .onClick(() => {
        onSelect();
      })
  }

  @Builder
  detailSheet() {
    Column({ space: 12 }) {
      Row() {
        Text('行为详情')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('✕')
          .fontSize(16)
          .fontColor(Theme.TEXT_SUB)
          .onClick(() => {
            this.showSheet = false;
          })
      }
      .width('100%')

      if (this.selRecord !== null) {
        Row({ space: 10 }) {
          Text(categoryIcon((this.selRecord as BehaviorRecord).type))
            .fontSize(30)
          Column({ space: 4 }) {
            Text((this.selRecord as BehaviorRecord).subType)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
            Text(`${(this.selRecord as BehaviorRecord).type} · ${(this.selRecord as BehaviorRecord).value}${(this.selRecord as BehaviorRecord).unit} × ${(this.selRecord as BehaviorRecord).factor}g`)
              .fontSize(12)
              .fontColor(Theme.TEXT_SUB)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`${((this.selRecord as BehaviorRecord).reductionG / 1000).toFixed(2)} kg`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.REDUCE)
        }
        .width('100%')

        Text(`时间：${DateUtil.formatFull((this.selRecord as BehaviorRecord).createdAt)}`)
          .fontSize(13)
          .fontColor(Theme.TEXT_SUB)
          .width('100%')

        Text(`备注：${(this.selRecord as BehaviorRecord).note !== '' ? (this.selRecord as BehaviorRecord).note : '无'}`)
          .fontSize(13)
          .fontColor(Theme.TEXT_SUB)
          .width('100%')

        TextInput({ placeholder: '修改备注（≤100字）', text: this.editNote })
          .height(42)
          .onChange((v: string) => {
            this.editNote = v;
          })

        Row({ space: 12 }) {
          Button('删除记录')
            .layoutWeight(1)
            .height(42)
            .fontSize(14)
            .backgroundColor(Theme.WARN)
            .onClick(() => {
              this.confirmDelete();
            })
          Button('保存备注')
            .layoutWeight(1)
            .height(42)
            .fontSize(14)
            .backgroundColor(Theme.PRIMARY)
            .onClick(() => {
              this.saveNote();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
  }

  private confirmDelete(): void {
    if (this.selRecord === null) {
      return;
    }
    const id = (this.selRecord as BehaviorRecord).id;
    AlertDialog.show({
      title: '删除确认',
      message: '删除后该记录的减排量与积分流水将无法恢复，确定删除？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '删除',
        fontColor: Theme.WARN,
        action: () => {
          BehaviorService.deleteById(id);
          this.showSheet = false;
          promptAction.showToast({ message: '已删除' });
        }
      }
    });
  }

  private async saveNote(): Promise<void> {
    if (this.selRecord === null) {
      return;
    }
    if (this.editNote.length > 100) {
      promptAction.showToast({ message: '备注不能超过 100 字' });
      return;
    }
    const id = (this.selRecord as BehaviorRecord).id;
    await BehaviorService.updateNote(id, this.editNote);
    this.selRecord = null;
    this.showSheet = false;
    promptAction.showToast({ message: '备注已更新' });
  }

  build() {
    Column({ space: 12 }) {
      Text('历史记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 14, top: 14 })

      // 筛选
      Column({ space: 10 }) {
        Row({ space: 8 }) {
          ForEach(RANGES, (r: string, idx: number) => {
            this.chip(r, this.rangeIndex === idx, (): void => {
              this.rangeIndex = idx;
              this.refresh();
            })
          }, (r: string) => r)
          Blank()
          Text(`合计 ${DateUtil.gramsToKg(this.totalG)} kg`)
            .fontSize(12)
            .fontColor(Theme.REDUCE)
        }
        .width('100%')

        Row({ space: 8 }) {
          ForEach(TYPES, (t: string) => {
            this.chip(t, this.typeFilter === t, (): void => {
              this.typeFilter = t;
              this.refresh();
            })
          }, (t: string) => t)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 14, right: 14 })

      List({ space: 8 }) {
        ForEach(this.records, (r: BehaviorRecord) => {
          ListItem() {
            Row({ space: 12 }) {
              Text(categoryIcon(r.type))
                .fontSize(24)
                .width(44)
                .height(44)
                .textAlign(TextAlign.Center)
                .backgroundColor(Theme.PRIMARY_BG)
                .borderRadius(12)
              Column({ space: 4 }) {
                Text(`${r.subType} ${r.value}${r.unit}`)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                Text(DateUtil.formatMDHM(r.createdAt) + (r.note !== '' ? ' · ' + r.note : ''))
                  .fontSize(11)
                  .fontColor(Theme.TEXT_SUB)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text(`-${(r.reductionG / 1000).toFixed(2)}kg`)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.REDUCE)
            }
            .width('100%')
            .padding(12)
            .borderRadius(12)
            .backgroundColor(Theme.CARD)
            .onClick(() => {
              this.selRecord = r;
              this.editNote = r.note;
              this.showSheet = true;
            })
          }
        }, (r: BehaviorRecord) => '' + r.id + '_' + r.note)
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 14, right: 14 })
      .bindSheet(this.showSheet, this.detailSheet(), {
        height: 460,
        showClose: false,
        onDisappear: () => {
          this.showSheet = false;
        }
      })

      if (this.records.length === 0) {
        EmptyState({
          icon: '📭',
          title: '暂无记录',
          desc: '当前筛选条件下没有低碳行为记录',
          buttonText: '去记录',
          onButton: (): void => {
            AppStorage.setOrCreate('mainTab', 1);
          }
        })
      }

      // 子类型减排对比
      if (this.bars.length > 0) {
        Column({ space: 10 }) {
          Text('子类型减排对比（当期）')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
          BarChart({ items: this.bars })
        }
        .width('100%')
        .margin({ left: 14, right: 14, bottom: 12 })
        .padding(14)
        .borderRadius(16)
        .backgroundColor(Theme.CARD)
      }
    }
    .width('100%')
    .height('100%')
  }
}
