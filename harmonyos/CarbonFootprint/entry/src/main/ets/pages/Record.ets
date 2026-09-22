import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants, gotoTab } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BehaviorCategory, SubType } from '../model/Models';
import { CalculationService } from '../service/CalculationService';
import { BehaviorService } from '../service/BehaviorService';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorPicker } from '../components/BehaviorPicker';

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
    return '💡 ' + sub.note;
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

  private showTimePicker(): void {
    const base = this.customTs > 0 ? this.customTs : Date.now();
    const d = new Date(base);
    TimePickerDialog.show({
      selected: d,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const ts = DateUtil.startOfDay(Date.now()) +
          value.hour * 3600000 + value.minute * 60000;
        if (ts > Date.now()) {
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
      let msg = `记录成功！减排 ${(result.grams / 1000).toFixed(2)} kg，+${result.points} 积分`;
      if (result.newBadges.length > 0) {
        msg += ` 🎉解锁徽章：${result.newBadges.join('、')}`;
      }
      promptAction.showToast({ message: msg, duration: 2500 });
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
    Scroll() {
      Column({ space: 14 }) {
        Text('低碳行为录入')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        // 1. 行为选择
        Column({ space: 12 }) {
          Text('选择行为')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          BehaviorPicker({ categories: this.categories, selType: this.selType, selSub: this.selSub })
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor(Theme.CARD)

        // 2. 数值输入
        Column({ space: 10 }) {
          Text('输入数值')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .width('100%')
          Row({ space: 10 }) {
            TextInput({ placeholder: '请输入数值', text: this.valueText })
              .type(InputType.NUMBER_DECIMAL)
              .layoutWeight(1)
              .height(44)
              .onChange((v: string) => {
                this.valueText = v;
              })
            Text(this.unitLabel())
              .fontSize(15)
              .fontColor(Theme.TEXT)
              .width(40)
              .textAlign(TextAlign.Center)
          }
          .width('100%')

          Row() {
            Text(`上限：${this.maxLabel()} ${this.unitLabel()}`)
              .fontSize(12)
              .fontColor(Theme.TEXT_SUB)
            Blank()
            Text(this.subNote())
              .fontSize(11)
              .fontColor(Theme.TEXT_SUB)
              .textAlign(TextAlign.End)
              .maxLines(2)
              .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor(Theme.CARD)

        // 3. 实时减排反馈
        Column({ space: 6 }) {
          Text('预计减排量')
            .fontSize(13)
            .fontColor('#C8E6C9')
          Row({ space: 4 }) {
            Text(this.estimateG() > 0 ? (this.estimateG() / 1000).toFixed(3) : '0')
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('kg CO₂e')
              .fontSize(13)
              .fontColor('#C8E6C9')
              .margin({ bottom: 6 })
            Blank()
            Text(this.estimateG() > 0 ? `≈ +${Math.max(1, Math.floor(this.estimateG() / 100))} 积分` : '输入数值实时计算')
              .fontSize(13)
              .fontColor('#FFFFFF')
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(10)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .linearGradient({ angle: 135, colors: [['#43A047', 0], ['#2E7D32', 1]] })

        // 4. 时间 + 备注
        Column({ space: 12 }) {
          Row() {
            Text('行为时间')
              .fontSize(14)
              .fontColor(Theme.TEXT)
            Blank()
            Text(this.timeLabel() + '  修改 >')
              .fontSize(13)
              .fontColor(Theme.PRIMARY)
              .onClick(() => {
                this.showTimePicker();
              })
          }
          .width('100%')

          Divider().color(Theme.DIVIDER)

          Row({ space: 10 }) {
            Text('备注')
              .fontSize(14)
              .fontColor(Theme.TEXT)
            TextInput({ placeholder: '选填，≤100 字', text: this.noteText })
              .layoutWeight(1)
              .height(40)
              .onChange((v: string) => {
                this.noteText = v;
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor(Theme.CARD)

        Button(this.submitting ? '保存中…' : '提交记录')
          .width('100%')
          .height(46)
          .fontSize(16)
          .backgroundColor(Theme.PRIMARY)
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
  }
}
