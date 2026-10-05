if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface BarChart_Params {
    items?: PieItem[];
    settings?: RenderingContextSettings;
    ctx?: CanvasRenderingContext2D;
}
interface GoalRing_Params {
    progress?: number;
    centerText?: string;
    subText?: string;
    settings?: RenderingContextSettings;
    ctx?: CanvasRenderingContext2D;
}
interface PieChart_Params {
    items?: PieItem[];
    centerSub?: string;
    settings?: RenderingContextSettings;
    ctx?: CanvasRenderingContext2D;
}
interface TrendBarChart_Params {
    points?: ChartPoint[];
    settings?: RenderingContextSettings;
    ctx?: CanvasRenderingContext2D;
}
interface LineChart_Params {
    points?: ChartPoint[];
    settings?: RenderingContextSettings;
    ctx?: CanvasRenderingContext2D;
}
import display from "@ohos:display";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
/** Canvas 的 font 单位是物理 px，需乘屏幕密度才能达到 Text fontSize 的 fp 视觉大小 */
function fpFont(n: number): string {
    return Math.round(n * display.getDefaultDisplaySync().densityPixels) + 'px';
}
export interface ChartPoint {
    label: string;
    value: number;
}
export interface PieItem {
    name: string;
    value: number;
    color: string;
    pct: number;
}
function fmtValue(v: number): string {
    if (v >= 1000000) {
        return (v / 1000000).toFixed(1) + 't';
    }
    else if (v >= 1000) {
        return (v / 1000).toFixed(1) + 'kg';
    }
    return Math.round(v) + 'g';
}
export class LineChart extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__points = new SynchedPropertyObjectOneWayPU(params.points, this, "points");
        this.settings = new RenderingContextSettings(true);
        this.ctx = new CanvasRenderingContext2D(this.settings);
        this.setInitiallyProvidedValue(params);
        this.declareWatch("points", this.redraw);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: LineChart_Params) {
        if (params.points === undefined) {
            this.__points.set([]);
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.ctx !== undefined) {
            this.ctx = params.ctx;
        }
    }
    updateStateVars(params: LineChart_Params) {
        this.__points.reset(params.points);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__points.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__points.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __points: SynchedPropertySimpleOneWayPU<ChartPoint[]>;
    get points() {
        return this.__points.get();
    }
    set points(newValue: ChartPoint[]) {
        this.__points.set(newValue);
    }
    private settings: RenderingContextSettings;
    private ctx: CanvasRenderingContext2D;
    redraw(): void {
        this.draw();
    }
    private draw(): void {
        const w = this.ctx.width;
        const h = this.ctx.height;
        this.ctx.clearRect(0, 0, w, h);
        const pts = this.points;
        if (pts.length === 0 || w <= 0 || h <= 0) {
            return;
        }
        const padL = 52;
        const padR = 14;
        const padT = 16;
        const padB = 30;
        const plotW = w - padL - padR;
        const plotH = h - padT - padB;
        let maxV = 1;
        for (const p of pts) {
            if (p.value > maxV) {
                maxV = p.value;
            }
        }
        maxV = maxV * 1.15;
        // 网格与 Y 轴标签
        this.ctx.font = fpFont(12);
        this.ctx.strokeStyle = Theme.DIVIDER;
        this.ctx.lineWidth = 1;
        for (let i = 0; i <= 4; i++) {
            const y = padT + plotH * i / 4;
            this.ctx.beginPath();
            this.ctx.moveTo(padL, y);
            this.ctx.lineTo(w - padR, y);
            this.ctx.stroke();
            this.ctx.fillStyle = Theme.TEXT_TERTIARY;
            this.ctx.textAlign = 'right';
            this.ctx.fillText(fmtValue(maxV * (1 - i / 4)), padL - 6, y + 4);
        }
        const px = (i: number): number => padL + plotW * (pts.length === 1 ? 0.5 : i / (pts.length - 1));
        const py = (v: number): number => padT + plotH * (1 - v / maxV);
        // X 轴标签
        this.ctx.textAlign = 'center';
        const step = Math.max(1, Math.ceil(pts.length / 6));
        for (let i = 0; i < pts.length; i += step) {
            this.ctx.fillStyle = Theme.TEXT_TERTIARY;
            this.ctx.fillText(pts[i].label, px(i), h - 10);
        }
        // 面积
        const grad = this.ctx.createLinearGradient(0, padT, 0, padT + plotH);
        grad.addColorStop(0, 'rgba(0,185,107,0.2)');
        grad.addColorStop(1, 'rgba(0,185,107,0.02)');
        this.ctx.fillStyle = grad;
        this.ctx.beginPath();
        this.ctx.moveTo(px(0), padT + plotH);
        for (let i = 0; i < pts.length; i++) {
            this.ctx.lineTo(px(i), py(pts[i].value));
        }
        this.ctx.lineTo(px(pts.length - 1), padT + plotH);
        this.ctx.closePath();
        this.ctx.fill();
        // 折线
        this.ctx.strokeStyle = Theme.PRIMARY;
        this.ctx.lineWidth = 2;
        this.ctx.beginPath();
        for (let i = 0; i < pts.length; i++) {
            if (i === 0) {
                this.ctx.moveTo(px(i), py(pts[i].value));
            }
            else {
                this.ctx.lineTo(px(i), py(pts[i].value));
            }
        }
        this.ctx.stroke();
        // 数据点
        for (let i = 0; i < pts.length; i++) {
            this.ctx.beginPath();
            this.ctx.arc(px(i), py(pts[i].value), 3, 0, Math.PI * 2);
            this.ctx.fillStyle = '#FFFFFF';
            this.ctx.fill();
            this.ctx.strokeStyle = Theme.PRIMARY;
            this.ctx.lineWidth = 2;
            this.ctx.stroke();
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.ctx);
            Canvas.debugLine("entry/src/main/ets/components/Chart.ets(128:5)", "entry");
            Canvas.width('100%');
            Canvas.height(290);
            Canvas.onReady(() => {
                this.draw();
            });
        }, Canvas);
        Canvas.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
