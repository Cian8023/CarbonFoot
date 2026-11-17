/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Theme } from '../common/Theme';
import { AppInit } from '../common/AppInit';
import { Constants, gotoTab } from '../common/Constants';
import { AiRecognizeService, AiGuess, AiCandidate, AiTicket } from '../service/AiRecognizeService';
import { CalculationService } from '../service/CalculationService';
import { BehaviorService } from '../service/BehaviorService';
import { DateUtil } from '../utils/DateUtil';
import { SRC_AI_TICKET, SRC_AI_SCENE } from '../model/Models';

/**
 * AI 拍照识别录入（创新拓展 2）：选图 → 识别 → 确认 → 自动录入。
 * 单张走票据卡/候选卡；多张走批量汇总卡，一次确认全部录入。
 */
interface BatchItem {
  type: string;
  subType: string;
  value: number;
  unit: string;
  factor: number;
  at: number;
  source: string;
  label: string;
}

@Entry
@Component
struct AiRecognize {
  @StorageProp('statusBarHeightPx') statusBarHeightPx: number = 0;
  @State recognizing: boolean = false;
  /** 批量识别进度文案（如「正在识别 3/9」），单张识别时为空 */
  @State batchProgress: string = '';
  @State guess: AiGuess | null = null;
  /** ticket=票据提取 / scene=场景候选 / none=没看出低碳行为 / ''=未识别 */
  @State resultKind: string = '';
  @State ticket: AiTicket | null = null;
  @State candidates: AiCandidate[] = [];
  @State pickedIdx: number = -1;
  @State failReason: string = '';
  @State failKind: string = '';
  @State showOrigin: boolean = false;
  @State originError: boolean = false;
  @State batchItems: BatchItem[] = [];
  /** 与 batchItems 一一对应的输入框文本，允许用户逐条改数值 */
  @State batchValues: string[] = [];
  @State batchFailed: number = 0;
  @State batchG: number = 0;
  @State batchPts: number = 0;
  @State batchBusy: boolean = false;
  @State estimateG: number = 0;
  @State estimatePts: number = 0;
  @State editValue: string = '';
  @State submitting: boolean = false;
  /** 最近一次识别的图片 uri，失败后「重试」复用 */
  private lastUri: string = '';

  private resetResult(): void {
    this.guess = null;
    this.resultKind = '';
    this.ticket = null;
    this.candidates = [];
    this.pickedIdx = -1;
    this.failReason = '';
    this.failKind = '';
    this.showOrigin = false;
    this.originError = false;
    this.editValue = '';
    this.estimateG = 0;
    this.estimatePts = 0;
    this.batchItems = [];
    this.batchValues = [];
    this.batchFailed = 0;
    this.batchG = 0;
    this.batchPts = 0;
  }

  private applyPick(type: string, subType: string, value: number): void {
    const s = CalculationService.findSub(type, subType);
    if (s === null) {
      return;
    }
    const g: AiGuess = { type: type, subType: subType, value: value, unit: s.unit };
    this.guess = g;
    this.editValue = '' + value;
    this.updateEstimate();
  }

  private async recognizeUri(uri: string): Promise<void> {
    try {
      await AppInit.ensure();
      AiRecognizeService.begin();
      this.lastUri = uri;
      this.recognizing = true;
      this.resetResult();
      promptAction.showToast({ message: 'AI 识别中…' });
      const b64 = await AiRecognizeService.imageToBase64(uri);
      const r = await AiRecognizeService.recognize(b64);
      if (!r.ok) {
        if (r.failKind === 'cancelled') {
          this.resetResult();
          return;
        }
        this.failReason = r.reason;
        this.failKind = r.failKind;
        return;
      }
      this.resultKind = r.kind;
      this.ticket = r.ticket;
      this.candidates = r.candidates;
      if (r.kind === 'ticket' && r.ticket !== null) {
        // 票据：数值来自原文，直接填好
        this.applyPick(r.ticket.type, r.ticket.subType, r.ticket.value);
      } else if (r.kind === 'scene' && r.candidates.length > 0 && r.candidates[0].conf >= 0.7) {
        // 场景：置信度够高才自动选中，否则等用户点
        this.pickedIdx = 0;
        const c = r.candidates[0];
        this.applyPick(c.type, c.subType, AiRecognizeService.suggestValue(c.type, c.subType));
      }
    } catch (e) {
      this.failKind = 'image';
      this.failReason = '图片处理失败：' + (e as Error).message;
    } finally {
      this.recognizing = false;
      this.batchProgress = '';
    }
  }

