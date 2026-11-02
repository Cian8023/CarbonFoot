import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Theme } from '../common/Theme';
import { AppInit } from '../common/AppInit';
import { bumpTick } from '../common/Constants';
import { InclusiveService, Benefit, Entitlement } from '../service/InclusiveService';
import { PointsService } from '../service/PointsService';
import { DateUtil } from '../utils/DateUtil';

/**
 * 城市碳普惠（创新拓展 3）：权益商城 + 积分兑换 + 权益记录。
 */
@Entry
@Component
struct Inclusive {
  @State benefits: Benefit[] = [];
  @State entitlements: Entitlement[] = [];
  @State balance: number = 0;
  @State statusText: string = '连接碳普惠平台中…';
  @State remoteMode: boolean = false;
  @State exchangingId: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      this.balance = await PointsService.getBalance();
      this.statusText = await InclusiveService.fetchBenefits();
      this.remoteMode = InclusiveService.isRemoteMode();
      this.benefits = InclusiveService.getBenefits();
      this.entitlements = await InclusiveService.listEntitlements();
    } catch (e) {
      this.statusText = '平台连接失败，已使用内置模拟模式';
      this.benefits = InclusiveService.getBenefits();
    }
  }

  private async doExchange(b: Benefit): Promise<void> {
    if (this.exchangingId !== '') {
      return;
    }
    AlertDialog.show({
      title: '兑换确认',
      message: `使用 ${b.cost} 积分兑换「${b.name}」？`,
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '兑换',
        fontColor: Theme.PRIMARY,
        action: () => {
          this.confirmExchange(b);
        }
      }
    });
  }

  private async confirmExchange(b: Benefit): Promise<void> {
    this.exchangingId = b.id;
    try {
      await InclusiveService.exchange(b);
      bumpTick();
      promptAction.showToast({ message: `兑换成功：${b.name}` });
      await this.refresh();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message });
    } finally {
      this.exchangingId = '';
    }
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
        Text('城市碳普惠平台')
          .fontSize(Theme.FS_HEAD)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('')
          .width(22)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14 })

      Scroll() {
        Column({ space: 12 }) {
          // 平台状态卡
          Row({ space: 10 }) {
            Circle({ width: 10, height: 10 })
              .fill(this.remoteMode ? Theme.PRIMARY : Theme.POINTS)
            Column({ space: 3 }) {
              Text(this.statusText)
                .fontSize(Theme.FS_BODY)
                .fontWeight(FontWeight.Medium)
              Text(`我的碳积分：${this.balance}`)
                .fontSize(Theme.FS_TERTIARY)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .borderRadius(Theme.R_LARGE)
          .backgroundColor(Theme.CARD)
          .borderWidth(1).borderColor(Theme.CARD_BORDER)
          .borderWidth(1).borderColor(Theme.CARD_BORDER)

          // 权益商城
          Column({ space: 10 }) {
            Text('可兑换权益')
              .fontSize(Theme.FS_TITLE)
              .fontWeight(FontWeight.Medium)
              .width('100%')

            ForEach(this.benefits, (b: Benefit) => {
              Row({ space: 12 }) {
                Text(b.icon)
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.PRIMARY)
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(Theme.PRIMARY_BG)
                  .borderRadius(20)
                Column({ space: 4 }) {
                  Text(b.name)
                    .fontSize(Theme.FS_CONTENT)
                    .fontWeight(FontWeight.Medium)
                  Text(b.desc)
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                    .maxLines(1)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Column({ space: 3 }) {
                  Button(`${b.cost} 分`)
                    .fontSize(Theme.FS_TERTIARY)
                    .height(32)
                    .backgroundColor(this.balance >= b.cost && b.stock > 0 ? Theme.PRIMARY : Theme.TEXT_TERTIARY)
                    .enabled(b.stock > 0)
                    .onClick(() => {
                      this.doExchange(b);
                    })
                  if (b.stock <= 0) {
                    Text('已兑完')
                      .fontSize(Theme.FS_MICRO)
                      .fontColor('#F53F3F')
                  } else {
                    Text(`余 ${b.stock}`)
                      .fontSize(Theme.FS_MICRO)
                      .fontColor(Theme.TEXT_TERTIARY)
                  }
                }
              }
              .width('100%')
              .padding(12)
              .borderRadius(14)
              .backgroundColor(Theme.BG_GRAY)
            }, (b: Benefit) => b.id + '_' + b.stock)
          }
          .width('100%')
          .padding(14)
          .borderRadius(Theme.R_LARGE)
          .backgroundColor(Theme.CARD)
          .borderWidth(1).borderColor(Theme.CARD_BORDER)

          // 权益记录
          if (this.entitlements.length > 0) {
            Column({ space: 10 }) {
              Text('我的权益记录')
                .fontSize(Theme.FS_TITLE)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              ForEach(this.entitlements, (e: Entitlement) => {
                Row({ space: 10 }) {
                  Text(e.icon)
                    .fontSize(Theme.FS_HERO)
                  Column({ space: 2 }) {
                    Text(e.name)
                      .fontSize(Theme.FS_BODY)
                      .fontWeight(FontWeight.Medium)
                    Text(`${e.from} · ${DateUtil.formatMDHM(e.time)}`)
                      .fontSize(Theme.FS_CAPTION)
                      .fontColor(Theme.TEXT_TERTIARY)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text('✓')
                    .fontColor(Theme.PRIMARY)
                }
                .width('100%')
                .padding(10)
                .borderRadius(10)
                .backgroundColor(Theme.BG)
              }, (e: Entitlement) => '' + e.time + e.name)
            }
            .width('100%')
            .padding(14)
            .borderRadius(16)
            .backgroundColor(Theme.CARD)
          }

          Text('说明：在「我的 > 服务配置」中填入碳普惠平台地址即可对接真实接口（可用 Node.js 起 Mock 服务）；未连通时自动使用内置模拟权益池。')
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
