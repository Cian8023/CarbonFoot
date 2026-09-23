import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants, bumpTick } from '../common/Constants';
import { Theme } from '../common/Theme';
import { AppConfig } from '../common/AppConfig';
import { BadgeDef, BehaviorRecord } from '../model/Models';
import { BadgeService } from '../service/BadgeService';
import { PointsService } from '../service/PointsService';
import { ExportService } from '../service/ExportService';
import { PrefsService } from '../common/PrefsService';
import { DateUtil } from '../utils/DateUtil';
import { BehaviorRepo } from '../db/Repository';

@Component
export struct MineView {
  @StorageLink('tick') @Watch('refresh') tick: number = 0;
  @State nickname: string = '绿色生活家';
  @State editing: boolean = false;
  @State nameInput: string = '';
  @State totalKg: string = '0.00';
  @State balance: number = 0;
  @State badgeText: string = '0/0';
  @State streak: number = 0;
  @State aiKey: string = '';
  @State aiUrl: string = '';
  @State inclusiveUrl: string = '';

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
      this.totalKg = DateUtil.gramsToKg(totalG);
      const badges: BadgeDef[] = await BadgeService.list();
      let unlocked = 0;
      for (const b of badges) {
        if (b.unlocked) {
          unlocked++;
        }
      }
      this.badgeText = `${unlocked}/${badges.length}`;
      this.aiKey = await AppConfig.getAiApiKey();
      this.aiUrl = await AppConfig.getAiBaseUrl();
      this.inclusiveUrl = await AppConfig.getInclusiveBaseUrl();
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

  private async doBackup(): Promise<void> {
    try {
      const path = await ExportService.backupJson();
      promptAction.showToast({ message: '备份完成：' + path, duration: 3500 });
    } catch (e) {
      promptAction.showToast({ message: '备份失败，请重试' });
    }
  }

  private async doExportCsv(): Promise<void> {
    try {
      const path = await ExportService.exportCsv();
      promptAction.showToast({ message: '报表已导出：' + path, duration: 3500 });
    } catch (e) {
      promptAction.showToast({ message: '导出失败，请重试' });
    }
  }

