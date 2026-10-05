if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface BadgeUnlockOverlay_Params {
    badges?: string[];
    onClose?: () => void;
    badgeScale?: number;
    glowScale?: number;
    glowOpacity?: number;
    textOpacity?: number;
}
export class BadgeUnlockOverlay extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__badges = new SynchedPropertyObjectOneWayPU(params.badges, this, "badges");
        this.onClose = (): void => {
        };
        this.__badgeScale = new ObservedPropertySimplePU(0.2, this, "badgeScale");
        this.__glowScale = new ObservedPropertySimplePU(0.5, this, "glowScale");
        this.__glowOpacity = new ObservedPropertySimplePU(0, this, "glowOpacity");
        this.__textOpacity = new ObservedPropertySimplePU(0, this, "textOpacity");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: BadgeUnlockOverlay_Params) {
        if (params.badges === undefined) {
            this.__badges.set([]);
        }
        if (params.onClose !== undefined) {
            this.onClose = params.onClose;
        }
        if (params.badgeScale !== undefined) {
            this.badgeScale = params.badgeScale;
        }
        if (params.glowScale !== undefined) {
            this.glowScale = params.glowScale;
        }
        if (params.glowOpacity !== undefined) {
            this.glowOpacity = params.glowOpacity;
        }
        if (params.textOpacity !== undefined) {
            this.textOpacity = params.textOpacity;
        }
    }
    updateStateVars(params: BadgeUnlockOverlay_Params) {
        this.__badges.reset(params.badges);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__badges.purgeDependencyOnElmtId(rmElmtId);
        this.__badgeScale.purgeDependencyOnElmtId(rmElmtId);
        this.__glowScale.purgeDependencyOnElmtId(rmElmtId);
        this.__glowOpacity.purgeDependencyOnElmtId(rmElmtId);
        this.__textOpacity.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__badges.aboutToBeDeleted();
        this.__badgeScale.aboutToBeDeleted();
        this.__glowScale.aboutToBeDeleted();
        this.__glowOpacity.aboutToBeDeleted();
        this.__textOpacity.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __badges: SynchedPropertySimpleOneWayPU<string[]>;
    get badges() {
        return this.__badges.get();
    }
    set badges(newValue: string[]) {
        this.__badges.set(newValue);
    }
    private onClose: () => void;
    private __badgeScale: ObservedPropertySimplePU<number>;
    get badgeScale() {
        return this.__badgeScale.get();
    }
    set badgeScale(newValue: number) {
        this.__badgeScale.set(newValue);
    }
    private __glowScale: ObservedPropertySimplePU<number>;
    get glowScale() {
        return this.__glowScale.get();
    }
    set glowScale(newValue: number) {
        this.__glowScale.set(newValue);
    }
    private __glowOpacity: ObservedPropertySimplePU<number>;
    get glowOpacity() {
        return this.__glowOpacity.get();
    }
    set glowOpacity(newValue: number) {
        this.__glowOpacity.set(newValue);
    }
    private __textOpacity: ObservedPropertySimplePU<number>;
    get textOpacity() {
        return this.__textOpacity.get();
    }
    set textOpacity(newValue: number) {
        this.__textOpacity.set(newValue);
    }
    aboutToAppear(): void {
        this.badgeScale = 0.2;
        this.glowScale = 0.5;
        this.glowOpacity = 0;
        this.textOpacity = 0;
        // 两段式弹出：过冲 -> 回弹
        Context.animateTo({ duration: 280, curve: Curve.EaseOut }, () => {
            this.badgeScale = 1.18;
            this.glowScale = 1;
            this.glowOpacity = 1;
        });
        setTimeout(() => {
            Context.animateTo({ duration: 180, curve: Curve.EaseInOut }, () => {
                this.badgeScale = 1;
            });
            Context.animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
                this.textOpacity = 1;
            });
        }, 280);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(38:5)", "entry");
            Stack.width('100%');
            Stack.height('100%');
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 半透明遮罩
            Column.create();
            Column.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(40:7)", "entry");
            // 半透明遮罩
            Column.width('100%');
            // 半透明遮罩
            Column.height('100%');
            // 半透明遮罩
            Column.backgroundColor('rgba(0,0,0,0.6)');
            // 半透明遮罩
            Column.onClick(() => {
                this.onClose();
            });
        }, Column);
        // 半透明遮罩
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(48:7)", "entry");
            Column.justifyContent(FlexAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 光环 + 徽章
            Stack.create();
            Stack.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(50:9)", "entry");
            // 光环 + 徽章
            Stack.scale({ x: this.badgeScale, y: this.badgeScale });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Circle.create({ width: 150, height: 150 });
            Circle.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(51:11)", "entry");
            Circle.fill('#F7BA1E');
            Circle.opacity(0.18 * this.glowOpacity);
            Circle.scale({ x: this.glowScale, y: this.glowScale });
        }, Circle);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Circle.create({ width: 116, height: 116 });
            Circle.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(55:11)", "entry");
            Circle.fill('#FFF6DC');
            Circle.opacity(this.glowOpacity);
        }, Circle);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Circle.create({ width: 96, height: 96 });
            Circle.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(58:11)", "entry");
            Circle.fill('#F7BA1E');
            Circle.opacity(0.9 * this.glowOpacity);
        }, Circle);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('🏅');
            Text.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(61:11)", "entry");
            Text.fontSize(46);
        }, Text);
        Text.pop();
        // 光环 + 徽章
        Stack.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(66:9)", "entry");
            Column.opacity(this.textOpacity);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('恭喜解锁新徽章');
            Text.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(67:11)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor('#FFFFFF');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.badges.join('、'));
            Text.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(71:11)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor('#F7BA1E');
            Text.textAlign(TextAlign.Center);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('点击任意处继续');
            Text.debugLine("entry/src/main/ets/components/BadgeUnlock.ets(79:9)", "entry");
            Text.fontSize(11);
            Text.fontColor('rgba(255,255,255,0.5)');
            Text.opacity(this.textOpacity);
        }, Text);
        Text.pop();
        Column.pop();
        Stack.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
