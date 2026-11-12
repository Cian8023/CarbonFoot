import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Theme } from '../common/Theme';
import { BehaviorRecord, behaviorSourceLabel } from '../model/Models';
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

@Component
export struct HistoryView {
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State records: BehaviorRecord[] = [];
  @State rawRecords: BehaviorRecord[] = [];
  // 时间档（0 全部 / 1 今日 / 2 近7天 / 3 近30天 / 4 自定义）；与首页周报卡预选联动：
  // @StorageLink 双向绑定后，周报卡写 historyRange=2 必然生效（同值写入与懒初始化场景均不再漏触发）
  @StorageLink('historyRange') @Watch('onRangeChanged') rangeIndex: number = 1;
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
  @State recBasis: string = '';
  @State recSource: string = '';
  @State totalG: number = 0;
  @State groups: RecordGroup[] = [];

  aboutToAppear(): void {
    this.refresh();
  }

  /** 档位变化（本页点选或首页周报卡预选）后刷新数据 */
  onRangeChanged(): void {
    this.refresh();
  }

  /** 刷新序号：并发调用时只采纳最后一次的结果，避免旧查询覆盖新数据 */
  private refreshSeq: number = 0;

  async refresh(): Promise<void> {
    const seq = ++this.refreshSeq;
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
      const rows = await BehaviorRepo.query(start, end, this.typeFilter);
      // 并发保护：若期间又触发了更新的一次 refresh，本次结果作废，
      // 否则先发出的慢查询会覆盖后发出的快查询，界面停在旧数据
      if (seq !== this.refreshSeq) {
        return;
      }
      this.rawRecords = rows;
      // 子类型对比直接复用本次区间查询结果，不再额外全表扫描
      this.bars = StatsService.subShare(this.rawRecords, 0);
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
    this.groups = this.buildGroups(list);
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
    // 系数出处与适用条件：让用户看得懂"这个数是怎么来的"
    const sub = CalculationService.findSub(r.type, r.subType);
    this.recBasis = sub !== null && sub.basis !== undefined ? sub.basis : '';
    if (sub !== null && sub.source !== undefined) {
      const yr = sub.year !== undefined ? ' · ' + sub.year : '';
      this.recSource = sub.source + yr;
    } else {
      this.recSource = '';
    }
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
          .fontSize(Theme.FS_TITLE)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('×')
          .fontSize(Theme.FS_TITLE)
          .fontColor(Theme.TEXT_TERTIARY)
          .onClick(() => {
            this.showSheet = false;
          })
      }
      .width('100%')

