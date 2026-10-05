if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Family_Params {
    groupCode?: string;
    hasGroup?: boolean;
    members?: FamilyMember[];
    totalG?: number;
    totalPoints?: number;
    weekG?: number;
    newMemberName?: string;
    newInviteCode?: string;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { SyncService } from "@normalized:N&&&entry/src/main/ets/service/SyncService&";
import type { FamilyMember } from "@normalized:N&&&entry/src/main/ets/service/SyncService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
class Family extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__groupCode = new ObservedPropertySimplePU('', this, "groupCode");
        this.__hasGroup = new ObservedPropertySimplePU(false, this, "hasGroup");
        this.__members = new ObservedPropertyObjectPU([], this, "members");
        this.__totalG = new ObservedPropertySimplePU(0, this, "totalG");
        this.__totalPoints = new ObservedPropertySimplePU(0, this, "totalPoints");
        this.__weekG = new ObservedPropertySimplePU(0, this, "weekG");
        this.__newMemberName = new ObservedPropertySimplePU('', this, "newMemberName");
        this.__newInviteCode = new ObservedPropertySimplePU('', this, "newInviteCode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Family_Params) {
        if (params.groupCode !== undefined) {
            this.groupCode = params.groupCode;
        }
        if (params.hasGroup !== undefined) {
            this.hasGroup = params.hasGroup;
        }
        if (params.members !== undefined) {
            this.members = params.members;
        }
        if (params.totalG !== undefined) {
            this.totalG = params.totalG;
        }
        if (params.totalPoints !== undefined) {
            this.totalPoints = params.totalPoints;
        }
        if (params.weekG !== undefined) {
            this.weekG = params.weekG;
        }
        if (params.newMemberName !== undefined) {
            this.newMemberName = params.newMemberName;
        }
        if (params.newInviteCode !== undefined) {
            this.newInviteCode = params.newInviteCode;
        }
    }
    updateStateVars(params: Family_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__groupCode.purgeDependencyOnElmtId(rmElmtId);
        this.__hasGroup.purgeDependencyOnElmtId(rmElmtId);
        this.__members.purgeDependencyOnElmtId(rmElmtId);
        this.__totalG.purgeDependencyOnElmtId(rmElmtId);
        this.__totalPoints.purgeDependencyOnElmtId(rmElmtId);
        this.__weekG.purgeDependencyOnElmtId(rmElmtId);
        this.__newMemberName.purgeDependencyOnElmtId(rmElmtId);
        this.__newInviteCode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__groupCode.aboutToBeDeleted();
        this.__hasGroup.aboutToBeDeleted();
        this.__members.aboutToBeDeleted();
        this.__totalG.aboutToBeDeleted();
        this.__totalPoints.aboutToBeDeleted();
        this.__weekG.aboutToBeDeleted();
        this.__newMemberName.aboutToBeDeleted();
        this.__newInviteCode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __groupCode: ObservedPropertySimplePU<string>;
    get groupCode() {
        return this.__groupCode.get();
    }
    set groupCode(newValue: string) {
        this.__groupCode.set(newValue);
    }
    private __hasGroup: ObservedPropertySimplePU<boolean>;
    get hasGroup() {
        return this.__hasGroup.get();
    }
    set hasGroup(newValue: boolean) {
        this.__hasGroup.set(newValue);
    }
    private __members: ObservedPropertyObjectPU<FamilyMember[]>;
    get members() {
        return this.__members.get();
    }
    set members(newValue: FamilyMember[]) {
        this.__members.set(newValue);
    }
    private __totalG: ObservedPropertySimplePU<number>;
    get totalG() {
        return this.__totalG.get();
    }
    set totalG(newValue: number) {
        this.__totalG.set(newValue);
    }
    private __totalPoints: ObservedPropertySimplePU<number>;
    get totalPoints() {
        return this.__totalPoints.get();
    }
    set totalPoints(newValue: number) {
        this.__totalPoints.set(newValue);
    }
    private __weekG: ObservedPropertySimplePU<number>;
    get weekG() {
        return this.__weekG.get();
    }
    set weekG(newValue: number) {
        this.__weekG.set(newValue);
    }
    private __newMemberName: ObservedPropertySimplePU<string>;
    get newMemberName() {
        return this.__newMemberName.get();
    }
    set newMemberName(newValue: string) {
        this.__newMemberName.set(newValue);
    }
    private __newInviteCode: ObservedPropertySimplePU<string>;
    get newInviteCode() {
        return this.__newInviteCode.get();
    }
    set newInviteCode(newValue: string) {
        this.__newInviteCode.set(newValue);
    }
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
        }
        catch (e) {
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
        if (this.newInviteCode.trim() !== this.groupCode) {
            promptAction.showToast({ message: '邀请码不匹配，无法并入该家庭组' });
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
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Family.ets(77:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(Theme.BG);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Family.ets(78:7)", "entry");
            Row.width('100%');
            Row.padding({ left: 14, right: 14, top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.debugLine("entry/src/main/ets/pages/Family.ets(79:9)", "entry");
            Text.fontSize(22);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Family.ets(84:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('家庭碳账户 · 多端同步');
            Text.debugLine("entry/src/main/ets/pages/Family.ets(85:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Family.ets(88:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('');
            Text.debugLine("entry/src/main/ets/pages/Family.ets(89:9)", "entry");
            Text.width(22);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/Family.ets(95:7)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.layoutWeight(1);
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Family.ets(96:9)", "entry");
            Column.width('100%');
            Column.padding(14);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (!this.hasGroup) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 未建组
                        Column.create({ space: 12 });
                        Column.debugLine("entry/src/main/ets/pages/Family.ets(99:13)", "entry");
                        // 未建组
                        Column.width('100%');
                        // 未建组
                        Column.padding(24);
                        // 未建组
                        Column.borderRadius(16);
                        // 未建组
                        Column.backgroundColor(Theme.CARD);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('家');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(100:15)", "entry");
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Medium);
                        Text.fontColor(Theme.PRIMARY);
                        Text.width(56);
                        Text.height(56);
                        Text.textAlign(TextAlign.Center);
                        Text.backgroundColor(Theme.PRIMARY_BG);
                        Text.borderRadius(28);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('创建家庭碳账户');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(109:15)", "entry");
                        Text.fontSize(16);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('家人各记各的，减排自动合并统计。一台设备创建家庭组，其他设备输入昵称并入成员（当前为演示模式）。');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(112:15)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                        Text.textAlign(TextAlign.Center);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('创建家庭组');
                        Button.debugLine("entry/src/main/ets/pages/Family.ets(116:15)", "entry");
                        Button.fontSize(14);
                        Button.backgroundColor(Theme.PRIMARY);
                        Button.onClick(() => {
                            this.createGroup();
                        });
                    }, Button);
                    Button.pop();
                    // 未建组
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 组信息 + 合并总览
                        Column.create({ space: 10 });
                        Column.debugLine("entry/src/main/ets/pages/Family.ets(129:13)", "entry");
                        // 组信息 + 合并总览
                        Column.width('100%');
                        // 组信息 + 合并总览
                        Column.padding(16);
                        // 组信息 + 合并总览
                        Column.borderRadius(Theme.R_MEDIUM);
                        // 组信息 + 合并总览
                        Column.backgroundColor(Theme.CARD);
                        // 组信息 + 合并总览
                        Column.border({ width: 1, color: Theme.DIVIDER });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/Family.ets(130:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('家庭组邀请码');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(131:17)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Family.ets(134:17)", "entry");
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.groupCode);
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(135:17)", "entry");
                        Text.fontSize(16);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.TEXT);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/Family.ets(142:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 4 });
                        Column.debugLine("entry/src/main/ets/pages/Family.ets(143:17)", "entry");
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(DateUtil.gramsToKg(this.totalG));
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(144:19)", "entry");
                        Text.fontSize(22);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.PRIMARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('家庭累计减排(kg)');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(148:19)", "entry");
                        Text.fontSize(11);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Divider.create();
                        Divider.debugLine("entry/src/main/ets/pages/Family.ets(153:17)", "entry");
                        Divider.vertical(true);
                        Divider.height(30);
                        Divider.color(Theme.DIVIDER);
                    }, Divider);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 4 });
                        Column.debugLine("entry/src/main/ets/pages/Family.ets(154:17)", "entry");
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('' + this.totalPoints);
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(155:19)", "entry");
                        Text.fontSize(22);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.TEXT);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('家庭合并积分');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(159:19)", "entry");
                        Text.fontSize(11);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Divider.create();
                        Divider.debugLine("entry/src/main/ets/pages/Family.ets(164:17)", "entry");
                        Divider.vertical(true);
                        Divider.height(30);
                        Divider.color(Theme.DIVIDER);
                    }, Divider);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 4 });
                        Column.debugLine("entry/src/main/ets/pages/Family.ets(165:17)", "entry");
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(DateUtil.gramsToKg(this.weekG));
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(166:19)", "entry");
                        Text.fontSize(22);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.TEXT);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('本周减排(kg)');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(170:19)", "entry");
                        Text.fontSize(11);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                    // 组信息 + 合并总览
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 成员排行
                        Column.create({ space: 10 });
                        Column.debugLine("entry/src/main/ets/pages/Family.ets(185:13)", "entry");
                        // 成员排行
                        Column.width('100%');
                        // 成员排行
                        Column.padding(14);
                        // 成员排行
                        Column.borderRadius(16);
                        // 成员排行
                        Column.backgroundColor(Theme.CARD);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/Family.ets(186:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('家庭成员减排排行');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(187:17)", "entry");
                        Text.fontSize(15);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Family.ets(190:17)", "entry");
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('退出家庭组');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(191:17)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.WARN);
                        Text.onClick(() => {
                            this.leave();
                        });
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = (_item, idx: number) => {
                            const m = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create({ space: 10 });
                                Row.debugLine("entry/src/main/ets/pages/Family.ets(201:17)", "entry");
                                Row.width('100%');
                                Row.padding(12);
                                Row.borderRadius(12);
                                Row.backgroundColor(Theme.BG);
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`${idx + 1}`);
                                Text.debugLine("entry/src/main/ets/pages/Family.ets(202:19)", "entry");
                                Text.fontSize(13);
                                Text.fontWeight(FontWeight.Medium);
                                Text.fontColor(idx < 3 ? Theme.PRIMARY : Theme.TEXT_TERTIARY);
                                Text.width(30);
                                Text.textAlign(TextAlign.Center);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Column.create({ space: 3 });
                                Column.debugLine("entry/src/main/ets/pages/Family.ets(208:19)", "entry");
                                Column.alignItems(HorizontalAlign.Start);
                                Column.layoutWeight(1);
                            }, Column);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create({ space: 6 });
                                Row.debugLine("entry/src/main/ets/pages/Family.ets(209:21)", "entry");
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(m.name);
                                Text.debugLine("entry/src/main/ets/pages/Family.ets(210:23)", "entry");
                                Text.fontSize(14);
                                Text.fontWeight(FontWeight.Medium);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                If.create();
                                if (!m.local) {
                                    this.ifElseBranchUpdateFunction(0, () => {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create('已同步');
                                            Text.debugLine("entry/src/main/ets/pages/Family.ets(214:25)", "entry");
                                            Text.fontSize(9);
                                            Text.fontColor(Theme.PRIMARY);
                                            Text.backgroundColor(Theme.PRIMARY_BG);
                                            Text.borderRadius(6);
                                            Text.padding({ left: 5, right: 5, top: 1, bottom: 1 });
                                        }, Text);
                                        Text.pop();
                                    });
                                }
                                else {
                                    this.ifElseBranchUpdateFunction(1, () => {
                                    });
                                }
                            }, If);
                            If.pop();
                            Row.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`积分 ${m.balance}`);
                                Text.debugLine("entry/src/main/ets/pages/Family.ets(222:21)", "entry");
                                Text.fontSize(11);
                                Text.fontColor(Theme.TEXT_TERTIARY);
                            }, Text);
                            Text.pop();
                            Column.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`${DateUtil.gramsToKg(m.totalG)} kg`);
                                Text.debugLine("entry/src/main/ets/pages/Family.ets(228:19)", "entry");
                                Text.fontSize(13);
                                Text.fontWeight(FontWeight.Medium);
                                Text.fontColor(Theme.REDUCE);
                            }, Text);
                            Text.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.members, forEachItemGenFunction, (m: FamilyMember) => m.deviceId, true, false);
                    }, ForEach);
                    ForEach.pop();
                    // 成员排行
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 加入成员（演示模式）
                        Column.create({ space: 10 });
                        Column.debugLine("entry/src/main/ets/pages/Family.ets(245:13)", "entry");
                        // 加入成员（演示模式）
                        Column.width('100%');
                        // 加入成员（演示模式）
                        Column.padding(14);
                        // 加入成员（演示模式）
                        Column.borderRadius(16);
                        // 加入成员（演示模式）
                        Column.backgroundColor(Theme.CARD);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('添加成员（演示：模拟其他设备数据同步到达）');
                        Text.debugLine("entry/src/main/ets/pages/Family.ets(246:15)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '输入家庭组邀请码', text: this.newInviteCode });
                        TextInput.debugLine("entry/src/main/ets/pages/Family.ets(250:15)", "entry");
                        TextInput.height(42);
                        TextInput.onChange((v: string) => {
                            this.newInviteCode = v;
                        });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 10 });
                        Row.debugLine("entry/src/main/ets/pages/Family.ets(255:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '输入成员昵称', text: this.newMemberName });
                        TextInput.debugLine("entry/src/main/ets/pages/Family.ets(256:17)", "entry");
                        TextInput.layoutWeight(1);
                        TextInput.height(42);
                        TextInput.onChange((v: string) => {
                            this.newMemberName = v;
                        });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('同步并入');
                        Button.debugLine("entry/src/main/ets/pages/Family.ets(262:17)", "entry");
                        Button.height(42);
                        Button.fontSize(13);
                        Button.backgroundColor(Theme.PRIMARY);
                        Button.onClick(() => {
                            this.joinMember();
                        });
                    }, Button);
                    Button.pop();
                    Row.pop();
                    // 加入成员（演示模式）
                    Column.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('说明：当前为家庭组演示模式，成员减排与积分数据由本机模拟生成，合并统计与排行链路完整可演示；分布式多端真实同步为后续迭代方向。');
            Text.debugLine("entry/src/main/ets/pages/Family.ets(278:11)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
    static getEntryName(): string {
        return "Family";
    }
}
registerNamedRoute(() => new Family(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/Family", pageFullPath: "entry/src/main/ets/pages/Family", integratedHsp: "false", moduleType: "followWithHap" });
