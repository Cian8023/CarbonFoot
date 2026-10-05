if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Inclusive_Params {
    benefits?: Benefit[];
    entitlements?: Entitlement[];
    balance?: number;
    statusText?: string;
    remoteMode?: boolean;
    exchangingId?: string;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { bumpTick } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { InclusiveService } from "@normalized:N&&&entry/src/main/ets/service/InclusiveService&";
import type { Benefit, Entitlement } from "@normalized:N&&&entry/src/main/ets/service/InclusiveService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
class Inclusive extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__benefits = new ObservedPropertyObjectPU([], this, "benefits");
        this.__entitlements = new ObservedPropertyObjectPU([], this, "entitlements");
        this.__balance = new ObservedPropertySimplePU(0, this, "balance");
        this.__statusText = new ObservedPropertySimplePU('连接碳普惠平台中…', this, "statusText");
        this.__remoteMode = new ObservedPropertySimplePU(false, this, "remoteMode");
        this.__exchangingId = new ObservedPropertySimplePU('', this, "exchangingId");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Inclusive_Params) {
        if (params.benefits !== undefined) {
            this.benefits = params.benefits;
        }
        if (params.entitlements !== undefined) {
            this.entitlements = params.entitlements;
        }
        if (params.balance !== undefined) {
            this.balance = params.balance;
        }
        if (params.statusText !== undefined) {
            this.statusText = params.statusText;
        }
        if (params.remoteMode !== undefined) {
            this.remoteMode = params.remoteMode;
        }
        if (params.exchangingId !== undefined) {
            this.exchangingId = params.exchangingId;
        }
    }
    updateStateVars(params: Inclusive_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__benefits.purgeDependencyOnElmtId(rmElmtId);
        this.__entitlements.purgeDependencyOnElmtId(rmElmtId);
        this.__balance.purgeDependencyOnElmtId(rmElmtId);
        this.__statusText.purgeDependencyOnElmtId(rmElmtId);
        this.__remoteMode.purgeDependencyOnElmtId(rmElmtId);
        this.__exchangingId.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__benefits.aboutToBeDeleted();
        this.__entitlements.aboutToBeDeleted();
        this.__balance.aboutToBeDeleted();
        this.__statusText.aboutToBeDeleted();
        this.__remoteMode.aboutToBeDeleted();
        this.__exchangingId.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __benefits: ObservedPropertyObjectPU<Benefit[]>;
    get benefits() {
        return this.__benefits.get();
    }
    set benefits(newValue: Benefit[]) {
        this.__benefits.set(newValue);
    }
    private __entitlements: ObservedPropertyObjectPU<Entitlement[]>;
    get entitlements() {
        return this.__entitlements.get();
    }
    set entitlements(newValue: Entitlement[]) {
        this.__entitlements.set(newValue);
    }
    private __balance: ObservedPropertySimplePU<number>;
    get balance() {
        return this.__balance.get();
    }
    set balance(newValue: number) {
        this.__balance.set(newValue);
    }
    private __statusText: ObservedPropertySimplePU<string>;
    get statusText() {
        return this.__statusText.get();
    }
    set statusText(newValue: string) {
        this.__statusText.set(newValue);
    }
    private __remoteMode: ObservedPropertySimplePU<boolean>;
    get remoteMode() {
        return this.__remoteMode.get();
    }
    set remoteMode(newValue: boolean) {
        this.__remoteMode.set(newValue);
    }
    private __exchangingId: ObservedPropertySimplePU<string>;
    get exchangingId() {
        return this.__exchangingId.get();
    }
    set exchangingId(newValue: string) {
        this.__exchangingId.set(newValue);
    }
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
        }
        catch (e) {
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
        }
        catch (e) {
            promptAction.showToast({ message: (e as Error).message });
        }
        finally {
            this.exchangingId = '';
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(78:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(Theme.BG);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Inclusive.ets(79:7)", "entry");
            Row.width('100%');
            Row.padding({ left: 14, right: 14, top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(80:9)", "entry");
            Text.fontSize(22);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Inclusive.ets(85:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('城市碳普惠平台');
            Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(86:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Inclusive.ets(89:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('');
            Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(90:9)", "entry");
            Text.width(22);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/Inclusive.ets(96:7)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.layoutWeight(1);
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(97:9)", "entry");
            Column.width('100%');
            Column.padding(14);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 平台状态卡
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Inclusive.ets(99:11)", "entry");
            // 平台状态卡
            Row.width('100%');
            // 平台状态卡
            Row.padding(14);
            // 平台状态卡
            Row.borderRadius(14);
            // 平台状态卡
            Row.backgroundColor(Theme.CARD);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Circle.create({ width: 10, height: 10 });
            Circle.debugLine("entry/src/main/ets/pages/Inclusive.ets(100:13)", "entry");
            Circle.fill(this.remoteMode ? Theme.PRIMARY : Theme.POINTS);
        }, Circle);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 3 });
            Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(102:13)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.statusText);
            Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(103:15)", "entry");
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`我的碳积分：${this.balance}`);
            Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(106:15)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        // 平台状态卡
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 权益商城
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(119:11)", "entry");
            // 权益商城
            Column.width('100%');
            // 权益商城
            Column.padding(14);
            // 权益商城
            Column.borderRadius(16);
            // 权益商城
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('可兑换权益');
            Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(120:13)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const b = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create({ space: 12 });
                    Row.debugLine("entry/src/main/ets/pages/Inclusive.ets(126:15)", "entry");
                    Row.width('100%');
                    Row.padding(12);
                    Row.borderRadius(12);
                    Row.backgroundColor(Theme.BG);
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(b.icon);
                    Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(127:17)", "entry");
                    Text.fontSize(15);
                    Text.fontWeight(FontWeight.Medium);
                    Text.fontColor(Theme.PRIMARY);
                    Text.width(40);
                    Text.height(40);
                    Text.textAlign(TextAlign.Center);
                    Text.backgroundColor(Theme.PRIMARY_BG);
                    Text.borderRadius(20);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 4 });
                    Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(136:17)", "entry");
                    Column.alignItems(HorizontalAlign.Start);
                    Column.layoutWeight(1);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(b.name);
                    Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(137:19)", "entry");
                    Text.fontSize(14);
                    Text.fontWeight(FontWeight.Medium);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(b.desc);
                    Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(140:19)", "entry");
                    Text.fontSize(11);
                    Text.fontColor(Theme.TEXT_TERTIARY);
                    Text.maxLines(1);
                }, Text);
                Text.pop();
                Column.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 3 });
                    Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(147:17)", "entry");
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel(`${b.cost} 分`);
                    Button.debugLine("entry/src/main/ets/pages/Inclusive.ets(148:19)", "entry");
                    Button.fontSize(12);
                    Button.height(32);
                    Button.backgroundColor(this.balance >= b.cost && b.stock > 0 ? Theme.PRIMARY : Theme.TEXT_TERTIARY);
                    Button.enabled(b.stock > 0);
                    Button.onClick(() => {
                        this.doExchange(b);
                    });
                }, Button);
                Button.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (b.stock <= 0) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('已兑完');
                                Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(157:21)", "entry");
                                Text.fontSize(9);
                                Text.fontColor('#F53F3F');
                            }, Text);
                            Text.pop();
                        });
                    }
                    else {
                        this.ifElseBranchUpdateFunction(1, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`余 ${b.stock}`);
                                Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(161:21)", "entry");
                                Text.fontSize(9);
                                Text.fontColor(Theme.TEXT_TERTIARY);
                            }, Text);
                            Text.pop();
                        });
                    }
                }, If);
                If.pop();
                Column.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, this.benefits, forEachItemGenFunction, (b: Benefit) => b.id, false, false);
        }, ForEach);
        ForEach.pop();
        // 权益商城
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 权益记录
            if (this.entitlements.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 10 });
                        Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(180:13)", "entry");
                        Column.width('100%');
                        Column.padding(14);
                        Column.borderRadius(16);
                        Column.backgroundColor(Theme.CARD);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('我的权益记录');
                        Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(181:15)", "entry");
                        Text.fontSize(15);
                        Text.fontWeight(FontWeight.Medium);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const e = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create({ space: 10 });
                                Row.debugLine("entry/src/main/ets/pages/Inclusive.ets(186:17)", "entry");
                                Row.width('100%');
                                Row.padding(10);
                                Row.borderRadius(10);
                                Row.backgroundColor(Theme.BG);
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(e.icon);
                                Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(187:19)", "entry");
                                Text.fontSize(20);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Column.create({ space: 2 });
                                Column.debugLine("entry/src/main/ets/pages/Inclusive.ets(189:19)", "entry");
                                Column.alignItems(HorizontalAlign.Start);
                                Column.layoutWeight(1);
                            }, Column);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(e.name);
                                Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(190:21)", "entry");
                                Text.fontSize(13);
                                Text.fontWeight(FontWeight.Medium);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`${e.from} · ${DateUtil.formatMDHM(e.time)}`);
                                Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(193:21)", "entry");
                                Text.fontSize(10);
                                Text.fontColor(Theme.TEXT_TERTIARY);
                            }, Text);
                            Text.pop();
                            Column.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('✓');
                                Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(199:19)", "entry");
                                Text.fontColor(Theme.PRIMARY);
                            }, Text);
                            Text.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.entitlements, forEachItemGenFunction, (e: Entitlement) => '' + e.time + e.name, false, false);
                    }, ForEach);
                    ForEach.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('说明：在「我的 > 服务配置」中填入碳普惠平台地址即可对接真实接口（可用 Node.js 起 Mock 服务）；未连通时自动使用内置模拟权益池。');
            Text.debugLine("entry/src/main/ets/pages/Inclusive.ets(214:11)", "entry");
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
        return "Inclusive";
    }
}
registerNamedRoute(() => new Inclusive(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/Inclusive", pageFullPath: "entry/src/main/ets/pages/Inclusive", integratedHsp: "false", moduleType: "followWithHap" });
