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
    this.ctx.strokeStyle = 'Theme.DIVIDER';
    this.ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
      const y = padT + plotH * i / 4;
      this.ctx.beginPath();
      this.ctx.moveTo(padL, y);
      this.ctx.lineTo(w - padR, y);
      this.ctx.stroke();
      this.ctx.fillStyle = 'Theme.TEXT_TERTIARY';
      this.ctx.textAlign = 'right';
      this.ctx.fillText(fmtValue(maxV * (1 - i / 4)), padL - 6, y + 4);
    }

    const px = (i: number): number => padL + plotW * (pts.length === 1 ? 0.5 : i / (pts.length - 1));
    const py = (v: number): number => padT + plotH * (1 - v / maxV);

    // X 轴标签
    this.ctx.textAlign = 'center';
    const step = Math.max(1, Math.ceil(pts.length / 6));
    for (let i = 0; i < pts.length; i += step) {
      this.ctx.fillStyle = 'Theme.TEXT_TERTIARY';
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
      .height(220)
      .onReady(() => {
        this.draw();
      })
  }
}

@Component
export struct PieChart {
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
      this.ctx.fillStyle = 'Theme.DIVIDER';
      this.ctx.fill();
      this.ctx.fillStyle = 'Theme.TEXT_TERTIARY';
      this.ctx.font = '13px sans-serif';
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
    this.ctx.arc(cx, cy, r * 0.58, 0, Math.PI * 2);
    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.fill();
    this.ctx.fillStyle = Theme.TEXT;
    this.ctx.font = 'bold 15px sans-serif';
    this.ctx.textAlign = 'center';
    this.ctx.fillText(fmtValue(total), cx, cy + 5);
  }

  build() {
    Canvas(this.ctx)
      .width('100%')
      .height(170)
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
    const padL = 78;
    const padR = 62;
    const rowH = Math.min(36, h / items.length);
    let maxV = 1;
    for (const it of items) {
      if (it.value > maxV) {
        maxV = it.value;
      }
    }
    const barW = w - padL - padR;
    this.ctx.font = '12px sans-serif';
    for (let i = 0; i < items.length; i++) {
      const it = items[i];
      const y = h / 2 + (i - items.length / 2) * rowH;
      const bw = Math.max(4, barW * it.value / maxV);
      // 名称
      this.ctx.fillStyle = '#1F2933';
      this.ctx.textAlign = 'right';
      let name = it.name;
      if (name.length > 4) {
        name = name.substring(0, 4);
      }
      this.ctx.fillText(name, padL - 8, y + 4);
      // 条
      const r = 6;
      const bx = padL;
      const by = y - 8;
      const bh = 16;
      this.ctx.beginPath();
      this.ctx.moveTo(bx + r, by);
      this.ctx.arcTo(bx + bw, by, bx + bw, by + bh, r);
      this.ctx.arcTo(bx + bw, by + bh, bx, by + bh, r);
      this.ctx.arcTo(bx, by + bh, bx, by, r);
      this.ctx.arcTo(bx, by, bx + bw, by, r);
      this.ctx.closePath();
      this.ctx.fillStyle = i === 0 ? Theme.PRIMARY : '#A5D6A7';
      this.ctx.fill();
      // 数值
      this.ctx.fillStyle = 'Theme.TEXT_TERTIARY';
      this.ctx.textAlign = 'left';
      this.ctx.fillText(fmtValue(it.value), padL + bw + 8, y + 4);
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
