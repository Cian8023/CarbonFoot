import display from '@ohos.display';
import { Theme } from '../common/Theme';
import { PercentUtil } from '../utils/PercentUtil';

/** Canvas 的 font 单位是物理 px，需乘屏幕密度才能达到 Text fontSize 的 fp 视觉大小（供证书/海报等复用） */
export function fpFont(n: number): string {
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
  /** 精确占比（0~100），用于画扇形与进度条，不要直接显示 */
  pct: number;
  /** 取整后的占比标签（如 `51%` / `<1%`），由 PercentUtil 统一计算，保证图例合计为 100% */
  pctText?: string;
}

/**
 * 图表数值统一用 kg 显示，保留一位小数。
 * 早期按量级在 g / kg / t 之间切换，同一张图里出现「0g」和「8.5kg」两种单位，
 * 容易被误读成不同量纲，故统一为 kg（内部存储仍是克）。
 */
function fmtValue(v: number): string {
  return (v / 1000).toFixed(1) + 'kg';
}

/** 把一组趋势数据压成指纹，用于判断"这次重绘的数据是否变了"（变了就清掉点击选中） */
function chartSig(pts: ChartPoint[]): string {
  let s = '';
  for (const p of pts) {
    s += p.label + ':' + p.value + ';';
  }
  return s;
}

/** 竖向柱状图： */
@Component
export struct TrendBarChart {
  @Prop @Watch('redraw') points: ChartPoint[] = [];
  /** 是否已完成首次绘制（可见区触发，避免首帧多 Canvas 抢占） */
  private drawn: boolean = false;
  /** 点击选中的数据点下标，-1 表示未选中（默认只标注峰值与当期） */
  private selIdx: number = -1;
  /** 上次绘制所用的数据指纹：数据一变就清掉选中，避免"新增记录后还标着旧的那一天" */
  private lastSig: string = '';
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  redraw(): void {
    // 数据换了（切周期/刷新），旧的选中下标已无意义
    this.selIdx = -1;
    this.draw();
  }

  /** 把点击的 x 坐标换算成柱子下标；点在绘图区外返回 -1 */
  private pickIndex(x: number): number {
    const n = this.points.length;
    const w = this.ctx.width;
    if (n === 0 || w <= 0) {
      return -1;
    }
    const padL = 12;
    const padR = 12;
    const plotW = w - padL - padR;
    if (x < padL - 6 || x > w - padR + 6) {
      return -1;
    }
    const i = Math.floor((x - padL) / (plotW / n));
    return Math.max(0, Math.min(n - 1, i));
  }

  private draw(): void {
    const w = this.ctx.width;
    const h = this.ctx.height;
    this.ctx.clearRect(0, 0, w, h);
    const pts = this.points;
    if (pts.length === 0 || w <= 0 || h <= 0) {
      return;
    }
    // 数据变了就清掉选中：新增/删除记录后不应继续标着原来那一天
    const sig = chartSig(pts);
    if (sig !== this.lastSig) {
      this.lastSig = sig;
      this.selIdx = -1;
    }
    const padL = 12;
    const padR = 12;
    const padT = 42;
    const padB = 50;
    const plotW = w - padL - padR;
    const plotH = h - padT - padB;
    let maxV = 0;
    for (const p of pts) {
      if (p.value > maxV) {
        maxV = p.value;
      }
    }
    // 全为 0 时仍画坐标轴，但额外给一句引导，避免用户面对空图表不知所措
    const empty = maxV <= 0;
    if (maxV < 1) {
      maxV = 1;
    }
    const n = pts.length;
    const slot = plotW / n;
    // 数值只标注峰值与当期，防止拥挤；点击某根柱子后改为标注被点中的那根
    let maxIdx = 0;
    for (let i = 1; i < n; i++) {
      if (pts[i].value > pts[maxIdx].value) {
        maxIdx = i;
      }
    }
    const sel = this.selIdx >= 0 && this.selIdx < n ? this.selIdx : -1;
    const barW = Math.min(60, slot * 0.72);
    const baseline = padT + plotH;

    // 水平基线（1/3 与 2/3 处），辅助量级对比
    this.ctx.strokeStyle = Theme.DIVIDER_LIGHT;
    this.ctx.lineWidth = 1;
    for (let g = 1; g <= 2; g++) {
      const gy = padT + plotH * g / 3;
      this.ctx.beginPath();
      this.ctx.moveTo(padL, gy);
      this.ctx.lineTo(w - padR, gy);
      this.ctx.stroke();
    }

    const barCx: number[] = [];
    const barTop: number[] = [];
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
      // 最后一根（当期）高亮渐变，其余浅绿渐变，越往下越淡
      const barGrad = this.ctx.createLinearGradient(0, by, 0, baseline);
      if (i === n - 1 || i === sel) {
        barGrad.addColorStop(0, Theme.PRIMARY);
        barGrad.addColorStop(1, 'rgba(47,107,79,0.40)');
      } else {
        barGrad.addColorStop(0, Theme.PRIMARY_HOVER);
        barGrad.addColorStop(1, 'rgba(35,199,124,0.15)');
      }
      this.ctx.fillStyle = barGrad;
      this.ctx.fill();
      // 被点中的柱子加描边，和"当期"区分开
      if (i === sel && i !== n - 1) {
        this.ctx.strokeStyle = Theme.PRIMARY;
        this.ctx.lineWidth = 2;
        this.ctx.stroke();
      }
      barCx.push(cx);
      barTop.push(by);
    }

