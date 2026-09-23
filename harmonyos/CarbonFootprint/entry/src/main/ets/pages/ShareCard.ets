import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { Theme } from '../common/Theme';
import { AppInit } from '../common/AppInit';
import { BehaviorRecord } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import { BadgeService } from '../service/BadgeService';
import { DateUtil } from '../utils/DateUtil';
import { PrefsService } from '../common/PrefsService';

/**
 * 减排成果分享卡片（创新拓展 4）：Canvas 生成成果海报，保存到相册目录供分享。
 */
@Entry
@Component
struct ShareCard {
  @State todayKg: string = '0.00';
  @State totalKg: string = '0.00';
  @State streak: number = 0;
  @State nickname: string = '绿色生活家';
  @State drawn: boolean = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
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
      this.todayKg = DateUtil.gramsToKg(todaySum);
      this.totalKg = DateUtil.gramsToKg(totalSum);
      this.streak = await BadgeService.currentStreak();
      this.nickname = await PrefsService.getNickname();
    } catch (e) {
      console.error('ShareCard load error: ' + JSON.stringify(e));
    }
  }

  private draw(): void {
    const w = this.ctx.width;
    const h = this.ctx.height;
    this.ctx.clearRect(0, 0, w, h);
    if (w <= 0) {
      return;
    }
    // 背景
    this.ctx.fillStyle = '#2E7D32';
    this.ctx.fillRect(0, 0, w, h);
    this.ctx.fillStyle = 'rgba(255,255,255,0.08)';
    this.ctx.beginPath();
    this.ctx.arc(w - 30, 40, 90, 0, Math.PI * 2);
    this.ctx.fill();
    this.ctx.beginPath();
    this.ctx.arc(20, h - 60, 70, 0, Math.PI * 2);
    this.ctx.fill();
    this.ctx.textAlign = 'center';
    // 标题
    this.ctx.fillStyle = '#C8E6C9';
    this.ctx.font = '13px sans-serif';
    this.ctx.fillText('碳足迹 · 全民绿色生活', w / 2, 52);
    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.font = 'bold 26px sans-serif';
    this.ctx.fillText('我的低碳成绩单', w / 2, 90);
    // 主数据
    this.ctx.font = '13px sans-serif';
    this.ctx.fillStyle = '#C8E6C9';
    this.ctx.fillText('今日减排', w / 2, 150);
    this.ctx.font = 'bold 46px sans-serif';
    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.fillText(`${this.todayKg} kg`, w / 2, 200);
    this.ctx.font = '13px sans-serif';
    this.ctx.fillStyle = '#C8E6C9';
    this.ctx.fillText('CO₂e', w / 2, 224);
    // 副数据行
    this.ctx.font = '14px sans-serif';
    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.fillText(`累计减排 ${this.totalKg}kg`, w * 0.28, 280);
    this.ctx.fillText(`连续打卡 ${this.streak}天`, w * 0.72, 280);
    // 昵称 + 标语
    this.ctx.font = '15px sans-serif';
    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.fillText(`—— ${this.nickname} ——`, w / 2, 330);
    this.ctx.font = '12px sans-serif';
    this.ctx.fillStyle = '#C8E6C9';
    this.ctx.fillText('每一克减排，都是给地球的温柔', w / 2, 360);
    this.ctx.fillText('我在用「碳足迹」践行低碳生活', w / 2, 386);
    this.drawn = true;
  }

  private async saveCard(): Promise<void> {
    try {
      const dataUrl = this.ctx.toDataURL('image/png', 1.0);
      const b64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
      const buf: Uint8Array = new util.Base64Helper().decodeSync(b64);
      const ctx = AppInit.getContext();
      const dir = ctx.filesDir + '/share';
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
      const path = dir + '/share_card_' + DateUtil.formatYMD(Date.now()).replace(/-/g, '') + '.png';
      const f = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(f.fd, buf.buffer as ArrayBuffer);
      fs.closeSync(f.fd);
      promptAction.showToast({ message: '卡片已保存：' + path, duration: 3000 });
    } catch (e) {
      promptAction.showToast({ message: '保存失败：' + JSON.stringify(e) });
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
        Text('减排成果分享')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('')
          .width(22)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14 })

      Column({ space: 16 }) {
        Canvas(this.ctx)
          .width('86%')
          .height(420)
          .borderRadius(16)
          .onReady(() => {
            setTimeout(() => {
              this.draw();
            }, 300);
          })

        Button('保存分享卡片')
          .width('60%')
          .height(44)
          .fontSize(15)
          .backgroundColor(Theme.PRIMARY)
          .onClick(() => {
            this.saveCard();
          })

        Text('卡片保存后可发送到微信朋友圈 / 家人群，带动更多人参与低碳生活')
          .fontSize(11)
          .fontColor(Theme.TEXT_TERTIARY)
          .textAlign(TextAlign.Center)
          .padding({ left: 30, right: 30 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.BG)
  }
}
