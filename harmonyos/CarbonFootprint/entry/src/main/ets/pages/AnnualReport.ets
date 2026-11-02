import router from '@ohos.router';
import { AppInit } from '../common/AppInit';
import { Constants } from '../common/Constants';
import { Theme } from '../common/Theme';
import { BehaviorRecord } from '../model/Models';
import { BehaviorRepo } from '../db/Repository';
import { DateUtil } from '../utils/DateUtil';
import { EcoUtil } from '../utils/EcoUtil';
import { EmptyState } from '../components/EmptyState';

/**
 * 年度报告：把一年的记录讲成四屏。
 *
 * 数据全部来自行为记录，不额外落表；四屏分别是总量、记录密度、
 * 高光项、意义换算，滑动切换。做这个页面的初衷是路演时能有一条
 * "故事线"，而不只是把图表堆在一起。
 */
@Entry
@Component
struct AnnualReport {
  @State year: number = new Date().getFullYear();
  @State totalG: number = 0;
  @State recordCount: number = 0;
  @State activeDays: number = 0;
  @State maxStreak: number = 0;
  @State topSub: string = '';
  @State topSubG: number = 0;
  @State topMonth: string = '';
  @State topMonthG: number = 0;
  @State firstDate: string = '';
  @State loaded: boolean = false;
  @State pageIndex: number = 0;

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      await AppInit.ensure();
      const y = new Date().getFullYear();
      this.year = y;
      const start = new Date(y, 0, 1).getTime();
      const end = new Date(y + 1, 0, 1).getTime() - 1;
      const all: BehaviorRecord[] = await BehaviorRepo.all();
      const list: BehaviorRecord[] = [];
      for (const r of all) {
        if (r.createdAt >= start && r.createdAt <= end) {
          list.push(r);
        }
      }
      let total = 0;
      const daySet: Set<number> = new Set<number>();
      const subMap: Map<string, number> = new Map<string, number>();
      const monthMap: Map<number, number> = new Map<number, number>();
      for (const r of list) {
        total += r.reductionG;
        daySet.add(DateUtil.startOfDay(r.createdAt));
        if (r.reductionG > 0) {
          const sp = subMap.get(r.subType);
          subMap.set(r.subType, (sp !== undefined ? sp : 0) + r.reductionG);
          const m = new Date(r.createdAt).getMonth();
          const mp = monthMap.get(m);
          monthMap.set(m, (mp !== undefined ? mp : 0) + r.reductionG);
        }
      }
      let topS = '';
      let topG = 0;
      subMap.forEach((v: number, k: string) => {
        if (v > topG) {
          topG = v;
          topS = k;
        }
      });
      let topM = -1;
      let topMG = 0;
      monthMap.forEach((v: number, k: number) => {
        if (v > topMG) {
          topMG = v;
          topM = k;
        }
      });
      const dayArr: number[] = [];
      daySet.forEach((d: number) => {
        dayArr.push(d);
      });
      dayArr.sort((a: number, b: number) => a - b);
      let maxStreak = 0;
      let cur = 0;
      let prev = -1;
      for (const d of dayArr) {
        if (prev < 0 || d - prev === DateUtil.DAY_MS) {
          cur++;
        } else {
          cur = 1;
        }
        if (cur > maxStreak) {
          maxStreak = cur;
        }
        prev = d;
      }
      this.totalG = total;
      this.recordCount = list.length;
      this.activeDays = dayArr.length;
      this.maxStreak = maxStreak;
      this.topSub = topS;
      this.topSubG = topG;
      this.topMonth = topM >= 0 ? (topM + 1) + ' 月' : '';
      this.topMonthG = topMG;
      this.firstDate = list.length > 0 ? DateUtil.formatYMD(list[list.length - 1].createdAt) : '';
      this.loaded = true;
    } catch (e) {
      console.error('AnnualReport load error: ' + JSON.stringify(e));
      this.loaded = true;
    }
  }

  @Builder
  coverSlide() {
    Column({ space: 8 }) {
      Text(`${this.year}`)
        .fontSize(76)
        .fontWeight(FontWeight.Bold)
        .fontColor('rgba(255,255,255,0.18)')
      Text('你的低碳足迹')
        .fontSize(Theme.FS_HERO)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
      Row({ space: 6 }) {
        Text(DateUtil.gramsToKg(this.totalG))
          .fontSize(54)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('kg')
          .fontSize(Theme.FS_TITLE)
          .fontColor('rgba(255,255,255,0.75)')
          .margin({ bottom: 10 })
      }
      .alignItems(VerticalAlign.Bottom)
      Text('CO₂e')
        .fontSize(Theme.FS_TERTIARY)
        .fontColor('rgba(255,255,255,0.6)')
      if (this.firstDate !== '') {
        Text(`从 ${this.firstDate} 的第一笔记录开始`)
          .fontSize(Theme.FS_TERTIARY)
          .fontColor('rgba(255,255,255,0.72)')
          .margin({ top: 22 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .linearGradient({ angle: 165, colors: [['#2F6B4F', 0.0], ['#1E4A37', 1.0]] })
    .borderRadius(24)
  }

  @Builder
  recordSlide() {
    Column({ space: 26 }) {
      Text('这一年，你记录了')
        .fontSize(Theme.FS_TITLE)
        .fontColor('rgba(255,255,255,0.75)')

      Row({ space: 6 }) {
        Text(`${this.recordCount}`)
          .fontSize(58)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text('笔')
          .fontSize(Theme.FS_TITLE)
          .fontColor('rgba(255,255,255,0.75)')
          .margin({ bottom: 12 })
      }
      .alignItems(VerticalAlign.Bottom)

      Row({ space: 40 }) {
        Column({ space: 4 }) {
          Text(`${this.activeDays}`)
            .fontSize(Theme.FS_DISPLAY)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('天有记录')
            .fontSize(Theme.FS_TERTIARY)
            .fontColor('rgba(255,255,255,0.7)')
        }
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text(`${this.maxStreak}`)
            .fontSize(Theme.FS_DISPLAY)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('最长连续')
            .fontSize(Theme.FS_TERTIARY)
            .fontColor('rgba(255,255,255,0.7)')
        }
        .alignItems(HorizontalAlign.Center)
      }
      .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .linearGradient({ angle: 165, colors: [['#5B7C99', 0.0], ['#3C566B', 1.0]] })
    .borderRadius(24)
  }

  @Builder
  highlightSlide() {
    Column({ space: 22 }) {
      Text('你的高光')
        .fontSize(Theme.FS_TITLE)
        .fontColor('rgba(255,255,255,0.75)')

      Column({ space: 6 }) {
        Text('减排最多的一项')
          .fontSize(Theme.FS_TERTIARY)
          .fontColor('rgba(255,255,255,0.7)')
        Text(this.topSub !== '' ? this.topSub : '—')
          .fontSize(Theme.FS_DISPLAY)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text(this.topSubG > 0 ? DateUtil.gramsToKg(this.topSubG) + ' kg CO₂e' : '')
          .fontSize(Theme.FS_BODY)
          .fontColor('rgba(255,255,255,0.8)')
      }
      .alignItems(HorizontalAlign.Center)

      Divider()
        .width(60)
        .color('rgba(255,255,255,0.3)')

      Column({ space: 6 }) {
        Text('最活跃的月份')
          .fontSize(Theme.FS_TERTIARY)
          .fontColor('rgba(255,255,255,0.7)')
        Text(this.topMonth !== '' ? this.topMonth : '—')
          .fontSize(Theme.FS_DISPLAY)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
        Text(this.topMonthG > 0 ? DateUtil.gramsToKg(this.topMonthG) + ' kg CO₂e' : '')
          .fontSize(Theme.FS_BODY)
          .fontColor('rgba(255,255,255,0.8)')
      }
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .linearGradient({ angle: 165, colors: [['#A8562F', 0.0], ['#7A3A1C', 1.0]] })
    .borderRadius(24)
  }

  @Builder
  meaningSlide() {
    Column({ space: 14 }) {
      Text('这些减排意味着')
        .fontSize(Theme.FS_TITLE)
        .fontColor('rgba(255,255,255,0.75)')

      Text(EcoUtil.totalText(this.totalG).replace('≈ ', ''))
        .fontSize(Theme.FS_DISPLAY)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)

      if (this.totalG / EcoUtil.TREE_G_PER_YEAR >= 0.1) {
        Text(`相当于少开 ${Math.round(this.totalG / EcoUtil.CAR_G_PER_KM)} 公里车`)
          .fontSize(Theme.FS_TITLE)
          .fontColor('rgba(255,255,255,0.82)')
          .textAlign(TextAlign.Center)
      }

      Divider()
        .width(60)
        .color('rgba(255,255,255,0.3)')
        .margin({ top: 10, bottom: 10 })

      Text('每一个数字背后，都是你真实做过的小事')
        .fontSize(Theme.FS_BODY)
        .fontColor('rgba(255,255,255,0.75)')
        .textAlign(TextAlign.Center)

      Button('继续记录')
        .fontSize(Theme.FS_CONTENT)
        .fontColor('#1E4A37')
        .backgroundColor('#FFFFFF')
        .borderRadius(22)
        .height(42)
        .padding({ left: 26, right: 26 })
        .margin({ top: 16 })
        .onClick(() => {
          AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding({ left: 24, right: 24 })
    .linearGradient({ angle: 165, colors: [['#B8862F', 0.0], ['#8A6220', 1.0]] })
    .borderRadius(24)
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(Theme.FS_HERO)
          .onClick(() => {
            router.back();
          })
        Blank()
        Text(`${this.year} 年度报告`)
          .fontSize(Theme.FS_HEAD)
          .fontWeight(FontWeight.Bold)
        Blank()
        Text('')
          .width(22)
      }
      .width('100%')
      .padding({ left: 14, right: 14, top: 14, bottom: 10 })

      if (!this.loaded) {
        Column()
          .layoutWeight(1)
      } else if (this.recordCount === 0) {
        Column() {
          EmptyState({
            icon: '',
            title: '今年还没有记录',
            desc: '从今天记一笔，明年就能看到属于你的年度报告',
            buttonText: '去记录',
            onButton: (): void => {
              AppStorage.setOrCreate('mainTab', Constants.TAB_RECORD);
              router.back();
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Swiper() {
          this.coverSlide()
          this.recordSlide()
          this.highlightSlide()
          this.meaningSlide()
        }
        .index(this.pageIndex)
        .indicator(true)
        .loop(false)
        .layoutWeight(1)
        .margin({ left: 14, right: 14 })
        .onChange((index: number) => {
          this.pageIndex = index;
        })

        Text('左右滑动查看')
          .fontSize(Theme.FS_SECONDARY)
          .fontColor(Theme.TEXT_TERTIARY)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 10, bottom: 14 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Theme.BG)
  }
}
