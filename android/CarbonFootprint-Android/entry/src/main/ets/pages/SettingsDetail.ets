import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AppInit } from '../common/AppInit';
import { Constants, bumpTick } from '../common/Constants';
import { Theme } from '../common/Theme';
import { AppConfig } from '../common/AppConfig';
import { ExportService } from '../service/ExportService';
import { PrefsService, DEFAULT_HOME_LAYOUT } from '../common/PrefsService';
import { InclusiveService } from '../service/InclusiveService';
import { BehaviorService } from '../service/BehaviorService';
import { PlatformSourceService, PlatformRecord } from '../service/PlatformSourceService';
import { SRC_PLATFORM } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import picker from '@ohos.file.picker';

/**
 * 设置详情页：个性化（目标/卡片布局）、服务配置、本地数据管理、关于。
 * 支持路由参数 focus: 'goal' 直接定位到目标设置，focus: 'ai' 直接定位到服务配置。
 */
@Entry
@Component
struct SettingsDetail {
  @StorageProp('statusBarHeightPx') statusBarHeightPx: number = 0;
  @State monthGoalInput: string = '30';
  @State homeLayout: string[] = [];
  @State hiddenCards: string[] = [];
  @State aiKey: string = '';
  @State aiUrl: string = '';
  @State aiModel: string = '';
  @State inclusiveUrl: string = '';
  @State syncUrl: string = '';
  @State goalHighlight: boolean = false;
  @State aiHighlight: boolean = false;
  /** 服务配置卡片在滚动内容中的 Y 偏移，focus:'ai' 时用于滚动定位 */
  @State aiCardY: number = -1;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    // 首页「修改目标」直达：高亮目标设置区数秒作视觉定位
    const params = router.getParams() as Record<string, string> | null;
    if (params !== null && params !== undefined && params['focus'] === 'goal') {
      this.goalHighlight = true;
      setTimeout((): void => {
        this.goalHighlight = false;
      }, 2500);
    }
    // AI 识别页「设置」直达：滚到服务配置并高亮
    if (params !== null && params !== undefined && params['focus'] === 'ai') {
      this.aiHighlight = true;
      setTimeout((): void => {
        this.aiHighlight = false;
      }, 3200);
      setTimeout((): void => {
        if (this.aiCardY >= 0) {
          this.scroller.scrollTo({ xOffset: 0, yOffset: this.aiCardY - 12, animation: true });
        }
      }, 450);
    }
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      this.aiKey = await AppConfig.getAiApiKey();
      this.aiUrl = await AppConfig.getAiBaseUrl();
      this.aiModel = await AppConfig.getAiModel();
      this.inclusiveUrl = await AppConfig.getInclusiveBaseUrl();
      this.syncUrl = await AppConfig.getSyncBaseUrl();
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

  private async doBackup(): Promise<void> {
    try {
      const uri = await ExportService.backupJson();
      // 告诉用户文件叫什么、去哪里找，否则"保存成功"之后找不到文件
      const name = uri.substring(uri.lastIndexOf('/') + 1);
      promptAction.showToast({ message: `已保存 ${name}，可在「文件管理」中查看`, duration: 4000 });
    } catch (e) {
      const msg = (e as Error).message;
      promptAction.showToast({ message: msg === '未选择保存位置' ? '已取消保存' : '备份失败，请重试' });
    }
  }

  private async doExportCsv(): Promise<void> {
    try {
      const uri = await ExportService.exportCsv();
      const name = uri.substring(uri.lastIndexOf('/') + 1);
      promptAction.showToast({ message: `已保存 ${name}，可用 Excel/WPS 打开`, duration: 4000 });
    } catch (e) {
      const msg = (e as Error).message;
      promptAction.showToast({ message: msg === '未选择保存位置' ? '已取消保存' : '导出失败，请重试' });
    }
  }

  private confirmImport(): void {
    AlertDialog.show({
      title: '导入备份',
      message: '导入将覆盖当前全部行为记录、积分流水、任务完成与徽章解锁状态，确定继续？',
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
      promptAction.showToast({ message: `已恢复 ${n} 条行为记录、积分流水与任务/徽章状态`, duration: 3000 });
      this.refresh();
    } catch (e) {
      promptAction.showToast({ message: '导入失败：文件无效或格式不正确', duration: 3000 });
    }
  }

  private async doClear(): Promise<void> {
    try {
      await ExportService.clearAll();
      bumpTick();
      promptAction.showToast({ message: '数据已清空' });
      this.refresh();
    } catch (e) {
      promptAction.showToast({ message: '清空失败，请重试' });
    }
  }

  private confirmClear(): void {
    AlertDialog.show({
      title: '清空所有数据',
      message: '将删除全部行为记录、积分流水与任务完成记录，徽章、植树证书与权益记录将一并重置。此操作不可恢复，确定继续？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '清空',
        fontColor: Theme.WARN,
        action: () => {
          this.doClear();
        }
      }
    });
  }

