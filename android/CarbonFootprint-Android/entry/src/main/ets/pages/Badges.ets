/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import util from '@ohos.util';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';
import { AppInit } from '../common/AppInit';
import { Constants, bumpTick } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BadgeDef } from '../model/Models';
import { BadgeService, BadgeProgressData } from '../service/BadgeService';
import { fpFont } from '../components/Chart';
import { PointsService } from '../service/PointsService';
import { BehaviorRepo } from '../db/Repository';
import { PrefsService } from '../common/PrefsService';
import { DateUtil } from '../utils/DateUtil';

@Entry
@Component
struct Badges {
  @StorageProp('statusBarHeightPx') statusBarHeightPx: number = 0;
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State badges: BadgeDef[] = [];
  @State balance: number = 0;
  @State certDate: number = 0;
  @State nickname: string = '绿色生活家';
  @State totalKg: string = '0.00';
  @State unlockedCount: number = 0;
  @State progressArr: BadgeProgressData[] = [];
  @State selBadge: BadgeDef | null = null;
  @State showDetail: boolean = false;
  @State selProgress: BadgeProgressData | null = null;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private certCtx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  /** 徽章图标名 → 系统矢量符号（badges.json icon 字段） */
  private badgeSymbols: Record<string, Resource> = {
    'leaf': $r('sys.symbol.leaf'),
    'medal': $r('sys.symbol.medal'),
    'rosette': $r('sys.symbol.rosette'),
    'flame': $r('sys.symbol.flame'),
    'calendar': $r('sys.symbol.calendar'),
    'star': $r('sys.symbol.star'),
    'checkmark_circle': $r('sys.symbol.checkmark_circle'),
    'book': $r('sys.symbol.book'),
    'flag': $r('sys.symbol.flag')
  };

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
      this.progressArr = await BadgeService.progressList(this.badges);
    } catch (e) {
      console.error('Badges refresh error: ' + JSON.stringify(e));
    }
  }

  @Builder
  badgeGlyph(icon: string, size: number, unlocked: boolean) {
    if (this.badgeSymbols[icon] !== undefined) {
      SymbolGlyph(this.badgeSymbols[icon])
        .fontSize(size)
        .fontColor([unlocked ? Theme.PRIMARY : Theme.TEXT_TERTIARY])
    } else {
      Text(icon)
        .fontSize(size)
        .fontColor(unlocked ? Theme.PRIMARY : Theme.TEXT_TERTIARY)
    }
  }

  private openBadgeDetail(b: BadgeDef, idx: number): void {
    this.selBadge = b;
    this.selProgress = this.progressArr.length > idx ? this.progressArr[idx] : null;
    this.showDetail = true;
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
    // 标题（Canvas 字号按密度换算，屏显与导出 PNG 均为高清比例）
    this.certCtx.fillStyle = Theme.PRIMARY;
    this.certCtx.font = 'bold ' + fpFont(30) + ' sans-serif';
    this.certCtx.fillText('植 树 证 书', w / 2, 70);
    this.certCtx.font = fpFont(11);
    this.certCtx.fillStyle = '#8A8A6A';
    this.certCtx.fillText('T R E E   P L A N T I N G   C E R T I F I C A T E', w / 2, 92);
    // 正文
    this.certCtx.fillStyle = '#3A4A3A';
    this.certCtx.font = fpFont(14);
    this.certCtx.fillText('兹证明', w / 2, 130);
    this.certCtx.font = 'bold ' + fpFont(24) + ' sans-serif';
    this.certCtx.fillStyle = Theme.TEXT;
    this.certCtx.fillText(this.nickname, w / 2, 165);
    this.certCtx.font = fpFont(14);
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
    this.certCtx.font = fpFont(12);
    this.certCtx.fillStyle = '#8A8A6A';
    this.certCtx.fillText('碳足迹 · 全民绿色生活碳积分与减排指南', w / 2, h - 44);
    this.certCtx.fillText(`证书编号：CF-${this.certDate}`, w / 2, h - 24);
  }

  private async saveCert(): Promise<void> {
    try {
      const dataUrl = this.certCtx.toDataURL('image/png', 1.0);
      const b64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
      const buf: Uint8Array = new util.Base64Helper().decodeSync(b64);
      const helper = photoAccessHelper.getPhotoAccessHelper(AppInit.getContext());
      const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
      // 相册 asset uri 不支持 TRUNC 语义，用纯 READ_WRITE 打开后整段写入
      const f = fs.openSync(uri, fs.OpenMode.READ_WRITE);
      // 只写视图覆盖的字节，避免把底层 buffer 的多余内容一并写入
      fs.writeSync(f.fd, buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength) as ArrayBuffer);
      fs.closeSync(f.fd);
      promptAction.showToast({ message: '证书已保存到相册', duration: 3000 });
    } catch (e) {
      promptAction.showToast({ message: '保存失败：' + JSON.stringify(e) });
    }
  }

  @Builder
  badgeDetailSheet() {
    Column({ space: 14 }) {
      Row() {
        Text('徽章详情')
          .fontSize(Theme.FS_TITLE)
          .fontWeight(FontWeight.Medium)
        Blank()
        Text('×')
          .fontSize(Theme.FS_TITLE)
          .fontColor(Theme.TEXT_TERTIARY)
          .onClick(() => {
            this.showDetail = false;
          })
      }
      .width('100%')

      if (this.selBadge !== null) {
        Row({ space: 14 }) {
          Column() {
            this.badgeGlyph((this.selBadge as BadgeDef).icon, 30, (this.selBadge as BadgeDef).unlocked)
          }
          .width(64)
          .height(64)
          .justifyContent(FlexAlign.Center)
          .backgroundColor((this.selBadge as BadgeDef).unlocked ? '#EAF1E3' : '#F1F1ED')
          .borderRadius(10)
          Column({ space: 6 }) {
            Text((this.selBadge as BadgeDef).name)
              .fontSize(Theme.FS_HEAD)
              .fontWeight(FontWeight.Bold)
            Text((this.selBadge as BadgeDef).description)
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(Theme.TEXT_TERTIARY)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')

        if ((this.selBadge as BadgeDef).unlocked) {
          Text('已解锁 · '+ DateUtil.formatFull((this.selBadge as BadgeDef).unlockedAt))
            .fontSize(Theme.FS_BODY)
            .fontColor(Theme.PRIMARY)
            .width('100%')
        } else if (this.selProgress !== null) {
          Column({ space: 8 }) {
            Text('当前进度：' + this.selProgress.label)
              .fontSize(Theme.FS_BODY)
              .fontColor(Theme.TEXT)
              .width('100%')
            Progress({ value: this.selProgress.pct, total: 100, type: ProgressType.Linear })
              .width('100%')
              .height(8)
              .color(Theme.PRIMARY)
            Text((this.selBadge as BadgeDef).description + '，达成后自动解锁')
              .fontSize(Theme.FS_SECONDARY)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')
          }
          .width('100%')
        }
      }
    }
    .width('100%')
    .padding(16)
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('‹')
          .fontSize(Theme.FS_DISPLAY)
          .fontColor(Theme.TEXT)
          .width(32)
          .height(32)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.back();
          })

        Text('徽章与证书')
          .fontSize(Theme.FS_HEAD)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.TEXT)
          .margin({ left: 8 })

        Blank()

        Text(`${this.unlockedCount}/${this.badges.length}`)
          .fontSize(Theme.FS_TERTIARY)
          .fontColor(Theme.TEXT_TERTIARY)
      }
      .width('100%')
      .height(52)
      .margin({ top: px2vp(this.statusBarHeightPx) })
      .padding({ left: 14, right: 14 })
      .border({ width: { bottom: 1 }, color: Theme.DIVIDER_LIGHT })

      Scroll() {
        Column({ space: 20 }) {
          // 徽章区域
          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Text('我的徽章')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.TEXT)

                Text('记录已经完成的绿色行动')
                  .fontSize(Theme.FS_TERTIARY)
                  .fontColor(Theme.TEXT_TERTIARY)
              }

              Blank()

              Text(`${this.unlockedCount} 个已获得`)
                .fontSize(Theme.FS_TERTIARY)
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
                    Column() {
                      this.badgeGlyph(b.icon, 20, b.unlocked)
                    }
                    .width(38)
                    .height(38)
                    .justifyContent(FlexAlign.Center)
                    .backgroundColor(b.unlocked ? '#EAF1E3' : '#F1F1ED')
                    .borderRadius(8)

                    Blank()

                    if (b.unlocked) {
                      Text('已获得')
                        .fontSize(Theme.FS_CAPTION)
                        .fontColor(Theme.PRIMARY)
                    }
                  }
                  .width('100%')

                  Text(b.name)
                    .fontSize(Theme.FS_CONTENT)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(b.unlocked ? Theme.TEXT : Theme.TEXT_TERTIARY)
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Text(b.description)
                    .fontSize(Theme.FS_SECONDARY)
                    .lineHeight(16)
                    .fontColor(Theme.TEXT_TERTIARY)
                    .width('100%')
                    .maxLines(2)

                  if (b.unlocked) {
                    Text(DateUtil.formatYMD(b.unlockedAt))
                      .fontSize(Theme.FS_CAPTION)
                      .fontColor(Theme.TEXT_TERTIARY)
                      .width('100%')
                  } else {
                    Column({ space: 4 }) {
                      Text((this.progressArr.length > 0) ? (this.progressArr[this.badges.indexOf(b)] !== undefined ? this.progressArr[this.badges.indexOf(b)].label : '进度加载中') : '进度加载中')
                        .fontSize(Theme.FS_CAPTION)
                        .fontColor(Theme.TEXT_TERTIARY)
                        .width('100%')
                      Progress({ value: (this.progressArr.length > 0 && this.progressArr[this.badges.indexOf(b)] !== undefined) ? this.progressArr[this.badges.indexOf(b)].pct : 0, total: 100, type: ProgressType.Linear })
                        .width('100%')
                        .height(6)
                        .color(Theme.PRIMARY)
                    }
                    .width('100%')
                  }
                }
                .width('48%')
                .height(150)
                .padding(12)
                .margin({ bottom: 10 })
                .backgroundColor(b.unlocked ? '#FDFCF9' : '#F5F2E9')
                .borderWidth(1).borderColor(Theme.CARD_BORDER)
                .borderRadius(14)
                .opacity(b.unlocked ? 1 : 0.72)
                .onClick(() => {
                  this.openBadgeDetail(b, this.badges.indexOf(b));
                })
              }, (b: BadgeDef) => b.code + '_' + (b.unlocked ? '1' : '0') + '_' + b.unlockedAt)
            }
            .width('100%')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 6 })
          .margin({ left: 14, right: 14, top: 14 })
          .borderRadius(Theme.R_LARGE)
          .backgroundColor(Theme.CARD)
          .borderWidth(1).borderColor(Theme.CARD_BORDER)

          // 证书区域
          Column({ space: 14 }) {
            Row() {
              Column({ space: 4 }) {
                Text('植树证书')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.TEXT)

                Text(this.certDate > 0 ? '感谢你为环境持续留下行动记录' : '用积分兑换一份电子纪念')
                  .fontSize(Theme.FS_TERTIARY)
                  .fontColor(Theme.TEXT_TERTIARY)
              }

              Blank()

              Text(`${this.balance} / ${Constants.CERT_COST}`)
                .fontSize(Theme.FS_TERTIARY)
                .fontColor(this.balance >= Constants.CERT_COST
                  ? Theme.PRIMARY
                  : Theme.TEXT_TERTIARY)
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
                  .fontSize(Theme.FS_TERTIARY)
                  .fontColor(Theme.TEXT_TERTIARY)

                Blank()

                // ArkUI-X / Android 不支持 SaveButton，改普通 Button 直接保存
                Button('保存')
                  .height(36)
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.PRIMARY)
                  .backgroundColor('#EAF1E3')
                  .borderRadius(4)
                  .onClick(async () => {
                    await this.saveCert();
                  })
              }
              .width('100%')
            } else {
              Column({ space: 14 }) {
                Row() {
                  Text('证')
                    .fontSize(Theme.FS_HEAD)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.PRIMARY)
                    .width(44)
                    .height(44)
                    .textAlign(TextAlign.Center)
                    .backgroundColor('#EAF1E3')
                    .borderRadius(6)

                  Column({ space: 5 }) {
                    Text('电子植树证书')
                      .fontSize(Theme.FS_CONTENT)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(Theme.TEXT)

                    Text(`还需 ${Math.max(Constants.CERT_COST - this.balance, 0)} 积分`)
                      .fontSize(Theme.FS_TERTIARY)
                      .fontColor(Theme.TEXT_TERTIARY)
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
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)

                  Blank()

                  Text(`目标 ${Constants.CERT_COST} 分`)
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .width('100%')

                Button(this.balance >= Constants.CERT_COST ? '兑换证书' : '继续积累积分')
                  .width('100%')
                  .height(40)
                  .fontSize(Theme.FS_CONTENT)
                  .fontColor(this.balance >= Constants.CERT_COST ? '#FFFFFF' : Theme.TEXT_TERTIARY)
                  .backgroundColor(this.balance >= Constants.CERT_COST ? Theme.PRIMARY : '#E6E6E1')
                  .borderRadius(12)
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
          .margin({ left: 14, right: 14, top: 14, bottom: 20 })
          .borderRadius(Theme.R_LARGE)
          .backgroundColor(Theme.CARD)
          .borderWidth(1).borderColor(Theme.CARD_BORDER)
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
    .bindSheet(this.showDetail, this.badgeDetailSheet(), {
      height: 420,
      showClose: false,
      onDisappear: () => {
        this.showDetail = false;
      }
    })
  }
}
