import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';
import display from '@ohos.display';
import Bridge from '@arkui-x.bridge';
import { AppInit } from '../common/AppInit';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    AppInit.bootstrap(this.context);
  }

  onDestroy(): void {
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 注意：沉浸式配置与避让区高度读取必须放在 loadContent 成功回调里，
    // 窗口内容加载完成后 getWindowAvoidArea 才能拿到真实值（否则返回 0）。
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code !== 0) {
        console.error('loadContent failed: ' + JSON.stringify(err));
        return;
      }
      this.applyImmersiveWindow(windowStage);
    });
  }

  /**
   * 配置沉浸式窗口 + 多机型状态栏高度适配。
   *
   * 设计原则（参考 Android 官方「避免硬编码状态栏高度」与鸿蒙沉浸式指南）：
   *  1. 状态栏高度取 TYPE_SYSTEM.topRect 与 TYPE_CUTOUT.topRect 的较大值，
   *     兼顾普通屏 / 刘海屏 / 挖孔屏 / 折叠屏；
   *  2. 单位为 px，写入 AppStorage 由页面 px2vp 转换后作为 padding；
   *  3. 注册 avoidAreaChange 监听，旋转 / 折叠 / 分屏时动态刷新；
   *  4. 延迟重试：ArkUI-X Android 上首帧可能仍返回 0，用多次重试兜底；
   *  5. 最终兜底用 display 密度按 24vp 估算，保证任何机型都有合理值。
   */
  private applyImmersiveWindow(windowStage: window.WindowStage): void {
    let win: window.Window | undefined;
    try {
      win = windowStage.getMainWindowSync();
    } catch (e) {
      console.error('[Immersive] getMainWindow fail: ' + JSON.stringify(e));
      return;
    }
    const mainWindow: window.Window = win as window.Window;

    // --- 1. 沉浸式窗口配置（每个接口单独容错，避免单端不支持影响启动） ---
    this.tryCall(() => mainWindow.setWindowLayoutFullScreen(true), 'fullScreen');
    this.tryCall(() => mainWindow.setWindowSystemBarEnable(['status']), 'systemBarEnable');
    this.tryCall(() => mainWindow.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      isStatusBarLightIcon: false
    }), 'systemBarProps');

    // --- 2. 多机型状态栏高度：Bridge(Android 原生) > AvoidArea > 密度兜底 ---
    // 创建一次 Bridge 复用（ArkUI-X Android 上 getWindowAvoidArea 常返回 0，
    // 因此优先用 Bridge 调 Android 原生 status_bar_height 资源，各机型自动适配）。
    const statusBridge = Bridge.createBridge('StatusBarBridge');
    const readAvoidHeight = (): number => {
      let hPx = 0;
      // 优先级 1：Android 原生 Bridge（真实系统资源，多机型自适应）
      try {
        const r = statusBridge.callMethodSync('getStatusBarHeight');
        if (typeof r === 'number' && r > 0) {
          hPx = r as number;
          console.info('[Immersive] height via Bridge = ' + hPx);
        }
      } catch (e) {
        // 非 Android 平台无此 Bridge，忽略，走后续方案
      }
      // 优先级 2：ArkUI window 避让区（鸿蒙端可用）
      if (hPx <= 0) {
        try {
          const sys = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
          hPx = sys.topRect.height;
          try {
            const cut = mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_CUTOUT);
            if (cut.topRect.height > hPx) {
              hPx = cut.topRect.height;
            }
          } catch (e) {
            // 部分平台不支持 TYPE_CUTOUT
          }
        } catch (e) {
          console.error('[Immersive] getWindowAvoidArea fail: ' + JSON.stringify(e));
        }
      }
      return hPx;
    };

    // 密度兜底值（24vp 状态栏标准高度换算为 px）
    const fallbackPx = (): number => {
      try {
        return Math.round(24 * display.getDefaultDisplaySync().densityPixels);
      } catch (e) {
        return 72; // 极端兜底：3 倍密度
      }
    };

    // 写入 AppStorage：真实值优先，否则密度兜底
    const commitHeight = (source: string): void => {
      let hPx = readAvoidHeight();
      if (hPx <= 0) {
        hPx = fallbackPx();
        console.info('[Immersive] use fallback (' + source + ') = ' + hPx);
      } else {
        console.info('[Immersive] use avoidArea (' + source + ') = ' + hPx);
      }
      AppStorage.setOrCreate('statusBarHeightPx', hPx);
    };

    // 首帧读取 + 多次延迟重试（覆盖 ArkUI-X 上布局异步就绪的情况）
    commitHeight('initial');
    setTimeout(() => commitHeight('delay-120ms'), 120);
    setTimeout(() => commitHeight('delay-500ms'), 500);

    // --- 3. 动态监听：旋转 / 折叠 / 分屏 / 避让区变化时刷新 ---
    try {
      mainWindow.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM ||
            data.type === window.AvoidAreaType.TYPE_CUTOUT) {
          const hPx = data.area.topRect.height;
          if (hPx > 0) {
            AppStorage.setOrCreate('statusBarHeightPx', hPx);
            console.info('[Immersive] avoidAreaChange = ' + hPx);
          }
        }
      });
    } catch (e) {
      console.error('[Immersive] on avoidAreaChange fail: ' + JSON.stringify(e));
    }
  }

  /** 统一的安全调用包装：Promise 接口失败只打日志，不影响其他配置 */
  private tryCall(action: () => Promise<void>, tag: string): void {
    try {
      action()
        .then(() => console.info('[Immersive] ' + tag + ' success'))
        .catch((e: object) => console.error('[Immersive] ' + tag + ' fail: ' + JSON.stringify(e)));
    } catch (e) {
      console.error('[Immersive] ' + tag + ' throw: ' + JSON.stringify(e));
    }
  }

  onWindowStageDestroy(): void {
  }

  onForeground(): void {
  }

  onBackground(): void {
  }
}