      if (this.selRecord !== null) {
        Row({ space: 10 }) {
          Text('·')
            .fontSize(Theme.FS_DISPLAY)
          Column({ space: 4 }) {
            Text((this.selRecord as BehaviorRecord).subType)
              .fontSize(Theme.FS_TITLE)
              .fontWeight(FontWeight.Medium)
            Text(`${(this.selRecord as BehaviorRecord).type} · ${(this.selRecord as BehaviorRecord).value}${(this.selRecord as BehaviorRecord).unit} × ${(this.selRecord as BehaviorRecord).factor}g`)
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(Theme.TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(`${((this.selRecord as BehaviorRecord).reductionG / 1000).toFixed(2)} kg CO₂e`)
            .fontSize(Theme.FS_HEAD)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.REDUCE)
        }
        .width('100%')

        // 算法透明：数值 × 系数 = 减排量，并给出单位含义、系数出处与估算声明
        Column({ space: 4 }) {
          Text(`计算：${(this.selRecord as BehaviorRecord).value}${(this.selRecord as BehaviorRecord).unit} × ${(this.selRecord as BehaviorRecord).factor}g/${(this.selRecord as BehaviorRecord).unit} = ${((this.selRecord as BehaviorRecord).reductionG / 1000).toFixed(2)} kg CO₂e`)
            .fontSize(Theme.FS_SECONDARY)
            .fontColor(Theme.TEXT_SECONDARY)
            .width('100%')
          if (this.recBasis !== '') {
            Text(`口径：${this.recBasis}`)
              .fontSize(Theme.FS_CAPTION)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')
          }
          if (this.recSource !== '') {
            Text(`系数出处：${this.recSource}`)
              .fontSize(Theme.FS_CAPTION)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')
          }
          Text('※ 减排量为估算值，用于生活记录与激励，不用于碳交易、碳核查或认证')
            .fontSize(Theme.FS_CAPTION)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
        }
        .width('100%')
        .padding(10)
        .backgroundColor(Theme.BG_GRAY)
        .borderRadius(10)
        .alignItems(HorizontalAlign.Start)

        Text(this.recPointsText)
          .fontSize(Theme.FS_TERTIARY)
          .fontColor(Theme.POINTS)
          .width('100%')

        Text(`录入时间：${DateUtil.formatFull((this.selRecord as BehaviorRecord).createdAt)}`)
          .fontSize(Theme.FS_BODY)
          .fontColor(Theme.TEXT_TERTIARY)
          .width('100%')

        Row({ space: 6 }) {
          Text('数据来源')
            .fontSize(Theme.FS_BODY)
            .fontColor(Theme.TEXT_TERTIARY)
          Text(behaviorSourceLabel((this.selRecord as BehaviorRecord).source))
            .fontSize(Theme.FS_CAPTION)
            .fontColor(Theme.PRIMARY)
            .border({ width: 1, color: Theme.PRIMARY, radius: 6 })
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
        }
        .width('100%')

        // 修改数值
        Row({ space: 10 }) {
          Text('数值')
            .fontSize(Theme.FS_BODY)
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
            .fontSize(Theme.FS_TERTIARY)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')

        // 修改日期（保留原时分秒；不可选未来日期）
        Row({ space: 10 }) {
          Text('日期')
            .fontSize(Theme.FS_BODY)
            .fontColor(Theme.TEXT)
            .width(40)
          CalendarPicker({
            selected: new Date(this.editTs > 0 ? this.editTs : (this.selRecord as BehaviorRecord).createdAt),
            end: new Date()
          })
            .onChange((date: Date) => {
              const base = this.editTs > 0 ? this.editTs : (this.selRecord as BehaviorRecord).createdAt;
              const d = new Date(base);
              this.editTs = new Date(date.getFullYear(), date.getMonth(), date.getDate(),
                d.getHours(), d.getMinutes(), d.getSeconds()).getTime();
            })
          if (this.editTs > 0) {
            Text('已改为 ' + DateUtil.formatMDHM(this.editTs))
              .fontSize(Theme.FS_SECONDARY)
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
            .fontSize(Theme.FS_CONTENT)
            .backgroundColor(Theme.PRIMARY)
            .onClick(() => {
              this.saveEdit();
            })
          Button('保存备注')
            .layoutWeight(1)
            .height(40)
            .fontSize(Theme.FS_CONTENT)
            .backgroundColor(Theme.PRIMARY_HOVER)
            .onClick(() => {
              this.saveNote();
            })
        }
        .width('100%')

        Button('删除记录')
          .width('100%')
          .height(40)
          .fontSize(Theme.FS_CONTENT)
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
      // 服务层会抛出具体原因（超上限 / 未来时间），原样提示，避免"失败请重试"掩盖真实问题
      promptAction.showToast({ message: (e as Error).message });
    }
  }

  private async doDelete(id: number): Promise<void> {
    try {
      await BehaviorService.deleteById(id);
      this.selRecord = null;
      this.showSheet = false;
      promptAction.showToast({ message: '已删除' });
    } catch (e) {
      promptAction.showToast({ message: '删除失败，请重试' });
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
          this.doDelete(id);
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
        .fontSize(Theme.FS_HERO)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .padding({ left: 14, top: 14 })

      // 筛选
      Column({ space: 10 }) {
        // 关键字输入只暂存，点击搜索按钮（或键盘回车）才过滤
        Row({ space: 8 }) {
          TextInput({ placeholder: '搜索子类型或备注', text: this.keyword })
            .height(36)
            .fontSize(Theme.FS_BODY)
            .layoutWeight(1)
            .backgroundColor(Theme.BG_GRAY)
            .borderRadius(12)
            .onChange((v: string) => {
              this.keyword = v;
            })
            .onSubmit(() => {
              this.applyFilter();
            })
          Button('搜索')
            .height(36)
            .fontSize(Theme.FS_BODY)
            .backgroundColor(Theme.PRIMARY)
            .borderRadius(12)
            .padding({ left: 14, right: 14 })
            .onClick(() => {
              this.applyFilter();
            })
        }
        .width('100%')

        Row({ space: 8 }) {
          ForEach(RANGES, (r: string, idx: number) => {
            Text(r)
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(this.rangeIndex === idx ? '#FFFFFF' : Theme.TEXT)
              .backgroundColor(this.rangeIndex === idx ? Theme.PRIMARY : Theme.BG_GRAY)
              .borderRadius(14)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => {
                this.rangeIndex = idx;
              })
          }, (r: string, idx: number) => idx.toString())
        }
        .width('100%')

        if (this.rangeIndex === 4) {
          // key 随起止变化：约束变化时重建日历，保证灰显范围始终最新
          ForEach([this.customStart + '_' + this.customEnd], (_k: string) => {
            Row({ space: 8 }) {
              Text('起')
                .fontSize(Theme.FS_TERTIARY)
                .fontColor(Theme.TEXT_TERTIARY)
              CalendarPicker({ selected: new Date(this.customStart), end: new Date(this.customEnd) })
                .onChange((date: Date) => {
                  this.customStart = DateUtil.startOfDay(date.getTime());
                  this.refresh();
                })
              Text('止')
                .fontSize(Theme.FS_TERTIARY)
                .fontColor(Theme.TEXT_TERTIARY)
              CalendarPicker({
                selected: new Date(this.customEnd),
                start: new Date(this.customStart),
                end: new Date(DateUtil.startOfDay(Date.now()))
              })
                .onChange((date: Date) => {
                  this.customEnd = DateUtil.startOfDay(date.getTime());
                  this.refresh();
                })
            }
            .width('100%')
            .focusable(false)
          }, (k: string) => k)
        }

        Row({ space: 8 }) {
          ForEach(TYPES, (t: string, idx: number) => {
            Text(t)
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(this.typeFilter === t ? '#FFFFFF' : Theme.TEXT)
              .backgroundColor(this.typeFilter === t ? Theme.PRIMARY : Theme.BG_GRAY)
              .borderRadius(14)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => {
                this.typeFilter = t;
                this.refresh();
              })
          }, (t: string, idx: number) => idx.toString())
        }
        .width('100%')

        // 合计单独一行：与时间筛选挤在同一行会被裁掉单位
        Row() {
          Text(`共 ${this.records.length} 条`)
            .fontSize(Theme.FS_SECONDARY)
            .fontColor(Theme.TEXT_TERTIARY)
          Blank()
          Text(`合计 ${DateUtil.gramsToKg(this.totalG)} kg CO₂e`)
            .fontSize(Theme.FS_TERTIARY)
            .fontColor(Theme.REDUCE)
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 14, right: 14 })

      // 记录列表：直接铺在整页 Scroll 里，随页面一起滚动
      Column({ space: 12 }) {
        ForEach(this.groups, (g: RecordGroup) => {
          Column({ space: 8 }) {
            Row() {
              Text(g.label)
                .fontSize(Theme.FS_TITLE)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.TEXT)
                .backgroundColor(Theme.BG_GRAY)
                .borderRadius(18)
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
                  Row({ space: 6 }) {
                    Text(`${r.subType} ${r.value}${r.unit}`)
                      .fontSize(Theme.FS_TITLE)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    if (r.source !== undefined && r.source !== '' && r.source !== 'manual') {
                      Text(behaviorSourceLabel(r.source))
                        .fontSize(Theme.FS_MICRO)
                        .fontColor(Theme.PRIMARY)
                        .backgroundColor(Theme.PRIMARY_BG)
                        .borderRadius(6)
                        .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                    }
                  }
                  .width('100%')
                  Text(DateUtil.formatMDHM(r.createdAt) + (r.note !== '' ? ' · ' + r.note : ''))
                    .fontSize(Theme.FS_BODY)
                    .fontColor(Theme.TEXT_TERTIARY)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text(`-${(r.reductionG / 1000).toFixed(2)}kg`)
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.REDUCE)
              }
              .width('100%')
              .padding(14)
              .borderRadius(16)
              .backgroundColor(Theme.CARD)
              .borderWidth(1).borderColor(Theme.CARD_BORDER)
              .onClick(() => {
                this.openDetail(r);
              })
            }, (r: BehaviorRecord) => '' + r.id + '_' + r.note + '_' + r.value)
          }
          .width('100%')
        }, (g: RecordGroup) => g.label + '#' + g.items.map((r: BehaviorRecord) => '' + r.id + '_' + r.value + '_' + r.reductionG).join(','))
      }
      .width('100%')
      .padding({ left: 14, right: 14 })

      if (this.records.length === 0) {
        EmptyState({
          icon: '',
          title: this.keyword.trim() === '' ? '暂无记录' : '没有匹配的记录',
          desc: this.keyword.trim() === ''
            ? '当前筛选条件下没有低碳行为记录'
            : `未找到包含「${this.keyword.trim()}」的记录，换个关键词试试`,
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
            .fontSize(Theme.FS_TITLE)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          BarChart({ items: this.bars })
        }
        .width('100%')
        .margin({ left: 14, right: 14, bottom: 12 })
        .padding(14)
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)
      }
    }
    .width('100%')
    .bindSheet(this.showSheet, this.detailSheet(), {
      height: 600,
      showClose: false,
      onDisappear: () => {
        this.showSheet = false;
      }
    })
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
  }
}
