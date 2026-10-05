if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface Badges_Params {
    tick?: number;
    badges?: BadgeDef[];
    balance?: number;
    certDate?: number;
    nickname?: string;
    totalKg?: string;
    unlockedCount?: number;
    progressArr?: BadgeProgressData[];
    selBadge?: BadgeDef | null;
    showDetail?: boolean;
    selProgress?: BadgeProgressData | null;
    settings?: RenderingContextSettings;
    certCtx?: CanvasRenderingContext2D;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import util from "@ohos:util";
import photoAccessHelper from "@ohos:file.photoAccessHelper";
import fs from "@ohos:file.fs";
import { AppInit } from "@normalized:N&&&entry/src/main/ets/common/AppInit&";
import { Constants, bumpTick } from "@normalized:N&&&entry/src/main/ets/common/Constants&";
import { Theme } from "@normalized:N&&&entry/src/main/ets/common/Theme&";
import type { BadgeDef } from '../model/Models';
import { BadgeService } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import type { BadgeProgressData } from "@normalized:N&&&entry/src/main/ets/service/BadgeService&";
import { PointsService } from "@normalized:N&&&entry/src/main/ets/service/PointsService&";
import { BehaviorRepo } from "@normalized:N&&&entry/src/main/ets/db/Repository&";
import { PrefsService } from "@normalized:N&&&entry/src/main/ets/common/PrefsService&";
import { DateUtil } from "@normalized:N&&&entry/src/main/ets/utils/DateUtil&";
class Badges extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__tick = this.createStorageLink('tick', 0, "tick");
        this.__badges = new ObservedPropertyObjectPU([], this, "badges");
        this.__balance = new ObservedPropertySimplePU(0, this, "balance");
        this.__certDate = new ObservedPropertySimplePU(0, this, "certDate");
        this.__nickname = new ObservedPropertySimplePU('绿色生活家', this, "nickname");
        this.__totalKg = new ObservedPropertySimplePU('0.00', this, "totalKg");
        this.__unlockedCount = new ObservedPropertySimplePU(0, this, "unlockedCount");
        this.__progressArr = new ObservedPropertyObjectPU([], this, "progressArr");
        this.__selBadge = new ObservedPropertyObjectPU(null, this, "selBadge");
        this.__showDetail = new ObservedPropertySimplePU(false, this, "showDetail");
        this.__selProgress = new ObservedPropertyObjectPU(null, this, "selProgress");
        this.settings = new RenderingContextSettings(true);
        this.certCtx = new CanvasRenderingContext2D(this.settings);
        this.setInitiallyProvidedValue(params);
        this.declareWatch("tick", this.refresh);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: Badges_Params) {
        if (params.badges !== undefined) {
            this.badges = params.badges;
        }
        if (params.balance !== undefined) {
            this.balance = params.balance;
        }
        if (params.certDate !== undefined) {
            this.certDate = params.certDate;
        }
        if (params.nickname !== undefined) {
            this.nickname = params.nickname;
        }
        if (params.totalKg !== undefined) {
            this.totalKg = params.totalKg;
        }
        if (params.unlockedCount !== undefined) {
            this.unlockedCount = params.unlockedCount;
        }
        if (params.progressArr !== undefined) {
            this.progressArr = params.progressArr;
        }
        if (params.selBadge !== undefined) {
            this.selBadge = params.selBadge;
        }
        if (params.showDetail !== undefined) {
            this.showDetail = params.showDetail;
        }
        if (params.selProgress !== undefined) {
            this.selProgress = params.selProgress;
        }
        if (params.settings !== undefined) {
            this.settings = params.settings;
        }
        if (params.certCtx !== undefined) {
            this.certCtx = params.certCtx;
        }
    }
    updateStateVars(params: Badges_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__tick.purgeDependencyOnElmtId(rmElmtId);
        this.__badges.purgeDependencyOnElmtId(rmElmtId);
        this.__balance.purgeDependencyOnElmtId(rmElmtId);
        this.__certDate.purgeDependencyOnElmtId(rmElmtId);
        this.__nickname.purgeDependencyOnElmtId(rmElmtId);
        this.__totalKg.purgeDependencyOnElmtId(rmElmtId);
        this.__unlockedCount.purgeDependencyOnElmtId(rmElmtId);
        this.__progressArr.purgeDependencyOnElmtId(rmElmtId);
        this.__selBadge.purgeDependencyOnElmtId(rmElmtId);
        this.__showDetail.purgeDependencyOnElmtId(rmElmtId);
        this.__selProgress.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__tick.aboutToBeDeleted();
        this.__badges.aboutToBeDeleted();
        this.__balance.aboutToBeDeleted();
        this.__certDate.aboutToBeDeleted();
        this.__nickname.aboutToBeDeleted();
        this.__totalKg.aboutToBeDeleted();
        this.__unlockedCount.aboutToBeDeleted();
        this.__progressArr.aboutToBeDeleted();
        this.__selBadge.aboutToBeDeleted();
        this.__showDetail.aboutToBeDeleted();
        this.__selProgress.aboutToBeDeleted();
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
    private __badges: ObservedPropertyObjectPU<BadgeDef[]>;
    get badges() {
        return this.__badges.get();
    }
    set badges(newValue: BadgeDef[]) {
        this.__badges.set(newValue);
    }
    private __balance: ObservedPropertySimplePU<number>;
    get balance() {
        return this.__balance.get();
    }
    set balance(newValue: number) {
        this.__balance.set(newValue);
    }
    private __certDate: ObservedPropertySimplePU<number>;
    get certDate() {
        return this.__certDate.get();
    }
    set certDate(newValue: number) {
        this.__certDate.set(newValue);
    }
    private __nickname: ObservedPropertySimplePU<string>;
    get nickname() {
        return this.__nickname.get();
    }
    set nickname(newValue: string) {
        this.__nickname.set(newValue);
    }
    private __totalKg: ObservedPropertySimplePU<string>;
    get totalKg() {
        return this.__totalKg.get();
    }
    set totalKg(newValue: string) {
        this.__totalKg.set(newValue);
    }
    private __unlockedCount: ObservedPropertySimplePU<number>;
    get unlockedCount() {
        return this.__unlockedCount.get();
    }
    set unlockedCount(newValue: number) {
        this.__unlockedCount.set(newValue);
    }
    private __progressArr: ObservedPropertyObjectPU<BadgeProgressData[]>;
    get progressArr() {
        return this.__progressArr.get();
    }
    set progressArr(newValue: BadgeProgressData[]) {
        this.__progressArr.set(newValue);
    }
    private __selBadge: ObservedPropertyObjectPU<BadgeDef | null>;
    get selBadge() {
        return this.__selBadge.get();
    }
    set selBadge(newValue: BadgeDef | null) {
        this.__selBadge.set(newValue);
    }
    private __showDetail: ObservedPropertySimplePU<boolean>;
    get showDetail() {
        return this.__showDetail.get();
    }
    set showDetail(newValue: boolean) {
        this.__showDetail.set(newValue);
    }
    private __selProgress: ObservedPropertyObjectPU<BadgeProgressData | null>;
    get selProgress() {
        return this.__selProgress.get();
    }
    set selProgress(newValue: BadgeProgressData | null) {
        this.__selProgress.set(newValue);
    }
    private settings: RenderingContextSettings;
    private certCtx: CanvasRenderingContext2D;
    aboutToAppear(): void {
        this.refresh();
    }
    async refresh(): Promise<void> {
        try {
            await AppInit.ensure();
            this.badges = await BadgeService.list();
            this.balance = await PointsService.getBalance();
            this.certDate = await PrefsService.getCertDate();
            this.nickname = await PrefsService.getNickname();
            let unlocked = 0;
            for (const b of this.badges) {
                if (b.unlocked) {
                    unlocked++;
                }
            }
            this.unlockedCount = unlocked;
            this.totalKg = DateUtil.gramsToKg(await BehaviorRepo.sumAllReduction());
            this.progressArr = await BadgeService.progressList(this.badges);
        }
        catch (e) {
            console.error('Badges refresh error: ' + JSON.stringify(e));
        }
    }
    private openBadgeDetail(b: BadgeDef, idx: number): void {
        this.selBadge = b;
        this.selProgress = this.progressArr.length > idx ? this.progressArr[idx] : null;
        this.showDetail = true;
    }
    private async exchangeCert(): Promise<void> {
        if (this.certDate > 0) {
            promptAction.showToast({ message: '已兑换过植树证书' });
            return;
        }
        if (this.balance < Constants.CERT_COST) {
            promptAction.showToast({ message: `积分不足，还差 ${Constants.CERT_COST - this.balance} 分` });
            return;
        }
        AlertDialog.show({
            title: '兑换植树证书',
            message: `将消耗 ${Constants.CERT_COST} 积分兑换一份电子植树证书，确定兑换？`,
            primaryButton: {
                value: '取消',
                action: () => {
                }
            },
            secondaryButton: {
                value: '兑换',
                fontColor: Theme.PRIMARY,
                action: () => {
                    this.doExchange();
                }
            }
        });
    }
    private async doExchange(): Promise<void> {
        try {
            await PointsService.addPoints('exchange', 0, '兑换电子植树证书', -Constants.CERT_COST);
            await PrefsService.setCertDate(Date.now());
            bumpTick();
            promptAction.showToast({ message: '恭喜获得植树证书！' });
        }
        catch (e) {
            promptAction.showToast({ message: '兑换失败，请重试' });
        }
    }
    private drawCert(): void {
        const w = this.certCtx.width;
        const h = this.certCtx.height;
        this.certCtx.clearRect(0, 0, w, h);
        if (w <= 0) {
            return;
        }
        // 底色
        this.certCtx.fillStyle = '#F7F5EC';
        this.certCtx.fillRect(0, 0, w, h);
        // 双边框
        // 单层细边框
        this.certCtx.strokeStyle = '#C9D5BC';
        this.certCtx.lineWidth = 1;
        this.certCtx.strokeRect(12, 12, w - 24, h - 24);
        this.certCtx.textAlign = 'center';
        // 标题
        this.certCtx.fillStyle = Theme.PRIMARY;
        this.certCtx.font = 'bold 30px sans-serif';
        this.certCtx.fillText('植 树 证 书', w / 2, 70);
        this.certCtx.font = '11px sans-serif';
        this.certCtx.fillStyle = '#8A8A6A';
        this.certCtx.fillText('T R E E   P L A N T I N G   C E R T I F I C A T E', w / 2, 92);
        // 正文
        this.certCtx.fillStyle = '#3A4A3A';
        this.certCtx.font = '14px sans-serif';
        this.certCtx.fillText('兹证明', w / 2, 130);
        this.certCtx.font = 'bold 24px sans-serif';
        this.certCtx.fillStyle = Theme.TEXT;
        this.certCtx.fillText(this.nickname, w / 2, 165);
        this.certCtx.font = '14px sans-serif';
        this.certCtx.fillStyle = '#3A4A3A';
        this.certCtx.fillText(`通过「碳足迹」应用累计减排 ${this.totalKg} kg CO₂e`, w / 2, 200);
        this.certCtx.fillText(`于 ${DateUtil.formatYMD(this.certDate)} 兑换电子植树证书一份`, w / 2, 224);
        this.certCtx.fillText('感谢您为地球增添的一抹绿色', w / 2, 248);
        // 装饰：三棵几何小树
        const treeXs = [w / 2 - 44, w / 2, w / 2 + 44];
        for (let i = 0; i < treeXs.length; i++) {
            const cx = treeXs[i];
            const scale = i === 1 ? 1.15 : 0.85;
            this.certCtx.fillStyle = '#A9C08F';
            this.certCtx.beginPath();
            this.certCtx.moveTo(cx, 292 - 30 * scale);
            this.certCtx.lineTo(cx - 14 * scale, 292 - 2);
            this.certCtx.lineTo(cx + 14 * scale, 292 - 2);
            this.certCtx.closePath();
            this.certCtx.fill();
            this.certCtx.fillStyle = '#C8B26A';
            this.certCtx.fillRect(cx - 2, 292 - 2, 4, 8);
        }
        // 落款
        this.certCtx.font = '12px sans-serif';
        this.certCtx.fillStyle = '#8A8A6A';
        this.certCtx.fillText('碳足迹 · 全民绿色生活碳积分与减排指南', w / 2, h - 44);
        this.certCtx.fillText(`证书编号：CF-${this.certDate}`, w / 2, h - 24);
    }
    private async saveCert(): Promise<void> {
        try {
            const dataUrl = this.certCtx.toDataURL('image/png', 1.0);
            const b64 = dataUrl.substring(dataUrl.indexOf(',') + 1);
            const buf: Uint8Array = new util.Base64Helper().decodeSync(b64);
            const helper = photoAccessHelper.getPhotoAccessHelper(AppInit.getContext());
            const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'png');
            const f = fs.openSync(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
            fs.writeSync(f.fd, buf.buffer as ArrayBuffer);
            fs.closeSync(f.fd);
            promptAction.showToast({ message: '证书已保存到相册', duration: 3000 });
        }
        catch (e) {
            promptAction.showToast({ message: '保存失败：' + JSON.stringify(e) });
        }
    }
    badgeDetailSheet(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 14 });
            Column.debugLine("entry/src/main/ets/pages/Badges.ets(177:5)", "entry");
            Column.width('100%');
            Column.padding(16);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Badges.ets(178:7)", "entry");
            Row.width('100%');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('徽章详情');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(179:9)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Badges.ets(182:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('×');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(183:9)", "entry");
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
            if (this.selBadge !== null) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create({ space: 14 });
                        Row.debugLine("entry/src/main/ets/pages/Badges.ets(193:9)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.selBadge as BadgeDef).unlocked ? (this.selBadge as BadgeDef).icon : '—');
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(194:11)", "entry");
                        Text.fontSize(30);
                        Text.width(64);
                        Text.height(64);
                        Text.textAlign(TextAlign.Center);
                        Text.backgroundColor((this.selBadge as BadgeDef).unlocked ? '#EAF1E3' : '#F1F1ED');
                        Text.borderRadius(10);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 6 });
                        Column.debugLine("entry/src/main/ets/pages/Badges.ets(201:11)", "entry");
                        Column.alignItems(HorizontalAlign.Start);
                        Column.layoutWeight(1);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.selBadge as BadgeDef).name);
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(202:13)", "entry");
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Bold);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create((this.selBadge as BadgeDef).description);
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(205:13)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if ((this.selBadge as BadgeDef).unlocked) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('已解锁 · ' + DateUtil.formatFull((this.selBadge as BadgeDef).unlockedAt));
                                    Text.debugLine("entry/src/main/ets/pages/Badges.ets(215:11)", "entry");
                                    Text.fontSize(13);
                                    Text.fontColor(Theme.PRIMARY);
                                    Text.width('100%');
                                }, Text);
                                Text.pop();
                            });
                        }
                        else if (this.selProgress !== null) {
                            this.ifElseBranchUpdateFunction(1, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Column.create({ space: 8 });
                                    Column.debugLine("entry/src/main/ets/pages/Badges.ets(220:11)", "entry");
                                    Column.width('100%');
                                }, Column);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('当前进度：' + this.selProgress.label);
                                    Text.debugLine("entry/src/main/ets/pages/Badges.ets(221:13)", "entry");
                                    Text.fontSize(13);
                                    Text.fontColor(Theme.TEXT);
                                    Text.width('100%');
                                }, Text);
                                Text.pop();
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Progress.create({ value: this.selProgress.pct, total: 100, type: ProgressType.Linear });
                                    Progress.debugLine("entry/src/main/ets/pages/Badges.ets(225:13)", "entry");
                                    Progress.width('100%');
                                    Progress.height(8);
                                    Progress.color(Theme.PRIMARY);
                                }, Progress);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('完成 ' + (this.selBadge as BadgeDef).description + ' 即可解锁');
                                    Text.debugLine("entry/src/main/ets/pages/Badges.ets(229:13)", "entry");
                                    Text.fontSize(11);
                                    Text.fontColor(Theme.TEXT_TERTIARY);
                                    Text.width('100%');
                                }, Text);
                                Text.pop();
                                Column.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(2, () => {
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
        Column.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/Badges.ets(243:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(Theme.BG);
            Column.bindSheet(this.showDetail, { builder: () => {
                    this.badgeDetailSheet.call(this);
                } }, {
                height: 420,
                showClose: false,
                onDisappear: () => {
                    this.showDetail = false;
                }
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 顶部导航
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Badges.ets(245:7)", "entry");
            // 顶部导航
            Row.width('100%');
            // 顶部导航
            Row.height(52);
            // 顶部导航
            Row.padding({ left: 14, right: 14 });
            // 顶部导航
            Row.border({ width: { bottom: 1 }, color: Theme.DIVIDER });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('‹');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(246:9)", "entry");
            Text.fontSize(30);
            Text.fontColor(Theme.TEXT);
            Text.width(32);
            Text.height(32);
            Text.textAlign(TextAlign.Center);
            Text.onClick(() => {
                router.back();
            });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('徽章与证书');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(256:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
            Text.margin({ left: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Badges.ets(262:9)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.unlockedCount}/${this.badges.length}`);
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(264:9)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        // 顶部导航
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/Badges.ets(273:7)", "entry");
            Scroll.scrollBar(BarState.Off);
            Scroll.layoutWeight(1);
            Scroll.align(Alignment.Top);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 20 });
            Column.debugLine("entry/src/main/ets/pages/Badges.ets(274:9)", "entry");
            Column.width('100%');
            Column.padding({ top: 14, bottom: 24 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 徽章区域
            Column.create({ space: 14 });
            Column.debugLine("entry/src/main/ets/pages/Badges.ets(276:11)", "entry");
            // 徽章区域
            Column.width('100%');
            // 徽章区域
            Column.padding({ left: 16, right: 16, top: 16, bottom: 6 });
            // 徽章区域
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Badges.ets(277:13)", "entry");
            Row.width('100%');
            Row.alignItems(VerticalAlign.Bottom);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Badges.ets(278:15)", "entry");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('我的徽章');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(279:17)", "entry");
            Text.fontSize(17);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('记录已经完成的绿色行动');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(284:17)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Badges.ets(289:15)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.unlockedCount} 个已获得`);
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(291:15)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.PRIMARY);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Badges.ets(298:13)", "entry");
            Divider.strokeWidth(1);
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Flex.create({
                wrap: FlexWrap.Wrap,
                justifyContent: FlexAlign.SpaceBetween
            });
            Flex.debugLine("entry/src/main/ets/pages/Badges.ets(302:13)", "entry");
            Flex.width('100%');
        }, Flex);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const b = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create({ space: 7 });
                    Column.debugLine("entry/src/main/ets/pages/Badges.ets(307:17)", "entry");
                    Column.width('48%');
                    Column.height(150);
                    Column.padding(12);
                    Column.margin({ bottom: 10 });
                    Column.backgroundColor(b.unlocked ? '#FBFCF8' : '#F7F7F4');
                    Column.border({
                        width: 1,
                        color: b.unlocked ? '#DCE6D2' : Theme.DIVIDER
                    });
                    Column.borderRadius(6);
                    Column.opacity(b.unlocked ? 1 : 0.72);
                    Column.onClick(() => {
                        this.openBadgeDetail(b, this.badges.indexOf(b));
                    });
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.debugLine("entry/src/main/ets/pages/Badges.ets(308:19)", "entry");
                    Row.width('100%');
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(b.unlocked ? b.icon : '—');
                    Text.debugLine("entry/src/main/ets/pages/Badges.ets(309:21)", "entry");
                    Text.fontSize(18);
                    Text.fontWeight(FontWeight.Medium);
                    Text.fontColor(b.unlocked ? Theme.PRIMARY : Theme.TEXT_TERTIARY);
                    Text.width(38);
                    Text.height(38);
                    Text.textAlign(TextAlign.Center);
                    Text.backgroundColor(b.unlocked ? '#EAF1E3' : '#F1F1ED');
                    Text.borderRadius(6);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Blank.create();
                    Blank.debugLine("entry/src/main/ets/pages/Badges.ets(319:21)", "entry");
                }, Blank);
                Blank.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (b.unlocked) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('已获得');
                                Text.debugLine("entry/src/main/ets/pages/Badges.ets(322:23)", "entry");
                                Text.fontSize(10);
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
                Row.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(b.name);
                    Text.debugLine("entry/src/main/ets/pages/Badges.ets(329:19)", "entry");
                    Text.fontSize(14);
                    Text.fontWeight(FontWeight.Medium);
                    Text.fontColor(b.unlocked ? Theme.TEXT : Theme.TEXT_TERTIARY);
                    Text.width('100%');
                    Text.maxLines(1);
                    Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(b.description);
                    Text.debugLine("entry/src/main/ets/pages/Badges.ets(337:19)", "entry");
                    Text.fontSize(11);
                    Text.lineHeight(16);
                    Text.fontColor(Theme.TEXT_TERTIARY);
                    Text.width('100%');
                    Text.maxLines(2);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (b.unlocked) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(DateUtil.formatYMD(b.unlockedAt));
                                Text.debugLine("entry/src/main/ets/pages/Badges.ets(345:21)", "entry");
                                Text.fontSize(10);
                                Text.fontColor(Theme.TEXT_TERTIARY);
                                Text.width('100%');
                            }, Text);
                            Text.pop();
                        });
                    }
                    else {
                        this.ifElseBranchUpdateFunction(1, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Column.create({ space: 4 });
                                Column.debugLine("entry/src/main/ets/pages/Badges.ets(350:21)", "entry");
                                Column.width('100%');
                            }, Column);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create((this.progressArr.length > 0) ? (this.progressArr[this.badges.indexOf(b)] !== undefined ? this.progressArr[this.badges.indexOf(b)].label : '进度加载中') : '进度加载中');
                                Text.debugLine("entry/src/main/ets/pages/Badges.ets(351:23)", "entry");
                                Text.fontSize(10);
                                Text.fontColor(Theme.TEXT_TERTIARY);
                                Text.width('100%');
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Progress.create({ value: (this.progressArr.length > 0 && this.progressArr[this.badges.indexOf(b)] !== undefined) ? this.progressArr[this.badges.indexOf(b)].pct : 0, total: 100, type: ProgressType.Linear });
                                Progress.debugLine("entry/src/main/ets/pages/Badges.ets(355:23)", "entry");
                                Progress.width('100%');
                                Progress.height(6);
                                Progress.color(Theme.PRIMARY);
                            }, Progress);
                            Column.pop();
                        });
                    }
                }, If);
                If.pop();
                Column.pop();
            };
            this.forEachUpdateFunction(elmtId, this.badges, forEachItemGenFunction, (b: BadgeDef) => b.code + '_' + (b.unlocked ? '1' : '0') + '_' + b.unlockedAt, false, false);
        }, ForEach);
        ForEach.pop();
        Flex.pop();
        // 徽章区域
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // 证书区域
            Column.create({ space: 14 });
            Column.debugLine("entry/src/main/ets/pages/Badges.ets(386:11)", "entry");
            // 证书区域
            Column.width('100%');
            // 证书区域
            Column.padding(16);
            // 证书区域
            Column.backgroundColor(Theme.CARD);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/Badges.ets(387:13)", "entry");
            Row.width('100%');
            Row.alignItems(VerticalAlign.Bottom);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 4 });
            Column.debugLine("entry/src/main/ets/pages/Badges.ets(388:15)", "entry");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('植树证书');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(389:17)", "entry");
            Text.fontSize(17);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor(Theme.TEXT);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.certDate > 0 ? '感谢你为环境持续留下行动记录' : '用积分兑换一份电子纪念');
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(394:17)", "entry");
            Text.fontSize(12);
            Text.fontColor(Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Column.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/Badges.ets(399:15)", "entry");
        }, Blank);
        Blank.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(`${this.balance} / ${Constants.CERT_COST}`);
            Text.debugLine("entry/src/main/ets/pages/Badges.ets(401:15)", "entry");
            Text.fontSize(12);
            Text.fontColor(this.balance >= Constants.CERT_COST
                ? Theme.PRIMARY
                : Theme.TEXT_TERTIARY);
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/Badges.ets(410:13)", "entry");
            Divider.strokeWidth(1);
            Divider.color(Theme.DIVIDER);
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.certDate > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Canvas.create(this.certCtx);
                        Canvas.debugLine("entry/src/main/ets/pages/Badges.ets(415:15)", "entry");
                        Canvas.width('100%');
                        Canvas.height(330);
                        Canvas.borderRadius(4);
                        Canvas.onReady(() => {
                            this.drawCert();
                        });
                    }, Canvas);
                    Canvas.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/Badges.ets(423:15)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`兑换于 ${DateUtil.formatYMD(this.certDate)}`);
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(424:17)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Badges.ets(428:17)", "entry");
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        SaveButton.create({ text: SaveDescription.SAVE_IMAGE });
                        SaveButton.debugLine("entry/src/main/ets/pages/Badges.ets(430:17)", "entry");
                        SaveButton.height(36);
                        SaveButton.fontSize(13);
                        SaveButton.fontColor(Theme.PRIMARY);
                        SaveButton.backgroundColor('#EAF1E3');
                        SaveButton.borderRadius(4);
                        SaveButton.onClick(async (event: ClickEvent, result: SaveButtonOnClickResult) => {
                            if (result === SaveButtonOnClickResult.SUCCESS) {
                                await this.saveCert();
                            }
                            else {
                                promptAction.showToast({ message: '未获得保存授权，请重试' });
                            }
                        });
                    }, SaveButton);
                    Row.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 14 });
                        Column.debugLine("entry/src/main/ets/pages/Badges.ets(446:15)", "entry");
                        Column.width('100%');
                        Column.padding({ top: 12, bottom: 8 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/Badges.ets(447:17)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('证');
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(448:19)", "entry");
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Medium);
                        Text.fontColor(Theme.PRIMARY);
                        Text.width(44);
                        Text.height(44);
                        Text.textAlign(TextAlign.Center);
                        Text.backgroundColor('#EAF1E3');
                        Text.borderRadius(6);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 5 });
                        Column.debugLine("entry/src/main/ets/pages/Badges.ets(458:19)", "entry");
                        Column.margin({ left: 12 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('电子植树证书');
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(459:21)", "entry");
                        Text.fontSize(14);
                        Text.fontWeight(FontWeight.Medium);
                        Text.fontColor(Theme.TEXT);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`还需 ${Math.max(Constants.CERT_COST - this.balance, 0)} 积分`);
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(464:21)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Column.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Badges.ets(470:19)", "entry");
                    }, Blank);
                    Blank.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Progress.create({
                            value: Math.min(this.balance, Constants.CERT_COST),
                            total: Constants.CERT_COST,
                            type: ProgressType.Linear
                        });
                        Progress.debugLine("entry/src/main/ets/pages/Badges.ets(474:17)", "entry");
                        Progress.width('100%');
                        Progress.color(Theme.PRIMARY);
                    }, Progress);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/Badges.ets(482:17)", "entry");
                        Row.width('100%');
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`当前 ${this.balance} 分`);
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(483:19)", "entry");
                        Text.fontSize(11);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/Badges.ets(487:19)", "entry");
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`目标 ${Constants.CERT_COST} 分`);
                        Text.debugLine("entry/src/main/ets/pages/Badges.ets(489:19)", "entry");
                        Text.fontSize(11);
                        Text.fontColor(Theme.TEXT_TERTIARY);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Button.createWithLabel(this.balance >= Constants.CERT_COST ? '兑换证书' : '继续积累积分');
                        Button.debugLine("entry/src/main/ets/pages/Badges.ets(495:17)", "entry");
                        Button.width('100%');
                        Button.height(40);
                        Button.fontSize(14);
                        Button.fontColor(this.balance >= Constants.CERT_COST ? '#FFFFFF' : Theme.TEXT_TERTIARY);
                        Button.backgroundColor(this.balance >= Constants.CERT_COST ? Theme.PRIMARY : '#E6E6E1');
                        Button.borderRadius(4);
                        Button.onClick(() => {
                            this.exchangeCert();
                        });
                    }, Button);
                    Button.pop();
                    Column.pop();
                });
            }
        }, If);
        If.pop();
        // 证书区域
        Column.pop();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    public __resetStateVarsOnReuse__Internal(params: Object): void {
    }
    static getEntryName(): string {
        return "Badges";
    }
}
registerNamedRoute(() => new Badges(undefined, {}), "", { bundleName: "com.carbon.footprint", moduleName: "entry", pagePath: "pages/Badges", pageFullPath: "entry/src/main/ets/pages/Badges", integratedHsp: "false", moduleType: "followWithHap" });