  private async pickAndRecognize(): Promise<void> {
    try {
      const uris = await AiRecognizeService.pickImages(9);
      if (uris.length === 1) {
        await this.recognizeUri(uris[0]);
      } else {
        await this.recognizeBatch(uris);
      }
    } catch (e) {
      promptAction.showToast({ message: '识别失败：' + (e as Error).message });
    }
  }

  /** 批量识别：逐张识别后汇总成一张确认卡，一次录入全部 */
  private async recognizeBatch(uris: string[]): Promise<void> {
    this.recognizing = true;
    this.resetResult();
    const items: BatchItem[] = [];
    let failed = 0;
    try {
      await AppInit.ensure();
      AiRecognizeService.begin();
      promptAction.showToast({ message: `正在识别 ${uris.length} 张…` });
      let doneCount = 0;
      for (const u of uris) {
        doneCount++;
        // 9 张串行识别约 40 秒，必须让用户看到进度，否则会以为卡死
        this.batchProgress = `正在识别 ${doneCount}/${uris.length}`;
        this.lastUri = u;
        try {
          const b64 = await AiRecognizeService.imageToBase64(u);
          const r = await AiRecognizeService.recognize(b64);
          if (r.failKind === 'cancelled') {
            break;
          }
          if (!r.ok) {
            failed++;
            continue;
          }
          if (r.kind === 'ticket' && r.ticket !== null) {
            const t = r.ticket;
            const s = CalculationService.findSub(t.type, t.subType);
            if (s === null) {
              failed++;
              continue;
            }
            const it: BatchItem = {
              type: t.type, subType: t.subType, value: t.value, unit: s.unit,
              factor: s.factor, at: t.at, source: SRC_AI_TICKET, label: t.label
            };
            items.push(it);
          } else if (r.kind === 'scene' && r.candidates.length > 0) {
            const c = r.candidates[0];
            const s = CalculationService.findSub(c.type, c.subType);
            if (s === null) {
              failed++;
              continue;
            }
            const it: BatchItem = {
              type: c.type, subType: c.subType,
              value: AiRecognizeService.suggestValue(c.type, c.subType), unit: s.unit,
              factor: s.factor, at: Date.now(), source: SRC_AI_SCENE, label: '场景'
            };
            items.push(it);
          } else {
            failed++;
          }
        } catch (e) {
          failed++;
        }
      }
      let g = 0;
      const vals: string[] = [];
      for (const it of items) {
        g += Math.round(it.value * it.factor);
        vals.push('' + it.value);
      }
      this.batchItems = items;
      this.batchValues = vals;
      this.batchFailed = failed;
      this.batchG = g;
      this.batchPts = CalculationService.valueToPoints(g);
      if (items.length === 0) {
        this.failKind = 'model';
        this.failReason = failed > 0 ? `这 ${failed} 张图都没识别出可录入的行为` : '未识别到内容';
      } else {
        this.resultKind = 'batch';
      }
    } finally {
      this.recognizing = false;
      this.batchProgress = '';
    }
  }

  /** 按当前输入框文本重算合计，改了数值立刻反映 */
  private recalcBatch(): void {
    let g = 0;
    for (let i = 0; i < this.batchItems.length; i++) {
      const v = Number(this.batchValues[i]);
      if (isFinite(v) && v > 0) {
        g += Math.round(v * this.batchItems[i].factor);
      }
    }
    this.batchG = g;
    this.batchPts = CalculationService.valueToPoints(g);
  }

