if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface KnowledgeDetail_Params {
    article?: Article | null;
    reachedEnd?: boolean;
    alreadyRead?: boolean;
    showUnlock?: boolean;
    unlockBadges?: string[];
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants, bumpTick } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import type { Article } from '../model/Models';
import { KnowledgeService } from "@normalized:N&&&entry/src/main/ets/service/KnowledgeService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { BadgeService } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import { BadgeUnlockOverlay } from "@normalized:N&&&entry/src/main/ets/components/BadgeUnlock&";
class KnowledgeDetail extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__article = new ObservedPropertyObjectPU(null, this, "article");
        this.__reachedEnd = new ObservedPropertySimplePU(false, this, "reachedEnd");
        this.__alreadyRead = new ObservedPropertySimplePU(false, this, "alreadyRead");
        this.__showUnlock = new ObservedPropertySimplePU(false, this, "showUnlock");
        this.__unlockBadges = new ObservedPropertyObjectPU([], this, "unlockBadges");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: KnowledgeDetail_Params) {
        if (params.article !== undefined) {
            this.article = params.article;
        }
        if (params.reachedEnd !== undefined) {
            this.reachedEnd = params.reachedEnd;
        }
        if (params.alreadyRead !== undefined) {
            this.alreadyRead = params.alreadyRead;
        }
        if (params.showUnlock !== undefined) {
            this.showUnlock = params.showUnlock;
        }
        if (params.unlockBadges !== undefined) {
            this.unlockBadges = params.unlockBadges;
        }
    }
    updateStateVars(params: KnowledgeDetail_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__article.purgeDependencyOnElmtId(rmElmtId);
        this.__reachedEnd.purgeDependencyOnElmtId(rmElmtId);
        this.__alreadyRead.purgeDependencyOnElmtId(rmElmtId);
        this.__showUnlock.purgeDependencyOnElmtId(rmElmtId);
        this.__unlockBadges.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__article.aboutToBeDeleted();
        this.__reachedEnd.aboutToBeDeleted();
        this.__alreadyRead.aboutToBeDeleted();
        this.__showUnlock.aboutToBeDeleted();
        this.__unlockBadges.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __article: ObservedPropertyObjectPU<Article | null>;
    get article() {
        return this.__article.get();
    }
    set article(newValue: Article | null) {
        this.__article.set(newValue);
    }
    private __reachedEnd: ObservedPropertySimplePU<boolean>;
    get reachedEnd() {
        return this.__reachedEnd.get();
    }
    set reachedEnd(newValue: boolean) {
        this.__reachedEnd.set(newValue);
    }
    private __alreadyRead: ObservedPropertySimplePU<boolean>;
    get alreadyRead() {
        return this.__alreadyRead.get();
    }
    set alreadyRead(newValue: boolean) {
        this.__alreadyRead.set(newValue);
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
        this.load();
    }
    private async load(): Promise<void> {
        try {
            await AppInit.ensure();
            const params = router.getParams() as Record<string, number>;
            const id = params !== undefined && params['id'] !== undefined ? params['id'] : -1;
            const a = KnowledgeService.byId(id);
            if (a !== undefined) {
                this.article = a;
            }
            this.alreadyRead = await PointsService.hasSourceRef('read', id);
        }
        catch (e) {
            console.error('KnowledgeDetail load error: ' + JSON.stringify(e));
        }
    }
    private async claimReadPoints(): Promise<void> {
        if (this.article === null) {
            return;
        }
        const a = this.article as Article;
        if (this.alreadyRead) {
            promptAction.showToast({ message: '本文已领取过阅读积分' });
            return;
        }
        if (!this.reachedEnd) {
            promptAction.showToast({ message: '请阅读到文章末尾再领取哦' });
            return;
        }
        try {
            await PointsService.addPoints('read', a.id, `阅读文章：${a.title}`, Constants.READ_POINTS);
            this.alreadyRead = true;
            bumpTick();
            promptAction.showToast({ message: `阅读完成，+${Constants.READ_POINTS} 积分！` });
            // 阅读路径同样触发徽章检测（如博学环保人），解锁时展示动画
            const newBadges: string[] = await BadgeService.checkAll();
            if (newBadges.length > 0) {
                this.unlockBadges = newBadges;
                this.showUnlock = true;
            }
        }
        catch (e) {
            promptAction.showToast({ message: '领取失败，请重试' });
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(70:5)", "entry");
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(71:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(72:7)", "entry");
            Row.width('100%');
            Row.padding({ left: 14, right: 14, top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(73:9)", "entry");
            Text.fontSize(22);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(78:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('文章详情');
            Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(79:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(82:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('');
            Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(83:9)", "entry");
            Text.width(22);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.article !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create();
                        Scroll.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(90:9)", "entry");
                        Scroll.scrollBar(BarState.Auto);
                        Scroll.layoutWeight(1);
                        Scroll.onReachEnd(() => {
                            this.reachedEnd = true;
                        });
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 16 });
                        Column.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(91:11)", "entry");
                        Column.width('100%');
                        Column.padding(16);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 10 });
                        Row.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(92:13)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(93:15)", "entry");
                        Column.width(3);
                        Column.height(44);
                        Column.borderRadius(2);
                        Column.backgroundColor(Theme.PRIMARY_HOVER);
                    }, Column);
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 6 });
                        Column.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(98:15)", "entry");
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.article as Article).title);
                        Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(99:17)", "entry");
                        Text.fontSize(20);
                        Text.fontWeight(FontWeight.Bold);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${(this.article as Article).category} · 双碳科普`);
                        Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(102:17)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const p = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(p);
                                Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(112:15)", "entry");
                                Text.fontSize(15);
                                Text.lineHeight(26);
                                Text.fontColor(Theme.TEXT);
                                Text.width('100%');
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, (this.article as Article).paragraphs, forEachItemGenFunction, (p: string, idx: number) => '' + idx + '_' + p.substring(0, 10), false, true);
                    }, ForEach);
                    ForEach.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('— 完 —');
                        Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(119:13)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                        Text.margin({ top: 10 });
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Scroll.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.alreadyRead ? '已领取阅读积分' :
                            this.reachedEnd ? '完成阅读，领 5 积分' : '继续阅读到底部可领积分…');
                        Button.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(133:9)", "entry");
                        Button.width('90%');
                        Button.height(44);
                        Button.fontSize(14);
                        Button.margin({ bottom: 12 });
                        Button.backgroundColor(this.alreadyRead ? Theme.TEXT_TERTIARY :
                            this.reachedEnd ? Theme.PRIMARY : Theme.PRIMARY_HOVER);
                        Button.onClick(() => {
                            this.claimReadPoints();
                        });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('把文中的技巧变成行动 → 去记录低碳行为');
                        Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(145:9)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                        Text.margin({ bottom: 12 });
                        Text.onClick(() => {
                            AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
                            router.back();
                        });
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 10 });
                        Column.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(154:9)", "entry");
                        Column.width('100%');
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('未找到该文章');
                        Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(155:11)", "entry");
                        Text.fontSize(14);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('文章不存在');
                        Text.debugLine("entry/src/main/ets/pages/KnowledgeDetail.ets(157:11)", "entry");
                        Text.fontSize(14);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
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
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/KnowledgeDetail.ets", line: 171, col: 7 });
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
    static getEntryName(): string {
        return "KnowledgeDetail";
    }
}
registerNamedRoute(() => new KnowledgeDetail(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/KnowledgeDetail", pageFullPath: "entry/src/main/ets/pages/KnowledgeDetail", integratedHsp: "false", moduleType: "followWithHap" });