    // 顶部数值：选中的那根优先显示，未选中时保持"峰值 + 当期"的老样子
    for (let i = 0; i < n; i++) {
      const v = pts[i].value;
      const isSel = i === sel;
      const isLast = i === n - 1;
      // 值为 0 的柱子平时不标，但被点中时要明确告诉用户"这天是 0"
      if (v <= 0 && !isSel) {
        continue;
      }
      if (!isSel && !isLast && i !== maxIdx) {
        continue;
      }
      this.ctx.fillStyle = isSel || isLast ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
      this.ctx.textAlign = 'center';
      this.ctx.font = 'bold ' + fpFont(isSel ? 22 : 20) + ' sans-serif';
      const txt = fmtValue(v);
      // 贴边的柱子（首尾）数值会被画布裁掉，按文字实际宽度夹紧回来
      const half = this.ctx.measureText(txt).width / 2;
      let tx = barCx[i];
      if (tx - half < 1) {
        tx = half + 1;
      }
      if (tx + half > w - 1) {
        tx = w - 1 - half;
      }
      this.ctx.fillText(txt, tx, barTop[i] - 10);
    }

    // X 轴标签（柱多于 8 根时隔一画一防重叠；选中的那个一定画出来）
    // 字号按标签长度自适应：月视图 "2026.10"、周视图 "10.26-11.1" 这类长标签
    // 用 16 号会超过槽宽糊成一团，这里降到 13 号，并保留重叠兜底跳过
    let lastRight = -9999;
    for (let i = 0; i < n; i++) {
      const isSel = i === sel;
      const isLast = i === n - 1;
      if (i % (n > 8 ? 2 : 1) !== 0 && !isSel && !isLast) {
        continue;
      }
      const lbl = pts[i].label;
      this.ctx.font = (isSel ? 'bold ' : '') + fpFont(lbl.length >= 6 ? 13 : 16);
      const half = this.ctx.measureText(lbl).width / 2;
      let lx = barCx[i];
      if (lx - half < 1) {
        lx = half + 1;
      }
      if (lx + half > w - 1) {
        lx = w - 1 - half;
      }
      // 与上一个标签压字则跳过；当期与选中的标签始终保留
      if (!isSel && !isLast && lx - half < lastRight + 2) {
        continue;
      }
      this.ctx.fillStyle = isSel ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
      this.ctx.textAlign = 'center';
      this.ctx.fillText(lbl, lx, h - 12);
      lastRight = lx + half;
    }

