import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BadgeDef } from '../model/Models';
import { BadgeService } from '../service/BadgeService';
import { PointsService } from '../service/PointsService';
import { PrefsService } from '../common/PrefsService';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorRepo } from '../db/Repository';
import { EcoUtil } from '../utils/EcoUtil';

@Component
export struct MineView {
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State nickname: string = '绿色生活家';
  @State editing: boolean = false;
  @State nameInput: string = '';
  @State totalKg: string = '0.00';
  @State totalG: number = 0;
  @State balance: number = 0;
  @State badgeText: string = '0/0';
  @State streak: number = 0;
  @State totalPoints: number = 0;

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      this.nickname = await PrefsService.getNickname();
      this.balance = await PointsService.getBalance();
      this.streak = await BadgeService.currentStreak();
      const totalG = await BehaviorRepo.sumAllReduction();
      this.totalG = totalG;
      this.totalKg = DateUtil.gramsToKg(totalG);
      const badges: BadgeDef[] = await BadgeService.list();
      let unlocked = 0;
      for (const b of badges) {
        if (b.unlocked) {
          unlocked++;
        }
      }
      this.badgeText = `${unlocked}/${badges.length}`;
      this.totalPoints = await PointsService.totalEarned();
    } catch (e) {
      console.error('MineView refresh error: ' + JSON.stringify(e));
    }
  }

  private async saveNickname(): Promise<void> {
    const name = this.nameInput.trim();
    if (name === '' || name.length > 16) {
      promptAction.showToast({ message: '昵称需为 1-16 个字符' });
      return;
    }
    await PrefsService.setNickname(name);
    this.nickname = name;
    this.editing = false;
    promptAction.showToast({ message: '昵称已更新' });
  }

  @Builder
  menuItem(label: string, sub: string, onTap: () => void) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(Theme.FS_CONTENT)
        .fontColor(Theme.TEXT)
        .layoutWeight(1)
      Text(sub)
        .fontSize(Theme.FS_TERTIARY)
        .fontColor(Theme.TEXT_TERTIARY)
      Text('›')
        .fontSize(Theme.FS_TITLE)
        .fontColor(Theme.TEXT_TERTIARY)
    }
    .width('100%')
    .padding(14)
    .onClick(() => {
      onTap();
    })
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        // 用户信息
        Column({ space: 16 }) {
          Row({ space: 14 }) {
            Column() {
              Text(this.nickname.substring(0, 1))
                .fontSize(Theme.FS_HERO)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.PRIMARY)
            }
            .width(56)
            .height(56)
            .borderRadius(28)
            .backgroundColor(Theme.PRIMARY_BG)
            .justifyContent(FlexAlign.Center)

            Column({ space: 6 }) {
              if (this.editing) {
                Row({ space: 8 }) {
                  TextInput({ text: this.nameInput, placeholder: '输入新昵称' })
                    .height(38)
                    .layoutWeight(1)
                    .onChange((v: string) => {
                      this.nameInput = v;
                    })
                  Text('保存')
                    .fontSize(Theme.FS_BODY)
                    .fontColor(Theme.PRIMARY)
                    .onClick(() => {
                      this.saveNickname();
                    })
                }
                .width('100%')
              } else {
                Row({ space: 8 }) {
                  Text(this.nickname)
                    .fontSize(Theme.FS_HEAD)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.TEXT)
                  Text('编辑')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.PRIMARY)
                    .backgroundColor(Theme.PRIMARY_BG)
                    .borderRadius(8)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .onClick(() => {
                      this.nameInput = this.nickname;
                      this.editing = true;
                    })
                }
              }
              Text(`连续打卡 ${this.streak} 天`)
                .fontSize(Theme.FS_TERTIARY)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')

          Divider().color(Theme.DIVIDER)

          Row() {
            Column({ space: 4 }) {
              Text(this.totalKg)
                .fontSize(Theme.FS_HEAD)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.PRIMARY)
              Text('累计减排(kg)')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .layoutWeight(1)

            Divider().vertical(true).height(28).color(Theme.DIVIDER)

            Column({ space: 4 }) {
              Text('' + this.balance)
                .fontSize(Theme.FS_HEAD)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.TEXT)
              Text('碳积分')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .layoutWeight(1)

            Divider().vertical(true).height(28).color(Theme.DIVIDER)

            Column({ space: 4 }) {
              Text(this.badgeText)
                .fontSize(Theme.FS_HEAD)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.TEXT)
              Text('徽章')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .layoutWeight(1)

            Divider().vertical(true).height(28).color(Theme.DIVIDER)

            Column({ space: 4 }) {
              Text('' + this.totalPoints)
                .fontSize(Theme.FS_HEAD)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.TEXT)
              Text('累计积分')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .layoutWeight(1)
          }
          .width('100%')

          // 累计减排折成树木，给数字一个参照系
          if (this.totalG > 0) {
            Text(EcoUtil.totalText(this.totalG))
              .fontSize(Theme.FS_SECONDARY)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')
              .textAlign(TextAlign.Center)
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .padding(18)
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)

        // 功能入口
        Column() {
          this.menuItem('徽章墙', '查看解锁进度', (): void => {
            router.pushUrl({ url: 'pages/Badges' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('双碳科普', '政策·技巧·动态', (): void => {
            router.pushUrl({ url: 'pages/Knowledge' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('积分流水', '收支明细', (): void => {
            AppStorage.setOrCreate('tasksSegment', 1);
            AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('年度报告', '这一年你的低碳足迹', (): void => {
            router.pushUrl({ url: 'pages/AnnualReport' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('植树证书', '积分兑换', (): void => {
            router.pushUrl({ url: 'pages/Badges' });
          })
        }
        .width('100%')
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)
        .clip(true)

        // 创新拓展功能
        Column() {
          Row({ space: 12 }) {
            Text('创')
              .fontSize(Theme.FS_HEAD)
              .fontColor(Theme.PRIMARY)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
            Text('创新拓展')
              .fontSize(Theme.FS_CONTENT)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding(14)

          Divider().color(Theme.DIVIDER)
          this.menuItem('AI 拍照识别录入', '智能识别低碳行为', (): void => {
            router.pushUrl({ url: 'pages/AiRecognize' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('城市碳普惠平台', '积分互通·权益兑换', (): void => {
            router.pushUrl({ url: 'pages/Inclusive' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('家庭碳账户', '多端同步·合并统计', (): void => {
            router.pushUrl({ url: 'pages/Family' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('减排成果分享', '生成分享卡片', (): void => {
            router.pushUrl({ url: 'pages/ShareCard' });
          })
        }
        .width('100%')
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)
        .clip(true)

        // 设置入口（个性化 / 服务配置 / 数据管理整合于此）
        Column() {
          this.menuItem('设置', '目标·布局·服务配置·数据管理', (): void => {
            router.pushUrl({ url: 'pages/SettingsDetail' });
          })
        }
        .width('100%')
        .borderRadius(Theme.R_LARGE)
        .backgroundColor(Theme.CARD)
        .borderWidth(1).borderColor(Theme.CARD_BORDER)
        .clip(true)

        // 底部声明
        Column({ space: 4 }) {
          Text(`碳足迹 v${Constants.VERSION} · Apache-2.0 · 零三方依赖`)
            .fontSize(Theme.FS_SECONDARY)
            .fontColor(Theme.TEXT_TERTIARY)
          Text('减排因子为公开核算资料整理的常用取值（2024），仅作生活估算，不用于碳交易、碳核查或认证')
            .fontSize(Theme.FS_CAPTION)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')
        .padding(6)
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
