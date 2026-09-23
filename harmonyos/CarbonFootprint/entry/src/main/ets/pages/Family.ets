import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { Theme } from '../common/Theme';
import { AppInit } from '../common/AppInit';
import { SyncService, FamilyMember } from '../service/SyncService';
import { DateUtil } from '../utils/DateUtil';

/**
 * 家庭碳积分合并统计（创新拓展 1）：超级终端多设备数据同步。
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
  @State newMemberName: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  async refresh(): Promise<void> {
    try {
      await AppInit.ensure();
      const group = await SyncService.getGroup();
      if (group !== null) {
        this.hasGroup = true;
        this.groupCode = group.code;
      }
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
    this.groupCode = await SyncService.createGroup();
    this.hasGroup = true;
    promptAction.showToast({ message: `家庭组已创建，邀请码：${this.groupCode}` });
  }

  private async joinMember(): Promise<void> {
    const name = this.newMemberName.trim();
    if (name === '') {
      promptAction.showToast({ message: '请输入家庭成员昵称' });
      return;
    }
    // 模拟器无分布式能力：走演示模式（真机同账号场景由分布式数据对象同步）
    await SyncService.addDemoMember(name);
    this.newMemberName = '';
    promptAction.showToast({ message: `成员「${name}」的数据已同步合并` });
    await this.refresh();
  }

  private async leave(): Promise<void> {
    await SyncService.leaveGroup();
    this.hasGroup = false;
    this.groupCode = '';
    await this.refresh();
    promptAction.showToast({ message: '已退出家庭组' });
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
        Text('家庭碳账户 · 多端同步')
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
          if (!this.hasGroup) {
            // 未建组
            Column({ space: 12 }) {
              Text('家')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.PRIMARY)
                .width(56)
                .height(56)
                .textAlign(TextAlign.Center)
                .backgroundColor(Theme.PRIMARY_BG)
                .borderRadius(28)
              Text('创建家庭碳账户')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
              Text('家人各记各的，减排自动合并统计。一台设备创建家庭组，其他设备凭邀请码加入（同一华为账号超级终端场景自动同步）。')
                .fontSize(12)
                .fontColor(Theme.TEXT_SUB)
                .textAlign(TextAlign.Center)
              Button('创建家庭组')
                .fontSize(14)
                .backgroundColor(Theme.PRIMARY)
                .onClick(() => {
                  this.createGroup();
                })
            }
            .width('100%')
            .padding(24)
            .borderRadius(16)
            .backgroundColor(Theme.CARD)
          } else {
            // 组信息 + 合并总览
            Column({ space: 10 }) {
              Row() {
                Text('家庭组邀请码')
                  .fontSize(13)
                  .fontColor(Theme.TEXT_SUB)
                Blank()
                Text(this.groupCode)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.TEXT)
              }
              .width('100%')

              Row() {
                Column({ space: 4 }) {
                  Text(DateUtil.gramsToKg(this.totalG))
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.PRIMARY)
                  Text('家庭累计减排(kg)')
                    .fontSize(11)
                    .fontColor(Theme.TEXT_SUB)
                }
                .layoutWeight(1)
                Divider().vertical(true).height(30).color(Theme.DIVIDER)
                Column({ space: 4 }) {
                  Text('' + this.totalPoints)
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.TEXT)
                  Text('家庭合并积分')
                    .fontSize(11)
                    .fontColor(Theme.TEXT_SUB)
                }
                .layoutWeight(1)
                Divider().vertical(true).height(30).color(Theme.DIVIDER)
                Column({ space: 4 }) {
                  Text(DateUtil.gramsToKg(this.weekG))
                    .fontSize(22)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(Theme.TEXT)
                  Text('本周减排(kg)')
                    .fontSize(11)
                    .fontColor(Theme.TEXT_SUB)
                }
                .layoutWeight(1)
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(Theme.R_CARD)
            .backgroundColor(Theme.CARD)
            .border({ width: 1, color: Theme.DIVIDER })

            // 成员排行
            Column({ space: 10 }) {
              Row() {
                Text('家庭成员减排排行')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                Blank()
                Text('退出家庭组')
                  .fontSize(12)
                  .fontColor(Theme.WARN)
                  .onClick(() => {
                    this.leave();
                  })
              }
              .width('100%')

              ForEach(this.members, (m: FamilyMember, idx: number) => {
                Row({ space: 10 }) {
                  Text(`${idx + 1}`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(idx < 3 ? Theme.PRIMARY : Theme.TEXT_SUB)
                    .width(30)
                    .textAlign(TextAlign.Center)
                  Column({ space: 3 }) {
                    Row({ space: 6 }) {
                      Text(m.name)
                        .fontSize(14)
                        .fontWeight(FontWeight.Medium)
                      if (!m.local) {
                        Text('已同步')
                          .fontSize(9)
                          .fontColor(Theme.PRIMARY)
                          .backgroundColor(Theme.PRIMARY_BG)
                          .borderRadius(6)
                          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                      }
                    }
                    Text(`积分 ${m.balance}`)
                      .fontSize(11)
                      .fontColor(Theme.TEXT_SUB)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  Text(`${DateUtil.gramsToKg(m.totalG)} kg`)
                    .fontSize(13)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.REDUCE)
                }
                .width('100%')
                .padding(12)
                .borderRadius(12)
                .backgroundColor(Theme.BG)
              }, (m: FamilyMember) => m.deviceId)
            }
            .width('100%')
            .padding(14)
            .borderRadius(16)
            .backgroundColor(Theme.CARD)

            // 加入成员（演示模式）
            Column({ space: 10 }) {
              Text('添加成员（演示：模拟其他设备数据同步到达）')
                .fontSize(12)
                .fontColor(Theme.TEXT_SUB)
                .width('100%')
              Row({ space: 10 }) {
                TextInput({ placeholder: '输入成员昵称', text: this.newMemberName })
                  .layoutWeight(1)
                  .height(42)
                  .onChange((v: string) => {
                    this.newMemberName = v;
                  })
                Button('同步并入')
                  .height(42)
                  .fontSize(13)
                  .backgroundColor(Theme.PRIMARY)
                  .onClick(() => {
                    this.joinMember();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(14)
            .borderRadius(16)
            .backgroundColor(Theme.CARD)
          }

          Text('说明：模拟器不支持分布式组网，页面以演示模式呈现合并统计链路；真机 + 同一华为账号场景可无缝切换为 distributedDataObject 真实同步。')
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