    if (empty) {
      this.ctx.fillStyle = Theme.TEXT_TERTIARY;
      this.ctx.textAlign = 'center';
      this.ctx.font = fpFont(15) + ' sans-serif';
      this.ctx.fillText('这段时间还没有记录', w / 2, padT + plotH / 2);
      this.ctx.font = fpFont(13) + ' sans-serif';
      this.ctx.fillText('去「录入」记一笔，趋势就出来了', w / 2, padT + plotH / 2 + 22);
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(330)
      // 延迟到进入可视区再首次绘制：首页一次挂多个 Canvas，
      // 若全部在首帧同时出图会互相抢占导致撕裂卡顿
      // 每次回到可见区都重绘：后台期间数据可能已变，只画首帧会停在旧画面
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible) {
          this.drawn = true;
          this.draw();
        }
      })
      .onClick((e: ClickEvent) => {
        const i = this.pickIndex(e.x);
        if (i < 0) {
          return;
        }
        // 再点同一根取消选中，回到"峰值 + 当期"的默认标注
        this.selIdx = this.selIdx === i ? -1 : i;
        this.draw();
      })
  }
}

/** 折线图：与柱状图共用同一份趋势数据，强调走势而非单期量级 */
@Component
export struct TrendLineChart {
  @Prop @Watch('redraw') points: ChartPoint[] = [];
  private drawn: boolean = false;
  /** 点击选中的数据点下标，-1 表示未选中（默认只标注峰值与当期） */
  private selIdx: number = -1;
  /** 上次绘制所用的数据指纹：数据一变就清掉选中，避免"新增记录后还标着旧的那一天" */
  private lastSig: string = '';
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  redraw(): void {
    this.selIdx = -1;
    this.draw();
  }

  /** 取离点击位置最近的数据点；点得太靠边返回 -1 */
  private pickIndex(x: number): number {
    const n = this.points.length;
    const w = this.ctx.width;
    if (n === 0 || w <= 0) {
      return -1;
    }
    const padL = 22;
    const padR = 22;
    const plotW = w - padL - padR;
    if (x < padL - 14 || x > w - padR + 14) {
      return -1;
    }
    if (n === 1) {
      return 0;
    }
    const i = Math.round((x - padL) / (plotW / (n - 1)));
    return Math.max(0, Math.min(n - 1, i));
  }

