import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Theme } from '../common/Theme';
import { BehaviorRecord } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import { BehaviorService } from '../service/BehaviorService';
import { CalculationService } from '../service/CalculationService';
import { StatsService } from '../service/StatsService';
import { PointsService } from '../service/PointsService';
import { DateUtil } from '../utils/DateUtil';
import { BarChart, PieItem } from '../components/Chart';
import { EmptyState } from '../components/EmptyState';

const RANGES: string[] = ['全部', '今日', '近7天', '近30天', '自定义'];
const TYPES: string[] = ['全部', '出行', '节水节电', '旧物回收', '光盘行动'];

/** 按日期分组后的一个分组 */
export interface RecordGroup {
  label: string;
  items: BehaviorRecord[];
}

/** 分组数据源：顶层按分组懒加载渲染，长列表不一次性铺满 */
class GroupDataSource implements IDataSource {
  private groups: RecordGroup[] = [];
  private listeners: DataChangeListener[] = [];

  setData(groups: RecordGroup[]): void {
    this.groups = groups;
    for (const l of this.listeners) {
      l.onDataReloaded();
    }
  }

  totalCount(): number {
    return this.groups.length;
  }

  getData(i: number): RecordGroup {
    return this.groups[i];
  }

  registerDataChangeListener(l: DataChangeListener): void {
    this.listeners.push(l);
  }

  unregisterDataChangeListener(l: DataChangeListener): void {
    const i = this.listeners.indexOf(l);
    if (i >= 0) {
      this.listeners.splice(i, 1);
    }
  }
}

@Component
export struct HistoryView {
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State records: BehaviorRecord[] = [];
  @State rawRecords: BehaviorRecord[] = [];
  @State rangeIndex: number = 1;
  // 首页周报卡跳转时预选的时间档（0 全部 / 1 今日 / 2 近7天 / 3 近30天 / 4 自定义） */
  @StorageProp('historyRange') @Watch('onExternalRange') extRange: number = 1;
  @State typeFilter: string = '全部';
  @State keyword: string = '';
  @State customStart: number = DateUtil.startOfDay(Date.now()) - 6 * DateUtil.DAY_MS;
  @State customEnd: number = DateUtil.startOfDay(Date.now());
  @State bars: PieItem[] = [];
  @State selRecord: BehaviorRecord | null = null;
  @State showSheet: boolean = false;
  @State editNote: string = '';
  @State editValue: string = '';
  @State editTs: number = 0;
  @State recPointsText: string = '';
  @State totalG: number = 0;
  private groupSrc: GroupDataSource = new GroupDataSource();

  aboutToAppear(): void {
    this.refresh();
  }

