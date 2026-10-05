if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface TasksView_Params {
    segment?: number;
    tick?: number;
    tasks?: TaskProgress[];
    flow?: PointsRecord[];
    balance?: number;
    loaded?: boolean;
    weekDone?: number;
    totalDone?: number;
    weekDaysLeft?: number;
    flowSource?: string;
    flowLimit?: number;
    detailTask?: TaskProgress | null;
    showDetail?: boolean;
    detailRule?: string;
    detailRemain?: string;
    detailRecords?: BehaviorRecord[];
    detailTotal?: number;
    showUnlock?: boolean;
    unlockBadges?: string[];
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import { sourceLabel } from "@normalized:N&&&entry/src/main/ets/model/Models&";
import type { TaskProgress, PointsRecord, BehaviorRecord } from "@normalized:N&&&entry/src/main/ets/model/Models&";
import { TaskService } from "@normalized:N&&&entry/src/main/ets/service/TaskService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { BehaviorRepo, TaskCheckUtil } from "@normalized:N&&&entry/src/main/ets/db/Repository&";
import type { TaskCheck } from "@normalized:N&&&entry/src/main/ets/model/Models&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
import { EmptyState } from "@normalized:N&&&entry/src/main/ets/components/EmptyState&";
import { BadgeService } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import { BadgeUnlockOverlay } from "@normalized:N&&&entry/src/main/ets/components/BadgeUnlock&";
const SOURCES: string[] = ['全部', 'behavior', 'task', 'read', 'exchange'];
export class TasksView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__segment = this.createStorageLink('tasksSegment', 0, "segment");
        this.__tick = this.createStorageLink('tick', 0, "tick");
        this.__tasks = new ObservedPropertyObjectPU([], this, "tasks");
        this.__flow = new ObservedPropertyObjectPU([], this, "flow");
        this.__balance = new ObservedPropertySimplePU(0, this, "balance");
        this.__loaded = new ObservedPropertySimplePU(false, this, "loaded");
        this.__weekDone = new ObservedPropertySimplePU(0, this, "weekDone");
        this.__totalDone = new ObservedPropertySimplePU(0, this, "totalDone");
        this.__weekDaysLeft = new ObservedPropertySimplePU(7, this, "weekDaysLeft");
        this.__flowSource = new ObservedPropertySimplePU('全部', this, "flowSource");
        this.__flowLimit = new ObservedPropertySimplePU(50, this, "flowLimit");
        this.__detailTask = new ObservedPropertyObjectPU(null, this, "detailTask");
        this.__showDetail = new ObservedPropertySimplePU(false, this, "showDetail");
        this.__detailRule = new ObservedPropertySimplePU('', this, "detailRule");
        this.__detailRemain = new ObservedPropertySimplePU('', this, "detailRemain");
        this.__detailRecords = new ObservedPropertyObjectPU([], this, "detailRecords");
        this.__detailTotal = new ObservedPropertySimplePU(0, this, "detailTotal");
        this.__showUnlock = new ObservedPropertySimplePU(false, this, "showUnlock");
        this.__unlockBadges = new ObservedPropertyObjectPU([], this, "unlockBadges");
        this.setInitiallyProvidedValue(params);
        this.declareWatch("segment", this.refresh);
        this.declareWatch("tick", this.refresh);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: TasksView_Params) {
        if (params.tasks !== undefined) {
            this.tasks = params.tasks;
        }
        if (params.flow !== undefined) {
            this.flow = params.flow;
        }
        if (params.balance !== undefined) {
            this.balance = params.balance;
        }
        if (params.loaded !== undefined) {
            this.loaded = params.loaded;
        }
        if (params.weekDone !== undefined) {
            this.weekDone = params.weekDone;
        }
        if (params.totalDone !== undefined) {
            this.totalDone = params.totalDone;
        }
        if (params.weekDaysLeft !== undefined) {
            this.weekDaysLeft = params.weekDaysLeft;
        }
        if (params.flowSource !== undefined) {
            this.flowSource = params.flowSource;
        }
        if (params.flowLimit !== undefined) {
            this.flowLimit = params.flowLimit;
        }
        if (params.detailTask !== undefined) {
            this.detailTask = params.detailTask;
        }
        if (params.showDetail !== undefined) {
            this.showDetail = params.showDetail;
        }
        if (params.detailRule !== undefined) {
            this.detailRule = params.detailRule;
        }
        if (params.detailRemain !== undefined) {
            this.detailRemain = params.detailRemain;
        }
        if (params.detailRecords !== undefined) {
            this.detailRecords = params.detailRecords;
        }
        if (params.detailTotal !== undefined) {
            this.detailTotal = params.detailTotal;
        }
        if (params.showUnlock !== undefined) {
            this.showUnlock = params.showUnlock;
        }
        if (params.unlockBadges !== undefined) {
            this.unlockBadges = params.unlockBadges;
        }
    }
    updateStateVars(params: TasksView_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__segment.purgeDependencyOnElmtId(rmElmtId);
        this.__tick.purgeDependencyOnElmtId(rmElmtId);
        this.__tasks.purgeDependencyOnElmtId(rmElmtId);
        this.__flow.purgeDependencyOnElmtId(rmElmtId);
        this.__balance.purgeDependencyOnElmtId(rmElmtId);
        this.__loaded.purgeDependencyOnElmtId(rmElmtId);
        this.__weekDone.purgeDependencyOnElmtId(rmElmtId);
        this.__totalDone.purgeDependencyOnElmtId(rmElmtId);
        this.__weekDaysLeft.purgeDependencyOnElmtId(rmElmtId);
        this.__flowSource.purgeDependencyOnElmtId(rmElmtId);
        this.__flowLimit.purgeDependencyOnElmtId(rmElmtId);
        this.__detailTask.purgeDependencyOnElmtId(rmElmtId);
        this.__showDetail.purgeDependencyOnElmtId(rmElmtId);
        this.__detailRule.purgeDependencyOnElmtId(rmElmtId);
        this.__detailRemain.purgeDependencyOnElmtId(rmElmtId);
        this.__detailRecords.purgeDependencyOnElmtId(rmElmtId);
        this.__detailTotal.purgeDependencyOnElmtId(rmElmtId);
        this.__showUnlock.purgeDependencyOnElmtId(rmElmtId);
        this.__unlockBadges.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__segment.aboutToBeDeleted();
        this.__tick.aboutToBeDeleted();
        this.__tasks.aboutToBeDeleted();
        this.__flow.aboutToBeDeleted();
        this.__balance.aboutToBeDeleted();
        this.__loaded.aboutToBeDeleted();
        this.__weekDone.aboutToBeDeleted();
        this.__totalDone.aboutToBeDeleted();
        this.__weekDaysLeft.aboutToBeDeleted();
        this.__flowSource.aboutToBeDeleted();
        this.__flowLimit.aboutToBeDeleted();
        this.__detailTask.aboutToBeDeleted();
        this.__showDetail.aboutToBeDeleted();
        this.__detailRule.aboutToBeDeleted();
        this.__detailRemain.aboutToBeDeleted();
        this.__detailRecords.aboutToBeDeleted();
        this.__detailTotal.aboutToBeDeleted();
        this.__showUnlock.aboutToBeDeleted();
        this.__unlockBadges.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __segment: ObservedPropertyAbstractPU<number>;
    get segment() {
        return this.__segment.get();
    }
    set segment(newValue: number) {
        this.__segment.set(newValue);
    }
    private __tick: ObservedPropertyAbstractPU<number>;
    get tick() {
        return this.__tick.get();
    }
    set tick(newValue: number) {
        this.__tick.set(newValue);
    }
    private __tasks: ObservedPropertyObjectPU<TaskProgress[]>;
    get tasks() {
        return this.__tasks.get();
    }
    set tasks(newValue: TaskProgress[]) {
        this.__tasks.set(newValue);
    }
    private __flow: ObservedPropertyObjectPU<PointsRecord[]>;
    get flow() {
        return this.__flow.get();
    }
    set flow(newValue: PointsRecord[]) {
        this.__flow.set(newValue);
    }
    private __balance: ObservedPropertySimplePU<number>;
    get balance() {
        return this.__balance.get();
    }
    set balance(newValue: number) {
        this.__balance.set(newValue);
    }
    private __loaded: ObservedPropertySimplePU<boolean>;
    get loaded() {
        return this.__loaded.get();
    }
    set loaded(newValue: boolean) {
        this.__loaded.set(newValue);
    }
    private __weekDone: ObservedPropertySimplePU<number>;
    get weekDone() {
        return this.__weekDone.get();
    }
    set weekDone(newValue: number) {
        this.__weekDone.set(newValue);
    }
    private __totalDone: ObservedPropertySimplePU<number>;
    get totalDone() {
        return this.__totalDone.get();
    }
    set totalDone(newValue: number) {
        this.__totalDone.set(newValue);
    }
    private __weekDaysLeft: ObservedPropertySimplePU<number>;
    get weekDaysLeft() {
        return this.__weekDaysLeft.get();
    }
    set weekDaysLeft(newValue: number) {
        this.__weekDaysLeft.set(newValue);
    }
    private __flowSource: ObservedPropertySimplePU<string>;
    get flowSource() {
        return this.__flowSource.get();
    }
    set flowSource(newValue: string) {
        this.__flowSource.set(newValue);
    }
    private __flowLimit: ObservedPropertySimplePU<number>;
    get flowLimit() {
        return this.__flowLimit.get();
    }
    set flowLimit(newValue: number) {
        this.__flowLimit.set(newValue);
    }
    private __detailTask: ObservedPropertyObjectPU<TaskProgress | null>;
    get detailTask() {
        return this.__detailTask.get();
    }
    set detailTask(newValue: TaskProgress | null) {
        this.__detailTask.set(newValue);
    }
    private __showDetail: ObservedPropertySimplePU<boolean>;
    get showDetail() {
        return this.__showDetail.get();
    }
    set showDetail(newValue: boolean) {
        this.__showDetail.set(newValue);
    }
    private __detailRule: ObservedPropertySimplePU<string>;
    get detailRule() {
        return this.__detailRule.get();
    }
    set detailRule(newValue: string) {
        this.__detailRule.set(newValue);
    }
    private __detailRemain: ObservedPropertySimplePU<string>;
    get detailRemain() {
        return this.__detailRemain.get();
    }
    set detailRemain(newValue: string) {
        this.__detailRemain.set(newValue);
    }
    private __detailRecords: ObservedPropertyObjectPU<BehaviorRecord[]>;
    get detailRecords() {
        return this.__detailRecords.get();
    }
    set detailRecords(newValue: BehaviorRecord[]) {
        this.__detailRecords.set(newValue);
    }
    private __detailTotal: ObservedPropertySimplePU<number>;
    get detailTotal() {
        return this.__detailTotal.get();
    }
    set detailTotal(newValue: number) {
        this.__detailTotal.set(newValue);
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
        this.refresh();
    }
    async refresh(): Promise<void> {
        try {
            await AppInit.ensure();
            // 达标任务自动发积分（提交行为时也会评估，此处兜底）
            const awarded: string[] = await TaskService.evaluateAll();
            if (awarded.length > 0 && this.loaded) {
                promptAction.showToast({
                    message: `完成任务：${awarded.join('、')}，积分已到账`,
                    duration: 2500
                });
            }
            // 任务路径解锁的徽章在此展示动画
            const newBadges: string[] = await BadgeService.checkAll();
            if (newBadges.length > 0) {
                this.unlockBadges = newBadges;
                this.showUnlock = true;
            }
            this.tasks = await TaskService.listProgress();
            this.balance = await PointsService.getBalance();
            this.weekDone = await TaskService.weekCompletedCount();
            this.totalDone = await PointsService.countSource('task');
            const weekStart = DateUtil.startOfWeek(Date.now());
            this.weekDaysLeft = Math.ceil((weekStart + 7 * DateUtil.DAY_MS - Date.now()) / DateUtil.DAY_MS);
            await this.loadFlow();
            this.loaded = true;
        }
        catch (e) {
            console.error('TasksView refresh error: ' + JSON.stringify(e));
        }
    }
    private async loadFlow(): Promise<void> {
        this.flow = await PointsService.listPaged(this.flowSource, this.flowLimit);
    }
    private async changeSource(src: string): Promise<void> {
        this.flowSource = src;
        this.flowLimit = 50;
        await this.loadFlow();
    }
    private async loadMore(): Promise<void> {
        this.flowLimit += 50;
        await this.loadFlow();
    }
    private sourceChipLabel(code: string): string {
        if (code === '全部') {
            return '全部';
        }
        return sourceLabel(code);
    }
    private async openDetail(p: TaskProgress): Promise<void> {
        this.detailTask = p;
        this.detailRule = '统计中…';
        this.detailRemain = '';
        this.detailRecords = [];
        this.detailTotal = 0;
        this.showDetail = true;
        const check: TaskCheck = TaskCheckUtil.parse(p.task.checkJson);
        const rule = check.matchType === 'sum'
            ? `判定规则：${check.subTypes.join('、')} 按单位（${check.unit}）数值累加`
            : `判定规则：${check.subTypes.join('、')} 按记录笔数累加`;
        this.detailRule = `${rule}，达到 ${check.target}${check.unit} 即完成。`;
        this.detailRemain = p.done ? '本期已达成，积分已发放' : `还差 ${(p.target - p.progress) > 0 ? (p.target - p.progress) : 0}${check.unit} 达标`;
        try {
            const start = TaskService.periodStart(p.task.period);
            const all = await BehaviorRepo.query(start, Date.now(), '全部');
            const contrib: BehaviorRecord[] = [];
            for (const r of all) {
                if (check.subTypes.indexOf(r.subType) >= 0) {
                    if (check.matchType === 'sum' && r.unit !== check.unit) {
                        continue;
                    }
                    contrib.push(r);
                }
            }
            this.detailTotal = contrib.length;
            const top: BehaviorRecord[] = [];
            for (let i = 0; i < contrib.length && i < 20; i++) {
                top.push(contrib[i]);
            }
            this.detailRecords = top;
        }
        catch (e) {
            console.error('openDetail error: ' + JSON.stringify(e));
        }
    }
    taskCard(p: TaskProgress, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/Tasks.ets(134:5)", "entry");
            Column.width('100%');
            Column.padding(14);
            Column.borderRadius(Theme.R_MEDIUM);
            Column.backgroundColor(Theme.CARD);
            Column.border({ width: 1, color: Theme.DIVIDER });
            Column.onClick(() => {
                this.openDetail(p);
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Tasks.ets(135:7)", "entry");
            Row.width('100%');
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 3 });
            Column.debugLine("entry/src/main/ets/pages/Tasks.ets(136:9)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/Tasks.ets(137:11)", "entry");
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(p.task.title);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(138:13)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(p.task.period === 'daily' ? '每日' : '每周');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(141:13)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.PRIMARY);
            Text.backgroundColor(Theme.PRIMARY_BG);
            Text.borderRadius(4);
            Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (p.task.period === 'weekly') {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`剩${this.weekDaysLeft}天`);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(148:15)", "entry");
                        Text.fontSize(10);
                        Text.fontColor('#FF7D00');
                        Text.backgroundColor('#FFF3E8');
                        Text.borderRadius(4);
                        Text.padding({ left: 6, right: 6, top: 2, bottom: 2 });
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
            if (p.done) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('已完成');
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(156:15)", "entry");
                        Text.fontSize(10);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Tasks.ets(159:15)", "entry");
                    }, Blank);
                    Blank.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(p.task.description);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(162:11)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.maxLines(2);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`+${p.task.points}`);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(169:9)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.POINTS);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Tasks.ets(177:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Progress.create({ value: p.progress, total: p.target, type: ProgressType.Linear });
            Progress.debugLine("entry/src/main/ets/pages/Tasks.ets(178:9)", "entry");
            Progress.layoutWeight(1);
            Progress.color(p.done ? Theme.PRIMARY_HOVER : Theme.PRIMARY);
        }, Progress);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(p.done ? '已达成' : `${p.progress}/${p.target}`);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(181:9)", "entry");
            Text.fontSize(12);
            Text.fontColor(p.done ? Theme.TEXT_TERTIARY : Theme.TEXT);
            Text.width(70);
            Text.textAlign(TextAlign.End);
        }, Text);
        Text.pop();
        Row.pop();
        Column.pop();
    }
    detailSheet(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Tasks.ets(201:5)", "entry");
            Column.width('100%');
            Column.padding(16);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Tasks.ets(202:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('任务详情');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(203:9)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Tasks.ets(206:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('×');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(207:9)", "entry");
            Text.fontSize(16);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.onClick(() => {
                this.showDetail = false;
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.detailTask !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 10 });
                        Row.debugLine("entry/src/main/ets/pages/Tasks.ets(217:9)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.detailTask as TaskProgress).task.title);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(218:11)", "entry");
                        Text.fontSize(17);
                        Text.fontWeight(FontWeight.Medium);
                        Text.layoutWeight(1);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`+${(this.detailTask as TaskProgress).task.points} 积分`);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(222:11)", "entry");
                        Text.fontSize(15);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.POINTS);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.detailRule);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(229:9)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_SECONDARY);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.detailRemain);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(234:9)", "entry");
                        Text.fontSize(13);
                        Text.fontColor((this.detailTask as TaskProgress).done ? Theme.TEXT_TERTIARY : Theme.PRIMARY);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`本期贡献记录（${this.detailTotal} 笔${this.detailTotal > 20 ? '，仅显示最近 20 笔' : ''}）`);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(239:9)", "entry");
                        Text.fontSize(12);
                        Text.fontWeight(FontWeight.Medium);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.detailRecords.length === 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('本期还没有相关记录，去录入页完成行为吧');
                                    Text.debugLine("entry/src/main/ets/pages/Tasks.ets(245:11)", "entry");
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
                const r = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create({ space: 10 });
                    Row.debugLine("entry/src/main/ets/pages/Tasks.ets(253:9)", "entry");
                    Row.width('100%');
                    Row.padding(10);
                    Row.borderRadius(Theme.R_SMALL);
                    Row.backgroundColor(Theme.BG);
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 3 });
                    Column.debugLine("entry/src/main/ets/pages/Tasks.ets(254:11)", "entry");
                    Column.alignItems(HorizontalAlign.Start);
                    Column.layoutWeight(1);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(`${r.subType} ${r.value}${r.unit}`);
                    Text.debugLine("entry/src/main/ets/pages/Tasks.ets(255:13)", "entry");
                    Text.fontSize(13);
                    Text.fontWeight(FontWeight.Medium);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(DateUtil.formatMDHM(r.createdAt));
                    Text.debugLine("entry/src/main/ets/pages/Tasks.ets(258:13)", "entry");
                    Text.fontSize(11);
                    Text.fontColor(Theme.TEXT_TERTIARY);
                }, Text);
                Text.pop();
                Column.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(`-${(r.reductionG / 1000).toFixed(2)}kg`);
                    Text.debugLine("entry/src/main/ets/pages/Tasks.ets(264:11)", "entry");
                    Text.fontSize(12);
                    Text.fontColor(Theme.REDUCE);
                }, Text);
                Text.pop();
                Row.pop();
            };
            this.forEachUpdateFunction(elmtId, this.detailRecords, forEachItemGenFunction, (r: BehaviorRecord) => '' + r.id + '_' + r.value, false, false);
        }, ForEach);
        ForEach.pop();
        Column.pop();
    }
    flowRow(p: PointsRecord, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Tasks.ets(280:5)", "entry");
            Row.width('100%');
            Row.padding(12);
            Row.borderRadius(Theme.R_SMALL);
            Row.backgroundColor(Theme.CARD);
            Row.border({ width: 1, color: Theme.DIVIDER });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(p.points >= 0 ? '+' : '−');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(281:7)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(p.points >= 0 ? Theme.PRIMARY : Theme.WARN);
            Text.width(28);
            Text.height(28);
            Text.textAlign(TextAlign.Center);
            Text.backgroundColor(Theme.BG);
            Text.borderRadius(14);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 3 });
            Column.debugLine("entry/src/main/ets/pages/Tasks.ets(290:7)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(p.action);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(291:9)", "entry");
            Text.fontSize(13);
            Text.fontWeight(FontWeight.Medium);
            Text.maxLines(2);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${sourceLabel(p.source)} · ${DateUtil.formatMDHM(p.createdAt)}`);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(295:9)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 3 });
            Column.debugLine("entry/src/main/ets/pages/Tasks.ets(301:7)", "entry");
            Column.alignItems(HorizontalAlign.End);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${p.points >= 0 ? '+' : ''}${p.points}`);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(302:9)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(p.points >= 0 ? Theme.PRIMARY : Theme.WARN);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`余额 ${p.balanceAfter}`);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(306:9)", "entry");
            Text.fontSize(10);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        Row.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("entry/src/main/ets/pages/Tasks.ets(320:5)", "entry");
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/Tasks.ets(321:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.bindSheet(this.showDetail, { builder: () => {
                    this.detailSheet.call(this);
                } }, {
                height: 560,
                showClose: false,
                onDisappear: () => {
                    this.showDetail = false;
                }
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('任务与积分');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(322:7)", "entry");
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.width('100%');
            Text.padding({ left: 14, top: 14 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 余额 + 徽章入口
            Row.create({ space: 10 });
            Row.debugLine("entry/src/main/ets/pages/Tasks.ets(329:7)", "entry");
            // 余额 + 徽章入口
            Row.width('100%');
            // 余额 + 徽章入口
            Row.padding(16);
            // 余额 + 徽章入口
            Row.borderRadius(Theme.R_MEDIUM);
            // 余额 + 徽章入口
            Row.backgroundColor(Theme.CARD);
            // 余额 + 徽章入口
            Row.border({ width: 1, color: Theme.DIVIDER });
            // 余额 + 徽章入口
            Row.margin({ left: 14, right: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Tasks.ets(330:9)", "entry");
            Column.alignItems(HorizontalAlign.Start);
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('碳积分余额');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(331:11)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('' + this.balance);
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(334:11)", "entry");
            Text.fontSize(30);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(Theme.PRIMARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Button.createWithLabel('徽章墙与证书');
            Button.debugLine("entry/src/main/ets/pages/Tasks.ets(341:9)", "entry");
            Button.fontSize(13);
            Button.fontColor(Theme.PRIMARY);
            Button.backgroundColor(Theme.CARD);
            Button.border({ width: 1, color: Theme.PRIMARY, radius: 18 });
            Button.onClick(() => {
                router.pushUrl({ url: 'pages/Badges' });
            });
        }, Button);
        Button.pop();
        // 余额 + 徽章入口
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 分段切换
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/Tasks.ets(358:7)", "entry");
            // 分段切换
            Row.width('100%');
            // 分段切换
            Row.padding({ left: 14, right: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('低碳任务');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(359:9)", "entry");
            Text.fontSize(14);
            Text.fontColor(this.segment === 0 ? '#FFFFFF' : Theme.TEXT);
            Text.backgroundColor(this.segment === 0 ? Theme.PRIMARY : Theme.CARD);
            Text.borderRadius(16);
            Text.padding({ left: 16, right: 16, top: 7, bottom: 7 });
            Text.onClick(() => {
                this.segment = 0;
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('积分流水');
            Text.debugLine("entry/src/main/ets/pages/Tasks.ets(368:9)", "entry");
            Text.fontSize(14);
            Text.fontColor(this.segment === 1 ? '#FFFFFF' : Theme.TEXT);
            Text.backgroundColor(this.segment === 1 ? Theme.PRIMARY : Theme.CARD);
            Text.borderRadius(16);
            Text.padding({ left: 16, right: 16, top: 7, bottom: 7 });
            Text.onClick(() => {
                this.segment = 1;
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Tasks.ets(377:9)", "entry");
        }, Blank);
        Blank.pop();
        // 分段切换
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.segment === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 任务完成统计
                        Row.create({ space: 12 });
                        Row.debugLine("entry/src/main/ets/pages/Tasks.ets(384:9)", "entry");
                        // 任务完成统计
                        Row.width('100%');
                        // 任务完成统计
                        Row.padding({ left: 16, right: 16, top: 10, bottom: 10 });
                        // 任务完成统计
                        Row.borderRadius(Theme.R_SMALL);
                        // 任务完成统计
                        Row.backgroundColor(Theme.CARD);
                        // 任务完成统计
                        Row.border({ width: 1, color: Theme.DIVIDER });
                        // 任务完成统计
                        Row.margin({ left: 14, right: 14 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`本周完成 ${this.weekDone} 次`);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(385:11)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`累计完成 ${this.totalDone} 次`);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(388:11)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Tasks.ets(391:11)", "entry");
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`周任务剩 ${this.weekDaysLeft} 天`);
                        Text.debugLine("entry/src/main/ets/pages/Tasks.ets(392:11)", "entry");
                        Text.fontSize(11);
                        Text.fontColor('#FF7D00');
                    }, Text);
                    Text.pop();
                    // 任务完成统计
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create({ space: 10 });
                        List.debugLine("entry/src/main/ets/pages/Tasks.ets(403:9)", "entry");
                        List.layoutWeight(1);
                        List.width('100%');
                        List.padding({ left: 14, right: 14, bottom: 14 });
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const p = _item;
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
                                    ListItem.debugLine("entry/src/main/ets/pages/Tasks.ets(405:13)", "entry");
                                };
                                const deepRenderFunction = (elmtId, isInitialRender) => {
                                    itemCreation(elmtId, isInitialRender);
                                    this.taskCard.bind(this)(p);
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.tasks, forEachItemGenFunction, (p: TaskProgress) => p.task.code + '_' + (p.done ? '1' : '0') + '_' + p.progress, false, false);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 来源筛选
                        Row.create({ space: 6 });
                        Row.debugLine("entry/src/main/ets/pages/Tasks.ets(415:9)", "entry");
                        // 来源筛选
                        Row.width('100%');
                        // 来源筛选
                        Row.padding({ left: 14, right: 14 });
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const s = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(this.sourceChipLabel(s));
                                Text.debugLine("entry/src/main/ets/pages/Tasks.ets(417:13)", "entry");
                                Text.fontSize(11);
                                Text.fontColor(this.flowSource === s ? '#FFFFFF' : Theme.TEXT);
                                Text.backgroundColor(this.flowSource === s ? Theme.PRIMARY : Theme.CARD);
                                Text.borderRadius(12);
                                Text.padding({ left: 10, right: 10, top: 5, bottom: 5 });
                                Text.onClick(() => {
                                    this.changeSource(s);
                                });
                            }, Text);
                            Text.pop();
                        };
                        this.forEachUpdateFunction(elmtId, SOURCES, forEachItemGenFunction, (s: string) => s, false, false);
                    }, ForEach);
                    ForEach.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Tasks.ets(427:11)", "entry");
                    }, Blank);
                    Blank.pop();
                    // 来源筛选
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create({ space: 8 });
                        List.debugLine("entry/src/main/ets/pages/Tasks.ets(432:9)", "entry");
                        List.layoutWeight(1);
                        List.width('100%');
                        List.padding({ left: 14, right: 14 });
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const p = _item;
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
                                    ListItem.debugLine("entry/src/main/ets/pages/Tasks.ets(434:13)", "entry");
                                };
                                const deepRenderFunction = (elmtId, isInitialRender) => {
                                    itemCreation(elmtId, isInitialRender);
                                    this.flowRow.bind(this)(p);
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.flow, forEachItemGenFunction, (p: PointsRecord) => '' + p.id, false, false);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.flow.length === this.flowLimit) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('加载更多（已显示 ' + this.flow.length + ' 条）');
                                    Text.debugLine("entry/src/main/ets/pages/Tasks.ets(444:11)", "entry");
                                    Text.fontSize(12);
                                    Text.fontColor(Theme.PRIMARY);
                                    Text.width('100%');
                                    Text.textAlign(TextAlign.Center);
                                    Text.padding({ top: 4, bottom: 10 });
                                    Text.onClick(() => {
                                        this.loadMore();
                                    });
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
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.segment === 0 && this.tasks.length === 0 && this.loaded) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new EmptyState(this, { icon: '', title: '暂无任务' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Tasks.ets", line: 457, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        icon: '',
                                        title: '暂无任务'
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
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.segment === 1 && this.flow.length === 0 && this.loaded) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new EmptyState(this, {
                                    icon: '',
                                    title: '还没有积分流水',
                                    desc: '记录低碳行为、完成任务、阅读科普都可以获得积分',
                                    buttonText: '去录入',
                                    onButton: (): void => {
                                        AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
                                    }
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Tasks.ets", line: 460, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        icon: '',
                                        title: '还没有积分流水',
                                        desc: '记录低碳行为、完成任务、阅读科普都可以获得积分',
                                        buttonText: '去录入',
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
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/Tasks.ets", line: 482, col: 7 });
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