export class TrendBarChart extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__points = new SynchedPropertyObjectOneWayPU(params.points, this, "points");
        this.settings = new RenderingContextSettings(true);
        this.ctx = new CanvasRenderingContext2D(this.settings);
        this.setInitiallyProvidedValue(params);
        this.declareWatch("points", this.redraw);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: TrendBarChart_Params) {
        if (params.points === undefined) {
            this.__points.set([]);
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.ctx !== undefined) {
            this.ctx = params.ctx;
        }
    }
    updateStateVars(params: TrendBarChart_Params) {
        this.__points.reset(params.points);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__points.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__points.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __points: SynchedPropertySimpleOneWayPU<ChartPoint[]>;
    get points() {
        return this.__points.get();
    }
    set points(newValue: ChartPoint[]) {
        this.__points.set(newValue);
    }
    private settings: RenderingContextSettings;
    private ctx: CanvasRenderingContext2D;
    redraw(): void {
        this.draw();
    }
    private draw(): void {
        const w = this.ctx.width;
        const h = this.ctx.height;
        this.ctx.clearRect(0, 0, w, h);
        const pts = this.points;
        if (pts.length === 0 || w <= 0 || h <= 0) {
            return;
        }
        const padL = 12;
        const padR = 12;
        const padT = 42;
        const padB = 50;
        const plotW = w - padL - padR;
        const plotH = h - padT - padB;
        let maxV = 1;
        for (const p of pts) {
            if (p.value > maxV) {
                maxV = p.value;
            }
        }
        const n = pts.length;
        const slot = plotW / n;
        // 数值只标注峰值与当期，防止拥挤
        let maxIdx = 0;
        for (let i = 1; i < n; i++) {
            if (pts[i].value > pts[maxIdx].value) {
                maxIdx = i;
            }
        }
        const barW = Math.min(60, slot * 0.72);
        const baseline = padT + plotH;
        for (let i = 0; i < n; i++) {
            const cx = padL + slot * i + slot / 2;
            const v = pts[i].value;
            const bh = Math.max(v > 0 ? 4 : 2, plotH * (v / maxV));
            const bx = cx - barW / 2;
            const by = baseline - bh;
            // 柱体（圆角顶）
            const r = Math.min(5, barW / 2);
            this.ctx.beginPath();
            this.ctx.moveTo(bx, baseline);
            this.ctx.lineTo(bx, by + r);
            this.ctx.arcTo(bx, by, bx + r, by, r);
            this.ctx.lineTo(bx + barW - r, by);
            this.ctx.arcTo(bx + barW, by, bx + barW, by + r, r);
            this.ctx.lineTo(bx + barW, baseline);
            this.ctx.closePath();
            // 最后一根（当期）高亮主绿，其余浅绿
            this.ctx.fillStyle = i === n - 1 ? Theme.PRIMARY : Theme.PRIMARY_LIGHT;
            this.ctx.fill();
            // 顶部数值
            if (v > 0 && (i === n - 1 || i === maxIdx)) {
                this.ctx.fillStyle = i === n - 1 ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
                this.ctx.textAlign = 'center';
                this.ctx.font = 'bold ' + fpFont(20) + ' sans-serif';
                this.ctx.fillText(fmtValue(v), cx, by - 10);
            }
            // X 轴标签（28px 大字，柱多于 8 根时隔一画一防重叠）
            if (i % (n > 8 ? 2 : 1) === 0) {
                this.ctx.fillStyle = Theme.TEXT_TERTIARY;
                this.ctx.textAlign = 'center';
                this.ctx.font = fpFont(16);
                this.ctx.fillText(pts[i].label, cx, h - 12);
            }
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.ctx);
            Canvas.debugLine("entry/src/main/ets/components/Chart.ets(217:5)", "entry");
            Canvas.width('100%');
            Canvas.height(330);
            Canvas.onReady(() => {
                this.draw();
            });
        }, Canvas);
        Canvas.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