  /** 首页周报卡等外部入口预选时间档 */
  onExternalRange(): void {
    if (this.rangeIndex !== this.extRange) {
      this.rangeIndex = this.extRange;
      this.refresh();
    }
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      const now = Date.now();
      let start = 0;
      let end = now;
      if (this.rangeIndex === 1) {
        start = DateUtil.startOfDay(now);
      } else if (this.rangeIndex === 2) {
        start = DateUtil.startOfDay(now) - 6 * DateUtil.DAY_MS;
      } else if (this.rangeIndex === 3) {
        start = DateUtil.startOfDay(now) - 29 * DateUtil.DAY_MS;
      } else if (this.rangeIndex === 4) {
        // 自定义区间：截止日取整天，未来时刻自动收敛到当前
        start = this.customStart;
        end = this.customEnd + DateUtil.DAY_MS - 1;
        if (end > now) {
          end = now;
        }
        if (start > end) {
          start = 0;
        }
      }
      this.rawRecords = await BehaviorRepo.query(start, end, this.typeFilter);
      const items = StatsService.subShare(await BehaviorRepo.all(), start === 0 ? 0 : start);
      this.bars = items;
      this.applyFilter();
    } catch (e) {
      console.error('HistoryView refresh error: ' + JSON.stringify(e));
    }
  }

  /** 关键字过滤 + 汇总 + 分组（输入关键字时只做内存过滤，不重复查库） */
  private applyFilter(): void {
    const kw = this.keyword.trim();
    let list = this.rawRecords;
    if (kw !== '') {
      list = list.filter((r: BehaviorRecord) => r.subType.includes(kw) || r.note.includes(kw));
    }
    this.records = list;
    let sum = 0;
    for (const r of list) {
      sum += r.reductionG;
    }
    this.totalG = sum;
    this.groupSrc.setData(this.buildGroups(list));
  }

  private buildGroups(list: BehaviorRecord[]): RecordGroup[] {
    const groups: RecordGroup[] = [];
    let cur: RecordGroup | null = null;
    for (const r of list) {
      const label = this.groupLabel(r.createdAt);
      if (cur === null || cur.label !== label) {
        const g: RecordGroup = { label: label, items: [] };
        groups.push(g);
        cur = g;
      }
      (cur as RecordGroup).items.push(r);
    }
    return groups;
  }

  /** 今天 / 昨天 / M月D日（跨年带年份）；记录已按时间倒序，顺序遍历即可分段 */
  private groupLabel(ts: number): string {
    const today = DateUtil.startOfDay(Date.now());
    const day = DateUtil.startOfDay(ts);
    if (day === today) {
      return '今天';
    }
    if (day === today - DateUtil.DAY_MS) {
      return '昨天';
    }
    const d = new Date(ts);
    const label = (d.getMonth() + 1) + '月' + d.getDate() + '日';
    if (d.getFullYear() === new Date().getFullYear()) {
      return label;
    }
    return d.getFullYear() + '年' + label;
  }

  private openDetail(r: BehaviorRecord): void {
    this.selRecord = r;
    this.editNote = r.note;
    this.editValue = '' + r.value;
    this.editTs = 0;
    this.recPointsText = '查询中…';
    this.showSheet = true;
    this.loadPoints(r.id);
  }

  /** 反查本笔记录关联的全部积分流水（发放/修改补正），展示净积分与冲减明细 */
  private async loadPoints(id: number): Promise<void> {
    try {
      const flows = await PointsService.listBySourceRef('behavior', id);
      let net = 0;
      let reversed = 0;
      for (const f of flows) {
        net += f.points;
        if (f.points < 0) {
          reversed += -f.points;
        }
      }
      if (flows.length === 0) {
        this.recPointsText = '本笔积分：0 分';
      } else if (reversed > 0) {
        this.recPointsText = `本笔积分：净 ${net} 分（含冲减 ${reversed} 分）`;
      } else {
        this.recPointsText = `本笔积分：+${net} 分`;
      }
    } catch (e) {
      this.recPointsText = '本笔积分：查询失败';
    }
  }

  @Builder
  detailSheet() {
    Column({ space: 12 }) {
      Row() {
        Text('行为详情')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('×')
          .fontSize(16)
          .fontColor(Theme.TEXT_TERTIARY)
          .onClick(() => {
            this.showSheet = false;
          })
      }
      .width('100%')

      if (this.selRecord !== null) {
        Row({ space: 10 }) {
          Text('·')
            .fontSize(30)
          Column({ space: 4 }) {
            Text((this.selRecord as BehaviorRecord).subType)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
            Text(`${(this.selRecord as BehaviorRecord).type} · ${(this.selRecord as BehaviorRecord).value}${(this.selRecord as BehaviorRecord).unit} × ${(this.selRecord as BehaviorRecord).factor}g`)
              .fontSize(12)
              .fontColor(Theme.TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`${((this.selRecord as BehaviorRecord).reductionG / 1000).toFixed(2)} kg`)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.REDUCE)
        }
        .width('100%')

        Text(this.recPointsText)
          .fontSize(12)
          .fontColor(Theme.POINTS)
          .width('100%')

        Text(`录入时间：${DateUtil.formatFull((this.selRecord as BehaviorRecord).createdAt)}`)
          .fontSize(13)
          .fontColor(Theme.TEXT_TERTIARY)
          .width('100%')

        // 修改数值
        Row({ space: 10 }) {
          Text('数值')
            .fontSize(13)
            .fontColor(Theme.TEXT)
            .width(40)
          TextInput({ placeholder: '修改数值', text: this.editValue })
            .type(InputType.NUMBER_DECIMAL)
            .layoutWeight(1)
            .height(38)
            .onChange((v: string) => {
              this.editValue = v;
            })
          Text((this.selRecord as BehaviorRecord).unit)
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')

        // 修改日期（保留原时分秒）
        Row({ space: 10 }) {
          Text('日期')
            .fontSize(13)
            .fontColor(Theme.TEXT)
            .width(40)
          CalendarPicker({ selected: new Date(this.editTs > 0 ? this.editTs : (this.selRecord as BehaviorRecord).createdAt) })
            .onChange((date: Date) => {
              const base = this.editTs > 0 ? this.editTs : (this.selRecord as BehaviorRecord).createdAt;
              const d = new Date(base);
              this.editTs = new Date(date.getFullYear(), date.getMonth(), date.getDate(),
                d.getHours(), d.getMinutes(), d.getSeconds()).getTime();
            })
          if (this.editTs > 0) {
            Text('已改为 ' + DateUtil.formatMDHM(this.editTs))
              .fontSize(11)
              .fontColor(Theme.PRIMARY)
          }
        }
        .width('100%')

        TextInput({ placeholder: '修改备注（≤100字）', text: this.editNote })
          .height(38)
          .onChange((v: string) => {
            this.editNote = v;
          })

        Row({ space: 12 }) {
          Button('保存修改')
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor(Theme.PRIMARY)
            .onClick(() => {
              this.saveEdit();
            })
          Button('保存备注')
            .layoutWeight(1)
            .height(40)
            .fontSize(14)
            .backgroundColor(Theme.PRIMARY_HOVER)
            .onClick(() => {
              this.saveNote();
            })
        }
        .width('100%')

        Button('删除记录')
          .width('100%')
          .height(40)
          .fontSize(14)
          .backgroundColor(Theme.WARN)
          .onClick(() => {
            this.confirmDelete();
          })
      }
    }
    .width('100%')
    .padding(16)
  }

  private async saveEdit(): Promise<void> {
    if (this.selRecord === null) {
      return;
    }
    const rec = this.selRecord as BehaviorRecord;
    const v = parseFloat(this.editValue);
    if (isNaN(v) || v <= 0) {
      promptAction.showToast({ message: '请输入大于 0 的数值' });
      return;
    }
    const sub = CalculationService.findSub(rec.type, rec.subType);
    if (sub !== null && v > sub.max) {
      promptAction.showToast({ message: `超出单次上限 ${sub.max}${sub.unit}` });
      return;
    }
    try {
      await BehaviorService.updateRecord(rec.id, v, this.editTs);
      this.selRecord = null;
      this.showSheet = false;
      promptAction.showToast({ message: '记录已更新' });
    } catch (e) {
      promptAction.showToast({ message: '更新失败，请重试' });
    }
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
    Scroll() {
    Column({ space: 12 }) {
      Text('历史记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 14, top: 14 })

      // 筛选
      Column({ space: 10 }) {
        TextInput({ placeholder: '搜索子类型或备注' })
          .height(36)
          .fontSize(13)
          .onChange((v: string) => {
            this.keyword = v;
            this.applyFilter();
          })

        Row({ space: 8 }) {
          ForEach(RANGES, (r: string, idx: number) => {
            Text(r)
              .fontSize(12)
              .fontColor(this.rangeIndex === idx ? '#FFFFFF' : Theme.TEXT)
              .backgroundColor(this.rangeIndex === idx ? Theme.PRIMARY : Theme.CARD)
              .borderRadius(14)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => {
                this.rangeIndex = idx;
                this.refresh();
              })
          }, (r: string, idx: number) => idx.toString())
          Blank()
          Text(`合计 ${DateUtil.gramsToKg(this.totalG)} kg`)
            .fontSize(12)
            .fontColor(Theme.REDUCE)
        }
        .width('100%')

        if (this.rangeIndex === 4) {
          Row({ space: 8 }) {
            Text('起')
              .fontSize(12)
              .fontColor(Theme.TEXT_TERTIARY)
            CalendarPicker({ selected: new Date(this.customStart) })
              .onChange((date: Date) => {
                this.customStart = DateUtil.startOfDay(date.getTime());
                this.refresh();
              })
            Text('止')
              .fontSize(12)
              .fontColor(Theme.TEXT_TERTIARY)
            CalendarPicker({ selected: new Date(this.customEnd) })
              .onChange((date: Date) => {
                this.customEnd = DateUtil.startOfDay(date.getTime());
                this.refresh();
              })
          }
          .width('100%')
        }

        Row({ space: 8 }) {
          ForEach(TYPES, (t: string, idx: number) => {
            Text(t)
              .fontSize(12)
              .fontColor(this.typeFilter === t ? '#FFFFFF' : Theme.TEXT)
              .backgroundColor(this.typeFilter === t ? Theme.PRIMARY : Theme.CARD)
              .borderRadius(14)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => {
                this.typeFilter = t;
                this.refresh();
              })
          }, (t: string, idx: number) => idx.toString())
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 14, right: 14 })

      List({ space: 12 }) {
        LazyForEach(this.groupSrc, (g: RecordGroup) => {
          ListItem() {
            Column({ space: 8 }) {
              Row() {
                Text(g.label)
                  .fontSize(28)
                  .fontColor(Theme.TEXT)
                  .backgroundColor(Theme.BG)
                  .borderRadius(16)
                  .padding({ left: 20, right: 20, top: 8, bottom: 8 })
              }
              .width('100%')
              ForEach(g.items, (r: BehaviorRecord) => {
                Row({ space: 12 }) {
                  Column()
                    .width(3)
                    .height(34)
                    .borderRadius(2)
                    .backgroundColor(Theme.PRIMARY_HOVER)
                  Column({ space: 4 }) {
                    Text(`${r.subType} ${r.value}${r.unit}`)
                      .fontSize(28)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(DateUtil.formatMDHM(r.createdAt) + (r.note !== '' ? ' · ' + r.note : ''))
                      .fontSize(28)
                      .fontColor(Theme.TEXT_TERTIARY)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(`-${(r.reductionG / 1000).toFixed(2)}kg`)
                    .fontSize(28)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.REDUCE)
                }
                .width('100%')
                .padding(12)
                .borderRadius(Theme.R_SMALL)
                .backgroundColor(Theme.CARD)
                .border({ width: 1, color: Theme.DIVIDER })
                .onClick(() => {
                  this.openDetail(r);
                })
              }, (r: BehaviorRecord) => '' + r.id + '_' + r.note + '_' + r.value)
            }
            .width('100%')
          }
        }, (g: RecordGroup) => g.label + '#' + g.items.length)
      }
      .width('100%')
      .padding({ left: 14, right: 14 })
      .height(this.records.length * 128 + 24)
      .bindSheet(this.showSheet, this.detailSheet(), {
        height: 600,
        showClose: false,
        onDisappear: () => {
          this.showSheet = false;
        }
      })

      if (this.records.length === 0) {
        EmptyState({
          icon: '',
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
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }
}
