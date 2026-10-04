import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants, bumpTick } from '../common/Constants';
import { Theme } from '../common/Theme';
import { AppConfig } from '../common/AppConfig';
import { ExportService } from '../service/ExportService';
import { PrefsService, DEFAULT_HOME_LAYOUT } from '../common/PrefsService';
import { InclusiveService } from '../service/InclusiveService';
import pasteboard from '@ohos.pasteboard';
import picker from '@ohos.file.picker';

/**
 * 设置详情页：个性化（目标/卡片布局）、服务配置、本地数据管理、关于。
 * 支持路由参数 focus: 'goal' 直接定位到目标设置（目标区位于页面顶部）。
 */
@Entry
@Component
struct SettingsDetail {
  @State monthGoalInput: string = '30';
  @State homeLayout: string[] = [];
  @State hiddenCards: string[] = [];
  @State aiKey: string = '';
  @State aiUrl: string = '';
  @State aiModel: string = '';
  @State inclusiveUrl: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      this.aiKey = await AppConfig.getAiApiKey();
      this.aiUrl = await AppConfig.getAiBaseUrl();
      this.aiModel = await AppConfig.getAiModel();
      this.inclusiveUrl = await AppConfig.getInclusiveBaseUrl();
      this.monthGoalInput = '' + (await PrefsService.getMonthlyGoalKg());
      this.homeLayout = await PrefsService.getHomeLayout();
      const hidden: string[] = [];
      for (const k of DEFAULT_HOME_LAYOUT) {
        if (this.homeLayout.indexOf(k) < 0) {
          hidden.push(k);
        }
      }
      this.hiddenCards = hidden;
    } catch (e) {
      console.error('SettingsDetail refresh error: ' + JSON.stringify(e));
    }
  }

  private async saveGoal(): Promise<void> {
    const n = parseFloat(this.monthGoalInput);
    if (isNaN(n) || n <= 0 || n > 100000) {
      promptAction.showToast({ message: '请输入 0 ~ 100000 之间的目标值' });
      return;
    }
    await PrefsService.setMonthlyGoalKg(Math.round(n * 10) / 10);
    promptAction.showToast({ message: '本月目标已更新' });
    bumpTick();
  }

  private async persistLayout(): Promise<void> {
    await PrefsService.setHomeLayout(this.homeLayout);
    bumpTick();
  }

  private moveCard(index: number, dir: number): void {
    const target = index + dir;
    if (target < 0 || target >= this.homeLayout.length) {
      return;
    }
    const arr = this.homeLayout.slice();
    const tmp = arr[index];
    arr[index] = arr[target];
    arr[target] = tmp;
    this.homeLayout = arr;
    this.persistLayout();
  }

  private hideCard(key: string): void {
    const arr = this.homeLayout.slice();
    const i = arr.indexOf(key);
    if (i >= 0) {
      arr.splice(i, 1);
    }
    this.homeLayout = arr;
    this.hiddenCards = this.hiddenCards.concat([key]);
    this.persistLayout();
  }

  private showCard(key: string): void {
    const arr = this.hiddenCards.slice();
    const i = arr.indexOf(key);
    if (i >= 0) {
      arr.splice(i, 1);
    }
    this.hiddenCards = arr;
    this.homeLayout = this.homeLayout.concat([key]);
    this.persistLayout();
  }

  private async copyPath(path: string): Promise<void> {
    const clip = pasteboard.getSystemPasteboard();
    await clip.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, path));
  }

  private async doBackup(): Promise<void> {
    try {
      const path = await ExportService.backupJson();
      await this.copyPath(path);
      promptAction.showToast({ message: '备份完成，文件路径已复制到剪贴板', duration: 3000 });
    } catch (e) {
      promptAction.showToast({ message: '备份失败，请重试' });
    }
  }

  private async doExportCsv(): Promise<void> {
    try {
      const path = await ExportService.exportCsv();
      await this.copyPath(path);
      promptAction.showToast({ message: '报表已导出，文件路径已复制到剪贴板', duration: 3000 });
    } catch (e) {
      promptAction.showToast({ message: '导出失败，请重试' });
    }
  }

  private confirmImport(): void {
    AlertDialog.show({
      title: '导入备份',
      message: '导入将覆盖当前全部行为记录与积分流水（任务完成记录与徽章不受影响），确定继续？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '选择文件导入',
        fontColor: Theme.PRIMARY,
        action: () => {
          this.doImport();
        }
      }
    });
  }

  private async doImport(): Promise<void> {
    try {
      const doc = new picker.DocumentSelectOptions();
      doc.maxSelectNumber = 1;
      doc.fileSuffixFilters = ['.json'];
      const dvs = new picker.DocumentViewPicker();
      const uris = await dvs.select(doc);
      if (uris === undefined || uris.length === 0) {
        return;
      }
      const n = await ExportService.importJson(uris[0]);
      promptAction.showToast({ message: `已恢复 ${n} 条行为记录及对应积分流水`, duration: 3000 });
      this.refresh();
    } catch (e) {
      promptAction.showToast({ message: '导入失败：文件无效或格式不正确', duration: 3000 });
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

  private async testInclusive(): Promise<void> {
    await AppConfig.setInclusiveBaseUrl(this.inclusiveUrl.trim());
    const msg = await InclusiveService.fetchBenefits();
    promptAction.showToast({ message: msg, duration: 3000 });
  }

  @Builder
  cardTitle(icon: string, title: string) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(18)
        .fontColor(Theme.PRIMARY)
        .backgroundColor(Theme.PRIMARY_BG)
        .borderRadius(4)
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 12 }) {
          // 顶部导航
          Row() {
            Text('←')
              .fontSize(22)
              .onClick(() => {
                router.back();
              })
            Blank()
            Text('设置')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
            Blank()
            Text('')
              .width(22)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 14 })

          // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
          Column({ space: 12 }) {
            this.cardTitle('个', '本月减排目标（kg）')

            Row({ space: 10 }) {
              Column({ space: 2 }) {
                Text('显示在首页目标环上')
                  .fontSize(11)
                  .fontColor(Theme.TEXT_TERTIARY)
                Text('保存后首页目标环与节奏提示即时更新')
                  .fontSize(10)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              TextInput({ text: this.monthGoalInput })
                .type(InputType.NUMBER_DECIMAL)
                .width(90)
                .height(36)
                .fontSize(13)
                .onChange((v: string) => {
                  this.monthGoalInput = v;
                })

              Button('保存')
                .height(36)
                .fontSize(13)
                .backgroundColor(Theme.PRIMARY)
                .onClick(() => {
                  this.saveGoal();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)
          .border({ width: 1, color: Theme.DIVIDER })

          // 个性化 · 首页卡片布局
          Column({ space: 10 }) {
            this.cardTitle('排', '首页卡片布局')
            Text('调整首页卡片顺序与显隐，改动即时生效')
              .fontSize(11)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')

            ForEach(this.homeLayout, (key: string, idx: number) => {
              Row({ space: 8 }) {
                Text('' + (idx + 1))
                  .fontSize(11)
                  .fontColor(Theme.TEXT_TERTIARY)
                  .width(18)
                Text(PrefsService.homeCardTitle(key))
                  .fontSize(13)
                  .fontColor(Theme.TEXT)
                  .layoutWeight(1)
                Button('↑')
                  .height(28)
                  .fontSize(12)
                  .backgroundColor(Theme.BG)
                  .fontColor(Theme.TEXT_SECONDARY)
                  .onClick(() => {
                    this.moveCard(idx, -1);
                  })
                Button('↓')
                  .height(28)
                  .fontSize(12)
                  .backgroundColor(Theme.BG)
                  .fontColor(Theme.TEXT_SECONDARY)
                  .onClick(() => {
                    this.moveCard(idx, 1);
                  })
                Button('隐藏')
                  .height(28)
                  .fontSize(11)
                  .backgroundColor(Theme.BG)
                  .fontColor('#F53F3F')
                  .onClick(() => {
                    this.hideCard(key);
                  })
              }
              .width('100%')
            }, (key: string) => key + '_' + this.homeLayout.indexOf(key))

            if (this.hiddenCards.length > 0) {
              ForEach(this.hiddenCards, (key: string) => {
                Row({ space: 8 }) {
                  Text(PrefsService.homeCardTitle(key))
                    .fontSize(13)
                    .fontColor(Theme.TEXT_TERTIARY)
                    .layoutWeight(1)
                  Button('显示')
                    .height(28)
                    .fontSize(11)
                    .backgroundColor(Theme.PRIMARY_BG)
                    .fontColor(Theme.PRIMARY)
                    .onClick(() => {
                      this.showCard(key);
                    })
                }
                .width('100%')
              }, (key: string) => 'hidden_' + key)
            }
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)
          .border({ width: 1, color: Theme.DIVIDER })

          // 服务配置
          Column({ space: 10 }) {
            this.cardTitle('配', '服务配置（联网能力）')

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
            Text('模型名（OpenAI 兼容接口的 model 参数）')
              .fontSize(11)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')
            TextInput({ placeholder: 'deepseek-chat', text: this.aiModel })
              .height(40)
              .onChange((v: string) => {
                this.aiModel = v;
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
                  AppConfig.setAiModel(this.aiModel.trim() === '' ? 'deepseek-chat' : this.aiModel.trim());
                  promptAction.showToast({ message: 'AI 服务配置已保存' });
                })
            }
            .width('100%')

            Divider().color(Theme.DIVIDER)

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
              Text('测试连接')
                .fontSize(13)
                .fontColor(Theme.POINTS)
                .onClick(() => {
                  this.testInclusive();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)
          .border({ width: 1, color: Theme.DIVIDER })

          // 本地数据管理
          Column({ space: 2 }) {
            this.cardTitle('档', '本地数据管理')

            Divider().color(Theme.DIVIDER).margin({ top: 8 })
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text('一键备份（JSON）')
                  .fontSize(14)
                  .fontColor(Theme.TEXT)
                Text('导出到应用沙箱，路径自动复制')
                  .fontSize(11)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('›')
                .fontSize(16)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              this.doBackup();
            })

            Divider().color(Theme.DIVIDER)
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text('导入备份（JSON）')
                  .fontSize(14)
                  .fontColor(Theme.TEXT)
                Text('覆盖行为与积分流水')
                  .fontSize(11)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('›')
                .fontSize(16)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              this.confirmImport();
            })

            Divider().color(Theme.DIVIDER)
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text('统计报表（CSV）')
                  .fontSize(14)
                  .fontColor(Theme.TEXT)
                Text('月度减排汇总，路径自动复制')
                  .fontSize(11)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('›')
                .fontSize(16)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              this.doExportCsv();
            })

            Divider().color(Theme.DIVIDER)
            Row({ space: 12 }) {
              Column({ space: 2 }) {
                Text('清空所有数据')
                  .fontSize(14)
                  .fontColor(Theme.TEXT)
                Text('不可恢复')
                  .fontSize(11)
                  .fontColor('#F53F3F')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text('›')
                .fontSize(16)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .onClick(() => {
              this.confirmClear();
            })
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor(Theme.CARD)
          .border({ width: 1, color: Theme.DIVIDER })

          // 关于
          Column({ space: 6 }) {
            Text(`碳足迹 v${Constants.VERSION} · Apache-2.0 · 零三方依赖`)
              .fontSize(12)
              .fontColor(Theme.TEXT_TERTIARY)
            Text('HarmonyOS · 低碳数据仅存本机；仅 AI 识别时图片发送至你配置的接口')
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
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.BG)
  }
}