  /** 单条预计减排（随输入框变化），供批量卡展示 */
  private batchItemKg(i: number): string {
    const v = Number(this.batchValues[i]);
    if (!isFinite(v) || v <= 0) {
      return '0.00';
    }
    return DateUtil.gramsToKg(Math.round(v * this.batchItems[i].factor));
  }

  private removeBatchItem(idx: number): void {
    const items: BatchItem[] = [];
    const vals: string[] = [];
    for (let i = 0; i < this.batchItems.length; i++) {
      if (i === idx) {
        continue;
      }
      items.push(this.batchItems[i]);
      vals.push(this.batchValues[i]);
    }
    this.batchItems = items;
    this.batchValues = vals;
    if (items.length === 0) {
      this.resetResult();
      return;
    }
    this.recalcBatch();
  }

  private async submitBatch(): Promise<void> {
    if (this.batchBusy || this.batchItems.length === 0) {
      return;
    }
    // 先整体校验，避免录到一半才失败
    for (let i = 0; i < this.batchItems.length; i++) {
      const v = Number(this.batchValues[i]);
      if (!isFinite(v) || v <= 0) {
        promptAction.showToast({ message: `第 ${i + 1} 条数值无效，请填写大于 0 的数` });
        return;
      }
    }
    this.batchBusy = true;
    let n = 0;
    try {
      for (let i = 0; i < this.batchItems.length; i++) {
        const it = this.batchItems[i];
        const v = Number(this.batchValues[i]);
        await BehaviorService.submit(it.type, it.subType, v, it.unit, it.factor,
          it.at, `AI 批量识别（${it.label}）`, it.source);
        n++;
      }
      promptAction.showToast({ message: `已录入 ${n} 条` });
      this.resetResult();
      gotoTab(Constants.TAB_RECORD);
      router.back();
    } catch (e) {
      promptAction.showToast({ message: `已录入 ${n} 条，下一条失败：${(e as Error).message}` });
    } finally {
      this.batchBusy = false;
    }
  }

  private async shootAndRecognize(): Promise<void> {
    try {
      const uri = await AiRecognizeService.shootImage();
      await this.recognizeUri(uri);
    } catch (e) {
      promptAction.showToast({ message: '识别失败：' + (e as Error).message });
    }
  }

  /** 「换一张」：清掉上次结果并立刻重新打开相册，而不是退回初始页让用户再点一次 */
  private retryPick(): void {
    this.resetResult();
    this.pickAndRecognize();
  }

  private updateEstimate(): void {
    if (this.guess === null) {
      this.estimateG = 0;
      this.estimatePts = 0;
      return;
    }
    const g = this.guess as AiGuess;
    const v = parseFloat(this.editValue);
    const val = isFinite(v) && v > 0 ? v : 0;
    this.estimateG = CalculationService.calculate(g.type, g.subType, val);
    this.estimatePts = this.estimateG > 0 ? Math.max(1, Math.floor(this.estimateG / 100)) : 0;
  }