  private draw(): void {
    const w = this.ctx.width;
    const h = this.ctx.height;
    this.ctx.clearRect(0, 0, w, h);
    const pts = this.points;
    if (pts.length === 0 || w <= 0 || h <= 0) {
      return;
    }
    // 数据变了就清掉选中：新增/删除记录后不应继续标着原来那一天
    const sig = chartSig(pts);
    if (sig !== this.lastSig) {
      this.lastSig = sig;
      this.selIdx = -1;
    }
    const padL = 22;
    const padR = 22;
    const padT = 42;
    const padB = 50;
    const plotW = w - padL - padR;
    const plotH = h - padT - padB;
    const baseline = padT + plotH;
    let maxV = 0;
    for (const p of pts) {
      if (p.value > maxV) {
        maxV = p.value;
      }
    }
    const empty = maxV <= 0;
    if (maxV < 1) {
      maxV = 1;
    }
    const n = pts.length;
    const stepX = n > 1 ? plotW / (n - 1) : 0;

    // 与柱状图共用 1/3、2/3 两条辅助线，切换时视觉基准不跳
    this.ctx.strokeStyle = Theme.DIVIDER_LIGHT;
    this.ctx.lineWidth = 1;
    for (let g = 1; g <= 2; g++) {
      const gy = padT + plotH * g / 3;
      this.ctx.beginPath();
      this.ctx.moveTo(padL, gy);
      this.ctx.lineTo(w - padR, gy);
      this.ctx.stroke();
    }

    const xs: number[] = [];
    const ys: number[] = [];
    for (let i = 0; i < n; i++) {
      xs.push(padL + stepX * i);
      ys.push(baseline - plotH * (pts[i].value / maxV));
    }

    // 面积：折线下方渐变，控制点取相邻两点中点，曲线不会过冲
    this.ctx.beginPath();
    this.ctx.moveTo(xs[0], baseline);
    this.ctx.lineTo(xs[0], ys[0]);
    for (let i = 1; i < n; i++) {
      const cpx = (xs[i - 1] + xs[i]) / 2;
      this.ctx.bezierCurveTo(cpx, ys[i - 1], cpx, ys[i], xs[i], ys[i]);
    }
    this.ctx.lineTo(xs[n - 1], baseline);
    this.ctx.closePath();
    const areaGrad = this.ctx.createLinearGradient(0, padT, 0, baseline);
    areaGrad.addColorStop(0, 'rgba(47,107,79,0.26)');
    areaGrad.addColorStop(1, 'rgba(47,107,79,0.02)');
    this.ctx.fillStyle = areaGrad;
    this.ctx.fill();

    // 折线本体
    this.ctx.beginPath();
    this.ctx.moveTo(xs[0], ys[0]);
    for (let i = 1; i < n; i++) {
      const cpx = (xs[i - 1] + xs[i]) / 2;
      this.ctx.bezierCurveTo(cpx, ys[i - 1], cpx, ys[i], xs[i], ys[i]);
    }
    this.ctx.strokeStyle = Theme.PRIMARY;
    this.ctx.lineWidth = 3;
    this.ctx.lineJoin = 'round';
    this.ctx.lineCap = 'round';
    this.ctx.stroke();

    let maxIdx = 0;
    for (let i = 1; i < n; i++) {
      if (pts[i].value > pts[maxIdx].value) {
        maxIdx = i;
      }
    }
    const sel = this.selIdx >= 0 && this.selIdx < n ? this.selIdx : -1;

    // 选中点的竖向指示线：从数据点垂到基线，一眼看出是哪一期
    if (sel >= 0) {
      this.ctx.save();
      this.ctx.setLineDash([4, 4]);
      this.ctx.strokeStyle = Theme.PRIMARY_HOVER;
      this.ctx.lineWidth = 1.5;
      this.ctx.beginPath();
      this.ctx.moveTo(xs[sel], ys[sel]);
      this.ctx.lineTo(xs[sel], baseline);
      this.ctx.stroke();
      this.ctx.setLineDash([]);
      this.ctx.restore();
    }

    // 普通点描白边小圆，峰值、当期与选中点放大并标注数值
    for (let i = 0; i < n; i++) {
      const isSel = i === sel;
      const isKey = isSel || i === n - 1 || i === maxIdx;
      if (isKey) {
        this.ctx.beginPath();
        this.ctx.arc(xs[i], ys[i], isSel ? 7 : 5.5, 0, Math.PI * 2);
        this.ctx.fillStyle = isSel || i === n - 1 ? Theme.PRIMARY : '#FFFFFF';
        this.ctx.fill();
        this.ctx.strokeStyle = Theme.PRIMARY;
        this.ctx.lineWidth = isSel ? 3 : 2.5;
        this.ctx.stroke();
        if (pts[i].value > 0 || isSel) {
          this.ctx.fillStyle = isSel || i === n - 1 ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
          this.ctx.textAlign = 'center';
          this.ctx.font = 'bold ' + fpFont(isSel ? 22 : 20) + ' sans-serif';
          const txt = fmtValue(pts[i].value);
          // 首尾点的数值会越出画布，夹紧回来
          const half = this.ctx.measureText(txt).width / 2;
          let tx = xs[i];
          if (tx - half < 1) {
            tx = half + 1;
          }
          if (tx + half > w - 1) {
            tx = w - 1 - half;
          }
          this.ctx.fillText(txt, tx, ys[i] - (isSel ? 18 : 16));
        }
      } else {
        this.ctx.beginPath();
        this.ctx.arc(xs[i], ys[i], 3, 0, Math.PI * 2);
        this.ctx.fillStyle = '#FFFFFF';
        this.ctx.fill();
        this.ctx.strokeStyle = Theme.PRIMARY_HOVER;
        this.ctx.lineWidth = 2;
        this.ctx.stroke();
      }
    }

    // X 轴标签：严格居中于数据点。旧逻辑给首尾固定内收 24，会把首尾与相邻日期挤在一起；
    // 现改为先量实际文字宽度，只有真的越出画布时才做最小必要平移，并对相邻标签做重叠保护。
    const labelIdx: number[] = [];
    for (let i = 0; i < n; i++) {
      if (i % (n > 8 ? 2 : 1) !== 0 && i !== n - 1 && i !== sel) {
        continue;
      }
      labelIdx.push(i);
    }
    let lastRight = -9999;
    for (let k = 0; k < labelIdx.length; k++) {
      const i = labelIdx[k];
      const isSel = i === sel;
      const lbl = pts[i].label;
      this.ctx.font = (isSel ? 'bold ' : '') + fpFont(lbl.length >= 6 ? 13 : 16);
      const half = this.ctx.measureText(lbl).width / 2;
      let lx = xs[i];
      if (lx - half < 1) {
        lx = half + 1;
      }
      if (lx + half > w - 1) {
        lx = w - 1 - half;
      }
      // 与上一个标签压字则跳过；最后一个标签与选中标签始终保留
      const isLast = k === labelIdx.length - 1;
      if (!isLast && !isSel && lx - half < lastRight + 2) {
        continue;
      }
      this.ctx.fillStyle = isSel ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
      this.ctx.textAlign = 'center';
      this.ctx.fillText(lbl, lx, h - 12);
      lastRight = lx + half;
    }

    if (empty) {
      this.ctx.fillStyle = Theme.TEXT_TERTIARY;
      this.ctx.textAlign = 'center';
      this.ctx.font = fpFont(15) + ' sans-serif';
      this.ctx.fillText('这段时间还没有记录', w / 2, padT + plotH / 2);
      this.ctx.font = fpFont(13) + ' sans-serif';
      this.ctx.fillText('去「录入」记一笔，趋势就出来了', w / 2, padT + plotH / 2 + 22);
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(330)
      // 每次回到可见区都重绘：后台期间数据可能已变，只画首帧会停在旧画面
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible) {
          this.drawn = true;
          this.draw();
        }
      })
      .onClick((e: ClickEvent) => {
        const i = this.pickIndex(e.x);
        if (i < 0) {
          return;
        }
        // 再点同一个点取消选中，回到"峰值 + 当期"的默认标注
        this.selIdx = this.selIdx === i ? -1 : i;
        this.draw();
      })
  }
}

