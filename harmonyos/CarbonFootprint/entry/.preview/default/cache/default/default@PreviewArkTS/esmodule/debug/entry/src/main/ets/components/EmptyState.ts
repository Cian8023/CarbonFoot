if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface EmptyState_Params {
    icon?: string;
    title?: string;
    desc?: string;
    buttonText?: string;
    onButton?: () => void;
}
export class EmptyState extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.icon = '';
        this.title = '暂无数据';
        this.desc = '';
        this.buttonText = '';
        this.onButton = () => { };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: EmptyState_Params) {
        if (params.icon !== undefined) {
            this.icon = params.icon;
        }
        if (params.title !== undefined) {
            this.title = params.title;
        }
        if (params.desc !== undefined) {
            this.desc = params.desc;
        }
        if (params.buttonText !== undefined) {
            this.buttonText = params.buttonText;
        }
        if (params.onButton !== undefined) {
            this.onButton = params.onButton;
        }
    }
    updateStateVars(params: EmptyState_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
    }
    aboutToBeDeleted() {
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private icon: string;
    private title: string;
    private desc: string;
    private buttonText: string;
    private onButton: () => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/components/EmptyState.ets(10:5)", "entry");
            Column.width('100%');
            Column.padding({ top: 48, bottom: 48, left: 24, right: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.icon !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.icon);
                        Text.debugLine("entry/src/main/ets/components/EmptyState.ets(12:9)", "entry");
                        Text.fontSize(52);
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
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.title);
            Text.debugLine("entry/src/main/ets/components/EmptyState.ets(15:7)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor('#1F2933');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.desc !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.desc);
                        Text.debugLine("entry/src/main/ets/components/EmptyState.ets(20:9)", "entry");
                        Text.fontSize(13);
                        Text.fontColor('#7A8B99');
                        Text.textAlign(TextAlign.Center);
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
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.buttonText !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.buttonText);
                        Button.debugLine("entry/src/main/ets/components/EmptyState.ets(26:9)", "entry");
                        Button.backgroundColor('#2E7D32');
                        Button.fontSize(14);
                        Button.onClick(() => {
                            this.onButton();
                        });
                    }, Button);
                    Button.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
