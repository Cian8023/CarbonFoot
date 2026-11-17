/* Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0 */
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Theme } from '../common/Theme';
import { AppInit } from '../common/AppInit';
import { SyncService, FamilyMember } from '../service/SyncService';
import { DateUtil } from '../utils/DateUtil';

/** 相对时间：用于展示成员"最后同步" */
function agoText(ts: number): string {
  if (ts <= 0) {
    return '未同步';
  }
  const d = Date.now() - ts;
  if (d < 60000) {
    return '刚刚';
  }
  if (d < 3600000) {
    return Math.floor(d / 60000) + ' 分钟前';
  }
  if (d < 86400000) {
    return Math.floor(d / 3600000) + ' 小时前';
  }
  return Math.floor(d / 86400000) + ' 天前';
}

/**
 * 家庭碳账户（创新拓展 1）：应用层多端同步。
 * 两台设备连宿主机 sync/server.js，通过 HTTP 交换成员快照。
 */
@Entry
@Component
struct Family {
  @State groupCode: string = '';
  @State hasGroup: boolean = false;
  @State members: FamilyMember[] = [];
  @State totalG: number = 0;
  @State totalPoints: number = 0;
  @State weekG: number = 0;
  @State joinCode: string = '';
  @State joinName: string = '';
  @State syncing: boolean = false;
  @State online: boolean = false;
  @State lastSync: number = 0;
  @State nickname: string = '';
  @State nickInput: string = '';

  aboutToAppear(): void {
    // 进页面先拉一次，避免显示上一次的离线状态/过期成员
    this.refresh(true);
  }

  async refresh(pull: boolean = false): Promise<void> {
    try {
      await AppInit.ensure();
      const group = await SyncService.getGroup();
      this.hasGroup = group !== null;
      this.groupCode = group !== null ? group.code : '';
      this.nickname = await SyncService.getNickname();
      this.nickInput = this.nickname;
      if (pull && group !== null) {
        await SyncService.pullMembers();
      }
      this.online = SyncService.isOnline();
      this.lastSync = SyncService.lastSyncTime();
      const stats = await SyncService.mergedStats();
      this.members = stats.members;
      this.totalG = stats.totalG;
      this.totalPoints = stats.totalPoints;
      this.weekG = await SyncService.familyWeekG();
    } catch (e) {
      console.error('Family refresh error: ' + JSON.stringify(e));
    }
  }

