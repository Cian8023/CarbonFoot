import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants } from '../common/Constants';
import { Theme } from '../common/Theme';
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
          promptAction.showToast({ message: '数据已清空' });
          this.refresh();
        }
      }
    });
  }

  @Builder
  menuItem(icon: string, label: string, sub: string, onTap: () => void) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(20)
      Text(label)
        .fontSize(14)
        .fontColor(Theme.TEXT)
        .layoutWeight(1)
      Text(sub)
        .fontSize(12)
        .fontColor(Theme.TEXT_SUB)
      Text('>')
        .fontSize(14)
        .fontColor(Theme.TEXT_SUB)
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
        Column({ space: 14 }) {
          Row({ space: 14 }) {
            Column() {
              Text('🌱')
                .fontSize(30)
            }
            .width(64)
            .height(64)
            .borderRadius(32)
            .backgroundColor('#FFFFFF')
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
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                  Text('✏️')
                    .fontSize(13)
                    .onClick(() => {
                      this.nameInput = this.nickname;
                      this.editing = true;
                    })
                }
              }
              Text(`连续打卡 ${this.streak} 天 · 地球的绿色伙伴`)
                .fontSize(12)
                .fontColor('#C8E6C9')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')

          Row() {
            Column({ space: 4 }) {
              Text(this.totalKg)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('累计减排(kg)')
                .fontSize(11)
                .fontColor('#C8E6C9')
            }
            .layoutWeight(1)

            Divider().vertical(true).height(30).color('rgba(255,255,255,0.3)')

            Column({ space: 4 }) {
              Text('' + this.balance)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('碳积分')
                .fontSize(11)
                .fontColor('#C8E6C9')
            }
            .layoutWeight(1)

            Divider().vertical(true).height(30).color('rgba(255,255,255,0.3)')

            Column({ space: 4 }) {
              Text(this.badgeText)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text('徽章')
                .fontSize(11)
                .fontColor('#C8E6C9')
            }
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(18)
        .borderRadius(16)
        .linearGradient({ angle: 135, colors: [['#43A047', 0], ['#2E7D32', 1]] })

        // 功能入口
        Column() {
          this.menuItem('🏅', '徽章墙', '查看解锁进度', (): void => {
            router.pushUrl({ url: 'pages/Badges' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('📚', '双碳科普', '政策·技巧·动态', (): void => {
            router.pushUrl({ url: 'pages/Knowledge' });
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('🪙', '积分流水', '收支明细', (): void => {
            AppStorage.setOrCreate('tasksSegment', 1);
            AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('🌳', '植树证书', '积分兑换', (): void => {
            router.pushUrl({ url: 'pages/Badges' });
          })
        }
        .width('100%')
        .borderRadius(16)
        .backgroundColor(Theme.CARD)
        .clip(true)

        // 数据管理
        Column() {
          Row({ space: 12 }) {
            Text('🗂️')
              .fontSize(18)
            Text('本地数据管理')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .padding(14)

          Divider().color(Theme.DIVIDER)
          this.menuItem('💾', '一键备份（JSON）', '导出到应用沙箱', (): void => {
            this.doBackup();
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('📊', '统计报表（CSV）', '月度减排汇总', (): void => {
            this.doExportCsv();
          })
          Divider().color(Theme.DIVIDER)
          this.menuItem('🗑️', '清空所有数据', '不可恢复', (): void => {
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
            .fontColor(Theme.TEXT_SUB)
          Text('OpenHarmony API 12 · 数据仅存储在本机，不上传云端')
            .fontSize(11)
            .fontColor(Theme.TEXT_SUB)
          Text('减排因子参考生态环境部公开核算方法，仅作生活估算演示')
            .fontSize(11)
            .fontColor(Theme.TEXT_SUB)
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
