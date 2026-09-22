import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import util from '@ohos.util';
import fs from '@ohos.file.fs';
import { AppInit } from '../common/AppInit';
import { Constants, bumpTick } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BadgeDef } from '../model/Models';
import { BadgeService } from '../service/BadgeService';
import { PointsService } from '../service/PointsService';
import { BehaviorRepo } from '../db/Repository';
import { PrefsService } from '../common/PrefsService';
import { DateUtil } from '../utils/DateUtil';

@Entry
@Component
struct Badges {
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State badges: BadgeDef[] = [];
  @State balance: number = 0;
  @State certDate: number = 0;
  @State nickname: string = '绿色生活家';
  @State totalKg: string = '0.00';
  @State unlockedCount: number = 0;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private certCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      this.badges = await BadgeService.list();
      this.balance = await PointsService.getBalance();
      this.certDate = await PrefsService.getCertDate();
      this.nickname = await PrefsService.getNickname();
      let unlocked = 0;
      for (const b of this.badges) {
        if (b.unlocked) {
          unlocked++;
        }
      }
      this.unlockedCount = unlocked;
      this.totalKg = DateUtil.gramsToKg(await BehaviorRepo.sumAllReduction());
    } catch (e) {
      console.error('Badges refresh error: ' + JSON.stringify(e));
    }
  }

  private async exchangeCert(): Promise<void> {
    if (this.certDate > 0) {
      promptAction.showToast({ message: '已兑换过植树证书' });
      return;
    }
    if (this.balance < Constants.CERT_COST) {
      promptAction.showToast({ message: `积分不足，还差 ${Constants.CERT_COST - this.balance} 分` });
      return;
    }
    AlertDialog.show({
      title: '兑换植树证书',
      message: `将消耗 ${Constants.CERT_COST} 积分兑换一份电子植树证书，确定兑换？`,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '兑换',
        fontColor: Theme.PRIMARY,
        action: () => {
          this.doExchange();
        }
      }
    });
  }

  private async doExchange(): Promise<void> {
    try {
      await PointsService.addPoints('exchange', 0, '兑换电子植树证书', -Constants.CERT_COST);
      await PrefsService.setCertDate(Date.now());
      bumpTick();
      promptAction.showToast({ message: '🌱 恭喜获得植树证书！' });
    } catch (e) {
      promptAction.showToast({ message: '兑换失败，请重试' });
    }
  }

  private drawCert(): void {
    const w = this.certCtx.width;
    const h = this.certCtx.height;
    this.certCtx.clearRect(0, 0, w, h);
    if (w <= 0) {
      return;
    }
    // 底色
    this.certCtx.fillStyle = '#F7F5EC';
    this.certCtx.fillRect(0, 0, w, h);
    // 双边框
    this.certCtx.strokeStyle = Theme.PRIMARY;
    this.certCtx.lineWidth = 4;
    this.certCtx.strokeRect(10, 10, w - 20, h - 20);
    this.certCtx.lineWidth = 1.5;
    this.certCtx.strokeRect(18, 18, w - 36, h - 36);
    this.certCtx.textAlign = 'center';
    // 标题
    this.certCtx.fillStyle = Theme.PRIMARY;
    this.certCtx.font = 'bold 30px sans-serif';
    this.certCtx.fillText('植 树 证 书', w / 2, 70);
    this.certCtx.font = '11px sans-serif';
    this.certCtx.fillStyle = '#8A8A6A';
    this.certCtx.fillText('T R E E   P L A N T I N G   C E R T I F I C A T E', w / 2, 92);
    // 正文
    this.certCtx.fillStyle = '#3A4A3A';
    this.certCtx.font = '14px sans-serif';
    this.certCtx.fillText('兹证明', w / 2, 130);
    this.certCtx.font = 'bold 24px sans-serif';
    this.certCtx.fillStyle = Theme.TEXT;
    this.certCtx.fillText(this.nickname, w / 2, 165);
    this.certCtx.font = '14px sans-serif';
    this.certCtx.fillStyle = '#3A4A3A';
    this.certCtx.fillText(`通过「碳足迹」应用累计减排 ${this.totalKg} kg CO₂e`, w / 2, 200);
    this.certCtx.fillText(`于 ${DateUtil.formatYMD(this.certDate)} 兑换电子植树证书一份`, w / 2, 224);
    this.certCtx.fillText('感谢您为地球增添的一抹绿色', w / 2, 248);
    // 装饰
    this.certCtx.font = '22px sans-serif';
    this.certCtx.fillText('🌳 🌳 🌳', w / 2, 292);
    // 落款
    this.certCtx.font = '12px sans-serif';
    this.certCtx.fillStyle = '#8A8A6A';
    this.certCtx.fillText('碳足迹 · 全民绿色生活碳积分与减排指南', w / 2, h - 44);
    this.certCtx.fillText(`证书编号：CF-${this.certDate}`, w / 2, h - 24);
  }

  private async saveCert(): Promise<void> {
    try {
      const dataUrl = this.certCtx.toDataURL('image/png', 1.0);
      const b64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
      const buf: Uint8Array = new util.Base64Helper().decodeSync(b64);
      const ctx = AppInit.getContext();
      const dir = ctx.filesDir + '/certificates';
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
      const path = dir + '/tree_certificate_' + DateUtil.formatYMD(Date.now()).replace(/-/g, '') + '.png';
      const f = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(f.fd, buf.buffer as ArrayBuffer);
      fs.closeSync(f.fd);
      promptAction.showToast({ message: '证书已保存：' + path, duration: 3000 });
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
        Text('徽章墙与植树证书')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('')
          .width(22)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14 })

      Scroll() {
        Column({ space: 12 }) {
          // 徽章墙
          Column({ space: 10 }) {
            Row() {
              Text('虚拟徽章墙')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
              Blank()
              Text(`${this.unlockedCount}/${this.badges.length} 已解锁`)
                .fontSize(12)
                .fontColor(Theme.TEXT_SUB)
            }
            .width('100%')

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
              ForEach(this.badges, (b: BadgeDef) => {
                Column({ space: 6 }) {
                  Text(b.unlocked ? b.icon : '🔒')
                    .fontSize(34)
                  Text(b.name)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(b.unlocked ? Theme.TEXT : Theme.TEXT_SUB)
                  Text(b.description)
                    .fontSize(10)
                    .fontColor(Theme.TEXT_SUB)
                    .textAlign(TextAlign.Center)
                    .maxLines(2)
                  if (b.unlocked) {
                    Text(`${DateUtil.formatYMD(b.unlockedAt)} 解锁`)
                      .fontSize(9)
                      .fontColor(Theme.PRIMARY)
                  }
                }
                .width('31%')
                .margin({ bottom: 10 })
                .padding({ top: 14, bottom: 12 })
                .borderRadius(12)
                .backgroundColor(b.unlocked ? '#FFF8E1' : Theme.BG)
                .border({ width: 1, color: b.unlocked ? '#FFE082' : Theme.DIVIDER })
                .opacity(b.unlocked ? 1 : 0.75)
              }, (b: BadgeDef) => b.code + '_' + (b.unlocked ? '1' : '0'))
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)

          // 植树证书
          Column({ space: 12 }) {
            Row() {
              Text('植树证书')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
              Blank()
              Text(`${this.balance}/${Constants.CERT_COST} 积分`)
                .fontSize(12)
                .fontColor(this.balance >= Constants.CERT_COST ? Theme.PRIMARY : Theme.TEXT_SUB)
            }
            .width('100%')

            if (this.certDate > 0) {
              Canvas(this.certCtx)
                .width('100%')
                .height(330)
                .borderRadius(8)
                .onReady(() => {
                  this.drawCert();
                })

              Button('保存证书图片')
                .width('100%')
                .height(42)
                .fontSize(14)
                .backgroundColor(Theme.PRIMARY)
                .onClick(() => {
                  this.saveCert();
                })
            } else {
              Column({ space: 10 }) {
                Text('🌲')
                  .fontSize(48)
                Text(`积分达到 ${Constants.CERT_COST} 分，即可兑换电子植树证书`)
                  .fontSize(13)
                  .fontColor(Theme.TEXT_SUB)
                  .textAlign(TextAlign.Center)
                Progress({ value: Math.min(this.balance, Constants.CERT_COST), total: Constants.CERT_COST, type: ProgressType.Linear })
                  .width('80%')
                  .color(Theme.PRIMARY)
                Button(this.balance >= Constants.CERT_COST ? '立即兑换' : '继续攒积分')
                  .fontSize(14)
                  .backgroundColor(this.balance >= Constants.CERT_COST ? Theme.PRIMARY : Theme.TEXT_SUB)
                  .onClick(() => {
                    this.exchangeCert();
                  })
              }
              .width('100%')
              .padding({ top: 20, bottom: 20 })
            }
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)
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
