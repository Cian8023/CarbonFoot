if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MineView_Params {
    tick?: number;
    nickname?: string;
    editing?: boolean;
    nameInput?: string;
    totalKg?: string;
    balance?: number;
    badgeText?: string;
    streak?: number;
    totalPoints?: number;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import type { BadgeDef } from '../model/Models';
import { BadgeService } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { PrefsService } from "@normalized:N&&&entry/src/main/ets/common/PrefsService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
import { BehaviorRepo } from "@normalized:N&&&entry/src/main/ets/db/Repository&";
export class MineView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__tick = this.createStorageLink('tick', 0, "tick");
        this.__nickname = new ObservedPropertySimplePU('绿色生活家', this, "nickname");
        this.__editing = new ObservedPropertySimplePU(false, this, "editing");
        this.__nameInput = new ObservedPropertySimplePU('', this, "nameInput");
        this.__totalKg = new ObservedPropertySimplePU('0.00', this, "totalKg");
        this.__balance = new ObservedPropertySimplePU(0, this, "balance");
        this.__badgeText = new ObservedPropertySimplePU('0/0', this, "badgeText");
        this.__streak = new ObservedPropertySimplePU(0, this, "streak");
        this.__totalPoints = new ObservedPropertySimplePU(0, this, "totalPoints");
        this.setInitiallyProvidedValue(params);
        this.declareWatch("tick", this.refresh);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MineView_Params) {
        if (params.nickname !== undefined) {
            this.nickname = params.nickname;
        }
        if (params.editing !== undefined) {
            this.editing = params.editing;
        }
        if (params.nameInput !== undefined) {
            this.nameInput = params.nameInput;
        }
        if (params.totalKg !== undefined) {
            this.totalKg = params.totalKg;
        }
        if (params.balance !== undefined) {
            this.balance = params.balance;
        }
        if (params.badgeText !== undefined) {
            this.badgeText = params.badgeText;
        }
        if (params.streak !== undefined) {
            this.streak = params.streak;
        }
        if (params.totalPoints !== undefined) {
            this.totalPoints = params.totalPoints;
        }
    }
    updateStateVars(params: MineView_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__tick.purgeDependencyOnElmtId(rmElmtId);
        this.__nickname.purgeDependencyOnElmtId(rmElmtId);
        this.__editing.purgeDependencyOnElmtId(rmElmtId);
        this.__nameInput.purgeDependencyOnElmtId(rmElmtId);
        this.__totalKg.purgeDependencyOnElmtId(rmElmtId);
        this.__balance.purgeDependencyOnElmtId(rmElmtId);
        this.__badgeText.purgeDependencyOnElmtId(rmElmtId);
        this.__streak.purgeDependencyOnElmtId(rmElmtId);
        this.__totalPoints.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__tick.aboutToBeDeleted();
        this.__nickname.aboutToBeDeleted();
        this.__editing.aboutToBeDeleted();
        this.__nameInput.aboutToBeDeleted();
        this.__totalKg.aboutToBeDeleted();
        this.__balance.aboutToBeDeleted();
        this.__badgeText.aboutToBeDeleted();
        this.__streak.aboutToBeDeleted();
        this.__totalPoints.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __tick: ObservedPropertyAbstractPU<number>;
    get tick() {
        return this.__tick.get();
    }
    set tick(newValue: number) {
        this.__tick.set(newValue);
    }
    private __nickname: ObservedPropertySimplePU<string>;
    get nickname() {
        return this.__nickname.get();
    }
    set nickname(newValue: string) {
        this.__nickname.set(newValue);
    }
    private __editing: ObservedPropertySimplePU<boolean>;
    get editing() {
        return this.__editing.get();
    }
    set editing(newValue: boolean) {
        this.__editing.set(newValue);
    }
    private __nameInput: ObservedPropertySimplePU<string>;
    get nameInput() {
        return this.__nameInput.get();
    }
    set nameInput(newValue: string) {
        this.__nameInput.set(newValue);
    }
    private __totalKg: ObservedPropertySimplePU<string>;
    get totalKg() {
        return this.__totalKg.get();
    }
    set totalKg(newValue: string) {
        this.__totalKg.set(newValue);
    }
    private __balance: ObservedPropertySimplePU<number>;
    get balance() {
        return this.__balance.get();
    }
    set balance(newValue: number) {
        this.__balance.set(newValue);
    }
    private __badgeText: ObservedPropertySimplePU<string>;
    get badgeText() {
        return this.__badgeText.get();
    }
    set badgeText(newValue: string) {
        this.__badgeText.set(newValue);
    }
    private __streak: ObservedPropertySimplePU<number>;
    get streak() {
        return this.__streak.get();
    }
    set streak(newValue: number) {
        this.__streak.set(newValue);
    }
    private __totalPoints: ObservedPropertySimplePU<number>;
    get totalPoints() {
        return this.__totalPoints.get();
    }
    set totalPoints(newValue: number) {
        this.__totalPoints.set(newValue);
    }
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
            this.totalPoints = await PointsService.totalEarned();
        }
        catch (e) {
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
    menuItem(label: string, sub: string, onTap: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.debugLine("entry/src/main/ets/pages/Settings.ets(65:5)", "entry");
            Row.width('100%');
            Row.padding(14);
            Row.onClick(() => {
                onTap();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(66:7)", "entry");
            Text.fontSize(14);
            Text.fontColor(Theme.TEXT);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(sub);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(70:7)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(73:7)", "entry");
            Text.fontSize(16);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/Settings.ets(85:5)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(86:7)", "entry");
            Column.width('100%');
            Column.padding(14);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 用户信息
            Column.create({ space: 16 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(88:9)", "entry");
            // 用户信息
            Column.width('100%');
            // 用户信息
            Column.padding(18);
            // 用户信息
            Column.borderRadius(Theme.R_MEDIUM);
            // 用户信息
            Column.backgroundColor(Theme.CARD);
            // 用户信息
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 14 });
            Row.debugLine("entry/src/main/ets/pages/Settings.ets(89:11)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(90:13)", "entry");
            Column.width(56);
            Column.height(56);
            Column.borderRadius(28);
            Column.backgroundColor(Theme.PRIMARY_BG);
            Column.justifyContent(FlexAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.nickname.substring(0, 1));
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(91:15)", "entry");
            Text.fontSize(24);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.PRIMARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(102:13)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.editing) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 8 });
                        Row.debugLine("entry/src/main/ets/pages/Settings.ets(104:17)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ text: this.nameInput, placeholder: '输入新昵称' });
                        TextInput.debugLine("entry/src/main/ets/pages/Settings.ets(105:19)", "entry");
                        TextInput.height(38);
                        TextInput.layoutWeight(1);
                        TextInput.onChange((v: string) => {
                            this.nameInput = v;
                        });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('保存');
                        Text.debugLine("entry/src/main/ets/pages/Settings.ets(111:19)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(Theme.PRIMARY);
                        Text.onClick(() => {
                            this.saveNickname();
                        });
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 8 });
                        Row.debugLine("entry/src/main/ets/pages/Settings.ets(120:17)", "entry");
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.nickname);
                        Text.debugLine("entry/src/main/ets/pages/Settings.ets(121:19)", "entry");
                        Text.fontSize(19);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.TEXT);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('编辑');
                        Text.debugLine("entry/src/main/ets/pages/Settings.ets(125:19)", "entry");
                        Text.fontSize(11);
                        Text.fontColor(Theme.PRIMARY);
                        Text.border({ width: 1, color: Theme.PRIMARY, radius: 8 });
                        Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                        Text.onClick(() => {
                            this.nameInput = this.nickname;
                            this.editing = true;
                        });
                    }, Text);
                    Text.pop();
                    Row.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`连续打卡 ${this.streak} 天`);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(136:15)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(145:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Settings.ets(147:11)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(148:13)", "entry");
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.totalKg);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(149:15)", "entry");
            Text.fontSize(19);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.PRIMARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('累计减排(kg)');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(153:15)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(159:13)", "entry");
            Divider.vertical(true);
            Divider.height(28);
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(161:13)", "entry");
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('' + this.balance);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(162:15)", "entry");
            Text.fontSize(19);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('碳积分');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(166:15)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(172:13)", "entry");
            Divider.vertical(true);
            Divider.height(28);
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(174:13)", "entry");
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.badgeText);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(175:15)", "entry");
            Text.fontSize(19);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('徽章');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(179:15)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(185:13)", "entry");
            Divider.vertical(true);
            Divider.height(28);
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(187:13)", "entry");
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('' + this.totalPoints);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(188:15)", "entry");
            Text.fontSize(19);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('累计积分');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(192:15)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        Row.pop();
        // 用户信息
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 功能入口
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(207:9)", "entry");
            // 功能入口
            Column.width('100%');
            // 功能入口
            Column.borderRadius(16);
            // 功能入口
            Column.backgroundColor(Theme.CARD);
            // 功能入口
            Column.clip(true);
        }, Column);
        this.menuItem.bind(this)('徽章墙', '查看解锁进度', (): void => {
            router.pushUrl({ url: 'pages/Badges' });
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(211:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.menuItem.bind(this)('双碳科普', '政策·技巧·动态', (): void => {
            router.pushUrl({ url: 'pages/Knowledge' });
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(215:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.menuItem.bind(this)('积分流水', '收支明细', (): void => {
            AppStorage.setOrCreate('tasksSegment', 1);
            AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(220:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.menuItem.bind(this)('植树证书', '积分兑换', (): void => {
            router.pushUrl({ url: 'pages/Badges' });
        });
        // 功能入口
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 创新拓展功能
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(231:9)", "entry");
            // 创新拓展功能
            Column.width('100%');
            // 创新拓展功能
            Column.borderRadius(16);
            // 创新拓展功能
            Column.backgroundColor(Theme.CARD);
            // 创新拓展功能
            Column.clip(true);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.debugLine("entry/src/main/ets/pages/Settings.ets(232:11)", "entry");
            Row.width('100%');
            Row.padding(14);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('创');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(233:13)", "entry");
            Text.fontSize(18);
            Text.fontColor(Theme.PRIMARY);
            Text.backgroundColor(Theme.PRIMARY_BG);
            Text.borderRadius(4);
            Text.padding({ left: 6, right: 6, top: 3, bottom: 3 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('创新拓展');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(239:13)", "entry");
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(246:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.menuItem.bind(this)('AI 拍照识别录入', '智能识别低碳行为', (): void => {
            router.pushUrl({ url: 'pages/AiRecognize' });
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(250:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.menuItem.bind(this)('城市碳普惠平台', '积分互通·权益兑换', (): void => {
            router.pushUrl({ url: 'pages/Inclusive' });
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(254:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.menuItem.bind(this)('家庭碳账户', '多端同步·合并统计', (): void => {
            router.pushUrl({ url: 'pages/Family' });
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Settings.ets(258:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.menuItem.bind(this)('减排成果分享', '生成分享卡片', (): void => {
            router.pushUrl({ url: 'pages/ShareCard' });
        });
        // 创新拓展功能
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 设置入口（个性化 / 服务配置 / 数据管理整合于此）
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(269:9)", "entry");
            // 设置入口（个性化 / 服务配置 / 数据管理整合于此）
            Column.width('100%');
            // 设置入口（个性化 / 服务配置 / 数据管理整合于此）
            Column.borderRadius(16);
            // 设置入口（个性化 / 服务配置 / 数据管理整合于此）
            Column.backgroundColor(Theme.CARD);
            // 设置入口（个性化 / 服务配置 / 数据管理整合于此）
            Column.clip(true);
        }, Column);
        this.menuItem.bind(this)('设置', '目标·布局·服务配置·数据管理', (): void => {
            router.pushUrl({ url: 'pages/SettingsDetail' });
        });
        // 设置入口（个性化 / 服务配置 / 数据管理整合于此）
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 底部声明
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Settings.ets(280:9)", "entry");
            // 底部声明
            Column.width('100%');
            // 底部声明
            Column.padding(6);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`碳足迹 v${Constants.VERSION} · Apache-2.0 · 零三方依赖`);
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(281:11)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('减排因子参考生态环境部公开核算方法，仅作生活估算演示');
            Text.debugLine("entry/src/main/ets/pages/Settings.ets(284:11)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        // 底部声明
        Column.pop();
        Column.pop();
        Scroll.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