@Component
export struct PieChart {
  @Prop @Watch('redraw') items: PieItem[] = [];
  /** 中心数字下方的说明文字（如"近7天总量"），空串不显示 */
  @Prop @Watch('redraw') centerSub: string = '';
  private drawn: boolean = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

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
      // 白色描边形成扇区间留白，更精致
      this.ctx.strokeStyle = '#FFFFFF';
      this.ctx.lineWidth = 3;
      this.ctx.stroke();
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
    } else {
      this.ctx.font = 'bold ' + fpFont(24) + ' sans-serif';
      this.ctx.fillText(fmtValue(total), cx, cy + 8);
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(220)
      // 每次回到可见区都重绘：后台期间数据可能已变，只画首帧会停在旧画面
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible) {
          this.drawn = true;
          this.draw();
        }
      })
  }
}

/** 目标进度环：本月减排目标完成度 */
@Component
export struct GoalRing {
  /** 0 ~ 1，大于 1 按已达成处理（金色） */
  @Prop @Watch('redraw') progress: number = 0;
  @Prop @Watch('redraw') centerText: string = '';
  @Prop @Watch('redraw') subText: string = '';
  private drawn: boolean = false;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

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
    // 环尺寸随画布自适应；中心数字与目标文字都收进环心，卡片不再有大片空白
    const r = Math.min(cx, cy) - 26;
    const lineW = 13;
    // 底环
    this.ctx.beginPath();
    this.ctx.arc(cx, cy, r, 0, Math.PI * 2);
    this.ctx.strokeStyle = Theme.BG_GRAY;
    this.ctx.lineWidth = lineW;
    this.ctx.lineCap = 'round';
    this.ctx.stroke();
    // 进度弧（从顶部顺时针）
    const done = this.progress >= 1;
    const p = Math.max(0, Math.min(1, this.progress));
    if (p > 0) {
      this.ctx.beginPath();
      this.ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p);
      this.ctx.strokeStyle = done ? '#B8862F' : Theme.PRIMARY;
      this.ctx.lineWidth = lineW;
      this.ctx.lineCap = 'round';
      this.ctx.stroke();
    }
    // 中心文字：数字 + 目标（达成时显示标记）双行收进环心；字号随画布宽度自适应
    const cfs = Math.max(18, Math.min(30, Math.round(cx * 0.34)));
    const sfs = Math.max(10, Math.min(14, Math.round(cx * 0.17)));
    this.ctx.textAlign = 'center';
    this.ctx.fillStyle = done ? '#B8862F' : Theme.TEXT;
    this.ctx.font = 'bold ' + fpFont(cfs) + ' sans-serif';
    this.ctx.fillText(this.centerText, cx, cy - 6);
    this.ctx.font = fpFont(sfs);
    if (done) {
      this.ctx.fillStyle = '#B8862F';
      this.ctx.fillText('已达成 ✓', cx, cy + 22);
    } else {
      this.ctx.fillStyle = Theme.TEXT_TERTIARY;
      this.ctx.fillText(this.subText, cx, cy + 22);
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(170)
      // 每次回到可见区都重绘：后台期间数据可能已变，只画首帧会停在旧画面
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible) {
          this.drawn = true;
          this.draw();
        }
      })
  }
}