  private async saveAiConfig(): Promise<void> {
    try {
      // 三项配置必须全部落盘后再提示成功，否则用户立刻退出页面可能丢配置
      await AppConfig.setAiApiKey(this.aiKey.trim());
      await AppConfig.setAiBaseUrl(this.aiUrl.trim());
      await AppConfig.setAiModel(this.aiModel.trim() === '' ? 'deepseek-flash' : this.aiModel.trim());
      promptAction.showToast({ message: 'AI 服务配置已保存' });
    } catch (e) {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  private async saveInclusiveUrl(): Promise<void> {
    try {
      await AppConfig.setInclusiveBaseUrl(this.inclusiveUrl.trim());
      promptAction.showToast({ message: '碳普惠平台地址已保存' });
    } catch (e) {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  private async testInclusive(): Promise<void> {
    await AppConfig.setInclusiveBaseUrl(this.inclusiveUrl.trim());
    const msg = await InclusiveService.fetchBenefits();
    const active = InclusiveService.getActiveBaseUrl();
    promptAction.showToast({
      message: active !== '' ? `${msg}（${active}）` : msg,
      duration: 3000
    });
  }

  private async saveSyncUrl(): Promise<void> {
    try {
      await AppConfig.setSyncBaseUrl(this.syncUrl.trim());
      promptAction.showToast({ message: '同步服务地址已保存' });
    } catch (e) {
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  /** 从平台（模拟）拉取行为记录，确认后逐条入库 */
  private async importFromPlatform(): Promise<void> {
    const r = await PlatformSourceService.fetch();
    if (!r.ok) {
      promptAction.showToast({ message: r.reason, duration: 3500 });
      return;
    }
    let km = 0;
    for (const rec of r.records) {
      if (rec.unit === 'km') {
        km += rec.value;
      }
    }
    const extra = km > 0 ? `，合计 ${km.toFixed(1)} km` : '';
    AlertDialog.show({
      title: '导入平台数据（模拟）',
      message: `从 ${r.baseUrl} 读到 ${r.records.length} 条记录${extra}。\n` +
        '数据来源为本地 mock 服务，导入后计入减排与积分。确认导入？',
      primaryButton: {
        value: '取消',
        action: () => {
        }
      },
      secondaryButton: {
        value: '导入',
        fontColor: Theme.PRIMARY,
        action: () => {
          this.doImportPlatform(r.records);
        }
      }
    });
  }

  private async doImportPlatform(records: PlatformRecord[]): Promise<void> {
    let n = 0;
    let skipped = 0;
    try {
      // 平台记录带固定时间戳，用「类型|子类|时间」判重，重复点导入不会翻倍
      const existing = await BehaviorRepo.all();
      const seen = new Set<string>();
      for (const r of existing) {
        seen.add(r.type + '|' + r.subType + '|' + r.createdAt);
      }
      for (const rec of records) {
        const key = rec.type + '|' + rec.subType + '|' + rec.at;
        if (seen.has(key)) {
          skipped++;
          continue;
        }
        await BehaviorService.submit(rec.type, rec.subType, rec.value, rec.unit,
          rec.factor, rec.at, `平台同步（${rec.label}）`, SRC_PLATFORM);
        seen.add(key);
        n++;
      }
      bumpTick();
      promptAction.showToast({
        message: skipped > 0
          ? `导入 ${n} 条，跳过 ${skipped} 条重复`
          : `已导入 ${n} 条平台记录`
      });
    } catch (e) {
      promptAction.showToast({ message: `导入中断：成功 ${n} 条，${(e as Error).message}` });
    }
  }

  @Builder
  cardTitle(icon: string, title: string) {
    Row({ space: 12 }) {
      Text(icon)
        .fontSize(Theme.FS_HEAD)
        .fontColor(Theme.PRIMARY)
        .backgroundColor(Theme.PRIMARY_BG)
        .borderRadius(4)
        .padding({ left: 6, right: 6, top: 3, bottom: 3 })
      Text(title)
        .fontSize(Theme.FS_CONTENT)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
  }

  build() {
    Stack() {
      Column() {
        // 顶部导航：固定在顶部，不随内容滚动
        Row() {
          Text('←')
            .fontSize(Theme.FS_HERO)
            .onClick(() => {
              router.back();
            })
          Blank()
          Text('设置')
            .fontSize(Theme.FS_HEAD)
            .fontWeight(FontWeight.Bold)
          Blank()
          Text('')
            .width(22)
        }
        .width('100%')
        .padding({ left: 14, right: 14, top: px2vp(this.statusBarHeightPx) + 14, bottom: 8 })

        Scroll(this.scroller) {
          Column({ space: 12 }) {

            // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
            Column({ space: 12 }) {
              this.cardTitle('个', '本月减排目标（kg）')

              Row({ space: 10 }) {
                Column({ space: 2 }) {
                  Text('显示在首页目标环上')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                  Text('保存后首页目标环与节奏提示即时更新')
                    .fontSize(Theme.FS_CAPTION)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                TextInput({ text: this.monthGoalInput })
                  .type(InputType.NUMBER_DECIMAL)
                  .width(90)
                  .height(36)
                  .fontSize(Theme.FS_BODY)
                  .backgroundColor(Theme.BG_GRAY)
                  .borderRadius(10)
                  .onChange((v: string) => {
                    this.monthGoalInput = v;
                  })

                Button('保存')
                  .height(36)
                  .fontSize(Theme.FS_BODY)
                  .backgroundColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.saveGoal();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
            .border({
              width: this.goalHighlight ? 2 : 0,
              color: Theme.PRIMARY
            })

            // 个性化 · 首页卡片布局
            Column({ space: 10 }) {
              this.cardTitle('排', '首页卡片布局')
              Text('调整首页卡片顺序与显隐，改动即时生效')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')

              ForEach(this.homeLayout, (key: string, idx: number) => {
                Row({ space: 8 }) {
                  Text('' + (idx + 1))
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                    .width(18)
                  Text(PrefsService.homeCardTitle(key))
                    .fontSize(Theme.FS_BODY)
                    .fontColor(Theme.TEXT)
                    .layoutWeight(1)
                  Button('↑')
                    .height(28)
                    .fontSize(Theme.FS_TERTIARY)
                    .backgroundColor(Theme.BG)
                    .fontColor(Theme.TEXT_SECONDARY)
                    .onClick(() => {
                      this.moveCard(idx, -1);
                    })
                  Button('↓')
                    .height(28)
                    .fontSize(Theme.FS_TERTIARY)
                    .backgroundColor(Theme.BG)
                    .fontColor(Theme.TEXT_SECONDARY)
                    .onClick(() => {
                      this.moveCard(idx, 1);
                    })
                  Button('隐藏')
                    .height(28)
                    .fontSize(Theme.FS_SECONDARY)
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
                      .fontSize(Theme.FS_BODY)
                      .fontColor(Theme.TEXT_TERTIARY)
                      .layoutWeight(1)
                    Button('显示')
                      .height(28)
                      .fontSize(Theme.FS_SECONDARY)
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
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)

            // 服务配置
            Column({ space: 10 }) {
              this.cardTitle('配', '服务配置（联网能力）')

              Text('AI 视觉接口 API Key（留空 = 不启用 AI 识别）')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
              TextInput({ placeholder: 'sk-...', text: this.aiKey })
                .height(40)
                // InputType.NEW_PASSWORD 在 ArkUI-X 上不支持，用 Password 等价替代
                .type(InputType.Password)
                .backgroundColor(Theme.BG_GRAY)
                .borderRadius(12)
                .onChange((v: string) => {
                  this.aiKey = v;
                })
              Text('Key 存于系统安全存储（Asset Store），不可用时退回本机偏好；演示请勿使用生产密钥')
                .fontSize(Theme.FS_CAPTION)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
              Text('模型名（必须是支持图片输入的视觉模型：deepseek-flash、glm-4v-flash、qwen-vl-max 等）')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
              TextInput({ placeholder: 'deepseek-flash', text: this.aiModel })
                .height(40)
                .backgroundColor(Theme.BG_GRAY)
                .borderRadius(12)
                .onChange((v: string) => {
                  this.aiModel = v;
                })
              Row({ space: 10 }) {
                TextInput({ placeholder: '视觉接口地址', text: this.aiUrl })
                  .layoutWeight(1)
                  .height(40)
                  .backgroundColor(Theme.BG_GRAY)
                  .borderRadius(12)
                  .onChange((v: string) => {
                    this.aiUrl = v;
                  })
                Text('保存')
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.saveAiConfig();
                  })
                // 旧的配置一旦存过就一直生效，改默认值不覆盖它；这里给个一键复位
                Text('恢复默认')
                  .fontSize(Theme.FS_TERTIARY)
                  .fontColor(Theme.TEXT_TERTIARY)
                  .onClick(() => {
                    this.aiUrl = 'https://api.deepseek.com/v1/chat/completions';
                    this.aiModel = 'deepseek-flash';
                    this.saveAiConfig();
                    promptAction.showToast({ message: '已恢复 deepseek-flash 默认配置', duration: 2500 });
                  })
              }
              .width('100%')

              Divider().color(Theme.DIVIDER)

              Text('碳普惠平台地址（留空或不可达 = 自动尝试 10.0.2.2 / 127.0.0.1）')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
              Row({ space: 10 }) {
                TextInput({ placeholder: '模拟器填 http://10.0.2.2:8080', text: this.inclusiveUrl })
                  .layoutWeight(1)
                  .height(40)
                  .backgroundColor(Theme.BG_GRAY)
                  .borderRadius(12)
                  .onChange((v: string) => {
                    this.inclusiveUrl = v;
                  })
                Text('保存')
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.saveInclusiveUrl();
                  })
              Text('测试连接')
                .fontSize(Theme.FS_BODY)
                .fontColor(Theme.POINTS)
                .onClick(() => {
                  this.testInclusive();
                })
            }
            .width('100%')

            Divider().color(Theme.DIVIDER)

            Row({ space: 10 }) {
              Column({ space: 2 }) {
                Text('从平台导入行为记录')
                  .fontSize(Theme.FS_BODY)
                Text('读取 mock 服务的行程数据，确认后计入减排（模拟）')
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.TEXT_TERTIARY)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text('导入')
                .fontSize(Theme.FS_BODY)
                .fontColor(Theme.POINTS)
                .onClick(() => {
                  this.importFromPlatform();
                })
            }
            .width('100%')

            Divider().color(Theme.DIVIDER)

            Text('家庭同步服务地址（留空 = 自动尝试 10.0.2.2 / 127.0.0.1 的 8081 端口）')
              .fontSize(Theme.FS_SECONDARY)
              .fontColor(Theme.TEXT_TERTIARY)
              .width('100%')
            Row({ space: 10 }) {
              TextInput({ placeholder: '模拟器留空即可', text: this.syncUrl })
                .layoutWeight(1)
                .height(40)
                .backgroundColor(Theme.BG_GRAY)
                .borderRadius(12)
                .onChange((v: string) => {
                  this.syncUrl = v;
                })
              Text('保存')
                .fontSize(Theme.FS_BODY)
                .fontColor(Theme.PRIMARY)
                .onClick(() => {
                  this.saveSyncUrl();
                })
            }
            .width('100%')
          }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(this.aiHighlight ? 2 : 1)
            .borderColor(this.aiHighlight ? Theme.PRIMARY : Theme.CARD_BORDER)
            .onAreaChange((_old: Area, now: Area) => {
              const y = now.position.y;
              if (typeof y === 'number') {
                this.aiCardY = y;
              }
            })

            // 本地数据管理
            Column({ space: 2 }) {
              this.cardTitle('档', '本地数据管理')

              Divider().color(Theme.DIVIDER).margin({ top: 8 })
              Row({ space: 12 }) {
                Column({ space: 2 }) {
                  Text('一键备份（JSON）')
                    .fontSize(Theme.FS_CONTENT)
                    .fontColor(Theme.TEXT)
                  Text('选择保存位置，可存到文件管理')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text('›')
                  .fontSize(Theme.FS_TITLE)
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
                    .fontSize(Theme.FS_CONTENT)
                    .fontColor(Theme.TEXT)
                  Text('覆盖行为与积分流水')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text('›')
                  .fontSize(Theme.FS_TITLE)
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
                    .fontSize(Theme.FS_CONTENT)
                    .fontColor(Theme.TEXT)
                  Text('月度减排汇总，保存为 CSV')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text('›')
                  .fontSize(Theme.FS_TITLE)
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
                    .fontSize(Theme.FS_CONTENT)
                    .fontColor(Theme.TEXT)
                  Text('不可恢复')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor('#F53F3F')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Text('›')
                  .fontSize(Theme.FS_TITLE)
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
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)

            // 关于
            Column({ space: 6 }) {
              Text(`碳足迹 v${Constants.VERSION} · Apache-2.0 · 零三方依赖`)
                .fontSize(Theme.FS_TERTIARY)
                .fontColor(Theme.TEXT_TERTIARY)
              Text('HarmonyOS · 低碳数据仅存本机；仅 AI 识别时图片发送至你配置的接口')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
              Text('减排因子为公开核算资料整理的常用取值（2024），仅作生活估算，不用于碳交易、碳核查或认证')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
            }
            .width('100%')
            .padding(10)
          }
          .width('100%')
          .padding({ left: 14, right: 14, bottom: 14 })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.BG)
  }
}
