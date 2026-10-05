if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HomeView_Params {
    tick?: number;
    loading?: boolean;
    todayG?: number;
    balance?: number;
    pending?: number;
    streak?: number;
    trendKind?: TrendKind;
    trend?: ChartPoint[];
    pie?: PieItem[];
    pendingTasks?: TaskProgress[];
    recTasks?: TaskProgress[];
    tips?: Suggestion[];
    monthG?: number;
    monthGoalKg?: number;
    weekly?: WeeklyReport;
    cardOrder?: string[];
}
interface Index_Params {
    mainTab?: number;
    tabsController?: TabsController;
}
import router from "@ohos:router";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import type { BehaviorRecord, TaskProgress } from '../model/Models';
import { BehaviorRepo } from "@normalized:N&&&entry/src/main/ets/db/Repository&";
import { TaskService } from "@normalized:N&&&entry/src/main/ets/service/TaskService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { BadgeService } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import { StatsService } from "@normalized:N&&&entry/src/main/ets/service/StatsService&";
import type { TrendKind, WeeklyReport } from "@normalized:N&&&entry/src/main/ets/service/StatsService&";
import { RecommendService } from "@normalized:N&&&entry/src/main/ets/service/RecommendService&";
import type { Suggestion } from "@normalized:N&&&entry/src/main/ets/service/RecommendService&";
import { PrefsService, DEFAULT_HOME_LAYOUT } from "@normalized:N&&&entry/src/main/ets/common/PrefsService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
import { TrendBarChart, PieChart, GoalRing } from "@normalized:N&&&entry/src/main/ets/components/Chart&";
import type { ChartPoint, PieItem } from "@normalized:N&&&entry/src/main/ets/components/Chart&";
import { EmptyState } from "@normalized:N&&&entry/src/main/ets/components/EmptyState&";
import { RecordView } from "@normalized:N&&&entry/src/main/ets/pages/Record&";
import { HistoryView } from "@normalized:N&&&entry/src/main/ets/pages/History&";
import { TasksView } from "@normalized:N&&&entry/src/main/ets/pages/Tasks&";
import { MineView } from "@normalized:N&&&entry/src/main/ets/pages/Settings&";
class Index extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__mainTab = this.createStorageLink('mainTab', 0, "mainTab");
        this.tabsController = new TabsController();
        this.setInitiallyProvidedValue(params);
        this.declareWatch("mainTab", this.onMainTabChanged);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Index_Params) {
        if (params.tabsController !== undefined) {
            this.tabsController = params.tabsController;
        }
    }
    updateStateVars(params: Index_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__mainTab.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__mainTab.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __mainTab: ObservedPropertyAbstractPU<number>;
    get mainTab() {
        return this.__mainTab.get();
    }
    set mainTab(newValue: number) {
        this.__mainTab.set(newValue);
    }
    private tabsController: TabsController;
    onMainTabChanged(): void {
        // AppStorage 驱动切 Tab（首页快捷入口、提交后跳转等场景）
        this.tabsController.changeIndex(this.mainTab);
    }
    tabItem(label: string, icon: string, index: number, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(34:5)", "entry");
            Column.width('100%');
            Column.justifyContent(FlexAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(icon);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(35:7)", "entry");
            Text.fontSize(20);
            Text.fontColor(this.mainTab === index ? Theme.PRIMARY : Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(38:7)", "entry");
            Text.fontSize(10);
            Text.fontWeight(this.mainTab === index ? FontWeight.Medium : FontWeight.Normal);
            Text.fontColor(this.mainTab === index ? Theme.PRIMARY : Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Tabs.create({ barPosition: BarPosition.End, index: this.mainTab, controller: this.tabsController });
            Tabs.debugLine("entry/src/main/ets/pages/Index.ets(48:5)", "entry");
            Tabs.scrollable(false);
            Tabs.barHeight(60);
            Tabs.backgroundColor(Theme.BG);
            Tabs.onChange((index: number) => {
                this.mainTab = index;
            });
        }, Tabs);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new HomeView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 50, col: 9 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "HomeView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabItem.call(this, '首页', '🏠', Constants.TAB_HOME);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/Index.ets(49:7)", "entry");
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new RecordView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 55, col: 9 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "RecordView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabItem.call(this, '录入', '✏️', Constants.TAB_RECORD);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/Index.ets(54:7)", "entry");
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new HistoryView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 60, col: 9 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "HistoryView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabItem.call(this, '历史', '📜', Constants.TAB_HISTORY);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/Index.ets(59:7)", "entry");
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new TasksView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 65, col: 9 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "TasksView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabItem.call(this, '任务', '🎯', Constants.TAB_TASKS);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/Index.ets(64:7)", "entry");
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        if (isInitialRender) {
                            let componentCall = new MineView(this, {}, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 70, col: 9 });
                            ViewPU.create(componentCall);
                            let paramsLambda = () => {
                                return {};
                            };
                            componentCall.paramsGenerator_ = paramsLambda;
                        }
                        else {
                            this.updateStateVarsOfChildByElmtId(elmtId, {});
                        }
                    }, { name: "MineView" });
                }
            });
            TabContent.tabBar({ builder: () => {
                    this.tabItem.call(this, '我的', '👤', Constants.TAB_MINE);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/Index.ets(69:7)", "entry");
        }, TabContent);
        TabContent.pop();
        Tabs.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
    static getEntryName(): string {
        return "Index";
    }
}
class HomeView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__tick = this.createStorageLink('tick', 0, "tick");
        this.__loading = new ObservedPropertySimplePU(true, this, "loading");
        this.__todayG = new ObservedPropertySimplePU(0, this, "todayG");
        this.__balance = new ObservedPropertySimplePU(0, this, "balance");
        this.__pending = new ObservedPropertySimplePU(0, this, "pending");
        this.__streak = new ObservedPropertySimplePU(0, this, "streak");
        this.__trendKind = new ObservedPropertySimplePU('day7', this, "trendKind");
        this.__trend = new ObservedPropertyObjectPU([], this, "trend");
        this.__pie = new ObservedPropertyObjectPU([], this, "pie");
        this.__pendingTasks = new ObservedPropertyObjectPU([], this, "pendingTasks");
        this.__recTasks = new ObservedPropertyObjectPU([], this, "recTasks");
        this.__tips = new ObservedPropertyObjectPU([], this, "tips");
        this.__monthG = new ObservedPropertySimplePU(0, this, "monthG");
        this.__monthGoalKg = new ObservedPropertySimplePU(30, this, "monthGoalKg");
        this.__weekly = new ObservedPropertyObjectPU({
            weekG: 0, lastWeekG: 0, deltaPct: -999, topSub: '', topSubG: 0, days: 0, slogan: ''
        }, this, "weekly");
        this.__cardOrder = new ObservedPropertyObjectPU(DEFAULT_HOME_LAYOUT, this, "cardOrder");
        this.setInitiallyProvidedValue(params);
        this.declareWatch("tick", this.refresh);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HomeView_Params) {
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.todayG !== undefined) {
            this.todayG = params.todayG;
        }
        if (params.balance !== undefined) {
            this.balance = params.balance;
        }
        if (params.pending !== undefined) {
            this.pending = params.pending;
        }
        if (params.streak !== undefined) {
            this.streak = params.streak;
        }
        if (params.trendKind !== undefined) {
            this.trendKind = params.trendKind;
        }
        if (params.trend !== undefined) {
            this.trend = params.trend;
        }
        if (params.pie !== undefined) {
            this.pie = params.pie;
        }
        if (params.pendingTasks !== undefined) {
            this.pendingTasks = params.pendingTasks;
        }
        if (params.recTasks !== undefined) {
            this.recTasks = params.recTasks;
        }
        if (params.tips !== undefined) {
            this.tips = params.tips;
        }
        if (params.monthG !== undefined) {
            this.monthG = params.monthG;
        }
        if (params.monthGoalKg !== undefined) {
            this.monthGoalKg = params.monthGoalKg;
        }
        if (params.weekly !== undefined) {
            this.weekly = params.weekly;
        }
        if (params.cardOrder !== undefined) {
            this.cardOrder = params.cardOrder;
        }
    }
    updateStateVars(params: HomeView_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__tick.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
        this.__todayG.purgeDependencyOnElmtId(rmElmtId);
        this.__balance.purgeDependencyOnElmtId(rmElmtId);
        this.__pending.purgeDependencyOnElmtId(rmElmtId);
        this.__streak.purgeDependencyOnElmtId(rmElmtId);
        this.__trendKind.purgeDependencyOnElmtId(rmElmtId);
        this.__trend.purgeDependencyOnElmtId(rmElmtId);
        this.__pie.purgeDependencyOnElmtId(rmElmtId);
        this.__pendingTasks.purgeDependencyOnElmtId(rmElmtId);
        this.__recTasks.purgeDependencyOnElmtId(rmElmtId);
        this.__tips.purgeDependencyOnElmtId(rmElmtId);
        this.__monthG.purgeDependencyOnElmtId(rmElmtId);
        this.__monthGoalKg.purgeDependencyOnElmtId(rmElmtId);
        this.__weekly.purgeDependencyOnElmtId(rmElmtId);
        this.__cardOrder.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__tick.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        this.__todayG.aboutToBeDeleted();
        this.__balance.aboutToBeDeleted();
        this.__pending.aboutToBeDeleted();
        this.__streak.aboutToBeDeleted();
        this.__trendKind.aboutToBeDeleted();
        this.__trend.aboutToBeDeleted();
        this.__pie.aboutToBeDeleted();
        this.__pendingTasks.aboutToBeDeleted();
        this.__recTasks.aboutToBeDeleted();
        this.__tips.aboutToBeDeleted();
        this.__monthG.aboutToBeDeleted();
        this.__monthGoalKg.aboutToBeDeleted();
        this.__weekly.aboutToBeDeleted();
        this.__cardOrder.aboutToBeDeleted();
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
    private __loading: ObservedPropertySimplePU<boolean>;
    get loading() {
        return this.__loading.get();
    }
    set loading(newValue: boolean) {
        this.__loading.set(newValue);
    }
    private __todayG: ObservedPropertySimplePU<number>;
    get todayG() {
        return this.__todayG.get();
    }
    set todayG(newValue: number) {
        this.__todayG.set(newValue);
    }
    private __balance: ObservedPropertySimplePU<number>;
    get balance() {
        return this.__balance.get();
    }
    set balance(newValue: number) {
        this.__balance.set(newValue);
    }
    private __pending: ObservedPropertySimplePU<number>;
    get pending() {
        return this.__pending.get();
    }
    set pending(newValue: number) {
        this.__pending.set(newValue);
    }
    private __streak: ObservedPropertySimplePU<number>;
    get streak() {
        return this.__streak.get();
    }
    set streak(newValue: number) {
        this.__streak.set(newValue);
    }
    private __trendKind: ObservedPropertySimplePU<TrendKind>;
    get trendKind() {
        return this.__trendKind.get();
    }
    set trendKind(newValue: TrendKind) {
        this.__trendKind.set(newValue);
    }
    private __trend: ObservedPropertyObjectPU<ChartPoint[]>;
    get trend() {
        return this.__trend.get();
    }
    set trend(newValue: ChartPoint[]) {
        this.__trend.set(newValue);
    }
    private __pie: ObservedPropertyObjectPU<PieItem[]>;
    get pie() {
        return this.__pie.get();
    }
    set pie(newValue: PieItem[]) {
        this.__pie.set(newValue);
    }
    private __pendingTasks: ObservedPropertyObjectPU<TaskProgress[]>;
    get pendingTasks() {
        return this.__pendingTasks.get();
    }
    set pendingTasks(newValue: TaskProgress[]) {
        this.__pendingTasks.set(newValue);
    }
    private __recTasks: ObservedPropertyObjectPU<TaskProgress[]>;
    get recTasks() {
        return this.__recTasks.get();
    }
    set recTasks(newValue: TaskProgress[]) {
        this.__recTasks.set(newValue);
    }
    private __tips: ObservedPropertyObjectPU<Suggestion[]>;
    get tips() {
        return this.__tips.get();
    }
    set tips(newValue: Suggestion[]) {
        this.__tips.set(newValue);
    }
    private __monthG: ObservedPropertySimplePU<number>;
    get monthG() {
        return this.__monthG.get();
    }
    set monthG(newValue: number) {
        this.__monthG.set(newValue);
    }
    private __monthGoalKg: ObservedPropertySimplePU<number>;
    get monthGoalKg() {
        return this.__monthGoalKg.get();
    }
    set monthGoalKg(newValue: number) {
        this.__monthGoalKg.set(newValue);
    }
    private __weekly: ObservedPropertyObjectPU<WeeklyReport>;
    get weekly() {
        return this.__weekly.get();
    }
    set weekly(newValue: WeeklyReport) {
        this.__weekly.set(newValue);
    }
    private __cardOrder: ObservedPropertyObjectPU<string[]>;
    get cardOrder() {
        return this.__cardOrder.get();
    }
    set cardOrder(newValue: string[]) {
        this.__cardOrder.set(newValue);
    }
    /** 本月剩余天数（含今天） */
    private daysLeftInMonth(): number {
        const d = new Date();
        const daysInMonth = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
        return daysInMonth - d.getDate() + 1;
    }
    /** 目标节奏提示文本；已达成或无目标返回空串 */
    private paceText(): string {
        if (this.monthGoalKg <= 0 || this.monthG >= this.monthGoalKg * 1000) {
            return '';
        }
        const perDay = (this.monthGoalKg * 1000 - this.monthG) / 1000 / this.daysLeftInMonth();
        return `本月还剩 ${this.daysLeftInMonth()} 天，日均 ${perDay.toFixed(2)} kg 即可达成`;
    }
    async aboutToAppear(): Promise<void> {
        await this.refresh();
    }
    async refresh(): Promise<void> {
        try {
            await AppInit.ensure();
            const records: BehaviorRecord[] = await BehaviorRepo.all();
            const todayStart = DateUtil.startOfDay(Date.now());
            let todaySum = 0;
            for (const r of records) {
                if (r.createdAt >= todayStart) {
                    todaySum += r.reductionG;
                }
            }
            this.todayG = todaySum;
            this.balance = await PointsService.getBalance();
            this.pending = await TaskService.pendingCount();
            this.streak = await BadgeService.currentStreak();
            this.trend = StatsService.trend(records, this.trendKind);
            this.pie = StatsService.categoryShare(records, StatsService.rangeStart(this.trendKind));
            this.monthG = StatsService.monthSum(records);
            this.weekly = StatsService.weekReport(records);
            this.monthGoalKg = await PrefsService.getMonthlyGoalKg();
            this.cardOrder = await PrefsService.getHomeLayout();
            const all = await TaskService.listProgress();
            const top: TaskProgress[] = [];
            for (const p of all) {
                if (!p.done && top.length < 3) {
                    top.push(p);
                }
            }
            this.pendingTasks = top;
            this.recTasks = await RecommendService.recommendTasks();
            this.tips = await RecommendService.suggestions();
            this.loading = false;
        }
        catch (e) {
            console.error('HomeView refresh error: ' + JSON.stringify(e));
            this.loading = false;
        }
    }
    statCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(164:5)", "entry");
            Column.width('100%');
            Column.padding(18);
            Column.borderRadius(Theme.R_MEDIUM);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Index.ets(165:7)", "entry");
            Row.width('100%');
            Row.alignItems(VerticalAlign.Top);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 6 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(166:9)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('今日减排');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(167:11)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 4 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(170:11)", "entry");
            Row.alignItems(VerticalAlign.Bottom);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(DateUtil.gramsToKg(this.todayG));
            Text.debugLine("entry/src/main/ets/pages/Index.ets(171:13)", "entry");
            Text.fontSize(38);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.PRIMARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('kg CO₂e');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(175:13)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.margin({ bottom: 6 });
        }, Text);
        Text.pop();
        Row.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(185:9)", "entry");
            Column.alignItems(HorizontalAlign.End);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 6 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(186:11)", "entry");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('连续打卡');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(187:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.streak} 天`);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(190:13)", "entry");
            Text.fontSize(12);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Circle.create({ width: 7, height: 7 });
            Circle.debugLine("entry/src/main/ets/pages/Index.ets(194:13)", "entry");
            Circle.fill(this.todayG > 0 ? Theme.PRIMARY : Theme.DIVIDER);
        }, Circle);
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 6 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(197:11)", "entry");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('碳积分');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(198:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.balance}`);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(201:13)", "entry");
            Text.fontSize(12);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 6 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(206:11)", "entry");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('待办任务');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(207:13)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.pending}`);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(210:13)", "entry");
            Text.fontSize(12);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        Row.pop();
        Column.pop();
        Row.pop();
        Column.pop();
    }
    /** 本月减排目标环（借鉴运动健康步数圆环） */
    goalCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(231:5)", "entry");
            Column.width('100%');
            Column.padding(14);
            Column.borderRadius(16);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Index.ets(232:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('本月减排目标');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(233:9)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Index.ets(236:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('修改目标 >');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(237:9)", "entry");
            Text.fontSize(13);
            Text.fontColor(Theme.PRIMARY);
            Text.onClick(() => {
                router.pushUrl({ url: 'pages/SettingsDetail', params: { focus: 'goal' } });
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 16 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(246:7)", "entry");
            Row.width('100%');
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            __Common__.create();
            __Common__.width(180);
        }, __Common__);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new GoalRing(this, {
                        progress: this.monthGoalKg > 0 ? this.monthG / (this.monthGoalKg * 1000) : 0,
                        centerText: (this.monthG / 1000).toFixed(1) + 'kg',
                        subText: '目标 ' + this.monthGoalKg + 'kg'
                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 247, col: 9 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            progress: this.monthGoalKg > 0 ? this.monthG / (this.monthGoalKg * 1000) : 0,
                            centerText: (this.monthG / 1000).toFixed(1) + 'kg',
                            subText: '目标 ' + this.monthGoalKg + 'kg'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        progress: this.monthGoalKg > 0 ? this.monthG / (this.monthGoalKg * 1000) : 0,
                        centerText: (this.monthG / 1000).toFixed(1) + 'kg',
                        subText: '目标 ' + this.monthGoalKg + 'kg'
                    });
                }
            }, { name: "GoalRing" });
        }
        __Common__.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(254:9)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 6 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(255:11)", "entry");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('达成率');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(256:13)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.monthGoalKg > 0 ? Math.round(this.monthG / (this.monthGoalKg * 1000) * 100) + '%' : '0%');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(259:13)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.monthG >= this.monthGoalKg * 1000 ? '#F7BA1E' : Theme.PRIMARY);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.monthG >= this.monthGoalKg * 1000) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('目标已达成，太棒了！');
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(265:13)", "entry");
                        Text.fontSize(13);
                        Text.fontColor('#F7BA1E');
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`还差 ${((this.monthGoalKg * 1000 - this.monthG) / 1000).toFixed(1)} kg 达成目标`);
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(269:13)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(Theme.TEXT_SECONDARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.paceText());
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(272:13)", "entry");
                        Text.fontSize(11);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('骑行通勤、光盘三餐都能攒进度');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(276:11)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        Row.pop();
        Column.pop();
    }
    quickEntry(icon: string, label: string, sub: string, bgColor: string, action: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("entry/src/main/ets/pages/Index.ets(295:5)", "entry");
            Stack.layoutWeight(1);
            Stack.height(78);
            Stack.borderRadius(Theme.R_SMALL);
            Stack.backgroundColor(Theme.CARD);
            Stack.border({ width: 1, color: Theme.DIVIDER });
            Stack.onClick(() => {
                action();
            });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/Index.ets(296:7)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.borderRadius(Theme.R_SMALL);
            Column.backgroundColor(bgColor);
            Column.opacity(0.08);
        }, Column);
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 2 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(303:7)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.justifyContent(FlexAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(icon);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(304:9)", "entry");
            Text.fontSize(18);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(307:9)", "entry");
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(sub);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(312:9)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        Stack.pop();
    }
    quickSection(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 5 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(332:5)", "entry");
            Column.width('100%');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 5 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(333:7)", "entry");
            Row.width('100%');
        }, Row);
        this.quickEntry.bind(this)('✏️', '行为录入', '记录低碳行为', '#00B96B', (): void => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
        });
        this.quickEntry.bind(this)('📜', '历史记录', '查询与筛选', '#722ED1', (): void => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_HISTORY);
        });
        this.quickEntry.bind(this)('🎯', '任务中心', '积分与徽章', '#F7BA1E', (): void => {
            AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
        });
        this.quickEntry.bind(this)('📚', '双碳科普', '政策与技巧', '#3491FA', (): void => {
            router.pushUrl({ url: 'pages/Knowledge' });
        });
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 创新拓展功能入口
            Row.create({ space: 5 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(349:7)", "entry");
            // 创新拓展功能入口
            Row.width('100%');
        }, Row);
        this.quickEntry.bind(this)('📷', '拍照识别', 'AI 自动录入', '#3491FA', (): void => {
            router.pushUrl({ url: 'pages/AiRecognize' });
        });
        this.quickEntry.bind(this)('🎁', '碳普惠', '积分兑权益', '#FF7D00', (): void => {
            router.pushUrl({ url: 'pages/Inclusive' });
        });
        this.quickEntry.bind(this)('👨‍👩‍👧', '家庭账户', '多端合并', '#14C9C9', (): void => {
            router.pushUrl({ url: 'pages/Family' });
        });
        this.quickEntry.bind(this)('📊', '成果分享', '生成海报', '#722ED1', (): void => {
            router.pushUrl({ url: 'pages/ShareCard' });
        });
        // 创新拓展功能入口
        Row.pop();
        Column.pop();
    }
    /** 减排趋势（柱状图风格，当期高亮） */
    trendCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(371:5)", "entry");
            Column.width('100%');
            Column.padding(14);
            Column.borderRadius(16);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Index.ets(372:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('减排趋势');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(373:9)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Index.ets(376:9)", "entry");
        }, Blank);
        Blank.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(380:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const kind = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(StatsService.shortLabel(kind as TrendKind));
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(382:11)", "entry");
                    Text.fontSize(11);
                    Text.fontColor(this.trendKind === kind ? '#FFFFFF' : Theme.TEXT_TERTIARY);
                    Text.backgroundColor(this.trendKind === kind ? Theme.PRIMARY : Theme.BG);
                    Text.borderRadius(10);
                    Text.padding({ left: 8, right: 8, top: 3, bottom: 3 });
                    Text.onClick(() => {
                        this.trendKind = kind as TrendKind;
                        this.refresh();
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, ['day7', 'week8', 'month12', 'year5'], forEachItemGenFunction, (kind: string) => kind, false, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Index.ets(393:9)", "entry");
        }, Blank);
        Blank.pop();
        Row.pop();
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new TrendBarChart(this, { points: this.trend }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 397, col: 7 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            points: this.trend
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        points: this.trend
                    });
                }
            }, { name: "TrendBarChart" });
        }
        Column.pop();
    }
    /** 分类占比环形图（中心大数字为当期总量） */
    pieCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(409:5)", "entry");
            Column.width('100%');
            Column.padding(14);
            Column.borderRadius(16);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${StatsService.kindLabel(this.trendKind)}分类占比`);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(410:7)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
            Text.width('100%');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.pie.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 8 });
                        Row.debugLine("entry/src/main/ets/pages/Index.ets(416:9)", "entry");
                        Row.width('100%');
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        __Common__.create();
                        __Common__.layoutWeight(1);
                    }, __Common__);
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new PieChart(this, { items: this.pie, centerSub: StatsService.kindLabel(this.trendKind) + '总量' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 417, col: 11 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        items: this.pie,
                                        centerSub: StatsService.kindLabel(this.trendKind) + '总量'
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    items: this.pie, centerSub: StatsService.kindLabel(this.trendKind) + '总量'
                                });
                            }
                        }, { name: "PieChart" });
                    }
                    __Common__.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 10 });
                        Column.debugLine("entry/src/main/ets/pages/Index.ets(419:11)", "entry");
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const item = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create({ space: 8 });
                                Row.debugLine("entry/src/main/ets/pages/Index.ets(421:15)", "entry");
                                Row.width('100%');
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Circle.create({ width: 14, height: 14 });
                                Circle.debugLine("entry/src/main/ets/pages/Index.ets(422:17)", "entry");
                                Circle.fill(item.color);
                            }, Circle);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(item.name);
                                Text.debugLine("entry/src/main/ets/pages/Index.ets(423:17)", "entry");
                                Text.fontSize(16);
                                Text.maxLines(1);
                                Text.fontColor(Theme.TEXT);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Blank.create();
                                Blank.debugLine("entry/src/main/ets/pages/Index.ets(427:17)", "entry");
                            }, Blank);
                            Blank.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(`${item.pct.toFixed(0)}%`);
                                Text.debugLine("entry/src/main/ets/pages/Index.ets(428:17)", "entry");
                                Text.fontSize(16);
                                Text.fontColor(Theme.TEXT_SECONDARY);
                            }, Text);
                            Text.pop();
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.pie, forEachItemGenFunction, (item: PieItem) => item.name, false, false);
                    }, ForEach);
                    ForEach.pop();
                    Column.pop();
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 12 });
                        Column.debugLine("entry/src/main/ets/pages/Index.ets(440:9)", "entry");
                        Column.width('100%');
                        Column.padding({ top: 20, bottom: 20 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('📊');
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(441:11)", "entry");
                        Text.fontSize(48);
                        Text.opacity(0.3);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('暂无数据');
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(444:11)", "entry");
                        Text.fontSize(14);
                        Text.fontColor(Theme.TEXT_SECONDARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('去录入第一笔减排记录吧');
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(447:11)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    /** 减排周报（借鉴运动健康周报） */
    weeklyCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(465:5)", "entry");
            Column.width('100%');
            Column.padding(14);
            Column.borderRadius(16);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
            Column.onClick(() => {
                // 点击周报卡：跳历史页并预选近7天
                AppStorage.setOrCreate('historyRange', 2);
                AppStorage.setOrCreate('mainTab', Constants.TAB_HISTORY);
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Index.ets(466:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('减排周报');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(467:9)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Index.ets(470:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(DateUtil.formatMD(DateUtil.startOfWeek(Date.now())) + ' 起');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(471:9)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(477:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(478:9)", "entry");
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('本周减排');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(479:11)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(DateUtil.gramsToKg(this.weekly.weekG));
            Text.debugLine("entry/src/main/ets/pages/Index.ets(482:11)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.PRIMARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(489:9)", "entry");
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('环比上周');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(490:11)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.weekly.deltaPct === -999) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('上周无数据');
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(494:13)", "entry");
                        Text.fontSize(14);
                        Text.fontWeight(FontWeight.Medium);
                        Text.fontColor(Theme.TEXT_SECONDARY);
                    }, Text);
                    Text.pop();
                });
            }
            else if (this.weekly.deltaPct >= 0) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`↑ ${this.weekly.deltaPct}%`);
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(499:13)", "entry");
                        Text.fontSize(14);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.PRIMARY);
                    }, Text);
                    Text.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`↓ ${-this.weekly.deltaPct}%`);
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(504:13)", "entry");
                        Text.fontSize(14);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor('#F53F3F');
                    }, Text);
                    Text.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(512:9)", "entry");
            Column.alignItems(HorizontalAlign.Start);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('本周打卡');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(513:11)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.weekly.days}/7 天`);
            Text.debugLine("entry/src/main/ets/pages/Index.ets(516:11)", "entry");
            Text.fontSize(14);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        Column.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.weekly.topSub !== '') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`本周最强项：${this.weekly.topSub}（${DateUtil.gramsToKg(this.weekly.topSubG)}）`);
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(526:9)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_SECONDARY);
                        Text.width('100%');
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
            if (this.weekly.weekG > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.weekly.slogan);
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(533:9)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.PRIMARY);
                        Text.backgroundColor(Theme.PRIMARY_BG);
                        Text.borderRadius(10);
                        Text.padding({ left: 10, right: 10, top: 6, bottom: 6 });
                        Text.width('100%');
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
        Column.pop();
    }
    /** 智能推荐（个性化任务 + 生活建议） */
    recCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(557:5)", "entry");
            Column.width('100%');
            Column.padding(14);
            Column.borderRadius(16);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 6 });
            Row.debugLine("entry/src/main/ets/pages/Index.ets(558:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('智能推荐');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(559:9)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('基于近 14 天行为习惯');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(562:9)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Index.ets(565:9)", "entry");
        }, Blank);
        Blank.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const p = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 4 });
                    Column.debugLine("entry/src/main/ets/pages/Index.ets(570:9)", "entry");
                    Column.alignItems(HorizontalAlign.Start);
                    Column.width('100%');
                    Column.padding(10);
                    Column.borderRadius(Theme.R_SMALL);
                    Column.backgroundColor(Theme.BG);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create({ space: 10 });
                    Row.debugLine("entry/src/main/ets/pages/Index.ets(571:11)", "entry");
                    Row.width('100%');
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create('任务');
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(572:13)", "entry");
                    Text.fontSize(9);
                    Text.fontColor(Theme.PRIMARY);
                    Text.backgroundColor(Theme.PRIMARY_BG);
                    Text.borderRadius(4);
                    Text.padding({ left: 5, right: 5, top: 2, bottom: 2 });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(p.task.title);
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(578:13)", "entry");
                    Text.fontSize(13);
                    Text.fontColor(Theme.TEXT);
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(`+${p.task.points} 积分`);
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(582:13)", "entry");
                    Text.fontSize(12);
                    Text.fontColor(Theme.POINTS);
                }, Text);
                Text.pop();
                Row.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (p.reason !== undefined && p.reason !== '') {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(p.reason);
                                Text.debugLine("entry/src/main/ets/pages/Index.ets(588:13)", "entry");
                                Text.fontSize(10);
                                Text.fontColor(Theme.TEXT_TERTIARY);
                                Text.width('100%');
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
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.recTasks, forEachItemGenFunction, (p: TaskProgress) => 'rec_' + p.task.code + '_' + (p.reason !== undefined ? p.reason : ''), false, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const s = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 4 });
                    Column.debugLine("entry/src/main/ets/pages/Index.ets(602:9)", "entry");
                    Column.alignItems(HorizontalAlign.Start);
                    Column.width('100%');
                    Column.padding(10);
                    Column.borderRadius(10);
                    Column.backgroundColor(Theme.PRIMARY_BG);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(s.title);
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(603:11)", "entry");
                    Text.fontSize(13);
                    Text.fontWeight(FontWeight.Medium);
                    Text.width('100%');
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(s.detail);
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(607:11)", "entry");
                    Text.fontSize(11);
                    Text.fontColor(Theme.TEXT_TERTIARY);
                    Text.width('100%');
                }, Text);
                Text.pop();
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.tips, forEachItemGenFunction, (s: Suggestion) => s.title, false, false);
        }, ForEach);
        ForEach.pop();
        Column.pop();
    }
    /** 待完成任务 */
    tasksCard(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(629:5)", "entry");
            Column.width('100%');
            Column.padding(14);
            Column.borderRadius(16);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Index.ets(630:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('待完成任务');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(631:9)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Index.ets(634:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('全部 >');
            Text.debugLine("entry/src/main/ets/pages/Index.ets(635:9)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.PRIMARY);
            Text.onClick(() => {
                AppStorage.setOrCreate('mainTab', Constants.TAB_TASKS);
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.pendingTasks.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('太棒了，本期任务都完成啦');
                        Text.debugLine("entry/src/main/ets/pages/Index.ets(645:9)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                        Text.width('100%');
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
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const p = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 4 });
                    Column.debugLine("entry/src/main/ets/pages/Index.ets(651:9)", "entry");
                    Column.width('100%');
                    Column.padding(10);
                    Column.borderRadius(Theme.R_SMALL);
                    Column.backgroundColor(Theme.BG);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create({ space: 10 });
                    Row.debugLine("entry/src/main/ets/pages/Index.ets(652:11)", "entry");
                    Row.width('100%');
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Circle.create({ width: 6, height: 6 });
                    Circle.debugLine("entry/src/main/ets/pages/Index.ets(653:13)", "entry");
                    Circle.fill(Theme.PRIMARY_HOVER);
                }, Circle);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(p.task.title);
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(654:13)", "entry");
                    Text.fontSize(13);
                    Text.fontColor(Theme.TEXT);
                    Text.layoutWeight(1);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(`+${p.task.points} 积分`);
                    Text.debugLine("entry/src/main/ets/pages/Index.ets(658:13)", "entry");
                    Text.fontSize(12);
                    Text.fontColor(Theme.POINTS);
                }, Text);
                Text.pop();
                Row.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Progress.create({ value: p.progress, total: p.target, type: ProgressType.Linear });
                    Progress.debugLine("entry/src/main/ets/pages/Index.ets(663:11)", "entry");
                    Progress.width('100%');
                    Progress.height(2);
                    Progress.color(Theme.PRIMARY_HOVER);
                }, Progress);
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.pendingTasks, forEachItemGenFunction, (p: TaskProgress) => p.task.code, false, false);
        }, ForEach);
        ForEach.pop();
        Column.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/Index.ets(682:5)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Index.ets(683:7)", "entry");
            Column.width('100%');
            Column.padding(14);
        }, Column);
        this.statCard.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 卡片顺序可自定义（我的 > 首页布局）
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const key = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (key === 'goal') {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.goalCard.bind(this)();
                        });
                    }
                    else if (key === 'quick') {
                        this.ifElseBranchUpdateFunction(1, () => {
                            this.quickSection.bind(this)();
                        });
                    }
                    else if (key === 'trend') {
                        this.ifElseBranchUpdateFunction(2, () => {
                            this.trendCard.bind(this)();
                        });
                    }
                    else if (key === 'pie') {
                        this.ifElseBranchUpdateFunction(3, () => {
                            this.pieCard.bind(this)();
                        });
                    }
                    else if (key === 'weekly') {
                        this.ifElseBranchUpdateFunction(4, () => {
                            this.weeklyCard.bind(this)();
                        });
                    }
                    else if (key === 'rec') {
                        this.ifElseBranchUpdateFunction(5, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                If.create();
                                if (this.recTasks.length > 0 || this.tips.length > 0) {
                                    this.ifElseBranchUpdateFunction(0, () => {
                                        this.recCard.bind(this)();
                                    });
                                }
                                else {
                                    this.ifElseBranchUpdateFunction(1, () => {
                                    });
                                }
                            }, If);
                            If.pop();
                        });
                    }
                    else if (key === 'tasks') {
                        this.ifElseBranchUpdateFunction(6, () => {
                            this.tasksCard.bind(this)();
                        });
                    }
                    else {
                        this.ifElseBranchUpdateFunction(7, () => {
                        });
                    }
                }, If);
                If.pop();
            };
            this.forEachUpdateFunction(elmtId, this.cardOrder, forEachItemGenFunction, (key: string) => key, false, false);
        }, ForEach);
        // 卡片顺序可自定义（我的 > 首页布局）
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (!this.loading && this.todayG === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new EmptyState(this, {
                                    icon: '',
                                    title: '今天还没有低碳记录',
                                    desc: '步行、光盘、节电……每一件小事都在改变世界',
                                    buttonText: '立即记录',
                                    onButton: (): void => {
                                        AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
                                    }
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Index.ets", line: 708, col: 11 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        icon: '',
                                        title: '今天还没有低碳记录',
                                        desc: '步行、光盘、节电……每一件小事都在改变世界',
                                        buttonText: '立即记录',
                                        onButton: (): void => {
                                            AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
                                        }
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {});
                            }
                        }, { name: "EmptyState" });
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Column.pop();
        Scroll.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
registerNamedRoute(() => new Index(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/Index", pageFullPath: "entry/src/main/ets/pages/Index", integratedHsp: "false", moduleType: "followWithHap" });