  private async submit(): Promise<void> {
    if (this.guess === null || this.submitting) {
      return;
    }
    const g = this.guess as AiGuess;
    const sub = CalculationService.findSub(g.type, g.subType);
    if (sub === null) {
      promptAction.showToast({ message: '识别结果不在行为字典中，请重新识别' });
      return;
    }
    const v = parseFloat(this.editValue);
    if (!isFinite(v) || v <= 0) {
      promptAction.showToast({ message: '请输入大于 0 的数值' });
      return;
    }
    if (v > sub.max) {
      promptAction.showToast({ message: `超出单次上限：最多 ${sub.max} ${sub.unit}` });
      return;
    }
    this.submitting = true;
    try {
      const isTicket = this.resultKind === 'ticket' && this.ticket !== null;
      const note = isTicket
        ? 'AI 票据识别（' + (this.ticket as AiTicket).label + '）'
        : 'AI 场景识别';
      const source = isTicket ? SRC_AI_TICKET : SRC_AI_SCENE;
      // 票据用票据上的日期入库，否则历史行程会全部记成「今天」
      const ts = isTicket ? (this.ticket as AiTicket).at : Date.now();
      const result = await BehaviorService.submit(g.type, g.subType, v, sub.unit,
        sub.factor, ts, note, source);
      let msg = `已自动录入！减排 ${DateUtil.gramsToKg(result.grams)} kg，+${result.points} 积分`;
      if (result.newBadges.length > 0) {
        msg += ` 解锁徽章：${result.newBadges.join('、')}`;
      }
      promptAction.showToast({ message: msg, duration: 2500 });
      this.guess = null;
      gotoTab(Constants.TAB_RECORD);
      router.back();
    } catch (e) {
      promptAction.showToast({ message: '录入失败，请重试' });
    } finally {
      this.submitting = false;
    }
  }

  /** 右上角「设置」：直达「我的 > 设置」的服务配置区（AI Key 与碳普惠地址都在那一节） */
  private openServiceConfig(): void {
    router.pushUrl({ url: 'pages/SettingsDetail', params: { focus: 'ai' } });
  }

