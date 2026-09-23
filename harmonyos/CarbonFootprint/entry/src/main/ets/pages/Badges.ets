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
      promptAction.showToast({ message: '恭喜获得植树证书！' });
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
    // 单层细边框
    this.certCtx.strokeStyle = '#C9D5BC';
    this.certCtx.lineWidth = 1;
    this.certCtx.strokeRect(12, 12, w - 24, h - 24);
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
    // 装饰：三棵几何小树
    const treeXs = [w / 2 - 44, w / 2, w / 2 + 44];
    for (let i = 0; i < treeXs.length; i++) {
      const cx = treeXs[i];
      const scale = i === 1 ? 1.15 : 0.85;
      this.certCtx.fillStyle = '#A9C08F';
      this.certCtx.beginPath();
      this.certCtx.moveTo(cx, 292 - 30 * scale);
      this.certCtx.lineTo(cx - 14 * scale, 292 - 2);
      this.certCtx.lineTo(cx + 14 * scale, 292 - 2);
      this.certCtx.closePath();
      this.certCtx.fill();
      this.certCtx.fillStyle = '#C8B26A';
      this.certCtx.fillRect(cx - 2, 292 - 2, 4, 8);
    }
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
    Column() {
      // 顶部导航
      Row() {
        Text('‹')
          .fontSize(30)
          .fontColor(Theme.TEXT)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        Text('徽章与证书')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.TEXT)
          .margin({ left: 8 })

        Blank()

        Text(`${this.unlockedCount}/${this.badges.length}`)
          .fontSize(12)
          .fontColor(Theme.TEXT_SUB)
      }
      .width('100%')
      .height(52)
      .padding({ left: 14, right: 14 })
      .border({ width: { bottom: 1 }, color: Theme.DIVIDER })

      Scroll() {
        Column({ space: 20 }) {
          // 徽章区域
          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Text('我的徽章')
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.TEXT)

                Text('记录已经完成的绿色行动')
                  .fontSize(12)
                  .fontColor(Theme.TEXT_SUB)
              }

              Blank()

              Text(`${this.unlockedCount} 个已获得`)
                .fontSize(12)
                .fontColor(Theme.PRIMARY)
            }
            .width('100%')
            .alignItems(VerticalAlign.Bottom)

            Divider()
              .strokeWidth(1)
              .color(Theme.DIVIDER)

            Flex({
              wrap: FlexWrap.Wrap,
              justifyContent: FlexAlign.SpaceBetween
            }) {
              ForEach(this.badges, (b: BadgeDef) => {
                Column({ space: 7 }) {
                  Row() {
                    Text(b.unlocked ? b.icon : '—')
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(b.unlocked ? Theme.PRIMARY : Theme.TEXT_SUB)
                      .width(38)
                      .height(38)
                      .textAlign(TextAlign.Center)
                      .backgroundColor(b.unlocked ? '#EAF1E3' : '#F1F1ED')
                      .borderRadius(6)

                    Blank()

                    if (b.unlocked) {
                      Text('已获得')
                        .fontSize(10)
                        .fontColor(Theme.PRIMARY)
                    }
                  }
                  .width('100%')

                  Text(b.name)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(b.unlocked ? Theme.TEXT : Theme.TEXT_SUB)
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(b.description)
                    .fontSize(11)
                    .lineHeight(16)
                    .fontColor(Theme.TEXT_SUB)
                    .width('100%')
                    .maxLines(2)

                  if (b.unlocked) {
                    Text(DateUtil.formatYMD(b.unlockedAt))
                      .fontSize(10)
                      .fontColor(Theme.TEXT_SUB)
                      .width('100%')
                  } else {
                    Text('尚未获得')
                      .fontSize(10)
                      .fontColor(Theme.TEXT_SUB)
                      .width('100%')
                  }
                }
                .width('48%')
                .height(132)
                .padding(12)
                .margin({ bottom: 10 })
                .backgroundColor(b.unlocked ? '#FBFCF8' : '#F7F7F4')
                .border({
                  width: 1,
                  color: b.unlocked ? '#DCE6D2' : Theme.DIVIDER
                })
                .borderRadius(6)
                .opacity(b.unlocked ? 1 : 0.72)
              }, (b: BadgeDef) => b.code + '_' + (b.unlocked ? '1' : '0'))
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 6 })
          .backgroundColor(Theme.CARD)

          // 证书区域
          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Text('植树证书')
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.TEXT)

                Text(this.certDate > 0 ? '感谢你为环境持续留下行动记录' : '用积分兑换一份电子纪念')
                  .fontSize(12)
                  .fontColor(Theme.TEXT_SUB)
              }

              Blank()

              Text(`${this.balance} / ${Constants.CERT_COST}`)
                .fontSize(12)
                .fontColor(this.balance >= Constants.CERT_COST
                  ? Theme.PRIMARY
                  : Theme.TEXT_SUB)
            }
            .width('100%')
            .alignItems(VerticalAlign.Bottom)

            Divider()
              .strokeWidth(1)
              .color(Theme.DIVIDER)

            if (this.certDate > 0) {
              Canvas(this.certCtx)
                .width('100%')
                .height(330)
                .borderRadius(4)
                .onReady(() => {
                  this.drawCert();
                })

              Row() {
                Text(`兑换于 ${DateUtil.formatYMD(this.certDate)}`)
                  .fontSize(12)
                  .fontColor(Theme.TEXT_SUB)

                Blank()

                Button('保存图片')
                  .height(36)
                  .fontSize(13)
                  .fontColor(Theme.PRIMARY)
                  .backgroundColor('#EAF1E3')
                  .borderRadius(4)
                  .onClick(() => {
                    this.saveCert();
                  })
              }
              .width('100%')
            } else {
              Column({ space: 14 }) {
                Row() {
                  Text('证')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.PRIMARY)
                    .width(44)
                    .height(44)
                    .textAlign(TextAlign.Center)
                    .backgroundColor('#EAF1E3')
                    .borderRadius(6)

                  Column({ space: 5 }) {
                    Text('电子植树证书')
                      .fontSize(14)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.TEXT)

                    Text(`还需 ${Math.max(Constants.CERT_COST - this.balance, 0)} 积分`)
                      .fontSize(12)
                      .fontColor(Theme.TEXT_SUB)
                  }
                  .margin({ left: 12 })

                  Blank()
                }
                .width('100%')

                Progress({
                  value: Math.min(this.balance, Constants.CERT_COST),
                  total: Constants.CERT_COST,
                  type: ProgressType.Linear
                })
                  .width('100%')
                  .color(Theme.PRIMARY)

                Row() {
                  Text(`当前 ${this.balance} 分`)
                    .fontSize(11)
                    .fontColor(Theme.TEXT_SUB)

                  Blank()

                  Text(`目标 ${Constants.CERT_COST} 分`)
                    .fontSize(11)
                    .fontColor(Theme.TEXT_SUB)
                }
                .width('100%')

                Button(this.balance >= Constants.CERT_COST ? '兑换证书' : '继续积累积分')
                  .width('100%')
                  .height(40)
                  .fontSize(14)
                  .fontColor(this.balance >= Constants.CERT_COST ? '#FFFFFF' : Theme.TEXT_SUB)
                  .backgroundColor(this.balance >= Constants.CERT_COST ? Theme.PRIMARY : '#E6E6E1')
                  .borderRadius(4)
                  .onClick(() => {
                    this.exchangeCert();
                  })
              }
              .width('100%')
              .padding({ top: 12, bottom: 8 })
            }
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.CARD)
        }
        .width('100%')
        .padding({ top: 14, bottom: 24 })
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
