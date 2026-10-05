if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface BehaviorPicker_Params {
    categories?: BehaviorCategory[];
    selType?: string;
    selSub?: string;
    catIndex?: number;
}
import type { BehaviorCategory, SubType } from '../model/Models';
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
export class BehaviorPicker extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__categories = new SynchedPropertyObjectOneWayPU(params.categories, this, "categories");
        this.__selType = new SynchedPropertySimpleTwoWayPU(params.selType, this, "selType");
        this.__selSub = new SynchedPropertySimpleTwoWayPU(params.selSub, this, "selSub");
        this.__catIndex = new ObservedPropertySimplePU(0, this, "catIndex");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: BehaviorPicker_Params) {
        if (params.categories === undefined) {
            this.__categories.set([]);
        }
        if (params.catIndex !== undefined) {
            this.catIndex = params.catIndex;
        }
    }
    updateStateVars(params: BehaviorPicker_Params) {
        this.__categories.reset(params.categories);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__categories.purgeDependencyOnElmtId(rmElmtId);
        this.__selType.purgeDependencyOnElmtId(rmElmtId);
        this.__selSub.purgeDependencyOnElmtId(rmElmtId);
        this.__catIndex.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__categories.aboutToBeDeleted();
        this.__selType.aboutToBeDeleted();
        this.__selSub.aboutToBeDeleted();
        this.__catIndex.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __categories: SynchedPropertySimpleOneWayPU<BehaviorCategory[]>;
    get categories() {
        return this.__categories.get();
    }
    set categories(newValue: BehaviorCategory[]) {
        this.__categories.set(newValue);
    }
    private __selType: SynchedPropertySimpleTwoWayPU<string>;
    get selType() {
        return this.__selType.get();
    }
    set selType(newValue: string) {
        this.__selType.set(newValue);
    }
    private __selSub: SynchedPropertySimpleTwoWayPU<string>;
    get selSub() {
        return this.__selSub.get();
    }
    set selSub(newValue: string) {
        this.__selSub.set(newValue);
    }
    private __catIndex: ObservedPropertySimplePU<number>;
    get catIndex() {
        return this.__catIndex.get();
    }
    set catIndex(newValue: number) {
        this.__catIndex.set(newValue);
    }
    aboutToAppear(): void {
        this.syncCatIndex();
    }
    private syncCatIndex(): void {
        for (let i = 0; i < this.categories.length; i++) {
            if (this.categories[i].name === this.selType) {
                this.catIndex = i;
                break;
            }
        }
    }
    private subList(): SubType[] {
        this.syncCatIndex();
        if (this.catIndex < 0 || this.catIndex >= this.categories.length) {
            return [];
        }
        return this.categories[this.catIndex].subTypes;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/components/BehaviorPicker.ets(33:5)", "entry");
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/components/BehaviorPicker.ets(34:7)", "entry");
            Row.width('100%');
            Row.justifyContent(FlexAlign.SpaceBetween);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, idx: number) => {
                const cat = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(cat.name);
                    Text.debugLine("entry/src/main/ets/components/BehaviorPicker.ets(36:11)", "entry");
                    Text.fontSize(14);
                    Text.fontColor(idx === this.catIndex ? '#FFFFFF' : Theme.TEXT);
                    Text.backgroundColor(idx === this.catIndex ? Theme.PRIMARY : Theme.CARD);
                    Text.borderRadius(18);
                    Text.padding({ left: 12, right: 12, top: 8, bottom: 8 });
                    Text.onClick(() => {
                        this.catIndex = idx;
                        this.selType = this.categories[idx].name;
                        if (this.subList().length > 0) {
                            this.selSub = this.subList()[0].name;
                        }
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.categories, forEachItemGenFunction, (cat: BehaviorCategory) => cat.name, true, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start });
            Flex.debugLine("entry/src/main/ets/components/BehaviorPicker.ets(54:7)", "entry");
            Flex.width('100%');
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const sub = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(sub.name);
                    Text.debugLine("entry/src/main/ets/components/BehaviorPicker.ets(56:11)", "entry");
                    Text.fontSize(13);
                    Text.fontColor(this.selSub === sub.name && this.selType === this.categories[this.catIndex].name
                        ? '#FFFFFF' : Theme.TEXT);
                    Text.width('23.5%');
                    Text.margin({ right: '1.5%', bottom: 8 });
                    Text.padding({ top: 12, bottom: 12 });
                    Text.textAlign(TextAlign.Center);
                    Text.borderRadius(10);
                    Text.backgroundColor(this.selSub === sub.name && this.selType === this.categories[this.catIndex].name
                        ? Theme.PRIMARY : Theme.CARD);
                    Text.border({ width: 1, color: this.selSub === sub.name && this.selType === this.categories[this.catIndex].name
                            ? Theme.PRIMARY : Theme.DIVIDER });
                    Text.onClick(() => {
                        this.selType = this.categories[this.catIndex].name;
                        this.selSub = sub.name;
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.subList(), forEachItemGenFunction, (sub: SubType) => sub.name, false, false);
        }, ForEach);
        ForEach.pop();
        Flex.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
        this.__selType.resetSource(params.selType);
        this.__selSub.resetSource(params.selSub);
    }
}
