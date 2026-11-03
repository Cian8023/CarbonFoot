import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { AppInit } from '../common/AppInit';
import { Constants, gotoTab } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BehaviorCategory, SubType } from '../model/Models';
import { CalculationService } from '../service/CalculationService';
import { BehaviorService } from '../service/BehaviorService';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorPicker } from '../components/BehaviorPicker';
import { BadgeUnlockOverlay } from '../components/BadgeUnlock';

@Component
export struct RecordView {
  @StorageLink('tick') @Watch('onDataTick') tick: number = 0;
  @State categories: BehaviorCategory[] = [];
  @State selType: string = '';
  @State selSub: string = '';
  @State valueText: string = '';
  @State noteText: string = '';
  @State customTs: number = 0;
  @State submitting: boolean = false;
  @State showUnlock: boolean = false;
  @State unlockBadges: string[] = [];

  aboutToAppear(): void {
    this.initData();
  }

  onDataTick(): void {
  }

  private async initData(): Promise<void> {
    try {
      await AppInit.ensure();
      this.categories = CalculationService.getCategories();
      if (this.categories.length > 0 && this.selSub === '') {
        this.selType = this.categories[0].name;
        this.selSub = this.categories[0].subTypes[0].name;
      }
    } catch (e) {
      console.error('RecordView init error: ' + JSON.stringify(e));
    }
  }

  private currentSub(): SubType | null {
    return CalculationService.findSub(this.selType, this.selSub);
  }

  private unitLabel(): string {
    const sub = this.currentSub();
    return sub !== null ? sub.unit : '-';
  }

  private maxLabel(): string {
    const sub = this.currentSub();
    return sub !== null ? '' + sub.max : '-';
  }

  private subNote(): string {
    const sub = this.currentSub();
    if (sub === null || sub.note === undefined) {
      return '';
    }
    return sub.note;
  }

  /** 录入页脚注：当前系数与"估算值"提示，完整出处见记录详情 */
  private factorHint(): string {
    const sub = this.currentSub();
    if (sub === null) {
      return '';
    }
    return `按 ${sub.factor} g/${sub.unit} 系数估算，结果为估算值`;
  }

  private parseValue(): number {
    const v = parseFloat(this.valueText);
    return isFinite(v) ? v : 0;
  }

  private validateValue(): string {
    const sub = this.currentSub();
    if (sub === null) {
      return '请先选择行为类型';
    }
    const v = this.parseValue();
    if (v <= 0) {
      return `请输入大于 0 的${sub.unit}数`;
    }
    if (v > sub.max) {
      return `超出上限：单次最多 ${sub.max} ${sub.unit}`;
    }
    return '';
  }

  private estimateG(): number {
    if (this.validateValue() !== '') {
      return 0;
    }
    return CalculationService.calculate(this.selType, this.selSub, this.parseValue());
  }

  private timeLabel(): string {
    const ts = this.customTs > 0 ? this.customTs : Date.now();
    return DateUtil.formatFull(ts);
  }

  /** 行为时间支持选年月日时分，分两步：先选日期（不可选未来），再选时分（当天上限为当前时刻） */
  private showTimePicker(): void {
    const base = this.customTs > 0 ? this.customTs : Date.now();
    CalendarPickerDialog.show({
      selected: new Date(base),
      end: new Date(),
      onAccept: (date: Date) => {
        this.showTimeOfDayPicker(date);
      }
    });
  }