  private async createGroup(): Promise<void> {
    try {
      this.groupCode = await SyncService.createGroup();
      this.hasGroup = true;
      promptAction.showToast({ message: `家庭组已创建，邀请码：${this.groupCode}`, duration: 3000 });
      await this.refresh();
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message, duration: 3500 });
    }
  }

  private async join(): Promise<void> {
    const code = this.joinCode.trim().toUpperCase();
    const name = this.joinName.trim();
    if (code === '') {
      promptAction.showToast({ message: '请输入家庭组邀请码' });
      return;
    }
    if (name === '') {
      promptAction.showToast({ message: '请输入本机昵称，方便家人识别' });
      return;
    }
    const r = await SyncService.joinGroup(code, name);
    if (r === 'offline') {
      promptAction.showToast({ message: '同步服务不可达，请先启动 node sync/server.js 8081', duration: 3500 });
      return;
    }
    if (r === 'notfound') {
      promptAction.showToast({ message: '邀请码不存在，请核对后重试' });
      return;
    }
    if (r !== 'ok') {
      promptAction.showToast({ message: '加入失败，请稍后重试' });
      return;
    }
    this.hasGroup = true;
    this.groupCode = code;
    this.joinCode = '';
    this.joinName = '';
    promptAction.showToast({ message: '已加入家庭组' });
    await this.refresh();
  }

  private async syncNow(): Promise<void> {
    if (this.syncing) {
      return;
    }
    this.syncing = true;
    try {
      const r = await SyncService.syncNow();
      promptAction.showToast({
        message: r === 'ok' ? '已同步最新数据' : '同步服务不可达，当前显示本地缓存'
      });
      await this.refresh();
    } catch (e) {
      promptAction.showToast({ message: '同步失败：' + (e as Error).message });
    } finally {
      this.syncing = false;
    }
  }

  private async leave(): Promise<void> {
    const r = await SyncService.leaveGroup();
    this.hasGroup = false;
    this.groupCode = '';
    await this.refresh();
    if (r === 'offline') {
      promptAction.showToast({
        message: '已退出本地家庭组；同步服务不可达，其他设备可能仍显示你的数据',
        duration: 3500
      });
    } else if (r === 'error') {
      promptAction.showToast({ message: '已退出本地家庭组；服务端移除失败，请稍后重试' });
    } else {
      promptAction.showToast({ message: '已退出家庭组' });
    }
  }

  private async saveNickname(): Promise<void> {
    const v = this.nickInput.trim();
    if (v === '') {
      promptAction.showToast({ message: '昵称不能为空' });
      return;
    }
    await SyncService.setNickname(v);
    await SyncService.reportSnapshot();
    await this.refresh();
    promptAction.showToast({ message: '昵称已更新' });
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
        Text('家庭碳账户 · 多端同步')
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
          if (!this.hasGroup) {
            // 建组
            Column({ space: 12 }) {
              Text('家')
                .fontSize(Theme.FS_HEAD)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.PRIMARY)
                .width(56)
                .height(56)
                .textAlign(TextAlign.Center)
                .backgroundColor(Theme.PRIMARY_BG)
                .borderRadius(28)
              Text('创建家庭碳账户')
                .fontSize(Theme.FS_TITLE)
                .fontWeight(FontWeight.Medium)
              Text('家人各记各的，减排自动合并统计。一台设备建组生成邀请码，其他设备输入邀请码加入。')
                .fontSize(Theme.FS_TERTIARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .textAlign(TextAlign.Center)
              Button('创建家庭组')
                .fontSize(Theme.FS_CONTENT)
                .backgroundColor(Theme.PRIMARY)
                .onClick(() => {
                  this.createGroup();
                })
            }
            .width('100%')
            .padding(24)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)

            // 加入
            Column({ space: 10 }) {
              Text('已有邀请码？加入家庭组')
                .fontSize(Theme.FS_TITLE)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              Text('在另一台设备上创建家庭组后，把那台设备的邀请码填到这里')
                .fontSize(Theme.FS_CAPTION)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
              TextInput({ placeholder: '邀请码，如 CF123456', text: this.joinCode })
                .height(42)
                .backgroundColor(Theme.BG_GRAY)
                .borderRadius(12)
                .onChange((v: string) => {
                  this.joinCode = v;
                })
              TextInput({ placeholder: '本机昵称，如 妈妈', text: this.joinName })
                .height(42)
                .backgroundColor(Theme.BG_GRAY)
                .borderRadius(12)
                .onChange((v: string) => {
                  this.joinName = v;
                })
              Button('加入家庭组')
                .width('100%')
                .height(42)
                .fontSize(Theme.FS_BODY)
                .backgroundColor(Theme.PRIMARY_HOVER)
                .onClick(() => {
                  this.join();
                })
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          } else {
            // 组信息 + 同步状态
            Column({ space: 10 }) {
              Row() {
                Text('家庭组邀请码')
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.TEXT_TERTIARY)
                Blank()
                Text(this.groupCode)
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.TEXT)
              }
              .width('100%')

              Row({ space: 8 }) {
                Text(this.online ? '● 已连接同步服务' : '● 离线（显示本地缓存）')
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(this.online ? Theme.PRIMARY : Theme.WARN)
                Text(this.lastSync > 0 ? agoText(this.lastSync) : '')
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.TEXT_TERTIARY)
                Blank()
                Text(this.syncing ? '同步中…' : '立即同步')
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.syncNow();
                  })
              }
              .width('100%')

              Divider().color(Theme.DIVIDER)

              Row() {
                Column({ space: 4 }) {
                  Text(DateUtil.gramsToKg(this.totalG))
                    .fontSize(Theme.FS_HERO)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.PRIMARY)
                  Text('家庭累计减排(kg)')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .layoutWeight(1)
                Divider().vertical(true).height(30).color(Theme.DIVIDER)
                Column({ space: 4 }) {
                  Text('' + this.totalPoints)
                    .fontSize(Theme.FS_HERO)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.TEXT)
                  Text('家庭合并积分')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .layoutWeight(1)
                Divider().vertical(true).height(30).color(Theme.DIVIDER)
                Column({ space: 4 }) {
                  Text(DateUtil.gramsToKg(this.weekG))
                    .fontSize(Theme.FS_HERO)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.TEXT)
                  Text('本周减排(kg)')
                    .fontSize(Theme.FS_SECONDARY)
                    .fontColor(Theme.TEXT_TERTIARY)
                }
                .layoutWeight(1)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)

            // 成员排行
            Column({ space: 10 }) {
              Row() {
                Text('家庭成员减排排行')
                  .fontSize(Theme.FS_TITLE)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text('退出家庭组')
                  .fontSize(Theme.FS_TERTIARY)
                  .fontColor(Theme.WARN)
                  .onClick(() => {
                    this.leave();
                  })
              }
              .width('100%')

              ForEach(this.members, (m: FamilyMember, idx: number) => {
                Row({ space: 10 }) {
                  Text(`${idx + 1}`)
                    .fontSize(Theme.FS_BODY)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(idx < 3 ? Theme.PRIMARY : Theme.TEXT_TERTIARY)
                    .width(30)
                    .textAlign(TextAlign.Center)
                  Column({ space: 3 }) {
                    Row({ space: 6 }) {
                      Text(m.name)
                        .fontSize(Theme.FS_CONTENT)
                        .fontWeight(FontWeight.Medium)
                      if (m.local) {
                        Text('本机')
                          .fontSize(Theme.FS_MICRO)
                          .fontColor(Theme.TEXT_TERTIARY)
                          .backgroundColor(Theme.BG_GRAY)
                          .borderRadius(6)
                          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      } else {
                        Text('已同步')
                          .fontSize(Theme.FS_MICRO)
                          .fontColor(Theme.PRIMARY)
                          .backgroundColor(Theme.PRIMARY_BG)
                          .borderRadius(6)
                          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      }
                    }
                    Text(m.local
                      ? `积分 ${m.balance}`
                      : `积分 ${m.balance} · ${agoText(m.updatedAt)}同步`)
                      .fontSize(Theme.FS_SECONDARY)
                      .fontColor(Theme.TEXT_TERTIARY)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(`${DateUtil.gramsToKg(m.totalG)} kg`)
                    .fontSize(Theme.FS_BODY)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.REDUCE)
                }
                .width('100%')
                .padding(12)
                .borderRadius(14)
                .backgroundColor(Theme.BG_GRAY)
              }, (m: FamilyMember) => m.deviceId)

              if (this.members.length <= 1) {
                Text('还没有其他成员。在另一台设备上输入邀请码「' + this.groupCode + '」加入后，这里会出现对方的数据。')
                  .fontSize(Theme.FS_CAPTION)
                  .fontColor(Theme.TEXT_TERTIARY)
                  .width('100%')
              }
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)

            // 本机昵称
            Column({ space: 8 }) {
              Text('本机昵称')
                .fontSize(Theme.FS_SECONDARY)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
              Row({ space: 10 }) {
                TextInput({ placeholder: '如 爸爸', text: this.nickInput })
                  .layoutWeight(1)
                  .height(38)
                  .backgroundColor(Theme.BG_GRAY)
                  .borderRadius(10)
                  .onChange((v: string) => {
                    this.nickInput = v;
                  })
                Text('保存')
                  .fontSize(Theme.FS_BODY)
                  .fontColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.saveNickname();
                  })
              }
              .width('100%')
              Text('每台设备上报自己的减排与积分，本机数据实时计算，其他设备的数据来自同步服务')
                .fontSize(Theme.FS_CAPTION)
                .fontColor(Theme.TEXT_TERTIARY)
                .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(Theme.R_LARGE)
            .backgroundColor(Theme.CARD)
            .borderWidth(1).borderColor(Theme.CARD_BORDER)
          }

          Text('说明：多端同步由本地 sync 服务（node sync/server.js 8081）中转，两台设备各自上报快照后合并展示。服务不可达时自动使用本地缓存，功能不中断。分布式软总线受模拟器 NAT 隔离与同账号互信限制，保留为真机扩展点。')
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
