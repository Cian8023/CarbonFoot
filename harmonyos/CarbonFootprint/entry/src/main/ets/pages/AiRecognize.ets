import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Theme } from '../common/Theme';
import { AppInit } from '../common/AppInit';
import { Constants, gotoTab } from '../common/Constants';
import { AiRecognizeService, AiGuess } from '../service/AiRecognizeService';
import { CalculationService } from '../service/CalculationService';
import { BehaviorService } from '../service/BehaviorService';
import { AppConfig } from '../common/AppConfig';
import { DateUtil } from '../utils/DateUtil';

/**
 * AI 拍照识别录入（创新拓展 2）：选图 → 识别 → 确认 → 自动录入。
 */
@Entry
@Component
struct AiRecognize {
  @State recognizing: boolean = false;
  @State guess: AiGuess | null = null;
  @State estimateG: number = 0;
  @State estimatePts: number = 0;
  @State submitting: boolean = false;

  private async pickAndRecognize(): Promise<void> {
    try {
      await AppInit.ensure();
      const uri = await AiRecognizeService.pickImage();
      this.recognizing = true;
      promptAction.showToast({ message: 'AI 识别中…' });
      const b64 = await AiRecognizeService.imageToBase64(uri);
      const g = await AiRecognizeService.recognize(b64);
      this.guess = g;
      this.updateEstimate();
    } catch (e) {
      promptAction.showToast({ message: '识别失败：' + (e as Error).message });
    } finally {
      this.recognizing = false;
    }
  }

  private updateEstimate(): void {
    if (this.guess === null) {
      this.estimateG = 0;
      this.estimatePts = 0;
      return;
    }
    const g = this.guess as AiGuess;
    this.estimateG = CalculationService.calculate(g.type, g.subType, g.value);
    this.estimatePts = this.estimateG > 0 ? Math.max(1, Math.floor(this.estimateG / 100)) : 0;
  }

  private async submit(): Promise<void> {
    if (this.guess === null || this.submitting) {
      return;
    }
    const g = this.guess as AiGuess;
    const sub = CalculationService.findSub(g.type, g.subType);
    if (sub === null) {
      return;
    }
    this.submitting = true;
    try {
      const result = await BehaviorService.submit(g.type, g.subType, g.value, sub.unit,
        sub.factor, Date.now(), 'AI 拍照识别' + (g.demo ? '（演示）' : ''));
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

  private async configApiKey(): Promise<void> {
    try {
      const key = await AppConfig.getAiApiKey();
      promptAction.showToast({
        message: key === '' ? '未配置 API Key（当前为离线演示识别）' : '已配置 API Key（在线识别）'
      });
    } catch (e) {
    }
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('←')
          .fontSize(22)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('AI 拍照识别低碳行为')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('设置')
          .fontSize(12)
          .fontColor(Theme.TEXT_SUB)
          .border({ width: 1, color: Theme.LINE, radius: 10 })
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .onClick(() => {
            this.configApiKey();
          })
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14 })

      Scroll() {
        Column({ space: 14 }) {
          // 说明卡
          Column({ space: 8 }) {
            Text('识')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.PRIMARY)
              .width(56)
              .height(56)
              .textAlign(TextAlign.Center)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(28)
            Text('拍下你的低碳行为')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
            Text('AI 自动识别行为类型并估算数值，一键录入减排数据')
              .fontSize(12)
              .fontColor(Theme.TEXT_SUB)
              .textAlign(TextAlign.Center)
          }
          .width('100%')
          .padding(20)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)

          Button(this.recognizing ? '识别中…' : ' 从相册选择图片识别')
            .width('100%')
            .height(46)
            .fontSize(15)
            .backgroundColor(Theme.PRIMARY)
            .enabled(!this.recognizing)
            .onClick(() => {
              this.pickAndRecognize();
            })

          // 识别结果
          if (this.guess !== null) {
            Column({ space: 12 }) {
              Row() {
                Text('识别结果')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                Blank()
                if ((this.guess as AiGuess).demo) {
                  Text('离线演示')
                    .fontSize(10)
                    .fontColor(Theme.WARN)
                    .border({ width: 1, color: Theme.WARN, radius: 8 })
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                } else {
                  Text('AI 在线识别')
                    .fontSize(10)
                    .fontColor(Theme.PRIMARY)
                    .border({ width: 1, color: Theme.PRIMARY, radius: 8 })
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                }
              }
              .width('100%')

              Row({ space: 12 }) {
                Text('AI')
                  .fontSize(13)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.PRIMARY)
                  .width(36)
                  .height(36)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(Theme.PRIMARY_BG)
                  .borderRadius(18)
                Column({ space: 4 }) {
                  Text(`${(this.guess as AiGuess).type} · ${(this.guess as AiGuess).subType}`)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                  Text(`预估数值：${(this.guess as AiGuess).value} ${(this.guess as AiGuess).unit}`)
                    .fontSize(12)
                    .fontColor(Theme.TEXT_SUB)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
              }
              .width('100%')

              Row() {
                Text(`预计减排 ${DateUtil.gramsToKg(this.estimateG)} kg CO₂e · ≈ +${this.estimatePts} 积分`)
                  .fontSize(13)
                  .fontColor(Theme.REDUCE)
              }
              .width('100%')
              .padding(10)
              .borderRadius(10)
              .backgroundColor(Theme.PRIMARY_BG)

              Text((this.guess as AiGuess).raw)
                .fontSize(10)
                .fontColor(Theme.TEXT_SUB)
                .maxLines(2)

              Row({ space: 12 }) {
                Button('重新识别')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(14)
                  .backgroundColor(Theme.TEXT_SUB)
                  .onClick(() => {
                    this.guess = null;
                  })
                Button(this.submitting ? '录入中…' : '确认录入')
                  .layoutWeight(1)
                  .height(42)
                  .fontSize(14)
                  .backgroundColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.submit();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(16)
            .backgroundColor(Theme.CARD)
          }

          Text('说明：在「我的 > 服务配置」中填入视觉模型 API Key 即可启用在线识别；未配置时使用离线演示识别，链路完整可演示。')
            .fontSize(11)
            .fontColor(Theme.TEXT_SUB)
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