  /** 原文对照：让用户核对识别依据，而不是盲信 AI */
  @Builder
  originPreview() {
    Column({ space: 8 }) {
      Row() {
        Text(this.showOrigin ? '收起原图' : '查看原图')
          .fontSize(Theme.FS_CAPTION)
          .fontColor(Theme.PRIMARY)
          .onClick(() => {
            this.showOrigin = !this.showOrigin;
          })
        Blank()
      }
      .width('100%')

      if (this.showOrigin) {
        if (this.originError) {
          Text('原图已不可用（可能已被删除或访问权限已失效）')
            .fontSize(Theme.FS_CAPTION)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
        } else {
          Image(this.lastUri)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Contain)
            .borderRadius(10)
            .backgroundColor(Theme.BG_GRAY)
            .onError(() => {
              this.originError = true;
            })
        }
      }
    }
    .width('100%')
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('←')
          .fontSize(Theme.FS_HERO)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('AI 辅助识别低碳行为')
          .fontSize(Theme.FS_HEAD)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('设置')
          .fontSize(Theme.FS_TERTIARY)
          .fontColor(Theme.TEXT_TERTIARY)
          .backgroundColor(Theme.BG_GRAY)
          .borderRadius(10)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .onClick(() => {
            this.openServiceConfig();
          })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: px2vp(this.statusBarHeightPx) + 14 })

      Scroll() {
        Column({ space: 14 }) {
          // 说明卡
          Column({ space: 8 }) {
            Text('识')
              .fontSize(Theme.FS_HEAD)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.PRIMARY)
              .width(56)
              .height(56)
              .textAlign(TextAlign.Center)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(28)
            Text('拍下你的低碳行为')
              .fontSize(Theme.FS_TITLE)
              .fontWeight(FontWeight.Medium)
            Text('AI 识别行为类型并估算数值，结果由你确认后才写入记录')
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(Theme.TEXT_TERTIARY)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(20)
          .borderRadius(Theme.R_LARGE)
          .backgroundColor(Theme.CARD)
          .borderWidth(1).borderColor(Theme.CARD_BORDER)

          Row({ space: 10 }) {
            Button(this.recognizing ? '识别中…' : '拍照识别')
              .layoutWeight(1)
              .height(46)
              .fontSize(Theme.FS_TITLE)
              .backgroundColor(Theme.PRIMARY)
              .enabled(!this.recognizing)
              .onClick(() => {
                this.shootAndRecognize();
              })
            Button('相册选图（可多选）')
              .layoutWeight(1)
              .height(46)
              .fontSize(Theme.FS_TITLE)
              .backgroundColor(Theme.PRIMARY_HOVER)
              .enabled(!this.recognizing)
              .onClick(() => {
                this.pickAndRecognize();
              })
          }
          .width('100%')

          if (this.recognizing) {
            if (this.batchProgress !== '') {
              Text(this.batchProgress)
                .fontSize(Theme.FS_BODY)
                .fontColor(Theme.TEXT_SECONDARY)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 4, bottom: 2 })
            }
            Button('取消识别')
              .width('100%')
              .height(36)
              .fontSize(Theme.FS_BODY)
              .backgroundColor(Theme.BG_GRAY)
              .fontColor(Theme.TEXT_TERTIARY)
              .onClick(() => {
                AiRecognizeService.cancel();
                this.recognizing = false;
                this.resetResult();
              })
          }

          // 识别失败：不编造结果，明确告知原因并给出出口
          if (this.failReason !== '') {
            Column({ space: 10 }) {
              Row({ space: 8 }) {
                Text('!')
                  .fontSize(Theme.FS_BODY)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.WARN)
                  .width(24)
                  .height(24)
                  .textAlign(TextAlign.Center)
                  .backgroundColor('#FDF0E8')
                  .borderRadius(12)
                Text('AI 识别不可用')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
              }
              .width('100%')

              Text(this.failReason)
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')

              Row({ space: 12 }) {
                if (this.failKind === 'config' || this.failKind === 'auth') {
                  Button('去填 Key')
                    .layoutWeight(1)
                    .height(38)
                    .fontSize(Theme.FS_BODY)
                    .backgroundColor(Theme.PRIMARY_BG)
                    .fontColor(Theme.PRIMARY)
                    .onClick(() => {
                      router.pushUrl({ url: 'pages/SettingsDetail', params: { focus: 'ai' } });
                    })
                } else if (this.failKind === 'image') {
                  Button('换一张')
                    .layoutWeight(1)
                    .height(38)
                    .fontSize(Theme.FS_BODY)
                    .backgroundColor(Theme.PRIMARY_BG)
                    .fontColor(Theme.PRIMARY)
                    .onClick(() => {
                      this.retryPick();
                    })
                } else {
                  Button('重试')
                    .layoutWeight(1)
                    .height(38)
                    .fontSize(Theme.FS_BODY)
                    .backgroundColor(Theme.PRIMARY_BG)
                    .fontColor(Theme.PRIMARY)
                    .onClick(() => {
                      if (this.lastUri !== '') {
                        this.recognizeUri(this.lastUri);
                      }
                    })
                }
                Button('去手动录入')
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(Theme.FS_BODY)
                  .backgroundColor(Theme.PRIMARY)
                  .onClick(() => {
                    gotoTab(Constants.TAB_RECORD);
                    router.back();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          }

          // 批量识别结果：一次确认全部录入
          if (this.resultKind === 'batch' && this.batchItems.length > 0) {
            Column({ space: 10 }) {
              Row() {
                Text('批量识别')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text(`${this.batchItems.length} 条`)
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.PRIMARY)
                  .border({ width: 1, color: Theme.PRIMARY, radius: 8 })
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              }
              .width('100%')

              Text('数值可逐条修改，点 × 删除不需要的条目')
                .fontSize(Theme.FS_CAPTION)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')

              ForEach(this.batchItems, (it: BatchItem, i: number) => {
                Row({ space: 8 }) {
                  Text(`${i + 1}`)
                    .fontSize(Theme.FS_CAPTION)
                    .fontColor(Theme.TEXT_TERTIARY)
                    .width(18)
                  Column({ space: 2 }) {
                    Text(`${it.type} · ${it.subType}`)
                      .fontSize(Theme.FS_BODY)
                      .fontColor(Theme.TEXT)
                    Text(`预计 ${this.batchItemKg(i)} kg`)
                      .fontSize(Theme.FS_MICRO)
                      .fontColor(Theme.REDUCE)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  TextInput({ text: this.batchValues[i] })
                    .type(InputType.NUMBER_DECIMAL)
                    .width(84)
                    .height(34)
                    .fontSize(Theme.FS_BODY)
                    .backgroundColor(Theme.BG_GRAY)
                    .borderRadius(8)
                    .onChange((v: string) => {
                      this.batchValues[i] = v;
                      this.recalcBatch();
                    })
                  Text(it.unit)
                    .fontSize(Theme.FS_CAPTION)
                    .fontColor(Theme.TEXT_TERTIARY)
                    .width(28)
                  Text('×')
                    .fontSize(Theme.FS_TITLE)
                    .fontColor(Theme.WARN)
                    .width(28)
                    .textAlign(TextAlign.Center)
                    .onClick(() => {
                      this.removeBatchItem(i);
                    })
                }
                .width('100%')
                .padding({ top: 6, bottom: 6 })
              }, (it: BatchItem, i: number) => i + '_' + it.type + '_' + it.at)

              if (this.batchFailed > 0) {
                Text(`${this.batchFailed} 张未识别出行为，已跳过`)
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.WARN)
                  .width('100%')
              }

              Row() {
                Text(`合计 ${DateUtil.gramsToKg(this.batchG)} kg CO₂e · ≈ +${this.batchPts} 积分`)
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.REDUCE)
              }
              .width('100%')
              .padding(10)
              .borderRadius(14)
              .backgroundColor(Theme.PRIMARY_BG)

              Row({ space: 12 }) {
                Button('取消')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(Theme.FS_CONTENT)
                  .backgroundColor(Theme.TEXT_TERTIARY)
                  .onClick(() => {
                    this.resetResult();
                  })
                Button(this.batchBusy ? '录入中…' : '全部录入')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(Theme.FS_CONTENT)
                  .backgroundColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.submitBatch();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          }

          // 票据提取结果：数值来自图片原文
          if (this.resultKind === 'ticket' && this.ticket !== null) {
            Column({ space: 8 }) {
              Row() {
                Text('检测到票据')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text((this.ticket as AiTicket).label)
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.PRIMARY)
                  .border({ width: 1, color: Theme.PRIMARY, radius: 8 })
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              }
              .width('100%')

              if ((this.ticket as AiTicket).evidence !== '') {
                Text((this.ticket as AiTicket).evidence)
                  .fontSize(Theme.FS_SECONDARY)
                  .fontColor(Theme.TEXT_TERTIARY)
                  .width('100%')
              }

              Text('数值取自图片原文，可按实际修改后再确认')
                .fontSize(Theme.FS_CAPTION)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')

              this.originPreview()
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          }

          // 场景候选：置信度不足时由用户点选，不替用户拍板
          if (this.resultKind === 'scene') {
            Column({ space: 8 }) {
              Row() {
                Text('AI 候选行为')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text('点选后确认')
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .width('100%')

              ForEach(this.candidates, (c: AiCandidate, i: number) => {
                Row({ space: 10 }) {
                  Text(`${c.type} · ${c.subType}`)
                    .fontSize(Theme.FS_BODY)
                    .fontWeight(this.pickedIdx === i ? FontWeight.Medium : FontWeight.Normal)
                    .fontColor(this.pickedIdx === i ? Theme.PRIMARY : Theme.TEXT)
                  Blank()
                  Text(`${Math.round(c.conf * 100)}%`)
                    .fontSize(Theme.FS_CAPTION)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .width('100%')
                .padding(10)
                .borderRadius(10)
                .backgroundColor(this.pickedIdx === i ? Theme.PRIMARY_BG : Theme.BG_GRAY)
                .borderWidth(this.pickedIdx === i ? 1 : 0)
                .borderColor(Theme.PRIMARY)
                .onClick(() => {
                  this.pickedIdx = i;
                  this.applyPick(c.type, c.subType, AiRecognizeService.suggestValue(c.type, c.subType));
                })
              }, (c: AiCandidate, i: number) => i + '_' + c.type + '_' + c.subType)

              this.originPreview()
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          }

          // 数值确认与提交
          if (this.guess !== null) {
            Column({ space: 12 }) {
              Row() {
                Text('确认信息')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text(this.resultKind === 'ticket' ? '票据识别' : 'AI 在线识别')
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.PRIMARY)
                  .border({ width: 1, color: Theme.PRIMARY, radius: 8 })
                  .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              }
              .width('100%')

              Row({ space: 12 }) {
                Text('AI')
                  .fontSize(Theme.FS_BODY)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.PRIMARY)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(Theme.PRIMARY_BG)
                  .borderRadius(18)
                Column({ space: 4 }) {
                  Text(`${(this.guess as AiGuess).type} · ${(this.guess as AiGuess).subType}`)
                    .fontSize(Theme.FS_TITLE)
                    .fontWeight(FontWeight.Medium)
                  Row({ space: 8 }) {
                    Text('数值')
                      .fontSize(Theme.FS_TERTIARY)
                      .fontColor(Theme.TEXT_TERTIARY)
                    TextInput({ text: this.editValue })
                      .type(InputType.NUMBER_DECIMAL)
                      .layoutWeight(1)
                      .height(34)
                      .fontSize(Theme.FS_BODY)
                      .onChange((v: string) => {
                        this.editValue = v;
                        this.updateEstimate();
                      })
                    Text((this.guess as AiGuess).unit)
                      .fontSize(Theme.FS_TERTIARY)
                      .fontColor(Theme.TEXT_TERTIARY)
                  }
                  .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')

              Row() {
                Text(`预计减排 ${DateUtil.gramsToKg(this.estimateG)} kg CO₂e · ≈ +${this.estimatePts} 积分`)
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.REDUCE)
              }
              .width('100%')
              .padding(10)
              .borderRadius(14)
              .backgroundColor(Theme.PRIMARY_BG)

              Row({ space: 12 }) {
                Button('重新识别')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(Theme.FS_CONTENT)
                  .backgroundColor(Theme.TEXT_TERTIARY)
                  .onClick(() => {
                    this.resetResult();
                  })
                Button(this.submitting ? '录入中…' : '确认录入')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(Theme.FS_CONTENT)
                  .backgroundColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.submit();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          }

          // 没看出低碳行为
          if (this.resultKind === 'none' && this.failReason === '') {
            Column({ space: 10 }) {
              Text('没看出低碳行为')
                .fontSize(Theme.FS_TITLE)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              Text('这张图里没有可对应的低碳行为。可以换一张，或直接手动记录。')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
              Row({ space: 12 }) {
                Button('换一张')
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(Theme.FS_BODY)
                  .backgroundColor(Theme.PRIMARY_BG)
                  .fontColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.retryPick();
                  })
                Button('去手动录入')
                  .layoutWeight(1)
                  .height(38)
                  .fontSize(Theme.FS_BODY)
                  .backgroundColor(Theme.PRIMARY)
                  .onClick(() => {
                    gotoTab(Constants.TAB_RECORD);
                    router.back();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          }

          Text('说明：需在「我的 > 设置 > 服务配置」填入视觉模型（默认 deepseek-flash，原生多模态；也可用 glm-4v-flash、qwen-vl-max）的接口地址、模型名与 API Key。识别分两种：① 行程单/外卖单/电费单/水费单等票据，直接读出里程或用量（数值取自原文，不是猜的）；② 普通照片给出最多 3 个候选，置信度不足时由你点选。相册可一次选多张（最多 9 张），逐张识别后汇总成一张确认卡，一次录入全部。未配置或调用失败时不会编造结果，会提示原因并提供「重试」与「去手动录入」。识别结果均可手动修改后再提交。')
            .fontSize(Theme.FS_SECONDARY)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')
        .padding(14)
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.BG)
  }
}