  private confirmClear(): void {
    AlertDialog.show({
      title: '清空所有数据',
      message: '将删除全部行为记录、积分流水与任务完成记录，徽章将重新锁定。此操作不可恢复，确定继续？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: Theme.WARN,
        action: () => {
          ExportService.clearAll();
          bumpTick();
          promptAction.showToast({ message: '数据已清空' });
          this.refresh();
        }
      }
    });
  }

  @Builder
  menuItem(label: string, sub: string, onTap: () => void) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(14)
        .fontColor(Theme.TEXT)
        .layoutWeight(1)
      Text(sub)
        .fontSize(12)
        .fontColor(Theme.TEXT_TERTIARY)
      Text('›')
        .fontSize(16)
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
                .fontSize(24)
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
                    .fontSize(13)
                    .fontColor(Theme.PRIMARY)
                    .onClick(() => {
                      this.saveNickname();
                    })
                }
                .width('100%')
              } else {
                Row({ space: 8 }) {
                  Text(this.nickname)
                    .fontSize(19)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.TEXT)
                  Text('编辑')
                    .fontSize(11)
                    .fontColor(Theme.PRIMARY)
                    .border({ width: 1, color: Theme.PRIMARY, radius: 8 })
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .onClick(() => {
                      this.nameInput = this.nickname;
                      this.editing = true;
                    })
                }
              }
              Text(`连续打卡 ${this.streak} 天`)
                .fontSize(12)
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
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.PRIMARY)
              Text('累计减排(kg)')
                .fontSize(11)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .layoutWeight(1)

            Divider().vertical(true).height(28).color(Theme.DIVIDER)

            Column({ space: 4 }) {
              Text('' + this.balance)
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.TEXT)
              Text('碳积分')
                .fontSize(11)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .layoutWeight(1)

            Divider().vertical(true).height(28).color(Theme.DIVIDER)

            Column({ space: 4 }) {
              Text(this.badgeText)
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor(Theme.TEXT)
              Text('徽章')
                .fontSize(11)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .borderRadius(Theme.R_MEDIUM)
        .backgroundColor(Theme.CARD)
        .border({ width: 1, color: Theme.DIVIDER })

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
          this.menuItem('植树证书', '积分兑换', (): void => {
            router.pushUrl({ url: 'pages/Badges' });
          })
        }
        .width('100%')
        .borderRadius(16)
        .backgroundColor(Theme.CARD)
        .clip(true)

        // 创新拓展功能
        Column() {
          Row({ space: 12 }) {
            Text('创')
              .fontSize(12)
              .fontColor(Theme.PRIMARY)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .fontSize(18)
            Text('创新拓展')
              .fontSize(14)
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
        .borderRadius(16)
        .backgroundColor(Theme.CARD)
        .clip(true)

        // 服务配置
        Column({ space: 10 }) {
          Row({ space: 12 }) {
            Text('配')
              .fontSize(12)
              .fontColor(Theme.PRIMARY)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .fontSize(18)
            Text('服务配置（联网能力）')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 14 })

          Text('AI 视觉接口 API Key（留空 = 离线演示识别）')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
          TextInput({ placeholder: 'sk-...', text: this.aiKey })
            .height(40)
            .type(InputType.NEW_PASSWORD)
            .onChange((v: string) => {
              this.aiKey = v;
            })
          Row({ space: 10 }) {
            TextInput({ placeholder: '视觉接口地址', text: this.aiUrl })
              .layoutWeight(1)
              .height(40)
              .onChange((v: string) => {
                this.aiUrl = v;
              })
            Text('保存')
              .fontSize(13)
              .fontColor(Theme.PRIMARY)
              .onClick(() => {
                AppConfig.setAiApiKey(this.aiKey.trim());
                AppConfig.setAiBaseUrl(this.aiUrl.trim());
                promptAction.showToast({ message: 'AI 服务配置已保存' });
              })
          }
          .width('100%')

          Text('碳普惠平台地址（不可达 = 内置模拟模式）')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
            .width('100%')
          Row({ space: 10 }) {
            TextInput({ placeholder: 'http://服务器:端口', text: this.inclusiveUrl })
              .layoutWeight(1)
              .height(40)
              .onChange((v: string) => {
                this.inclusiveUrl = v;
              })
            Text('保存')
              .fontSize(13)
              .fontColor(Theme.PRIMARY)
              .onClick(() => {
                AppConfig.setInclusiveBaseUrl(this.inclusiveUrl.trim());
                promptAction.showToast({ message: '碳普惠平台地址已保存' });
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 14, right: 14, bottom: 14 })
        .borderRadius(16)
        .backgroundColor(Theme.CARD)

        // 数据管理
        Column() {
          Row({ space: 12 }) {
            Text('档')
              .fontSize(12)
              .fontColor(Theme.PRIMARY)
              .backgroundColor(Theme.PRIMARY_BG)
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 3, bottom: 3 })
              .fontSize(18)
            Text('本地数据管理')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding(14)

          Divider().color(Theme.DIVIDER)
          this.menuItem('一键备份（JSON）', '导出到应用沙箱', (): void => {
            this.doBackup();
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('统计报表（CSV）', '月度减排汇总', (): void => {
            this.doExportCsv();
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('清空所有数据', '不可恢复', (): void => {
            this.confirmClear();
          })
        }
        .width('100%')
        .borderRadius(16)
        .backgroundColor(Theme.CARD)
        .clip(true)

        // 关于
        Column({ space: 6 }) {
          Text(`碳足迹 v${Constants.VERSION}`)
            .fontSize(12)
            .fontColor(Theme.TEXT_TERTIARY)
          Text('OpenHarmony API 12 · 数据仅存储在本机，不上传云端')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
          Text('减排因子参考生态环境部公开核算方法，仅作生活估算演示')
            .fontSize(11)
            .fontColor(Theme.TEXT_TERTIARY)
        }
        .width('100%')
        .padding(10)
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
