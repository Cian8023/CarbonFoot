if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface RecordView_Params {
    tick?: number;
    categories?: BehaviorCategory[];
    selType?: string;
    selSub?: string;
    valueText?: string;
    noteText?: string;
    customTs?: number;
    submitting?: boolean;
    showUnlock?: boolean;
    unlockBadges?: string[];
}
import promptAction from "@ohos:promptAction";
import router from "@ohos:router";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants, gotoTab } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import type { BehaviorCategory, SubType } from '../model/Models';
import { CalculationService } from "@normalized:N&&&entry/src/main/ets/service/CalculationService&";
import { BehaviorService } from "@normalized:N&&&entry/src/main/ets/service/BehaviorService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
import { BehaviorPicker } from "@normalized:N&&&entry/src/main/ets/components/BehaviorPicker&";
import { BadgeUnlockOverlay } from "@normalized:N&&&entry/src/main/ets/components/BadgeUnlock&";
export class RecordView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__tick = this.createStorageLink('tick', 0, "tick");
        this.__categories = new ObservedPropertyObjectPU([], this, "categories");
        this.__selType = new ObservedPropertySimplePU('', this, "selType");
        this.__selSub = new ObservedPropertySimplePU('', this, "selSub");
        this.__valueText = new ObservedPropertySimplePU('', this, "valueText");
        this.__noteText = new ObservedPropertySimplePU('', this, "noteText");
        this.__customTs = new ObservedPropertySimplePU(0, this, "customTs");
        this.__submitting = new ObservedPropertySimplePU(false, this, "submitting");
        this.__showUnlock = new ObservedPropertySimplePU(false, this, "showUnlock");
        this.__unlockBadges = new ObservedPropertyObjectPU([], this, "unlockBadges");
        this.setInitiallyProvidedValue(params);
        this.declareWatch("tick", this.onDataTick);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: RecordView_Params) {
        if (params.categories !== undefined) {
            this.categories = params.categories;
        }
        if (params.selType !== undefined) {
            this.selType = params.selType;
        }
        if (params.selSub !== undefined) {
            this.selSub = params.selSub;
        }
        if (params.valueText !== undefined) {
            this.valueText = params.valueText;
        }
        if (params.noteText !== undefined) {
            this.noteText = params.noteText;
        }
        if (params.customTs !== undefined) {
            this.customTs = params.customTs;
        }
        if (params.submitting !== undefined) {
            this.submitting = params.submitting;
        }
        if (params.showUnlock !== undefined) {
            this.showUnlock = params.showUnlock;
        }
        if (params.unlockBadges !== undefined) {
            this.unlockBadges = params.unlockBadges;
        }
    }
    updateStateVars(params: RecordView_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__tick.purgeDependencyOnElmtId(rmElmtId);
        this.__categories.purgeDependencyOnElmtId(rmElmtId);
        this.__selType.purgeDependencyOnElmtId(rmElmtId);
        this.__selSub.purgeDependencyOnElmtId(rmElmtId);
        this.__valueText.purgeDependencyOnElmtId(rmElmtId);
        this.__noteText.purgeDependencyOnElmtId(rmElmtId);
        this.__customTs.purgeDependencyOnElmtId(rmElmtId);
        this.__submitting.purgeDependencyOnElmtId(rmElmtId);
        this.__showUnlock.purgeDependencyOnElmtId(rmElmtId);
        this.__unlockBadges.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__tick.aboutToBeDeleted();
        this.__categories.aboutToBeDeleted();
        this.__selType.aboutToBeDeleted();
        this.__selSub.aboutToBeDeleted();
        this.__valueText.aboutToBeDeleted();
        this.__noteText.aboutToBeDeleted();
        this.__customTs.aboutToBeDeleted();
        this.__submitting.aboutToBeDeleted();
        this.__showUnlock.aboutToBeDeleted();
        this.__unlockBadges.aboutToBeDeleted();
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
    private __categories: ObservedPropertyObjectPU<BehaviorCategory[]>;
    get categories() {
        return this.__categories.get();
    }
    set categories(newValue: BehaviorCategory[]) {
        this.__categories.set(newValue);
    }
    private __selType: ObservedPropertySimplePU<string>;
    get selType() {
        return this.__selType.get();
    }
    set selType(newValue: string) {
        this.__selType.set(newValue);
    }
    private __selSub: ObservedPropertySimplePU<string>;
    get selSub() {
        return this.__selSub.get();
    }
    set selSub(newValue: string) {
        this.__selSub.set(newValue);
    }
    private __valueText: ObservedPropertySimplePU<string>;
    get valueText() {
        return this.__valueText.get();
    }
    set valueText(newValue: string) {
        this.__valueText.set(newValue);
    }
    private __noteText: ObservedPropertySimplePU<string>;
    get noteText() {
        return this.__noteText.get();
    }
    set noteText(newValue: string) {
        this.__noteText.set(newValue);
    }
    private __customTs: ObservedPropertySimplePU<number>;
    get customTs() {
        return this.__customTs.get();
    }
    set customTs(newValue: number) {
        this.__customTs.set(newValue);
    }
    private __submitting: ObservedPropertySimplePU<boolean>;
    get submitting() {
        return this.__submitting.get();
    }
    set submitting(newValue: boolean) {
        this.__submitting.set(newValue);
    }
    private __showUnlock: ObservedPropertySimplePU<boolean>;
    get showUnlock() {
        return this.__showUnlock.get();
    }
    set showUnlock(newValue: boolean) {
        this.__showUnlock.set(newValue);
    }
    private __unlockBadges: ObservedPropertyObjectPU<string[]>;
    get unlockBadges() {
        return this.__unlockBadges.get();
    }
    set unlockBadges(newValue: string[]) {
        this.__unlockBadges.set(newValue);
    }
    aboutToAppear(): void {
        this.initData();
    }
    onDataTick(): void {
    }
    private async initData(): Promise<void> {
        try {
            await AppInit.ensure();
            this.categories = CalculationService.getCategories();
            if (this.categories.length > 0 && this.selSub === '') {
                this.selType = this.categories[0].name;
                this.selSub = this.categories[0].subTypes[0].name;
            }
        }
        catch (e) {
            console.error('RecordView init error: ' + JSON.stringify(e));
        }
    }
    private currentSub(): SubType | null {
        return CalculationService.findSub(this.selType, this.selSub);
    }
    private unitLabel(): string {
        const sub = this.currentSub();
        return sub !== null ? sub.unit : '-';
    }
    private maxLabel(): string {
        const sub = this.currentSub();
        return sub !== null ? '' + sub.max : '-';
    }
    private subNote(): string {
        const sub = this.currentSub();
        if (sub === null || sub.note === undefined) {
            return '';
        }
        return sub.note;
    }
    private parseValue(): number {
        const v = parseFloat(this.valueText);
        return isFinite(v) ? v : 0;
    }
    private validateValue(): string {
        const sub = this.currentSub();
        if (sub === null) {
            return '请先选择行为类型';
        }
        const v = this.parseValue();
        if (v <= 0) {
            return `请输入大于 0 的${sub.unit}数`;
        }
        if (v > sub.max) {
            return `超出上限：单次最多 ${sub.max} ${sub.unit}`;
        }
        return '';
    }
    private estimateG(): number {
        if (this.validateValue() !== '') {
            return 0;
        }
        return CalculationService.calculate(this.selType, this.selSub, this.parseValue());
    }
    private timeLabel(): string {
        const ts = this.customTs > 0 ? this.customTs : Date.now();
        return DateUtil.formatFull(ts);
    }
    private showTimePicker(): void {
        const base = this.customTs > 0 ? this.customTs : Date.now();
        const d = new Date(base);
        TimePickerDialog.show({
            selected: d,
            useMilitaryTime: true,
            onAccept: (value: TimePickerResult) => {
                const ts = DateUtil.startOfDay(Date.now()) +
                    value.hour * 3600000 + value.minute * 60000;
                if (ts > Date.now()) {
                    promptAction.showToast({ message: '不能选择未来的时间哦' });
                    return;
                }
                this.customTs = ts;
            }
        });
    }
    private async submit(): Promise<void> {
        const err = this.validateValue();
        if (err !== '') {
            promptAction.showToast({ message: err });
            return;
        }
        if (this.noteText.length > 100) {
            promptAction.showToast({ message: '备注不能超过 100 字' });
            return;
        }
        const ts = this.customTs > 0 ? this.customTs : Date.now();
        if (ts > Date.now()) {
            promptAction.showToast({ message: '时间不能晚于当前时刻' });
            return;
        }
        const sub = this.currentSub();
        if (sub === null) {
            return;
        }
        this.submitting = true;
        try {
            const result = await BehaviorService.submit(this.selType, this.selSub, this.parseValue(), sub.unit, sub.factor, ts, this.noteText);
            const msg = `记录成功！减排 ${(result.grams / 1000).toFixed(2)} kg，+${result.points} 积分`;
            promptAction.showToast({ message: msg, duration: 2500 });
            if (result.newBadges.length > 0) {
                // 勋章解锁全屏动画（替代原 Toast 文字提示）
                this.unlockBadges = result.newBadges;
                this.showUnlock = true;
            }
            // 重置表单
            this.valueText = '';
            this.noteText = '';
            this.customTs = 0;
            // 跳转积分流水
            AppStorage.setOrCreate('tasksSegment', 1);
            gotoTab(Constants.TAB_TASKS);
        }
        catch (e) {
            promptAction.showToast({ message: '保存失败，请重试' });
        }
        finally {
            this.submitting = false;
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("entry/src/main/ets/pages/Record.ets(163:5)", "entry");
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/Record.ets(164:5)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.debugLine("entry/src/main/ets/pages/Record.ets(165:7)", "entry");
            Column.width('100%');
            Column.padding(14);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Record.ets(166:9)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('低碳行为录入');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(167:11)", "entry");
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Record.ets(170:11)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('拍照识别');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(171:11)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.PRIMARY);
            Text.border({ width: 1, color: Theme.PRIMARY, radius: 14 });
            Text.padding({ left: 12, right: 12, top: 5, bottom: 5 });
            Text.onClick(() => {
                router.pushUrl({ url: 'pages/AiRecognize' });
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 1. 行为选择
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Record.ets(183:9)", "entry");
            // 1. 行为选择
            Column.width('100%');
            // 1. 行为选择
            Column.padding(14);
            // 1. 行为选择
            Column.borderRadius(16);
            // 1. 行为选择
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('选择行为');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(184:11)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.width('100%');
        }, Text);
        Text.pop();
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new BehaviorPicker(this, { categories: this.categories, selType: this.__selType, selSub: this.__selSub }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Record.ets", line: 188, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            categories: this.categories,
                            selType: this.__selType,
                            selSub: this.__selSub
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        categories: this.categories
                    });
                }
            }, { name: "BehaviorPicker" });
        }
        // 1. 行为选择
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 2. 数值输入
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Record.ets(196:9)", "entry");
            // 2. 数值输入
            Column.width('100%');
            // 2. 数值输入
            Column.padding(14);
            // 2. 数值输入
            Column.borderRadius(16);
            // 2. 数值输入
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('输入数值');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(197:11)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Record.ets(201:11)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '请输入数值', text: this.valueText });
            TextInput.debugLine("entry/src/main/ets/pages/Record.ets(202:13)", "entry");
            TextInput.type(InputType.NUMBER_DECIMAL);
            TextInput.layoutWeight(1);
            TextInput.height(44);
            TextInput.onChange((v: string) => {
                this.valueText = v;
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.unitLabel());
            Text.debugLine("entry/src/main/ets/pages/Record.ets(209:13)", "entry");
            Text.fontSize(15);
            Text.fontColor(Theme.TEXT);
            Text.width(40);
            Text.textAlign(TextAlign.Center);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Record.ets(217:11)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`上限：${this.maxLabel()} ${this.unitLabel()}`);
            Text.debugLine("entry/src/main/ets/pages/Record.ets(218:13)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Record.ets(221:13)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.subNote());
            Text.debugLine("entry/src/main/ets/pages/Record.ets(222:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.textAlign(TextAlign.End);
            Text.maxLines(2);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        Row.pop();
        // 2. 数值输入
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 3. 实时减排反馈
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/Record.ets(237:9)", "entry");
            // 3. 实时减排反馈
            Column.width('100%');
            // 3. 实时减排反馈
            Column.padding(16);
            // 3. 实时减排反馈
            Column.borderRadius(Theme.R_MEDIUM);
            // 3. 实时减排反馈
            Column.backgroundColor(Theme.PRIMARY_BG);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('预计减排量');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(238:11)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Record.ets(242:11)", "entry");
            Row.width('100%');
            Row.alignItems(VerticalAlign.Bottom);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 4 });
            Row.debugLine("entry/src/main/ets/pages/Record.ets(243:13)", "entry");
            Row.alignItems(VerticalAlign.Bottom);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.estimateG() > 0 ? (this.estimateG() / 1000).toFixed(3) : '0.000');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(244:15)", "entry");
            Text.fontSize(34);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.PRIMARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('kg CO₂e');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(248:15)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Record.ets(254:13)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.estimateG() > 0 ? `预计 +${Math.max(1, Math.floor(this.estimateG() / 100))} 积分` : '输入数值后实时计算');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(255:13)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
        // 3. 实时减排反馈
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 4. 时间 + 备注
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Record.ets(268:9)", "entry");
            // 4. 时间 + 备注
            Column.width('100%');
            // 4. 时间 + 备注
            Column.padding(14);
            // 4. 时间 + 备注
            Column.borderRadius(16);
            // 4. 时间 + 备注
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Record.ets(269:11)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('行为时间');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(270:13)", "entry");
            Text.fontSize(14);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Record.ets(273:13)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.timeLabel());
            Text.debugLine("entry/src/main/ets/pages/Record.ets(274:13)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('  修改');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(277:13)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.PRIMARY);
            Text.onClick(() => {
                this.showTimePicker();
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Record.ets(286:11)", "entry");
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Record.ets(288:11)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('备注');
            Text.debugLine("entry/src/main/ets/pages/Record.ets(289:13)", "entry");
            Text.fontSize(14);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '选填，≤100 字', text: this.noteText });
            TextInput.debugLine("entry/src/main/ets/pages/Record.ets(292:13)", "entry");
            TextInput.layoutWeight(1);
            TextInput.height(40);
            TextInput.onChange((v: string) => {
                this.noteText = v;
            });
        }, TextInput);
        Row.pop();
        // 4. 时间 + 备注
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel(this.submitting ? '保存中…' : '提交记录');
            Button.debugLine("entry/src/main/ets/pages/Record.ets(306:9)", "entry");
            Button.width('100%');
            Button.height(46);
            Button.fontSize(16);
            Button.backgroundColor(Theme.PRIMARY);
            Button.enabled(!this.submitting);
            Button.onClick(() => {
                this.submit();
            });
        }, Button);
        Button.pop();
        Column.pop();
        Scroll.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 勋章解锁动画层（置顶）
            if (this.showUnlock) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new BadgeUnlockOverlay(this, {
                                    badges: this.unlockBadges,
                                    onClose: (): void => {
                                        this.showUnlock = false;
                                    }
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Record.ets", line: 326, col: 7 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        badges: this.unlockBadges,
                                        onClose: (): void => {
                                            this.showUnlock = false;
                                        }
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    badges: this.unlockBadges
                                });
                            }
                        }, { name: "BadgeUnlockOverlay" });
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Stack.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
