if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ShareCard_Params {
    todayKg?: string;
    totalKg?: string;
    streak?: number;
    nickname?: string;
    drawn?: boolean;
    settings?: RenderingContextSettings;
    ctx?: CanvasRenderingContext2D;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import fs from "@ohos:file.fs";
import photoAccessHelper from "@ohos:file.photoAccessHelper";
import util from "@ohos:util";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import type { BehaviorRecord } from '../model/Models';
import { BehaviorRepo } from "@normalized:N&&&entry/src/main/ets/db/Repository&";
import { BadgeService } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
import { PrefsService } from "@normalized:N&&&entry/src/main/ets/common/PrefsService&";
class ShareCard extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__todayKg = new ObservedPropertySimplePU('0.00', this, "todayKg");
        this.__totalKg = new ObservedPropertySimplePU('0.00', this, "totalKg");
        this.__streak = new ObservedPropertySimplePU(0, this, "streak");
        this.__nickname = new ObservedPropertySimplePU('绿色生活家', this, "nickname");
        this.__drawn = new ObservedPropertySimplePU(false, this, "drawn");
        this.settings = new RenderingContextSettings(true);
        this.ctx = new CanvasRenderingContext2D(this.settings);
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ShareCard_Params) {
        if (params.todayKg !== undefined) {
            this.todayKg = params.todayKg;
        }
        if (params.totalKg !== undefined) {
            this.totalKg = params.totalKg;
        }
        if (params.streak !== undefined) {
            this.streak = params.streak;
        }
        if (params.nickname !== undefined) {
            this.nickname = params.nickname;
        }
        if (params.drawn !== undefined) {
            this.drawn = params.drawn;
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.ctx !== undefined) {
            this.ctx = params.ctx;
        }
    }
    updateStateVars(params: ShareCard_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__todayKg.purgeDependencyOnElmtId(rmElmtId);
        this.__totalKg.purgeDependencyOnElmtId(rmElmtId);
        this.__streak.purgeDependencyOnElmtId(rmElmtId);
        this.__nickname.purgeDependencyOnElmtId(rmElmtId);
        this.__drawn.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__todayKg.aboutToBeDeleted();
        this.__totalKg.aboutToBeDeleted();
        this.__streak.aboutToBeDeleted();
        this.__nickname.aboutToBeDeleted();
        this.__drawn.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __todayKg: ObservedPropertySimplePU<string>;
    get todayKg() {
        return this.__todayKg.get();
    }
    set todayKg(newValue: string) {
        this.__todayKg.set(newValue);
    }
    private __totalKg: ObservedPropertySimplePU<string>;
    get totalKg() {
        return this.__totalKg.get();
    }
    set totalKg(newValue: string) {
        this.__totalKg.set(newValue);
    }
    private __streak: ObservedPropertySimplePU<number>;
    get streak() {
        return this.__streak.get();
    }
    set streak(newValue: number) {
        this.__streak.set(newValue);
    }
    private __nickname: ObservedPropertySimplePU<string>;
    get nickname() {
        return this.__nickname.get();
    }
    set nickname(newValue: string) {
        this.__nickname.set(newValue);
    }
    private __drawn: ObservedPropertySimplePU<boolean>;
    get drawn() {
        return this.__drawn.get();
    }
    set drawn(newValue: boolean) {
        this.__drawn.set(newValue);
    }
    private settings: RenderingContextSettings;
    private ctx: CanvasRenderingContext2D;
    aboutToAppear(): void {
        this.load();
    }
    private async load(): Promise<void> {
        try {
            await AppInit.ensure();
            const records: BehaviorRecord[] = await BehaviorRepo.all();
            const todayStart = DateUtil.startOfDay(Date.now());
            let todaySum = 0;
            let totalSum = 0;
            for (const r of records) {
                totalSum += r.reductionG;
                if (r.createdAt >= todayStart) {
                    todaySum += r.reductionG;
                }
            }
            this.todayKg = DateUtil.gramsToKg(todaySum);
            this.totalKg = DateUtil.gramsToKg(totalSum);
            this.streak = await BadgeService.currentStreak();
            this.nickname = await PrefsService.getNickname();
        }
        catch (e) {
            console.error('ShareCard load error: ' + JSON.stringify(e));
        }
    }
    private draw(): void {
        const w = this.ctx.width;
        const h = this.ctx.height;
        this.ctx.clearRect(0, 0, w, h);
        if (w <= 0) {
            return;
        }
        // 背景
        this.ctx.fillStyle = '#2E7D32';
        this.ctx.fillRect(0, 0, w, h);
        this.ctx.fillStyle = 'rgba(255,255,255,0.08)';
        this.ctx.beginPath();
        this.ctx.arc(w - 30, 40, 90, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.beginPath();
        this.ctx.arc(20, h - 60, 70, 0, Math.PI * 2);
        this.ctx.fill();
        this.ctx.textAlign = 'center';
        // 标题
        this.ctx.fillStyle = '#C8E6C9';
        this.ctx.font = '13px sans-serif';
        this.ctx.fillText('碳足迹 · 全民绿色生活', w / 2, 52);
        this.ctx.fillStyle = '#FFFFFF';
        this.ctx.font = 'bold 26px sans-serif';
        this.ctx.fillText('我的低碳成绩单', w / 2, 90);
        // 主数据
        this.ctx.font = '13px sans-serif';
        this.ctx.fillStyle = '#C8E6C9';
        this.ctx.fillText('今日减排', w / 2, 150);
        this.ctx.font = 'bold 46px sans-serif';
        this.ctx.fillStyle = '#FFFFFF';
        this.ctx.fillText(`${this.todayKg} kg`, w / 2, 200);
        this.ctx.font = '13px sans-serif';
        this.ctx.fillStyle = '#C8E6C9';
        this.ctx.fillText('CO₂e', w / 2, 224);
        // 副数据行
        this.ctx.font = '14px sans-serif';
        this.ctx.fillStyle = '#FFFFFF';
        this.ctx.fillText(`累计减排 ${this.totalKg}kg`, w * 0.28, 280);
        this.ctx.fillText(`连续打卡 ${this.streak}天`, w * 0.72, 280);
        // 昵称 + 标语
        this.ctx.font = '15px sans-serif';
        this.ctx.fillStyle = '#FFFFFF';
        this.ctx.fillText(`—— ${this.nickname} ——`, w / 2, 330);
        this.ctx.font = '12px sans-serif';
        this.ctx.fillStyle = '#C8E6C9';
        this.ctx.fillText('每一克减排，都是给地球的温柔', w / 2, 360);
        this.ctx.fillText('我在用「碳足迹」践行低碳生活', w / 2, 386);
        this.drawn = true;
    }
    private async saveCard(): Promise<void> {
        try {
            const dataUrl = this.ctx.toDataURL('image/png', 1.0);
            const b64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
            const buf: Uint8Array = new util.Base64Helper().decodeSync(b64);
            const helper = photoAccessHelper.getPhotoAccessHelper(AppInit.getContext());
            const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
            const f = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
            fs.writeSync(f.fd, buf.buffer as ArrayBuffer);
            fs.closeSync(f.fd);
            promptAction.showToast({ message: '卡片已保存到相册', duration: 3000 });
        }
        catch (e) {
            promptAction.showToast({ message: '保存失败：' + JSON.stringify(e) });
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 12 });
            Column.debugLine("entry/src/main/ets/pages/ShareCard.ets(122:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(Theme.BG);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/ShareCard.ets(123:7)", "entry");
            Row.width('100%');
            Row.padding({ left: 14, right: 14, top: 14 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('←');
            Text.debugLine("entry/src/main/ets/pages/ShareCard.ets(124:9)", "entry");
            Text.fontSize(22);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/ShareCard.ets(129:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('减排成果分享');
            Text.debugLine("entry/src/main/ets/pages/ShareCard.ets(130:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/ShareCard.ets(133:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('');
            Text.debugLine("entry/src/main/ets/pages/ShareCard.ets(134:9)", "entry");
            Text.width(22);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 16 });
            Column.debugLine("entry/src/main/ets/pages/ShareCard.ets(140:7)", "entry");
            Column.width('100%');
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Canvas.create(this.ctx);
            Canvas.debugLine("entry/src/main/ets/pages/ShareCard.ets(141:9)", "entry");
            Canvas.width('86%');
            Canvas.height(420);
            Canvas.borderRadius(16);
            Canvas.onReady(() => {
                setTimeout(() => {
                    this.draw();
                }, 300);
            });
        }, Canvas);
        Canvas.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            SaveButton.create({ text: SaveDescription.SAVE_IMAGE });
            SaveButton.debugLine("entry/src/main/ets/pages/ShareCard.ets(151:9)", "entry");
            SaveButton.width('60%');
            SaveButton.height(44);
            SaveButton.fontSize(15);
            SaveButton.fontColor('#FFFFFF');
            SaveButton.backgroundColor(Theme.PRIMARY);
            SaveButton.onClick(async (event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                    await this.saveCard();
                }
                else {
                    promptAction.showToast({ message: '未获得保存授权，请重试' });
                }
            });
        }, SaveButton);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('卡片保存后可发送到微信朋友圈 / 家人群，带动更多人参与低碳生活');
            Text.debugLine("entry/src/main/ets/pages/ShareCard.ets(165:9)", "entry");
            Text.fontSize(11);
            Text.fontColor(Theme.TEXT_TERTIARY);
            Text.textAlign(TextAlign.Center);
            Text.padding({ left: 30, right: 30 });
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
    static getEntryName(): string {
        return "ShareCard";
    }
}
registerNamedRoute(() => new ShareCard(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/ShareCard", pageFullPath: "entry/src/main/ets/pages/ShareCard", integratedHsp: "false", moduleType: "followWithHap" });
