if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Knowledge_Params {
    articles?: Article[];
    category?: string;
    readIds?: number[];
}
import router from "@ohos:router";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import type { Article } from '../model/Models';
import { KnowledgeService } from "@normalized:N&&&entry/src/main/ets/service/KnowledgeService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
const CATEGORIES: string[] = ['全部', '政策解读', '生活技巧', '行业动态'];
class Knowledge extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__articles = new ObservedPropertyObjectPU([], this, "articles");
        this.__category = new ObservedPropertySimplePU('全部', this, "category");
        this.__readIds = new ObservedPropertyObjectPU([], this, "readIds");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Knowledge_Params) {
        if (params.articles !== undefined) {
            this.articles = params.articles;
        }
        if (params.category !== undefined) {
            this.category = params.category;
        }
        if (params.readIds !== undefined) {
            this.readIds = params.readIds;
        }
    }
    updateStateVars(params: Knowledge_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__articles.purgeDependencyOnElmtId(rmElmtId);
        this.__category.purgeDependencyOnElmtId(rmElmtId);
        this.__readIds.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__articles.aboutToBeDeleted();
        this.__category.aboutToBeDeleted();
        this.__readIds.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __articles: ObservedPropertyObjectPU<Article[]>;
    get articles() {
        return this.__articles.get();
    }
    set articles(newValue: Article[]) {
        this.__articles.set(newValue);
    }
    private __category: ObservedPropertySimplePU<string>;
    get category() {
        return this.__category.get();
    }
    set category(newValue: string) {
        this.__category.set(newValue);
    }
    private __readIds: ObservedPropertyObjectPU<number[]>;
    get readIds() {
        return this.__readIds.get();
    }
    set readIds(newValue: number[]) {
        this.__readIds.set(newValue);
    }
    aboutToAppear(): void {
        this.refresh();
    }
    async refresh(): Promise<void> {
        try {
            await AppInit.ensure();
            this.articles = KnowledgeService.list(this.category);
            const ids: number[] = [];
            for (const a of KnowledgeService.list('全部')) {
                if (await PointsService.hasSourceRef('read', a.id)) {
                    ids.push(a.id);
                }
            }
            this.readIds = ids;
        }
        catch (e) {
            console.error('Knowledge refresh error: ' + JSON.stringify(e));
        }
    }
    private isRead(id: number): boolean {
        return this.readIds.indexOf(id) >= 0;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Knowledge.ets(43:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(Theme.BG);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Knowledge.ets(44:7)", "entry");
            Row.width('100%');
            Row.padding({ left: 14, right: 14, top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(45:9)", "entry");
            Text.fontSize(22);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Knowledge.ets(50:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('双碳科普专栏');
            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(51:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Knowledge.ets(54:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('');
            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(55:9)", "entry");
            Text.width(22);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 分类筛选
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/Knowledge.ets(62:7)", "entry");
            // 分类筛选
            Row.width('100%');
            // 分类筛选
            Row.padding({ left: 14, right: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const c = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(c);
                    Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(64:11)", "entry");
                    Text.fontSize(12);
                    Text.fontColor(this.category === c ? '#FFFFFF' : Theme.TEXT);
                    Text.backgroundColor(this.category === c ? Theme.PRIMARY : Theme.CARD);
                    Text.borderRadius(14);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.onClick(() => {
                        this.category = c;
                        this.refresh();
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, CATEGORIES, forEachItemGenFunction, (c: string) => c, false, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Knowledge.ets(75:9)", "entry");
        }, Blank);
        Blank.pop();
        // 分类筛选
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 阅读统计
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/Knowledge.ets(81:7)", "entry");
            // 阅读统计
            Row.width('100%');
            // 阅读统计
            Row.padding({ left: 16, right: 16, top: 10, bottom: 10 });
            // 阅读统计
            Row.borderRadius(Theme.R_SMALL);
            // 阅读统计
            Row.backgroundColor(Theme.CARD);
            // 阅读统计
            Row.border({ width: 1, color: Theme.DIVIDER });
            // 阅读统计
            Row.margin({ left: 14, right: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`已读 ${this.readIds.length}/${KnowledgeService.list('全部').length} 篇`);
            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(82:9)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`阅读积分 +${this.readIds.length * 5}`);
            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(85:9)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.POINTS);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Knowledge.ets(88:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('连续阅读可解锁「博学环保人」徽章');
            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(89:9)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        // 阅读统计
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            List.create({ space: 10 });
            List.debugLine("entry/src/main/ets/pages/Knowledge.ets(100:7)", "entry");
            List.layoutWeight(1);
            List.width('100%');
            List.padding({ left: 14, right: 14, bottom: 14 });
        }, List);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const a = _item;
                {
                    const itemCreation = (elmtId, isInitialRender) => {
                        ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                        ListItem.create(deepRenderFunction, true);
                        if (!isInitialRender) {
                            ListItem.pop();
                        }
                        ViewStackProcessor.StopGetAccessRecording();
                    };
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        ListItem.create(deepRenderFunction, true);
                        ListItem.debugLine("entry/src/main/ets/pages/Knowledge.ets(102:11)", "entry");
                    };
                    const deepRenderFunction = (elmtId, isInitialRender) => {
                        itemCreation(elmtId, isInitialRender);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Row.create({ space: 12 });
                            Row.debugLine("entry/src/main/ets/pages/Knowledge.ets(103:13)", "entry");
                            Row.width('100%');
                            Row.padding(12);
                            Row.borderRadius(Theme.R_SMALL);
                            Row.backgroundColor(Theme.CARD);
                            Row.border({ width: 1, color: Theme.DIVIDER });
                            Row.onClick(() => {
                                router.pushUrl({ url: 'pages/KnowledgeDetail', params: { id: a.id } });
                            });
                        }, Row);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.debugLine("entry/src/main/ets/pages/Knowledge.ets(104:15)", "entry");
                            Column.width(3);
                            Column.height(44);
                            Column.borderRadius(2);
                            Column.backgroundColor(Theme.PRIMARY_HOVER);
                        }, Column);
                        Column.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create({ space: 5 });
                            Column.debugLine("entry/src/main/ets/pages/Knowledge.ets(109:15)", "entry");
                            Column.alignItems(HorizontalAlign.Start);
                            Column.layoutWeight(1);
                        }, Column);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(a.title);
                            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(110:17)", "entry");
                            Text.fontSize(15);
                            Text.fontWeight(FontWeight.Medium);
                            Text.maxLines(2);
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(a.summary);
                            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(114:17)", "entry");
                            Text.fontSize(12);
                            Text.fontColor(Theme.TEXT_TERTIARY);
                            Text.maxLines(2);
                            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Row.create({ space: 8 });
                            Row.debugLine("entry/src/main/ets/pages/Knowledge.ets(119:17)", "entry");
                        }, Row);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(a.category);
                            Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(120:19)", "entry");
                            Text.fontSize(10);
                            Text.fontColor(Theme.PRIMARY);
                            Text.backgroundColor(Theme.PRIMARY_BG);
                            Text.borderRadius(8);
                            Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            If.create();
                            if (this.isRead(a.id)) {
                                this.ifElseBranchUpdateFunction(0, () => {
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create('已读 +5 分');
                                        Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(127:21)", "entry");
                                        Text.fontSize(10);
                                        Text.fontColor(Theme.TEXT_TERTIARY);
                                    }, Text);
                                    Text.pop();
                                });
                            }
                            else {
                                this.ifElseBranchUpdateFunction(1, () => {
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create('阅读得 5 分 >');
                                        Text.debugLine("entry/src/main/ets/pages/Knowledge.ets(131:21)", "entry");
                                        Text.fontSize(10);
                                        Text.fontColor(Theme.POINTS);
                                    }, Text);
                                    Text.pop();
                                });
                            }
                        }, If);
                        If.pop();
                        Row.pop();
                        Column.pop();
                        Row.pop();
                        ListItem.pop();
                    };
                    this.observeComponentCreation2(itemCreation2, ListItem);
                    ListItem.pop();
                }
            };
            this.forEachUpdateFunction(elmtId, this.articles, forEachItemGenFunction, (a: Article) => '' + a.id + '_' + (this.isRead(a.id) ? 'r' : 'n'), false, false);
        }, ForEach);
        ForEach.pop();
        List.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
    static getEntryName(): string {
        return "Knowledge";
    }
}
registerNamedRoute(() => new Knowledge(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/Knowledge", pageFullPath: "entry/src/main/ets/pages/Knowledge", integratedHsp: "false", moduleType: "followWithHap" });