/** 子类型减排对比：名称+数值一行，下方带轨道的细进度条（纯 ArkUI，随卡片自适应宽度） */
@Component
export struct BarChart {
  @Prop items: PieItem[] = [];

  private totalValue(): number {
    let sum = 0;
    for (const it of this.items) {
      sum += it.value;
    }
    return sum;
  }

  /** 数值降序（subShare 已排序，此处兜底） */
  private sortedItems(): PieItem[] {
    return this.items.slice().sort((a: PieItem, b: PieItem) => b.value - a.value);
  }

  /** 占当期总量的百分比；>0 但不足 1% 显示 <1% */
  private pctOf(it: PieItem, total: number): number {
    return Math.max(0, Math.min(100, total > 0 ? it.value / total * 100 : 0));
  }

  /**
   * 各项百分比标签。
   * 逐项 toFixed(0) 会因各自四舍五入导致合计出现 99% 或 101%（如 51+39+9），
   * 改用 PercentUtil 的最大余数法，保证合计恰为 100%；不足 1% 的项仍显示「<1%」。
   */
  private pctLabels(list: PieItem[]): string[] {
    const values: number[] = [];
    for (const it of list) {
      values.push(it.value);
    }
    return PercentUtil.text(values);
  }

  /** 取排序后第 idx 项的百分比标签（build 内不能声明局部变量，故按需计算；列表 ≤6 项开销可忽略） */
  private pctLabelAt(list: PieItem[], idx: number): string {
    const labels = this.pctLabels(list);
    return idx >= 0 && idx < labels.length ? labels[idx] : '';
  }

  build() {
    Column({ space: 14 }) {
      ForEach(this.sortedItems(), (it: PieItem, idx: number) => {
        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text(it.name)
              .fontSize(Theme.FS_CONTENT)
              .fontWeight(idx === 0 ? FontWeight.Medium : FontWeight.Normal)
              .fontColor(Theme.TEXT)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(fmtValue(it.value))
              .fontSize(Theme.FS_CONTENT)
              .fontWeight(FontWeight.Bold)
              .fontColor(idx === 0 ? Theme.PRIMARY : Theme.TEXT_SECONDARY)
          }
          .width('100%')

          Row({ space: 8 }) {
            Stack({ alignContent: Alignment.Start }) {
              Column()
                .width('100%')
                .height(8)
                .borderRadius(4)
                .backgroundColor(Theme.BG_GRAY)
              if (idx === 0) {
                Column()
                  .width(this.pctOf(it, this.totalValue()) + '%')
                  .height(8)
                  .borderRadius(4)
                  .linearGradient({
                    angle: 90,
                    colors: [[Theme.PRIMARY, 0.0], [Theme.PRIMARY_HOVER, 1.0]]
                  })
              } else {
                Column()
                  .width(this.pctOf(it, this.totalValue()) + '%')
                  .height(8)
                  .borderRadius(4)
                  .backgroundColor(Theme.PRIMARY_LIGHT)
              }
            }
            .layoutWeight(1)

            Text(this.pctLabelAt(this.sortedItems(), idx))
              .fontSize(Theme.FS_TERTIARY)
              .fontColor(Theme.TEXT_TERTIARY)
              .width(44)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
        .width('100%')
      }, (it: PieItem) => it.name)
    }
    .width('100%')
  }
}
