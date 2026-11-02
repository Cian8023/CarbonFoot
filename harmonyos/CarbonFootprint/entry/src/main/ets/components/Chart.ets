import display from '@ohos.display';
import { Theme } from '../common/Theme';

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
  pct: number;
}

function fmtValue(v: number): string {
  if (v >= 1000000) {
    return (v / 1000000).toFixed(1) + 't';
  } else if (v >= 1000) {
    return (v / 1000).toFixed(1) + 'kg';
  }
  return Math.round(v) + 'g';
}

/** 竖向柱状图：华为运动健康风格的周/月/年减排趋势 */
@Component
export struct TrendBarChart {
  @Prop @Watch('redraw') points: ChartPoint[] = [];
  /** 是否已完成首次绘制（可见区触发，避免首帧多 Canvas 抢占） */
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
      if (i === n - 1) {
        barGrad.addColorStop(0, Theme.PRIMARY);
        barGrad.addColorStop(1, 'rgba(47,107,79,0.40)');
      } else {
        barGrad.addColorStop(0, Theme.PRIMARY_HOVER);
        barGrad.addColorStop(1, 'rgba(35,199,124,0.15)');
      }
      this.ctx.fillStyle = barGrad;
      this.ctx.fill();
      // 顶部数值
      if (v > 0 && (i === n - 1 || i === maxIdx)) {
        this.ctx.fillStyle = i === n - 1 ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
        this.ctx.textAlign = 'center';
        this.ctx.font = 'bold ' + fpFont(20) + ' sans-serif';
        this.ctx.fillText(fmtValue(v), cx, by - 10);
      }
      // X 轴标签（柱多于 8 根时隔一画一防重叠；纯数字标签比中文字短，字号可以统一）
      if (i % (n > 8 ? 2 : 1) === 0) {
        this.ctx.fillStyle = Theme.TEXT_TERTIARY;
        this.ctx.textAlign = 'center';
        this.ctx.font = fpFont(pts[i].label.length > 7 ? 14 : 16);
        this.ctx.fillText(pts[i].label, cx, h - 12);
      }
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(330)
      // 延迟到进入可视区再首次绘制：首页一次挂多个 Canvas，
      // 若全部在首帧同时出图会互相抢占导致撕裂卡顿
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible && !this.drawn) {
          this.drawn = true;
          this.draw();
        }
      })
  }
}

/** 折线图：与柱状图共用同一份趋势数据，强调走势而非单期量级 */
@Component
export struct TrendLineChart {
  @Prop @Watch('redraw') points: ChartPoint[] = [];
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
    const pts = this.points;
    if (pts.length === 0 || w <= 0 || h <= 0) {
      return;
    }
    const padL = 22;
    const padR = 22;
    const padT = 42;
    const padB = 50;
    const plotW = w - padL - padR;
    const plotH = h - padT - padB;
    const baseline = padT + plotH;
    let maxV = 1;
    for (const p of pts) {
      if (p.value > maxV) {
        maxV = p.value;
      }
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

    // 普通点描白边小圆，峰值与当期放大并标注数值
    for (let i = 0; i < n; i++) {
      const isKey = i === n - 1 || i === maxIdx;
      if (isKey) {
        this.ctx.beginPath();
        this.ctx.arc(xs[i], ys[i], 5.5, 0, Math.PI * 2);
        this.ctx.fillStyle = i === n - 1 ? Theme.PRIMARY : '#FFFFFF';
        this.ctx.fill();
        this.ctx.strokeStyle = Theme.PRIMARY;
        this.ctx.lineWidth = 2.5;
        this.ctx.stroke();
        if (pts[i].value > 0) {
          this.ctx.fillStyle = i === n - 1 ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
          this.ctx.textAlign = 'center';
          this.ctx.font = 'bold ' + fpFont(20) + ' sans-serif';
          this.ctx.fillText(fmtValue(pts[i].value), xs[i], ys[i] - 16);
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
      if (i % (n > 8 ? 2 : 1) !== 0 && i !== n - 1) {
        continue;
      }
      labelIdx.push(i);
    }
    let lastRight = -9999;
    for (let k = 0; k < labelIdx.length; k++) {
      const i = labelIdx[k];
      const lbl = pts[i].label;
      this.ctx.font = fpFont(lbl.length > 7 ? 14 : 16);
      const half = this.ctx.measureText(lbl).width / 2;
      let lx = xs[i];
      if (lx - half < 1) {
        lx = half + 1;
      }
      if (lx + half > w - 1) {
        lx = w - 1 - half;
      }
      // 与上一个标签压字则跳过；最后一个标签始终保留
      const isLast = k === labelIdx.length - 1;
      if (!isLast && lx - half < lastRight + 2) {
        continue;
      }
      this.ctx.fillStyle = Theme.TEXT_TERTIARY;
      this.ctx.textAlign = 'center';
      this.ctx.fillText(lbl, lx, h - 12);
      lastRight = lx + half;
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(330)
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible && !this.drawn) {
          this.drawn = true;
          this.draw();
        }
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
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible && !this.drawn) {
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
      .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean) => {
        if (isVisible && !this.drawn) {
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

  private pctLabel(it: PieItem, total: number): string {
    const pct = this.pctOf(it, total);
    if (it.value > 0 && pct < 1) {
      return '<1%';
    }
    return pct.toFixed(0) + '%';
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

            Text(this.pctLabel(it, this.totalValue()))
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