export class PieChart extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__items = new SynchedPropertyObjectOneWayPU(params.items, this, "items");
        this.__centerSub = new SynchedPropertySimpleOneWayPU(params.centerSub, this, "centerSub");
        this.settings = new RenderingContextSettings(true);
        this.ctx = new CanvasRenderingContext2D(this.settings);
        this.setInitiallyProvidedValue(params);
        this.declareWatch("items", this.redraw);
        this.declareWatch("centerSub", this.redraw);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: PieChart_Params) {
        if (params.items === undefined) {
            this.__items.set([]);
        }
        if (params.centerSub === undefined) {
            this.__centerSub.set('');
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.ctx !== undefined) {
            this.ctx = params.ctx;
        }
    }
    updateStateVars(params: PieChart_Params) {
        this.__items.reset(params.items);
        this.__centerSub.reset(params.centerSub);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__items.purgeDependencyOnElmtId(rmElmtId);
        this.__centerSub.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__items.aboutToBeDeleted();
        this.__centerSub.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __items: SynchedPropertySimpleOneWayPU<PieItem[]>;
    get items() {
        return this.__items.get();
    }
    set items(newValue: PieItem[]) {
        this.__items.set(newValue);
    }
    /** 中心数字下方的说明文字（如"近7天总量"），空串不显示 */
    private __centerSub: SynchedPropertySimpleOneWayPU<string>;
    get centerSub() {
        return this.__centerSub.get();
    }
    set centerSub(newValue: string) {
        this.__centerSub.set(newValue);
    }
    private settings: RenderingContextSettings;
    private ctx: CanvasRenderingContext2D;
    redraw(): void {
        this.draw();
    }
    private draw(): void {
        const w = this.ctx.width;
        const h = this.ctx.height;
        this.ctx.clearRect(0, 0, w, h);
        if (w <= 0 || h <= 0) {
            return;
        }
        const cx = w / 2;
        const cy = h / 2;
        const r = Math.min(cx, cy) - 8;
        let total = 0;
        for (const it of this.items) {
            total += it.value;
        }
        if (total <= 0) {
            this.ctx.beginPath();
            this.ctx.arc(cx, cy, r, 0, Math.PI * 2);
            this.ctx.fillStyle = Theme.DIVIDER;
            this.ctx.fill();
            this.ctx.fillStyle = Theme.TEXT_TERTIARY;
            this.ctx.font = fpFont(16);
            this.ctx.textAlign = 'center';
            this.ctx.fillText('暂无数据', cx, cy + 6);
            return;
        }
        let start = -Math.PI / 2;
        for (const it of this.items) {
            const angle = it.value / total * Math.PI * 2;
            this.ctx.beginPath();
            this.ctx.moveTo(cx, cy);
            this.ctx.arc(cx, cy, r, start, start + angle);
            this.ctx.closePath();
            this.ctx.fillStyle = it.color;
            this.ctx.fill();
            start += angle;
        }
        // 中心挖空成环
        this.ctx.beginPath();
        this.ctx.arc(cx, cy, r * 0.64, 0, Math.PI * 2);
        this.ctx.fillStyle = '#FFFFFF';
        this.ctx.fill();
        // 中心总量大数字 + 副标题
        this.ctx.textAlign = 'center';
        this.ctx.fillStyle = Theme.TEXT;
        if (this.centerSub !== '') {
            this.ctx.font = 'bold ' + fpFont(22) + ' sans-serif';
            this.ctx.fillText(fmtValue(total), cx, cy - 4);
            this.ctx.fillStyle = Theme.TEXT_TERTIARY;
            this.ctx.font = fpFont(14);
            this.ctx.fillText(this.centerSub, cx, cy + 22);
        }
        else {
            this.ctx.font = 'bold ' + fpFont(24) + ' sans-serif';
            this.ctx.fillText(fmtValue(total), cx, cy + 8);
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.ctx);
            Canvas.debugLine("entry/src/main/ets/components/Chart.ets(295:5)", "entry");
            Canvas.width('100%');
            Canvas.height(220);
            Canvas.onReady(() => {
                this.draw();
            });
        }, Canvas);
        Canvas.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
