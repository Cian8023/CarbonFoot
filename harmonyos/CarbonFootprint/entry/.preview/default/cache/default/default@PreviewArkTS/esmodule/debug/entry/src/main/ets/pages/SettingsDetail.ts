if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingsDetail_Params {
    monthGoalInput?: string;
    homeLayout?: string[];
    hiddenCards?: string[];
    aiKey?: string;
    aiUrl?: string;
    aiModel?: string;
    inclusiveUrl?: string;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants, bumpTick } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import { AppConfig } from "@normalized:N&&&entry/src/main/ets/common/AppConfig&";
import { ExportService } from "@normalized:N&&&entry/src/main/ets/service/ExportService&";
import { PrefsService, DEFAULT_HOME_LAYOUT } from "@normalized:N&&&entry/src/main/ets/common/PrefsService&";
import { InclusiveService } from "@normalized:N&&&entry/src/main/ets/service/InclusiveService&";
import pasteboard from "@ohos:pasteboard";
import picker from "@ohos:file.picker";
class SettingsDetail extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__monthGoalInput = new ObservedPropertySimplePU('30', this, "monthGoalInput");
        this.__homeLayout = new ObservedPropertyObjectPU([], this, "homeLayout");
        this.__hiddenCards = new ObservedPropertyObjectPU([], this, "hiddenCards");
        this.__aiKey = new ObservedPropertySimplePU('', this, "aiKey");
        this.__aiUrl = new ObservedPropertySimplePU('', this, "aiUrl");
        this.__aiModel = new ObservedPropertySimplePU('', this, "aiModel");
        this.__inclusiveUrl = new ObservedPropertySimplePU('', this, "inclusiveUrl");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingsDetail_Params) {
        if (params.monthGoalInput !== undefined) {
            this.monthGoalInput = params.monthGoalInput;
        }
        if (params.homeLayout !== undefined) {
            this.homeLayout = params.homeLayout;
        }
        if (params.hiddenCards !== undefined) {
            this.hiddenCards = params.hiddenCards;
        }
        if (params.aiKey !== undefined) {
            this.aiKey = params.aiKey;
        }
        if (params.aiUrl !== undefined) {
            this.aiUrl = params.aiUrl;
        }
        if (params.aiModel !== undefined) {
            this.aiModel = params.aiModel;
        }
        if (params.inclusiveUrl !== undefined) {
            this.inclusiveUrl = params.inclusiveUrl;
        }
    }
    updateStateVars(params: SettingsDetail_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__monthGoalInput.purgeDependencyOnElmtId(rmElmtId);
        this.__homeLayout.purgeDependencyOnElmtId(rmElmtId);
        this.__hiddenCards.purgeDependencyOnElmtId(rmElmtId);
        this.__aiKey.purgeDependencyOnElmtId(rmElmtId);
        this.__aiUrl.purgeDependencyOnElmtId(rmElmtId);
        this.__aiModel.purgeDependencyOnElmtId(rmElmtId);
        this.__inclusiveUrl.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__monthGoalInput.aboutToBeDeleted();
        this.__homeLayout.aboutToBeDeleted();
        this.__hiddenCards.aboutToBeDeleted();
        this.__aiKey.aboutToBeDeleted();
        this.__aiUrl.aboutToBeDeleted();
        this.__aiModel.aboutToBeDeleted();
        this.__inclusiveUrl.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __monthGoalInput: ObservedPropertySimplePU<string>;
    get monthGoalInput() {
        return this.__monthGoalInput.get();
    }
    set monthGoalInput(newValue: string) {
        this.__monthGoalInput.set(newValue);
    }
    private __homeLayout: ObservedPropertyObjectPU<string[]>;
    get homeLayout() {
        return this.__homeLayout.get();
    }
    set homeLayout(newValue: string[]) {
        this.__homeLayout.set(newValue);
    }
    private __hiddenCards: ObservedPropertyObjectPU<string[]>;
    get hiddenCards() {
        return this.__hiddenCards.get();
    }
    set hiddenCards(newValue: string[]) {
        this.__hiddenCards.set(newValue);
    }
    private __aiKey: ObservedPropertySimplePU<string>;
    get aiKey() {
        return this.__aiKey.get();
    }
    set aiKey(newValue: string) {
        this.__aiKey.set(newValue);
    }
    private __aiUrl: ObservedPropertySimplePU<string>;
    get aiUrl() {
        return this.__aiUrl.get();
    }
    set aiUrl(newValue: string) {
        this.__aiUrl.set(newValue);
    }
    private __aiModel: ObservedPropertySimplePU<string>;
    get aiModel() {
        return this.__aiModel.get();
    }
    set aiModel(newValue: string) {
        this.__aiModel.set(newValue);
    }
    private __inclusiveUrl: ObservedPropertySimplePU<string>;
    get inclusiveUrl() {
        return this.__inclusiveUrl.get();
    }
    set inclusiveUrl(newValue: string) {
        this.__inclusiveUrl.set(newValue);
    }
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
        }
        catch (e) {
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
        }
        catch (e) {
            promptAction.showToast({ message: '备份失败，请重试' });
        }
    }
    private async doExportCsv(): Promise<void> {
        try {
            const path = await ExportService.exportCsv();
            await this.copyPath(path);
            promptAction.showToast({ message: '报表已导出，文件路径已复制到剪贴板', duration: 3000 });
        }
        catch (e) {
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
        }
        catch (e) {
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
    cardTitle(icon: string, title: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(196:5)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(icon);
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(197:7)", "entry");
            Text.fontSize(18);
            Text.fontColor(Theme.PRIMARY);
            Text.backgroundColor(Theme.PRIMARY_BG);
            Text.borderRadius(4);
            Text.padding({ left: 6, right: 6, top: 3, bottom: 3 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(203:7)", "entry");
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Row.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(211:5)", "entry");
            Stack.width('100%');
            Stack.height('100%');
            Stack.backgroundColor(Theme.BG);
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(212:7)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(213:9)", "entry");
            Column.width('100%');
            Column.padding(14);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部导航
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(215:11)", "entry");
            // 顶部导航
            Row.width('100%');
            // 顶部导航
            Row.padding({ left: 14, right: 14, top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(216:13)", "entry");
            Text.fontSize(22);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(221:13)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('设置');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(222:13)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(225:13)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(226:13)", "entry");
            Text.width(22);
        }, Text);
        Text.pop();
        // 顶部导航
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(233:11)", "entry");
            // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
            Column.width('100%');
            // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
            Column.padding(14);
            // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
            Column.borderRadius(16);
            // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
            Column.backgroundColor(Theme.CARD);
            // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.cardTitle.bind(this)('个', '本月减排目标（kg）');
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(236:13)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(237:15)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('显示在首页目标环上');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(238:17)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('保存后首页目标环与节奏提示即时更新');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(241:17)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ text: this.monthGoalInput });
            TextInput.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(248:15)", "entry");
            TextInput.type(InputType.NUMBER_DECIMAL);
            TextInput.width(90);
            TextInput.height(36);
            TextInput.fontSize(13);
            TextInput.onChange((v: string) => {
                this.monthGoalInput = v;
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('保存');
            Button.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(257:15)", "entry");
            Button.height(36);
            Button.fontSize(13);
            Button.backgroundColor(Theme.PRIMARY);
            Button.onClick(() => {
                this.saveGoal();
            });
        }, Button);
        Button.pop();
        Row.pop();
        // 个性化 · 本月减排目标（置顶，首页"修改目标"直达此处）
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 个性化 · 首页卡片布局
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(274:11)", "entry");
            // 个性化 · 首页卡片布局
            Column.width('100%');
            // 个性化 · 首页卡片布局
            Column.padding(14);
            // 个性化 · 首页卡片布局
            Column.borderRadius(16);
            // 个性化 · 首页卡片布局
            Column.backgroundColor(Theme.CARD);
            // 个性化 · 首页卡片布局
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.cardTitle.bind(this)('排', '首页卡片布局');
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('调整首页卡片顺序与显隐，改动即时生效');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(276:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, idx: number) => {
                const key = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create({ space: 8 });
                    Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(282:15)", "entry");
                    Row.width('100%');
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('' + (idx + 1));
                    Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(283:17)", "entry");
                    Text.fontSize(11);
                    Text.fontColor(Theme.TEXT_TERTIARY);
                    Text.width(18);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(PrefsService.homeCardTitle(key));
                    Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(287:17)", "entry");
                    Text.fontSize(13);
                    Text.fontColor(Theme.TEXT);
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel('↑');
                    Button.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(291:17)", "entry");
                    Button.height(28);
                    Button.fontSize(12);
                    Button.backgroundColor(Theme.BG);
                    Button.fontColor(Theme.TEXT_SECONDARY);
                    Button.onClick(() => {
                        this.moveCard(idx, -1);
                    });
                }, Button);
                Button.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel('↓');
                    Button.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(299:17)", "entry");
                    Button.height(28);
                    Button.fontSize(12);
                    Button.backgroundColor(Theme.BG);
                    Button.fontColor(Theme.TEXT_SECONDARY);
                    Button.onClick(() => {
                        this.moveCard(idx, 1);
                    });
                }, Button);
                Button.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Button.createWithLabel('隐藏');
                    Button.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(307:17)", "entry");
                    Button.height(28);
                    Button.fontSize(11);
                    Button.backgroundColor(Theme.BG);
                    Button.fontColor('#F53F3F');
                    Button.onClick(() => {
                        this.hideCard(key);
                    });
                }, Button);
                Button.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, this.homeLayout, forEachItemGenFunction, (key: string) => key + '_' + this.homeLayout.indexOf(key), true, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.hiddenCards.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const key = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create({ space: 8 });
                                Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(321:17)", "entry");
                                Row.width('100%');
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(PrefsService.homeCardTitle(key));
                                Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(322:19)", "entry");
                                Text.fontSize(13);
                                Text.fontColor(Theme.TEXT_TERTIARY);
                                Text.layoutWeight(1);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Button.createWithLabel('显示');
                                Button.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(326:19)", "entry");
                                Button.height(28);
                                Button.fontSize(11);
                                Button.backgroundColor(Theme.PRIMARY_BG);
                                Button.fontColor(Theme.PRIMARY);
                                Button.onClick(() => {
                                    this.showCard(key);
                                });
                            }, Button);
                            Button.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.hiddenCards, forEachItemGenFunction, (key: string) => 'hidden_' + key, false, false);
                    }, ForEach);
                    ForEach.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        // 个性化 · 首页卡片布局
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 服务配置
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(346:11)", "entry");
            // 服务配置
            Column.width('100%');
            // 服务配置
            Column.padding(14);
            // 服务配置
            Column.borderRadius(16);
            // 服务配置
            Column.backgroundColor(Theme.CARD);
            // 服务配置
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.cardTitle.bind(this)('配', '服务配置（联网能力）');
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('AI 视觉接口 API Key（留空 = 离线演示识别）');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(349:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: 'sk-...', text: this.aiKey });
            TextInput.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(353:13)", "entry");
            TextInput.height(40);
            TextInput.type(InputType.NEW_PASSWORD);
            TextInput.onChange((v: string) => {
                this.aiKey = v;
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('模型名（OpenAI 兼容接口的 model 参数）');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(359:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: 'deepseek-chat', text: this.aiModel });
            TextInput.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(363:13)", "entry");
            TextInput.height(40);
            TextInput.onChange((v: string) => {
                this.aiModel = v;
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(368:13)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '视觉接口地址', text: this.aiUrl });
            TextInput.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(369:15)", "entry");
            TextInput.layoutWeight(1);
            TextInput.height(40);
            TextInput.onChange((v: string) => {
                this.aiUrl = v;
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('保存');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(375:15)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.PRIMARY);
            Text.onClick(() => {
                AppConfig.setAiApiKey(this.aiKey.trim());
                AppConfig.setAiBaseUrl(this.aiUrl.trim());
                AppConfig.setAiModel(this.aiModel.trim() === '' ? 'deepseek-chat' : this.aiModel.trim());
                promptAction.showToast({ message: 'AI 服务配置已保存' });
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(387:13)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('碳普惠平台地址（不可达 = 内置模拟模式）');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(389:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(393:13)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: 'http://服务器:端口', text: this.inclusiveUrl });
            TextInput.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(394:15)", "entry");
            TextInput.layoutWeight(1);
            TextInput.height(40);
            TextInput.onChange((v: string) => {
                this.inclusiveUrl = v;
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('保存');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(400:15)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.PRIMARY);
            Text.onClick(() => {
                AppConfig.setInclusiveBaseUrl(this.inclusiveUrl.trim());
                promptAction.showToast({ message: '碳普惠平台地址已保存' });
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('测试连接');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(407:15)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.POINTS);
            Text.onClick(() => {
                this.testInclusive();
            });
        }, Text);
        Text.pop();
        Row.pop();
        // 服务配置
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 本地数据管理
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(423:11)", "entry");
            // 本地数据管理
            Column.width('100%');
            // 本地数据管理
            Column.padding(14);
            // 本地数据管理
            Column.borderRadius(16);
            // 本地数据管理
            Column.backgroundColor(Theme.CARD);
            // 本地数据管理
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.cardTitle.bind(this)('档', '本地数据管理');
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(426:13)", "entry");
            Divider.color(Theme.DIVIDER);
            Divider.margin({ top: 8 });
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(427:13)", "entry");
            Row.width('100%');
            Row.padding({ top: 10, bottom: 10 });
            Row.onClick(() => {
                this.doBackup();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(428:15)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('一键备份（JSON）');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(429:17)", "entry");
            Text.fontSize(14);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('导出到应用沙箱，路径自动复制');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(432:17)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(438:15)", "entry");
            Text.fontSize(16);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(448:13)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(449:13)", "entry");
            Row.width('100%');
            Row.padding({ top: 10, bottom: 10 });
            Row.onClick(() => {
                this.confirmImport();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(450:15)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('导入备份（JSON）');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(451:17)", "entry");
            Text.fontSize(14);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('覆盖行为与积分流水');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(454:17)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(460:15)", "entry");
            Text.fontSize(16);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(470:13)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(471:13)", "entry");
            Row.width('100%');
            Row.padding({ top: 10, bottom: 10 });
            Row.onClick(() => {
                this.doExportCsv();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(472:15)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('统计报表（CSV）');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(473:17)", "entry");
            Text.fontSize(14);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('月度减排汇总，路径自动复制');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(476:17)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(482:15)", "entry");
            Text.fontSize(16);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(492:13)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 12 });
            Row.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(493:13)", "entry");
            Row.width('100%');
            Row.padding({ top: 10, bottom: 10 });
            Row.onClick(() => {
                this.confirmClear();
            });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(494:15)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('清空所有数据');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(495:17)", "entry");
            Text.fontSize(14);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('不可恢复');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(498:17)", "entry");
            Text.fontSize(11);
            Text.fontColor('#F53F3F');
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('›');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(504:15)", "entry");
            Text.fontSize(16);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
        // 本地数据管理
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 关于
            Column.create({ space: 6 });
            Column.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(521:11)", "entry");
            // 关于
            Column.width('100%');
            // 关于
            Column.padding(10);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`碳足迹 v${Constants.VERSION} · Apache-2.0 · 零三方依赖`);
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(522:13)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('HarmonyOS · 低碳数据仅存本机；仅 AI 识别时图片发送至你配置的接口');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(525:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('减排因子参考生态环境部公开核算方法，仅作生活估算演示');
            Text.debugLine("entry/src/main/ets/pages/SettingsDetail.ets(528:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        // 关于
        Column.pop();
        Column.pop();
        Scroll.pop();
        Stack.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
    static getEntryName(): string {
        return "SettingsDetail";
    }
}
registerNamedRoute(() => new SettingsDetail(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/SettingsDetail", pageFullPath: "entry/src/main/ets/pages/SettingsDetail", integratedHsp: "false", moduleType: "followWithHap" });