  /** 选完日期后紧接选时分；若选中的是当天，时分不得超过当前时刻 */
  private showTimeOfDayPicker(date: Date): void {
    const base = this.customTs > 0 ? this.customTs : Date.now();
    const baseDate = new Date(base);
    const seedTime = new Date(date.getFullYear(), date.getMonth(), date.getDate(),
      baseDate.getHours(), baseDate.getMinutes());
    const isToday = DateUtil.startOfDay(date.getTime()) === DateUtil.startOfDay(Date.now());
    TimePickerDialog.show({
      selected: seedTime,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const ts = new Date(date.getFullYear(), date.getMonth(), date.getDate(),
          value.hour, value.minute).getTime();
        if (isToday && ts > Date.now()) {
          promptAction.showToast({ message: '不能选择未来的时间哦' });
          return;
        }
        this.customTs = ts;
      }
    });
  }

  private async submit(): Promise<void> {
    const err = this.validateValue();
    if (err !== '') {
      promptAction.showToast({ message: err });
      return;
    }
    if (this.noteText.length > 100) {
      promptAction.showToast({ message: '备注不能超过 100 字' });
      return;
    }
    const ts = this.customTs > 0 ? this.customTs : Date.now();
    if (ts > Date.now()) {
      promptAction.showToast({ message: '时间不能晚于当前时刻' });
      return;
    }
    const sub = this.currentSub();
    if (sub === null) {
      return;
    }
    this.submitting = true;
    try {
      const result = await BehaviorService.submit(this.selType, this.selSub,
        this.parseValue(), sub.unit, sub.factor, ts, this.noteText);
      const msg = `记录成功！减排 ${(result.grams / 1000).toFixed(2)} kg，+${result.points} 积分`;
      promptAction.showToast({ message: msg, duration: 2500 });
      if (result.newBadges.length > 0) {
        // 勋章解锁全屏动画（替代原 Toast 文字提示）
        this.unlockBadges = result.newBadges;
        this.showUnlock = true;
      }
      // 重置表单
      this.valueText = '';
      this.noteText = '';
      this.customTs = 0;
      // 跳转积分流水
      AppStorage.setOrCreate('tasksSegment', 1);
      gotoTab(Constants.TAB_TASKS);
    } catch (e) {
      promptAction.showToast({ message: '保存失败，请重试' });
    } finally {
      this.submitting = false;
    }
  }

  build() {
    Stack() {
    Scroll() {
      Column({ space: 14 }) {
        Row() {
          Text('低碳行为录入')
            .fontSize(Theme.FS_HERO)
            .fontWeight(FontWeight.Bold)
          Blank()
          Text('拍照识别')
            .fontSize(Theme.FS_BODY)
            .fontColor(Theme.PRIMARY)
            .backgroundColor(Theme.PRIMARY_BG)
            .borderRadius(14)
            .padding({ left: 12, right: 12, top: 5, bottom: 5 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/AiRecognize' });
            })
        }
        .width('100%')

        // 1. 行为选择
        Column({ space: 12 }) {
          Text('选择行为')
            .fontSize(Theme.FS_TITLE)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          BehaviorPicker({ categories: this.categories, selType: this.selType, selSub: this.selSub })
        }
        .width('100%')
        .padding(14)
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)

        // 2. 数值输入
        Column({ space: 10 }) {
          Text('输入数值')
            .fontSize(Theme.FS_TITLE)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row({ space: 10 }) {
            TextInput({ placeholder: '请输入数值', text: this.valueText })
              .type(InputType.NUMBER_DECIMAL)
              .layoutWeight(1)
              .height(44)
              .backgroundColor(Theme.BG_GRAY)
              .borderRadius(12)
              .onChange((v: string) => {
                this.valueText = v;
              })
            Text(this.unitLabel())
              .fontSize(Theme.FS_TITLE)
              .fontColor(Theme.TEXT)
              .width(40)
              .textAlign(TextAlign.Center)
          }
          .width('100%')

          Row() {
            Text(`上限：${this.maxLabel()} ${this.unitLabel()}`)
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(Theme.TEXT_TERTIARY)
            Blank()
            Text(this.subNote())
              .fontSize(Theme.FS_SECONDARY)
              .fontColor(Theme.TEXT_TERTIARY)
              .textAlign(TextAlign.End)
              .maxLines(2)
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)

        // 3. 实时减排反馈
        Column({ space: 8 }) {
          Text('预计减排量')
            .fontSize(Theme.FS_TERTIARY)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
          Row() {
            Row({ space: 4 }) {
              Text(this.estimateG() > 0 ? (this.estimateG() / 1000).toFixed(3) : '0.000')
                .fontSize(34)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.PRIMARY)
              Text('kg CO₂e')
                .fontSize(Theme.FS_BODY)
                .fontColor(Theme.TEXT_TERTIARY)
                .margin({ bottom: 6 })
            }
            .alignItems(VerticalAlign.Bottom)
            Blank()
            Text(this.estimateG() > 0 ? `预计 +${Math.max(1, Math.floor(this.estimateG() / 100))} 积分` : '输入数值后实时计算')
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(Theme.TEXT_TERTIARY)
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)
          Text(this.factorHint())
            .fontSize(Theme.FS_CAPTION)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.PRIMARY_BG)

        // 4. 时间 + 备注
        Column({ space: 12 }) {
          Row() {
            Text('行为时间')
              .fontSize(Theme.FS_CONTENT)
              .fontColor(Theme.TEXT)
            Blank()
            Text(this.timeLabel())
              .fontSize(Theme.FS_BODY)
              .fontColor(Theme.TEXT_TERTIARY)
            Text('  修改')
              .fontSize(Theme.FS_BODY)
              .fontColor(Theme.PRIMARY)
              .onClick(() => {
                this.showTimePicker();
              })
          }
          .width('100%')

          Divider().color(Theme.DIVIDER)

          Row({ space: 10 }) {
            Text('备注')
              .fontSize(Theme.FS_CONTENT)
              .fontColor(Theme.TEXT)
            TextInput({ placeholder: '选填，≤100 字', text: this.noteText })
              .layoutWeight(1)
              .height(40)
              .backgroundColor(Theme.BG_GRAY)
              .borderRadius(12)
              .onChange((v: string) => {
                this.noteText = v;
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)

        Button(this.submitting ? '保存中…' : '提交记录')
          .width('100%')
          .height(48)
          .fontSize(Theme.FS_TITLE)
          .backgroundColor(Theme.PRIMARY)
          .borderWidth(1).borderColor(Theme.CARD_BORDER)
          .enabled(!this.submitting)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .padding(14)
    }
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
    .align(Alignment.Top)

    // 勋章解锁动画层（置顶）
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