export class GoalRing extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__progress = new SynchedPropertySimpleOneWayPU(params.progress, this, "progress");
        this.__centerText = new SynchedPropertySimpleOneWayPU(params.centerText, this, "centerText");
        this.__subText = new SynchedPropertySimpleOneWayPU(params.subText, this, "subText");
        this.settings = new RenderingContextSettings(true);
        this.ctx = new CanvasRenderingContext2D(this.settings);
        this.setInitiallyProvidedValue(params);
        this.declareWatch("progress", this.redraw);
        this.declareWatch("centerText", this.redraw);
        this.declareWatch("subText", this.redraw);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: GoalRing_Params) {
        if (params.progress === undefined) {
            this.__progress.set(0);
        }
        if (params.centerText === undefined) {
            this.__centerText.set('');
        }
        if (params.subText === undefined) {
            this.__subText.set('');
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.ctx !== undefined) {
            this.ctx = params.ctx;
        }
    }
    updateStateVars(params: GoalRing_Params) {
        this.__progress.reset(params.progress);
        this.__centerText.reset(params.centerText);
        this.__subText.reset(params.subText);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__progress.purgeDependencyOnElmtId(rmElmtId);
        this.__centerText.purgeDependencyOnElmtId(rmElmtId);
        this.__subText.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__progress.aboutToBeDeleted();
        this.__centerText.aboutToBeDeleted();
        this.__subText.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    /** 0 ~ 1，大于 1 按已达成处理（金色） */
    private __progress: SynchedPropertySimpleOneWayPU<number>;
    get progress() {
        return this.__progress.get();
    }
    set progress(newValue: number) {
        this.__progress.set(newValue);
    }
    private __centerText: SynchedPropertySimpleOneWayPU<string>;
    get centerText() {
        return this.__centerText.get();
    }
    set centerText(newValue: string) {
        this.__centerText.set(newValue);
    }
    private __subText: SynchedPropertySimpleOneWayPU<string>;
    get subText() {
        return this.__subText.get();
    }
    set subText(newValue: string) {
        this.__subText.set(newValue);
    }
    private settings: RenderingContextSettings;
    private ctx: CanvasRenderingContext2D;
    redraw(): void {
        this.draw();
    }
    private draw(): void {
        const w = this.ctx.width;
        const h = this.ctx.height;
        this.ctx.clearRect(0, 0, w, h);
        if (w <= 0 || h <= 0) {
            return;
        }
        const cx = w / 2;
        const cy = h / 2;
        // 环缩小；同时保证环外上下的副文字/达成标记不被画布裁切（副文字下移留出与环的间距）
        const r = Math.min(Math.min(cx, cy) - 26, h - cy - 56, cy - 50);
        const lineW = 12;
        // 底环
        this.ctx.beginPath();
        this.ctx.arc(cx, cy, r, 0, Math.PI * 2);
        this.ctx.strokeStyle = Theme.DIVIDER;
        this.ctx.lineWidth = lineW;
        this.ctx.lineCap = 'round';
        this.ctx.stroke();
        // 进度弧（从顶部顺时针）
        const done = this.progress >= 1;
        const p = Math.max(0, Math.min(1, this.progress));
        if (p > 0) {
            this.ctx.beginPath();
            this.ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p);
            this.ctx.strokeStyle = done ? '#F7BA1E' : Theme.PRIMARY;
            this.ctx.lineWidth = lineW;
            this.ctx.lineCap = 'round';
            this.ctx.stroke();
        }
        // 中心文字（副文字/达成标记画在环外上下，均留在画布内）
        this.ctx.textAlign = 'center';
        this.ctx.fillStyle = done ? '#F7BA1E' : Theme.TEXT;
        this.ctx.font = 'bold ' + fpFont(32) + ' sans-serif';
        this.ctx.fillText(this.centerText, cx, cy + 11);
        this.ctx.fillStyle = Theme.PRIMARY;
        this.ctx.font = fpFont(28);
        this.ctx.fillText(this.subText, cx, cy + r + 42);
        if (done) {
            this.ctx.fillStyle = '#F7BA1E';
            this.ctx.font = fpFont(28);
            this.ctx.fillText('已达成 ✓', cx, cy - r - 24);
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.ctx);
            Canvas.debugLine("entry/src/main/ets/components/Chart.ets(364:5)", "entry");
            Canvas.width('100%');
            Canvas.height(240);
            Canvas.onReady(() => {
                this.draw();
            });
        }, Canvas);
        Canvas.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
