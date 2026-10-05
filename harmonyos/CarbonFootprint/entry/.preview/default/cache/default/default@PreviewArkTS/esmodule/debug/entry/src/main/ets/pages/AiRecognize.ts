if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface AiRecognize_Params {
    recognizing?: boolean;
    guess?: AiGuess | null;
    estimateG?: number;
    estimatePts?: number;
    submitting?: boolean;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants, gotoTab } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { AiRecognizeService } from "@normalized:N&&&entry/src/main/ets/service/AiRecognizeService&";
import type { AiGuess } from "@normalized:N&&&entry/src/main/ets/service/AiRecognizeService&";
import { CalculationService } from "@normalized:N&&&entry/src/main/ets/service/CalculationService&";
import { BehaviorService } from "@normalized:N&&&entry/src/main/ets/service/BehaviorService&";
import { AppConfig } from "@normalized:N&&&entry/src/main/ets/common/AppConfig&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
class AiRecognize extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__recognizing = new ObservedPropertySimplePU(false, this, "recognizing");
        this.__guess = new ObservedPropertyObjectPU(null, this, "guess");
        this.__estimateG = new ObservedPropertySimplePU(0, this, "estimateG");
        this.__estimatePts = new ObservedPropertySimplePU(0, this, "estimatePts");
        this.__submitting = new ObservedPropertySimplePU(false, this, "submitting");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: AiRecognize_Params) {
        if (params.recognizing !== undefined) {
            this.recognizing = params.recognizing;
        }
        if (params.guess !== undefined) {
            this.guess = params.guess;
        }
        if (params.estimateG !== undefined) {
            this.estimateG = params.estimateG;
        }
        if (params.estimatePts !== undefined) {
            this.estimatePts = params.estimatePts;
        }
        if (params.submitting !== undefined) {
            this.submitting = params.submitting;
        }
    }
    updateStateVars(params: AiRecognize_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__recognizing.purgeDependencyOnElmtId(rmElmtId);
        this.__guess.purgeDependencyOnElmtId(rmElmtId);
        this.__estimateG.purgeDependencyOnElmtId(rmElmtId);
        this.__estimatePts.purgeDependencyOnElmtId(rmElmtId);
        this.__submitting.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__recognizing.aboutToBeDeleted();
        this.__guess.aboutToBeDeleted();
        this.__estimateG.aboutToBeDeleted();
        this.__estimatePts.aboutToBeDeleted();
        this.__submitting.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __recognizing: ObservedPropertySimplePU<boolean>;
    get recognizing() {
        return this.__recognizing.get();
    }
    set recognizing(newValue: boolean) {
        this.__recognizing.set(newValue);
    }
    private __guess: ObservedPropertyObjectPU<AiGuess | null>;
    get guess() {
        return this.__guess.get();
    }
    set guess(newValue: AiGuess | null) {
        this.__guess.set(newValue);
    }
    private __estimateG: ObservedPropertySimplePU<number>;
    get estimateG() {
        return this.__estimateG.get();
    }
    set estimateG(newValue: number) {
        this.__estimateG.set(newValue);
    }
    private __estimatePts: ObservedPropertySimplePU<number>;
    get estimatePts() {
        return this.__estimatePts.get();
    }
    set estimatePts(newValue: number) {
        this.__estimatePts.set(newValue);
    }
    private __submitting: ObservedPropertySimplePU<boolean>;
    get submitting() {
        return this.__submitting.get();
    }
    set submitting(newValue: boolean) {
        this.__submitting.set(newValue);
    }
    private async recognizeUri(uri: string): Promise<void> {
        try {
            await AppInit.ensure();
            this.recognizing = true;
            promptAction.showToast({ message: 'AI 识别中…' });
            const b64 = await AiRecognizeService.imageToBase64(uri);
            const g = await AiRecognizeService.recognize(b64);
            this.guess = g;
            this.updateEstimate();
        }
        catch (e) {
            promptAction.showToast({ message: '识别失败：' + (e as Error).message });
        }
        finally {
            this.recognizing = false;
        }
    }
    private async pickAndRecognize(): Promise<void> {
        try {
            const uri = await AiRecognizeService.pickImage();
            await this.recognizeUri(uri);
        }
        catch (e) {
            promptAction.showToast({ message: '识别失败：' + (e as Error).message });
        }
    }
    private async shootAndRecognize(): Promise<void> {
        try {
            const uri = await AiRecognizeService.shootImage();
            await this.recognizeUri(uri);
        }
        catch (e) {
            promptAction.showToast({ message: '识别失败：' + (e as Error).message });
        }
    }
    private updateEstimate(): void {
        if (this.guess === null) {
            this.estimateG = 0;
            this.estimatePts = 0;
            return;
        }
        const g = this.guess as AiGuess;
        this.estimateG = CalculationService.calculate(g.type, g.subType, g.value);
        this.estimatePts = this.estimateG > 0 ? Math.max(1, Math.floor(this.estimateG / 100)) : 0;
    }
    private async submit(): Promise<void> {
        if (this.guess === null || this.submitting) {
            return;
        }
        const g = this.guess as AiGuess;
        const sub = CalculationService.findSub(g.type, g.subType);
        if (sub === null) {
            return;
        }
        this.submitting = true;
        try {
            const result = await BehaviorService.submit(g.type, g.subType, g.value, sub.unit, sub.factor, Date.now(), 'AI 拍照识别' + (g.demo ? '（演示）' : ''));
            let msg = `已自动录入！减排 ${DateUtil.gramsToKg(result.grams)} kg，+${result.points} 积分`;
            if (result.newBadges.length > 0) {
                msg += ` 解锁徽章：${result.newBadges.join('、')}`;
            }
            promptAction.showToast({ message: msg, duration: 2500 });
            this.guess = null;
            gotoTab(Constants.TAB_RECORD);
            router.back();
        }
        catch (e) {
            promptAction.showToast({ message: '录入失败，请重试' });
        }
        finally {
            this.submitting = false;
        }
    }
    private async configApiKey(): Promise<void> {
        try {
            const key = await AppConfig.getAiApiKey();
            promptAction.showToast({
                message: key === '' ? '未配置 API Key（当前为离线演示识别）' : '已配置 API Key（在线识别）'
            });
        }
        catch (e) {
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/AiRecognize.ets(108:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(Theme.BG);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/AiRecognize.ets(109:7)", "entry");
            Row.width('100%');
            Row.padding({ left: 14, right: 14, top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(110:9)", "entry");
            Text.fontSize(22);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/AiRecognize.ets(115:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('AI 拍照识别低碳行为');
            Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(116:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/AiRecognize.ets(119:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('设置');
            Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(120:9)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.border({ width: 1, color: Theme.BORDER, radius: 10 });
            Text.padding({ left: 8, right: 8, top: 3, bottom: 3 });
            Text.onClick(() => {
                this.configApiKey();
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/AiRecognize.ets(132:7)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.layoutWeight(1);
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.debugLine("entry/src/main/ets/pages/AiRecognize.ets(133:9)", "entry");
            Column.width('100%');
            Column.padding(14);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 说明卡
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/AiRecognize.ets(135:11)", "entry");
            // 说明卡
            Column.width('100%');
            // 说明卡
            Column.padding(20);
            // 说明卡
            Column.borderRadius(16);
            // 说明卡
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('识');
            Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(136:13)", "entry");
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
            Text.create('拍下你的低碳行为');
            Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(145:13)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('AI 自动识别行为类型并估算数值，一键录入减排数据');
            Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(148:13)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.textAlign(TextAlign.Center);
        }, Text);
        Text.pop();
        // 说明卡
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/AiRecognize.ets(158:11)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel(this.recognizing ? '识别中…' : '📷 拍照识别');
            Button.debugLine("entry/src/main/ets/pages/AiRecognize.ets(159:13)", "entry");
            Button.layoutWeight(1);
            Button.height(46);
            Button.fontSize(15);
            Button.backgroundColor(Theme.PRIMARY);
            Button.enabled(!this.recognizing);
            Button.onClick(() => {
                this.shootAndRecognize();
            });
        }, Button);
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('🖼 从相册选择');
            Button.debugLine("entry/src/main/ets/pages/AiRecognize.ets(168:13)", "entry");
            Button.layoutWeight(1);
            Button.height(46);
            Button.fontSize(15);
            Button.backgroundColor(Theme.PRIMARY_HOVER);
            Button.enabled(!this.recognizing);
            Button.onClick(() => {
                this.pickAndRecognize();
            });
        }, Button);
        Button.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 识别结果
            if (this.guess !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 12 });
                        Column.debugLine("entry/src/main/ets/pages/AiRecognize.ets(182:13)", "entry");
                        Column.width('100%');
                        Column.padding(14);
                        Column.borderRadius(16);
                        Column.backgroundColor(Theme.CARD);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/AiRecognize.ets(183:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('识别结果');
                        Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(184:17)", "entry");
                        Text.fontSize(15);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/AiRecognize.ets(187:17)", "entry");
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if ((this.guess as AiGuess).demo) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('离线演示');
                                    Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(189:19)", "entry");
                                    Text.fontSize(10);
                                    Text.fontColor(Theme.WARN);
                                    Text.border({ width: 1, color: Theme.WARN, radius: 8 });
                                    Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('AI 在线识别');
                                    Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(195:19)", "entry");
                                    Text.fontSize(10);
                                    Text.fontColor(Theme.PRIMARY);
                                    Text.border({ width: 1, color: Theme.PRIMARY, radius: 8 });
                                    Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                                }, Text);
                                Text.pop();
                            });
                        }
                    }, If);
                    If.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 12 });
                        Row.debugLine("entry/src/main/ets/pages/AiRecognize.ets(204:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('AI');
                        Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(205:17)", "entry");
                        Text.fontSize(13);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.PRIMARY);
                        Text.width(36);
                        Text.height(36);
                        Text.textAlign(TextAlign.Center);
                        Text.backgroundColor(Theme.PRIMARY_BG);
                        Text.borderRadius(18);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 4 });
                        Column.debugLine("entry/src/main/ets/pages/AiRecognize.ets(214:17)", "entry");
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${(this.guess as AiGuess).type} · ${(this.guess as AiGuess).subType}`);
                        Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(215:19)", "entry");
                        Text.fontSize(17);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`预估数值：${(this.guess as AiGuess).value} ${(this.guess as AiGuess).unit}`);
                        Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(218:19)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/AiRecognize.ets(227:15)", "entry");
                        Row.width('100%');
                        Row.padding(10);
                        Row.borderRadius(10);
                        Row.backgroundColor(Theme.PRIMARY_BG);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`预计减排 ${DateUtil.gramsToKg(this.estimateG)} kg CO₂e · ≈ +${this.estimatePts} 积分`);
                        Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(228:17)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(Theme.REDUCE);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.guess as AiGuess).raw);
                        Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(237:15)", "entry");
                        Text.fontSize(10);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                        Text.maxLines(2);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 12 });
                        Row.debugLine("entry/src/main/ets/pages/AiRecognize.ets(242:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('重新识别');
                        Button.debugLine("entry/src/main/ets/pages/AiRecognize.ets(243:17)", "entry");
                        Button.layoutWeight(1);
                        Button.height(42);
                        Button.fontSize(14);
                        Button.backgroundColor(Theme.TEXT_TERTIARY);
                        Button.onClick(() => {
                            this.guess = null;
                        });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.submitting ? '录入中…' : '确认录入');
                        Button.debugLine("entry/src/main/ets/pages/AiRecognize.ets(251:17)", "entry");
                        Button.layoutWeight(1);
                        Button.height(42);
                        Button.fontSize(14);
                        Button.backgroundColor(Theme.PRIMARY);
                        Button.onClick(() => {
                            this.submit();
                        });
                    }, Button);
                    Button.pop();
                    Row.pop();
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
            Text.create('说明：在「我的 > 服务配置」中填入视觉模型 API Key 即可启用在线识别；未配置时使用离线演示识别，链路完整可演示。');
            Text.debugLine("entry/src/main/ets/pages/AiRecognize.ets(268:11)", "entry");
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
        return "AiRecognize";
    }
}
registerNamedRoute(() => new AiRecognize(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/AiRecognize", pageFullPath: "entry/src/main/ets/pages/AiRecognize", integratedHsp: "false", moduleType: "followWithHap" });
