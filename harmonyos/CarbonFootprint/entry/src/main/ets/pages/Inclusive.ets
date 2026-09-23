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
          .fontSize(22)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text('城市碳普惠平台')
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
          // 平台状态卡
          Row({ space: 10 }) {
            Circle({ width: 10, height: 10 })
              .fill(this.remoteMode ? Theme.PRIMARY : Theme.POINTS)
            Column({ space: 3 }) {
              Text(this.statusText)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
              Text(`我的碳积分：${this.balance}`)
                .fontSize(12)
                .fontColor(Theme.TEXT_SUB)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .borderRadius(14)
          .backgroundColor(Theme.CARD)

          // 权益商城
          Column({ space: 10 }) {
            Text('可兑换权益')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .width('100%')

            ForEach(this.benefits, (b: Benefit) => {
              Row({ space: 12 }) {
                Text(b.icon)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.PRIMARY)
                  .width(40)
                  .height(40)
                  .textAlign(TextAlign.Center)
                  .backgroundColor(Theme.PRIMARY_BG)
                  .borderRadius(20)
                Column({ space: 4 }) {
                  Text(b.name)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                  Text(b.desc)
                    .fontSize(11)
                    .fontColor(Theme.TEXT_SUB)
                    .maxLines(1)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Button(`${b.cost} 分`)
                  .fontSize(12)
                  .height(32)
                  .backgroundColor(this.balance >= b.cost ? Theme.PRIMARY : Theme.TEXT_SUB)
                  .onClick(() => {
                    this.doExchange(b);
                  })
              }
              .width('100%')
              .padding(12)
              .borderRadius(12)
              .backgroundColor(Theme.BG)
            }, (b: Benefit) => b.id)
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)

          // 权益记录
          if (this.entitlements.length > 0) {
            Column({ space: 10 }) {
              Text('我的权益记录')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              ForEach(this.entitlements, (e: Entitlement) => {
                Row({ space: 10 }) {
                  Text(e.icon)
                    .fontSize(20)
                  Column({ space: 2 }) {
                    Text(e.name)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                    Text(`${e.from} · ${DateUtil.formatMDHM(e.time)}`)
                      .fontSize(10)
                      .fontColor(Theme.TEXT_SUB)
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