export class BarChart extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__items = new SynchedPropertyObjectOneWayPU(params.items, this, "items");
        this.settings = new RenderingContextSettings(true);
        this.ctx = new CanvasRenderingContext2D(this.settings);
        this.setInitiallyProvidedValue(params);
        this.declareWatch("items", this.redraw);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: BarChart_Params) {
        if (params.items === undefined) {
            this.__items.set([]);
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.ctx !== undefined) {
            this.ctx = params.ctx;
        }
    }
    updateStateVars(params: BarChart_Params) {
        this.__items.reset(params.items);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__items.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__items.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __items: SynchedPropertySimpleOneWayPU<PieItem[]>;
    get items() {
        return this.__items.get();
    }
    set items(newValue: PieItem[]) {
        this.__items.set(newValue);
    }
    private settings: RenderingContextSettings;
    private ctx: CanvasRenderingContext2D;
    redraw(): void {
        this.draw();
    }
    private draw(): void {
        const w = this.ctx.width;
        const h = this.ctx.height;
        this.ctx.clearRect(0, 0, w, h);
        const items = this.items;
        if (items.length === 0 || w <= 0 || h <= 0) {
            return;
        }
        const padL = 158;
        const padR = 112;
        const rowH = 76;
        let maxV = 1;
        for (const it of items) {
            if (it.value > maxV) {
                maxV = it.value;
            }
        }
        const barW = w - padL - padR;
        for (let i = 0; i < items.length; i++) {
            const it = items[i];
            const y = 40 + i * rowH + rowH / 2;
            const bw = Math.max(6, barW * it.value / maxV);
            // 名称（最多 5 个字）
            this.ctx.fillStyle = Theme.TEXT;
            this.ctx.textAlign = 'right';
            let name = it.name;
            if (name.length > 5) {
                name = name.substring(0, 5);
            }
            this.ctx.font = fpFont(28);
            this.ctx.fillText(name, padL - 10, y + 10);
            // 条
            const r = 8;
            const bx = padL;
            const by = y - 15;
            const bh = 30;
            this.ctx.beginPath();
            this.ctx.moveTo(bx + r, by);
            this.ctx.arcTo(bx + bw, by, bx + bw, by + bh, r);
            this.ctx.arcTo(bx + bw, by + bh, bx, by + bh, r);
            this.ctx.arcTo(bx, by + bh, bx, by, r);
            this.ctx.arcTo(bx, by, bx + bw, by, r);
            this.ctx.closePath();
            this.ctx.fillStyle = i === 0 ? Theme.PRIMARY : Theme.PRIMARY_LIGHT;
            this.ctx.fill();
            // 数值（深色加大，一眼可读）
            this.ctx.fillStyle = Theme.TEXT_SECONDARY;
            this.ctx.textAlign = 'left';
            this.ctx.font = fpFont(28);
            this.ctx.fillText(fmtValue(it.value), padL + bw + 8, y + 10);
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.ctx);
            Canvas.debugLine("entry/src/main/ets/components/Chart.ets(438:5)", "entry");
            Canvas.width('100%');
            Canvas.height(this.items.length * 76 + 70);
            Canvas.onReady(() => {
                this.draw();
            });
        }, Canvas);
        Canvas.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
}
