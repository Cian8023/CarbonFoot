import { Theme } from '../common/Theme';

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

@Component
export struct LineChart {
  @Prop @Watch('redraw') points: ChartPoint[] = [];
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
    this.ctx.font = '11px sans-serif';
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
      } else {
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

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(290)
      .onReady(() => {
        this.draw();
      })
  }
}

/** 竖向柱状图：华为运动健康风格的周/月/年减排趋势 */
@Component
export struct TrendBarChart {
  @Prop @Watch('redraw') points: ChartPoint[] = [];
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
    // 柱多时只标注峰值与当期，防止拥挤
    const sparse = n > 8;
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
      if (v > 0 && (!sparse || i === n - 1 || i === maxIdx)) {
        this.ctx.fillStyle = i === n - 1 ? Theme.PRIMARY : Theme.TEXT_TERTIARY;
        this.ctx.textAlign = 'center';
        this.ctx.font = 'bold 28px sans-serif';
        this.ctx.fillText(fmtValue(v), cx, by - 10);
      }
      // X 轴标签（28px 大字，柱多于 8 根时隔一画一防重叠）
      if (i % (n > 8 ? 2 : 1) === 0) {
        this.ctx.fillStyle = Theme.TEXT_TERTIARY;
        this.ctx.textAlign = 'center';
        this.ctx.font = '28px sans-serif';
        this.ctx.fillText(pts[i].label, cx, h - 12);
      }
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(330)
      .onReady(() => {
        this.draw();
      })
  }
}

@Component
export struct PieChart {
  @Prop @Watch('redraw') items: PieItem[] = [];
  /** 中心数字下方的说明文字（如"近7天总量"），空串不显示 */
  @Prop @Watch('redraw') centerSub: string = '';
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
      this.ctx.font = '14px sans-serif';
      this.ctx.textAlign = 'center';
      this.ctx.fillText('暂无数据', cx, cy + 5);
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
    this.ctx.arc(cx, cy, r * 0.56, 0, Math.PI * 2);
    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.fill();
    // 中心总量大数字 + 副标题
    this.ctx.textAlign = 'center';
    this.ctx.fillStyle = Theme.TEXT;
    if (this.centerSub !== '') {
      this.ctx.font = 'bold 28px sans-serif';
      this.ctx.fillText(fmtValue(total), cx, cy - 2);
      this.ctx.fillStyle = Theme.TEXT_TERTIARY;
      this.ctx.font = '28px sans-serif';
      this.ctx.fillText(this.centerSub, cx, cy + r + 34);
    } else {
      this.ctx.font = 'bold 28px sans-serif';
      this.ctx.fillText(fmtValue(total), cx, cy + 10);
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(220)
      .onReady(() => {
        this.draw();
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
    const r = Math.min(cx, cy) - 20;
    const lineW = 14;
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
    // 中心文字
    this.ctx.textAlign = 'center';
    this.ctx.fillStyle = done ? '#F7BA1E' : Theme.TEXT;
    this.ctx.font = 'bold 28px sans-serif';
    this.ctx.fillText(this.centerText, cx, cy + 4);
    this.ctx.fillStyle = Theme.TEXT_TERTIARY;
    this.ctx.font = '28px sans-serif';
    this.ctx.fillText(this.subText, cx, cy + r + 40);
    if (done) {
      this.ctx.fillStyle = '#F7BA1E';
      this.ctx.font = '28px sans-serif';
      this.ctx.fillText('已达成 ✓', cx, cy - r - 16);
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(240)
      .onReady(() => {
        this.draw();
      })
  }
}

/** 横向条形图：用于子类型减排对比 */
@Component
export struct BarChart {
  @Prop @Watch('redraw') items: PieItem[] = [];
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

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
      this.ctx.font = '28px sans-serif';
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
      this.ctx.font = '28px sans-serif';
      this.ctx.fillText(fmtValue(it.value), padL + bw + 8, y + 10);
    }
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(this.items.length * 76 + 70)
      .onReady(() => {
        this.draw();
      })
  }
}
