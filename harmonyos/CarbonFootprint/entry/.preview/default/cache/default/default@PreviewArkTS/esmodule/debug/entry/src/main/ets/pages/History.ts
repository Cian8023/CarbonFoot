if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HistoryView_Params {
    tick?: number;
    records?: BehaviorRecord[];
    rawRecords?: BehaviorRecord[];
    rangeIndex?: number;
    extRange?: number;
    typeFilter?: string;
    keyword?: string;
    customStart?: number;
    customEnd?: number;
    bars?: PieItem[];
    selRecord?: BehaviorRecord | null;
    showSheet?: boolean;
    editNote?: string;
    editValue?: string;
    editTs?: number;
    recPointsText?: string;
    totalG?: number;
    groups?: RecordGroup[];
}
import promptAction from "@ohos:promptAction";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import type { BehaviorRecord } from '../model/Models';
import { BehaviorRepo } from "@normalized:N&&&entry/src/main/ets/db/Repository&";
import { BehaviorService } from "@normalized:N&&&entry/src/main/ets/service/BehaviorService&";
import { CalculationService } from "@normalized:N&&&entry/src/main/ets/service/CalculationService&";
import { StatsService } from "@normalized:N&&&entry/src/main/ets/service/StatsService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
import { BarChart } from "@normalized:N&&&entry/src/main/ets/components/Chart&";
import type { PieItem } from "@normalized:N&&&entry/src/main/ets/components/Chart&";
import { EmptyState } from "@normalized:N&&&entry/src/main/ets/components/EmptyState&";
const RANGES: string[] = ['全部', '今日', '近7天', '近30天', '自定义'];
const TYPES: string[] = ['全部', '出行', '节水节电', '旧物回收', '光盘行动'];
/** 按日期分组后的一个分组 */
export interface RecordGroup {
    label: string;
    items: BehaviorRecord[];
}
export class HistoryView extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__tick = this.createStorageLink('tick', 0, "tick");
        this.__records = new ObservedPropertyObjectPU([], this, "records");
        this.__rawRecords = new ObservedPropertyObjectPU([], this, "rawRecords");
        this.__rangeIndex = new ObservedPropertySimplePU(1, this, "rangeIndex");
        this.__extRange = this.createStorageProp('historyRange', 1, "extRange");
        this.__typeFilter = new ObservedPropertySimplePU('全部', this, "typeFilter");
        this.__keyword = new ObservedPropertySimplePU('', this, "keyword");
        this.__customStart = new ObservedPropertySimplePU(DateUtil.startOfDay(Date.now()) - 6 * DateUtil.DAY_MS, this, "customStart");
        this.__customEnd = new ObservedPropertySimplePU(DateUtil.startOfDay(Date.now()), this, "customEnd");
        this.__bars = new ObservedPropertyObjectPU([], this, "bars");
        this.__selRecord = new ObservedPropertyObjectPU(null, this, "selRecord");
        this.__showSheet = new ObservedPropertySimplePU(false, this, "showSheet");
        this.__editNote = new ObservedPropertySimplePU('', this, "editNote");
        this.__editValue = new ObservedPropertySimplePU('', this, "editValue");
        this.__editTs = new ObservedPropertySimplePU(0, this, "editTs");
        this.__recPointsText = new ObservedPropertySimplePU('', this, "recPointsText");
        this.__totalG = new ObservedPropertySimplePU(0, this, "totalG");
        this.__groups = new ObservedPropertyObjectPU([], this, "groups");
        this.setInitiallyProvidedValue(params);
        this.declareWatch("tick", this.refresh);
        this.declareWatch("extRange", this.onExternalRange);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HistoryView_Params) {
        if (params.records !== undefined) {
            this.records = params.records;
        }
        if (params.rawRecords !== undefined) {
            this.rawRecords = params.rawRecords;
        }
        if (params.rangeIndex !== undefined) {
            this.rangeIndex = params.rangeIndex;
        }
        if (params.typeFilter !== undefined) {
            this.typeFilter = params.typeFilter;
        }
        if (params.keyword !== undefined) {
            this.keyword = params.keyword;
        }
        if (params.customStart !== undefined) {
            this.customStart = params.customStart;
        }
        if (params.customEnd !== undefined) {
            this.customEnd = params.customEnd;
        }
        if (params.bars !== undefined) {
            this.bars = params.bars;
        }
        if (params.selRecord !== undefined) {
            this.selRecord = params.selRecord;
        }
        if (params.showSheet !== undefined) {
            this.showSheet = params.showSheet;
        }
        if (params.editNote !== undefined) {
            this.editNote = params.editNote;
        }
        if (params.editValue !== undefined) {
            this.editValue = params.editValue;
        }
        if (params.editTs !== undefined) {
            this.editTs = params.editTs;
        }
        if (params.recPointsText !== undefined) {
            this.recPointsText = params.recPointsText;
        }
        if (params.totalG !== undefined) {
            this.totalG = params.totalG;
        }
        if (params.groups !== undefined) {
            this.groups = params.groups;
        }
    }
    updateStateVars(params: HistoryView_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__tick.purgeDependencyOnElmtId(rmElmtId);
        this.__records.purgeDependencyOnElmtId(rmElmtId);
        this.__rawRecords.purgeDependencyOnElmtId(rmElmtId);
        this.__rangeIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__extRange.purgeDependencyOnElmtId(rmElmtId);
        this.__typeFilter.purgeDependencyOnElmtId(rmElmtId);
        this.__keyword.purgeDependencyOnElmtId(rmElmtId);
        this.__customStart.purgeDependencyOnElmtId(rmElmtId);
        this.__customEnd.purgeDependencyOnElmtId(rmElmtId);
        this.__bars.purgeDependencyOnElmtId(rmElmtId);
        this.__selRecord.purgeDependencyOnElmtId(rmElmtId);
        this.__showSheet.purgeDependencyOnElmtId(rmElmtId);
        this.__editNote.purgeDependencyOnElmtId(rmElmtId);
        this.__editValue.purgeDependencyOnElmtId(rmElmtId);
        this.__editTs.purgeDependencyOnElmtId(rmElmtId);
        this.__recPointsText.purgeDependencyOnElmtId(rmElmtId);
        this.__totalG.purgeDependencyOnElmtId(rmElmtId);
        this.__groups.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__tick.aboutToBeDeleted();
        this.__records.aboutToBeDeleted();
        this.__rawRecords.aboutToBeDeleted();
        this.__rangeIndex.aboutToBeDeleted();
        this.__extRange.aboutToBeDeleted();
        this.__typeFilter.aboutToBeDeleted();
        this.__keyword.aboutToBeDeleted();
        this.__customStart.aboutToBeDeleted();
        this.__customEnd.aboutToBeDeleted();
        this.__bars.aboutToBeDeleted();
        this.__selRecord.aboutToBeDeleted();
        this.__showSheet.aboutToBeDeleted();
        this.__editNote.aboutToBeDeleted();
        this.__editValue.aboutToBeDeleted();
        this.__editTs.aboutToBeDeleted();
        this.__recPointsText.aboutToBeDeleted();
        this.__totalG.aboutToBeDeleted();
        this.__groups.aboutToBeDeleted();
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
    private __records: ObservedPropertyObjectPU<BehaviorRecord[]>;
    get records() {
        return this.__records.get();
    }
    set records(newValue: BehaviorRecord[]) {
        this.__records.set(newValue);
    }
    private __rawRecords: ObservedPropertyObjectPU<BehaviorRecord[]>;
    get rawRecords() {
        return this.__rawRecords.get();
    }
    set rawRecords(newValue: BehaviorRecord[]) {
        this.__rawRecords.set(newValue);
    }
    private __rangeIndex: ObservedPropertySimplePU<number>;
    get rangeIndex() {
        return this.__rangeIndex.get();
    }
    set rangeIndex(newValue: number) {
        this.__rangeIndex.set(newValue);
    }
    // 首页周报卡跳转时预选的时间档（0 全部 / 1 今日 / 2 近7天 / 3 近30天 / 4 自定义） */
    private __extRange: ObservedPropertyAbstractPU<number>;
    get extRange() {
        return this.__extRange.get();
    }
    set extRange(newValue: number) {
        this.__extRange.set(newValue);
    }
    private __typeFilter: ObservedPropertySimplePU<string>;
    get typeFilter() {
        return this.__typeFilter.get();
    }
    set typeFilter(newValue: string) {
        this.__typeFilter.set(newValue);
    }
    private __keyword: ObservedPropertySimplePU<string>;
    get keyword() {
        return this.__keyword.get();
    }
    set keyword(newValue: string) {
        this.__keyword.set(newValue);
    }
    private __customStart: ObservedPropertySimplePU<number>;
    get customStart() {
        return this.__customStart.get();
    }
    set customStart(newValue: number) {
        this.__customStart.set(newValue);
    }
    private __customEnd: ObservedPropertySimplePU<number>;
    get customEnd() {
        return this.__customEnd.get();
    }
    set customEnd(newValue: number) {
        this.__customEnd.set(newValue);
    }
    private __bars: ObservedPropertyObjectPU<PieItem[]>;
    get bars() {
        return this.__bars.get();
    }
    set bars(newValue: PieItem[]) {
        this.__bars.set(newValue);
    }
    private __selRecord: ObservedPropertyObjectPU<BehaviorRecord | null>;
    get selRecord() {
        return this.__selRecord.get();
    }
    set selRecord(newValue: BehaviorRecord | null) {
        this.__selRecord.set(newValue);
    }
    private __showSheet: ObservedPropertySimplePU<boolean>;
    get showSheet() {
        return this.__showSheet.get();
    }
    set showSheet(newValue: boolean) {
        this.__showSheet.set(newValue);
    }
    private __editNote: ObservedPropertySimplePU<string>;
    get editNote() {
        return this.__editNote.get();
    }
    set editNote(newValue: string) {
        this.__editNote.set(newValue);
    }
    private __editValue: ObservedPropertySimplePU<string>;
    get editValue() {
        return this.__editValue.get();
    }
    set editValue(newValue: string) {
        this.__editValue.set(newValue);
    }
    private __editTs: ObservedPropertySimplePU<number>;
    get editTs() {
        return this.__editTs.get();
    }
    set editTs(newValue: number) {
        this.__editTs.set(newValue);
    }
    private __recPointsText: ObservedPropertySimplePU<string>;
    get recPointsText() {
        return this.__recPointsText.get();
    }
    set recPointsText(newValue: string) {
        this.__recPointsText.set(newValue);
    }
    private __totalG: ObservedPropertySimplePU<number>;
    get totalG() {
        return this.__totalG.get();
    }
    set totalG(newValue: number) {
        this.__totalG.set(newValue);
    }
    private __groups: ObservedPropertyObjectPU<RecordGroup[]>;
    get groups() {
        return this.__groups.get();
    }
    set groups(newValue: RecordGroup[]) {
        this.__groups.set(newValue);
    }
    aboutToAppear(): void {
        this.refresh();
    }
    /** 首页周报卡等外部入口预选时间档 */
    onExternalRange(): void {
        if (this.rangeIndex !== this.extRange) {
            this.rangeIndex = this.extRange;
            this.refresh();
        }
    }
    async refresh(): Promise<void> {
        try {
            await AppInit.ensure();
            const now = Date.now();
            let start = 0;
            let end = now;
            if (this.rangeIndex === 1) {
                start = DateUtil.startOfDay(now);
            }
            else if (this.rangeIndex === 2) {
                start = DateUtil.startOfDay(now) - 6 * DateUtil.DAY_MS;
            }
            else if (this.rangeIndex === 3) {
                start = DateUtil.startOfDay(now) - 29 * DateUtil.DAY_MS;
            }
            else if (this.rangeIndex === 4) {
                // 自定义区间：截止日取整天，未来时刻自动收敛到当前
                start = this.customStart;
                end = this.customEnd + DateUtil.DAY_MS - 1;
                if (end > now) {
                    end = now;
                }
                if (start > end) {
                    start = 0;
                }
            }
            this.rawRecords = await BehaviorRepo.query(start, end, this.typeFilter);
            const items = StatsService.subShare(await BehaviorRepo.all(), start === 0 ? 0 : start);
            this.bars = items;
            this.applyFilter();
        }
        catch (e) {
            console.error('HistoryView refresh error: ' + JSON.stringify(e));
        }
    }
    /** 关键字过滤 + 汇总 + 分组（输入关键字时只做内存过滤，不重复查库） */
    private applyFilter(): void {
        const kw = this.keyword.trim();
        let list = this.rawRecords;
        if (kw !== '') {
            list = list.filter((r: BehaviorRecord) => r.subType.includes(kw) || r.note.includes(kw));
        }
        this.records = list;
        let sum = 0;
        for (const r of list) {
            sum += r.reductionG;
        }
        this.totalG = sum;
        this.groups = this.buildGroups(list);
    }
    private buildGroups(list: BehaviorRecord[]): RecordGroup[] {
        const groups: RecordGroup[] = [];
        let cur: RecordGroup | null = null;
        for (const r of list) {
            const label = this.groupLabel(r.createdAt);
            if (cur === null || cur.label !== label) {
                const g: RecordGroup = { label: label, items: [] };
                groups.push(g);
                cur = g;
            }
            (cur as RecordGroup).items.push(r);
        }
        return groups;
    }
    /** 今天 / 昨天 / M月D日（跨年带年份）；记录已按时间倒序，顺序遍历即可分段 */
    private groupLabel(ts: number): string {
        const today = DateUtil.startOfDay(Date.now());
        const day = DateUtil.startOfDay(ts);
        if (day === today) {
            return '今天';
        }
        if (day === today - DateUtil.DAY_MS) {
            return '昨天';
        }
        const d = new Date(ts);
        const label = (d.getMonth() + 1) + '月' + d.getDate() + '日';
        if (d.getFullYear() === new Date().getFullYear()) {
            return label;
        }
        return d.getFullYear() + '年' + label;
    }
    private openDetail(r: BehaviorRecord): void {
        this.selRecord = r;
        this.editNote = r.note;
        this.editValue = '' + r.value;
        this.editTs = 0;
        this.recPointsText = '查询中…';
        this.showSheet = true;
        this.loadPoints(r.id);
    }
    /** 反查本笔记录关联的全部积分流水（发放/修改补正），展示净积分与冲减明细 */
    private async loadPoints(id: number): Promise<void> {
        try {
            const flows = await PointsService.listBySourceRef('behavior', id);
            let net = 0;
            let reversed = 0;
            for (const f of flows) {
                net += f.points;
                if (f.points < 0) {
                    reversed += -f.points;
                }
            }
            if (flows.length === 0) {
                this.recPointsText = '本笔积分：0 分';
            }
            else if (reversed > 0) {
                this.recPointsText = `本笔积分：净 ${net} 分（含冲减 ${reversed} 分）`;
            }
            else {
                this.recPointsText = `本笔积分：+${net} 分`;
            }
        }
        catch (e) {
            this.recPointsText = '本笔积分：查询失败';
        }
    }
    detailSheet(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/History.ets(174:5)", "entry");
            Column.width('100%');
            Column.padding(16);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/History.ets(175:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('行为详情');
            Text.debugLine("entry/src/main/ets/pages/History.ets(176:9)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/History.ets(179:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('×');
            Text.debugLine("entry/src/main/ets/pages/History.ets(180:9)", "entry");
            Text.fontSize(16);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.onClick(() => {
                this.showSheet = false;
            });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.selRecord !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 10 });
                        Row.debugLine("entry/src/main/ets/pages/History.ets(190:9)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('·');
                        Text.debugLine("entry/src/main/ets/pages/History.ets(191:11)", "entry");
                        Text.fontSize(30);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 4 });
                        Column.debugLine("entry/src/main/ets/pages/History.ets(193:11)", "entry");
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.selRecord as BehaviorRecord).subType);
                        Text.debugLine("entry/src/main/ets/pages/History.ets(194:13)", "entry");
                        Text.fontSize(17);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${(this.selRecord as BehaviorRecord).type} · ${(this.selRecord as BehaviorRecord).value}${(this.selRecord as BehaviorRecord).unit} × ${(this.selRecord as BehaviorRecord).factor}g`);
                        Text.debugLine("entry/src/main/ets/pages/History.ets(197:13)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${((this.selRecord as BehaviorRecord).reductionG / 1000).toFixed(2)} kg`);
                        Text.debugLine("entry/src/main/ets/pages/History.ets(203:11)", "entry");
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(Theme.REDUCE);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.recPointsText);
                        Text.debugLine("entry/src/main/ets/pages/History.ets(210:9)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.POINTS);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`录入时间：${DateUtil.formatFull((this.selRecord as BehaviorRecord).createdAt)}`);
                        Text.debugLine("entry/src/main/ets/pages/History.ets(215:9)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                        Text.width('100%');
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 修改数值
                        Row.create({ space: 10 });
                        Row.debugLine("entry/src/main/ets/pages/History.ets(221:9)", "entry");
                        // 修改数值
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('数值');
                        Text.debugLine("entry/src/main/ets/pages/History.ets(222:11)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(Theme.TEXT);
                        Text.width(40);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '修改数值', text: this.editValue });
                        TextInput.debugLine("entry/src/main/ets/pages/History.ets(226:11)", "entry");
                        TextInput.type(InputType.NUMBER_DECIMAL);
                        TextInput.layoutWeight(1);
                        TextInput.height(38);
                        TextInput.onChange((v: string) => {
                            this.editValue = v;
                        });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.selRecord as BehaviorRecord).unit);
                        Text.debugLine("entry/src/main/ets/pages/History.ets(233:11)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    // 修改数值
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // 修改日期（保留原时分秒）
                        Row.create({ space: 10 });
                        Row.debugLine("entry/src/main/ets/pages/History.ets(240:9)", "entry");
                        // 修改日期（保留原时分秒）
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('日期');
                        Text.debugLine("entry/src/main/ets/pages/History.ets(241:11)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(Theme.TEXT);
                        Text.width(40);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        CalendarPicker.create({ selected: new Date(this.editTs > 0 ? this.editTs : (this.selRecord as BehaviorRecord).createdAt) });
                        CalendarPicker.debugLine("entry/src/main/ets/pages/History.ets(245:11)", "entry");
                        CalendarPicker.onChange((date: Date) => {
                            const base = this.editTs > 0 ? this.editTs : (this.selRecord as BehaviorRecord).createdAt;
                            const d = new Date(base);
                            this.editTs = new Date(date.getFullYear(), date.getMonth(), date.getDate(), d.getHours(), d.getMinutes(), d.getSeconds()).getTime();
                        });
                    }, CalendarPicker);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.editTs > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('已改为 ' + DateUtil.formatMDHM(this.editTs));
                                    Text.debugLine("entry/src/main/ets/pages/History.ets(253:13)", "entry");
                                    Text.fontSize(11);
                                    Text.fontColor(Theme.PRIMARY);
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
                    // 修改日期（保留原时分秒）
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        TextInput.create({ placeholder: '修改备注（≤100字）', text: this.editNote });
                        TextInput.debugLine("entry/src/main/ets/pages/History.ets(260:9)", "entry");
                        TextInput.height(38);
                        TextInput.onChange((v: string) => {
                            this.editNote = v;
                        });
                    }, TextInput);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 12 });
                        Row.debugLine("entry/src/main/ets/pages/History.ets(266:9)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('保存修改');
                        Button.debugLine("entry/src/main/ets/pages/History.ets(267:11)", "entry");
                        Button.layoutWeight(1);
                        Button.height(40);
                        Button.fontSize(14);
                        Button.backgroundColor(Theme.PRIMARY);
                        Button.onClick(() => {
                            this.saveEdit();
                        });
                    }, Button);
                    Button.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('保存备注');
                        Button.debugLine("entry/src/main/ets/pages/History.ets(275:11)", "entry");
                        Button.layoutWeight(1);
                        Button.height(40);
                        Button.fontSize(14);
                        Button.backgroundColor(Theme.PRIMARY_HOVER);
                        Button.onClick(() => {
                            this.saveNote();
                        });
                    }, Button);
                    Button.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel('删除记录');
                        Button.debugLine("entry/src/main/ets/pages/History.ets(286:9)", "entry");
                        Button.width('100%');
                        Button.height(40);
                        Button.fontSize(14);
                        Button.backgroundColor(Theme.WARN);
                        Button.onClick(() => {
                            this.confirmDelete();
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
    private async saveEdit(): Promise<void> {
        if (this.selRecord === null) {
            return;
        }
        const rec = this.selRecord as BehaviorRecord;
        const v = parseFloat(this.editValue);
        if (isNaN(v) || v <= 0) {
            promptAction.showToast({ message: '请输入大于 0 的数值' });
            return;
        }
        const sub = CalculationService.findSub(rec.type, rec.subType);
        if (sub !== null && v > sub.max) {
            promptAction.showToast({ message: `超出单次上限 ${sub.max}${sub.unit}` });
            return;
        }
        try {
            await BehaviorService.updateRecord(rec.id, v, this.editTs);
            this.selRecord = null;
            this.showSheet = false;
            promptAction.showToast({ message: '记录已更新' });
        }
        catch (e) {
            promptAction.showToast({ message: '更新失败，请重试' });
        }
    }
    private confirmDelete(): void {
        if (this.selRecord === null) {
            return;
        }
        const id = (this.selRecord as BehaviorRecord).id;
        AlertDialog.show({
            title: '删除确认',
            message: '删除后该记录的减排量与积分流水将无法恢复，确定删除？',
            primaryButton: {
                value: '取消',
                action: () => {
                }
            },
            secondaryButton: {
                value: '删除',
                fontColor: Theme.WARN,
                action: () => {
                    BehaviorService.deleteById(id);
                    this.showSheet = false;
                    promptAction.showToast({ message: '已删除' });
                }
            }
        });
    }
    private async saveNote(): Promise<void> {
        if (this.selRecord === null) {
            return;
        }
        if (this.editNote.length > 100) {
            promptAction.showToast({ message: '备注不能超过 100 字' });
            return;
        }
        const id = (this.selRecord as BehaviorRecord).id;
        await BehaviorService.updateNote(id, this.editNote);
        this.selRecord = null;
        this.showSheet = false;
        promptAction.showToast({ message: '备注已更新' });
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/History.ets(366:5)", "entry");
            Scroll.scrollBar(BarState.Auto);
            Scroll.width('100%');
            Scroll.height('100%');
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/History.ets(367:5)", "entry");
            Column.width('100%');
            Column.bindSheet(this.showSheet, { builder: () => {
                    this.detailSheet.call(this);
                } }, {
                height: 600,
                showClose: false,
                onDisappear: () => {
                    this.showSheet = false;
                }
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('历史记录');
            Text.debugLine("entry/src/main/ets/pages/History.ets(368:7)", "entry");
            Text.fontSize(20);
            Text.fontWeight(FontWeight.Bold);
            Text.width('100%');
            Text.padding({ left: 14, top: 14 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 筛选
            Column.create({ space: 10 });
            Column.debugLine("entry/src/main/ets/pages/History.ets(375:7)", "entry");
            // 筛选
            Column.width('100%');
            // 筛选
            Column.padding({ left: 14, right: 14 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TextInput.create({ placeholder: '搜索子类型或备注' });
            TextInput.debugLine("entry/src/main/ets/pages/History.ets(376:9)", "entry");
            TextInput.height(36);
            TextInput.fontSize(13);
            TextInput.onChange((v: string) => {
                this.keyword = v;
                this.applyFilter();
            });
        }, TextInput);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/History.ets(384:9)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, idx: number) => {
                const r = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(r);
                    Text.debugLine("entry/src/main/ets/pages/History.ets(386:13)", "entry");
                    Text.fontSize(12);
                    Text.fontColor(this.rangeIndex === idx ? '#FFFFFF' : Theme.TEXT);
                    Text.backgroundColor(this.rangeIndex === idx ? Theme.PRIMARY : Theme.CARD);
                    Text.borderRadius(14);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.onClick(() => {
                        this.rangeIndex = idx;
                        this.refresh();
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, RANGES, forEachItemGenFunction, (r: string, idx: number) => idx.toString(), true, true);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/History.ets(397:11)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`合计 ${DateUtil.gramsToKg(this.totalG)} kg`);
            Text.debugLine("entry/src/main/ets/pages/History.ets(398:11)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.REDUCE);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.rangeIndex === 4) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 8 });
                        Row.debugLine("entry/src/main/ets/pages/History.ets(405:11)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('起');
                        Text.debugLine("entry/src/main/ets/pages/History.ets(406:13)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        CalendarPicker.create({ selected: new Date(this.customStart) });
                        CalendarPicker.debugLine("entry/src/main/ets/pages/History.ets(409:13)", "entry");
                        CalendarPicker.onChange((date: Date) => {
                            this.customStart = DateUtil.startOfDay(date.getTime());
                            this.refresh();
                        });
                    }, CalendarPicker);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('止');
                        Text.debugLine("entry/src/main/ets/pages/History.ets(414:13)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        CalendarPicker.create({ selected: new Date(this.customEnd) });
                        CalendarPicker.debugLine("entry/src/main/ets/pages/History.ets(417:13)", "entry");
                        CalendarPicker.onChange((date: Date) => {
                            this.customEnd = DateUtil.startOfDay(date.getTime());
                            this.refresh();
                        });
                    }, CalendarPicker);
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/History.ets(426:9)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, idx: number) => {
                const t = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(t);
                    Text.debugLine("entry/src/main/ets/pages/History.ets(428:13)", "entry");
                    Text.fontSize(12);
                    Text.fontColor(this.typeFilter === t ? '#FFFFFF' : Theme.TEXT);
                    Text.backgroundColor(this.typeFilter === t ? Theme.PRIMARY : Theme.CARD);
                    Text.borderRadius(14);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.onClick(() => {
                        this.typeFilter = t;
                        this.refresh();
                    });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, TYPES, forEachItemGenFunction, (t: string, idx: number) => idx.toString(), true, true);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        // 筛选
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 记录列表：直接铺在整页 Scroll 里，随页面一起滚动
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/History.ets(446:7)", "entry");
            // 记录列表：直接铺在整页 Scroll 里，随页面一起滚动
            Column.width('100%');
            // 记录列表：直接铺在整页 Scroll 里，随页面一起滚动
            Column.padding({ left: 14, right: 14 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const g = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 8 });
                    Column.debugLine("entry/src/main/ets/pages/History.ets(448:11)", "entry");
                    Column.width('100%');
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.debugLine("entry/src/main/ets/pages/History.ets(449:13)", "entry");
                    Row.width('100%');
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(g.label);
                    Text.debugLine("entry/src/main/ets/pages/History.ets(450:15)", "entry");
                    Text.fontSize(28);
                    Text.fontColor(Theme.TEXT);
                    Text.backgroundColor(Theme.BG);
                    Text.borderRadius(16);
                    Text.padding({ left: 20, right: 20, top: 8, bottom: 8 });
                }, Text);
                Text.pop();
                Row.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    ForEach.create();
                    const forEachItemGenFunction = _item => {
                        const r = _item;
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Row.create({ space: 12 });
                            Row.debugLine("entry/src/main/ets/pages/History.ets(459:15)", "entry");
                            Row.width('100%');
                            Row.padding(12);
                            Row.borderRadius(Theme.R_SMALL);
                            Row.backgroundColor(Theme.CARD);
                            Row.border({ width: 1, color: Theme.DIVIDER });
                            Row.onClick(() => {
                                this.openDetail(r);
                            });
                        }, Row);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.debugLine("entry/src/main/ets/pages/History.ets(460:17)", "entry");
                            Column.width(3);
                            Column.height(34);
                            Column.borderRadius(2);
                            Column.backgroundColor(Theme.PRIMARY_HOVER);
                        }, Column);
                        Column.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create({ space: 4 });
                            Column.debugLine("entry/src/main/ets/pages/History.ets(465:17)", "entry");
                            Column.alignItems(HorizontalAlign.Start);
                            Column.layoutWeight(1);
                        }, Column);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(`${r.subType} ${r.value}${r.unit}`);
                            Text.debugLine("entry/src/main/ets/pages/History.ets(466:19)", "entry");
                            Text.fontSize(28);
                            Text.fontWeight(FontWeight.Medium);
                            Text.maxLines(1);
                            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(DateUtil.formatMDHM(r.createdAt) + (r.note !== '' ? ' · ' + r.note : ''));
                            Text.debugLine("entry/src/main/ets/pages/History.ets(471:19)", "entry");
                            Text.fontSize(28);
                            Text.fontColor(Theme.TEXT_TERTIARY);
                            Text.maxLines(1);
                            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                        }, Text);
                        Text.pop();
                        Column.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(`-${(r.reductionG / 1000).toFixed(2)}kg`);
                            Text.debugLine("entry/src/main/ets/pages/History.ets(479:17)", "entry");
                            Text.fontSize(28);
                            Text.fontWeight(FontWeight.Bold);
                            Text.fontColor(Theme.REDUCE);
                        }, Text);
                        Text.pop();
                        Row.pop();
                    };
                    this.forEachUpdateFunction(elmtId, g.items, forEachItemGenFunction, (r: BehaviorRecord) => '' + r.id + '_' + r.note + '_' + r.value, false, false);
                }, ForEach);
                ForEach.pop();
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.groups, forEachItemGenFunction, (g: RecordGroup) => g.label + '#' + g.items.length, false, false);
        }, ForEach);
        ForEach.pop();
        // 记录列表：直接铺在整页 Scroll 里，随页面一起滚动
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.records.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new EmptyState(this, {
                                    icon: '',
                                    title: '暂无记录',
                                    desc: '当前筛选条件下没有低碳行为记录',
                                    buttonText: '去记录',
                                    onButton: (): void => {
                                        AppStorage.setOrCreate('mainTab', 1);
                                    }
                                }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/History.ets", line: 501, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        icon: '',
                                        title: '暂无记录',
                                        desc: '当前筛选条件下没有低碳行为记录',
                                        buttonText: '去记录',
                                        onButton: (): void => {
                                            AppStorage.setOrCreate('mainTab', 1);
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
            // 子类型减排对比
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // 子类型减排对比
            if (this.bars.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 10 });
                        Column.debugLine("entry/src/main/ets/pages/History.ets(514:9)", "entry");
                        Column.width('100%');
                        Column.margin({ left: 14, right: 14, bottom: 12 });
                        Column.padding(14);
                        Column.borderRadius(16);
                        Column.backgroundColor(Theme.CARD);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('子类型减排对比（当期）');
                        Text.debugLine("entry/src/main/ets/pages/History.ets(515:11)", "entry");
                        Text.fontSize(14);
                        Text.fontWeight(FontWeight.Medium);
                    }, Text);
                    Text.pop();
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new BarChart(this, { items: this.bars }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/History.ets", line: 518, col: 11 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        items: this.bars
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    items: this.bars
                                });
                            }
                        }, { name: "BarChart" });
                    }
                    Column.pop();
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
        this.__extRange.resetSource();
    }
}
