# 故障排查报告：Android 沉浸式状态栏与页面顶部避让（多机型适配）

| 项目 | 内容 |
| --- | --- |
| 文档类型 | 故障排查报告 / 开发记录 |
| 所属项目 | CarbonFootprint（碳足迹）· Android 端（ArkUI-X） |
| 问题标题 | 状态栏（时间/电量）遮挡导致页面顶部渐变与圆角无法完整显示 |
| 发生日期 | 2026-11-17 |
| 报告版本 | v2.0（含多机型适配重构） |
| 严重程度 | 体验级（功能可用，视觉割裂） |
| 当前状态 | ✅ 已解决并验证（主 Tab 页 + 真实高度多机型适配） |
| 关键词 | ArkUI-X、沉浸式状态栏、setWindowLayoutFullScreen、expandSafeArea、Bridge、status_bar_height、多机型适配、getWindowAvoidArea |

---

## 一、摘要（TL;DR）

应用打包到 Android 真机后，顶部是**不透明的黑色系统状态栏**，页面内容从其下方开始，导致设计上的**顶部渐变与圆角无法延伸显示**，视觉割裂。

**修复分两部分**：

**A. 沉浸式视觉**（让内容延伸到状态栏区域）
1. `EntryAbility` 设 `setWindowLayoutFullScreen(true)` + `setWindowSystemBarEnable(['status'])` + 状态栏透明深色图标；
2. 顶部渐变块加 `expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP])`；
3. 全屏布局下内容不再自动避让，各页面顶部手动加状态栏高度 padding。

**B. 多机型状态栏高度**（核心难点）
- 先试 `getWindowAvoidArea(TYPE_SYSTEM)` → 在 ArkUI-X Android 上**始终返回 0**（移到 loadContent 回调、延迟重试均无效）；
- 退而用 `display.densityPixels × 24vp` 估算 → 算出 76px，但真机实际是 **138px**，误差近一倍；
- **最终方案：用 ArkUI-X Bridge 调 Android 原生 `status_bar_height` 系统资源**，拿到各机型系统定义的真实值（本机 138px），普通屏/刘海屏/挖孔屏/折叠屏全部自适应。

**关键启示**：
- 状态栏高度**禁止硬编码或用密度估算**，Android 官方和鸿蒙官方都要求取系统避让区真值；
- ArkUI-X Android 上 `getWindowAvoidArea` 不可靠时，**Bridge 调原生资源**是通用可行的多机型适配方案。

---

## 二、环境信息

| 类别 | 版本 / 说明 |
| --- | --- |
| 设备 | 小米 23117RK66C（manet），Android 14，屏幕 1440×3200 |
| 密度 | Physical 560 / Override 506 dpi（densityPixels≈3.16） |
| 真实状态栏高度 | **138px**（系统 `status_bar_height` 资源，adb `dumpsys window` 的 `overrideNonDecorInsets=[0,138]` 印证） |
| ArkUI-X 版本 | 26.0.0.28 |
| 应用包名 | `com.carbon.footprint` |
| 构建命令 | `ace build apk --debug --target-platform arm64` |

---

## 三、问题现象

- 顶部为黑色不透明状态栏，页面内容从下方开始，顶部渐变被"切掉"。
- 沉浸式改完后出现新问题：标题被顶到状态栏区域与时间/电量图标重叠——因为全屏布局下内容不再自动避让。

---

## 四、排查与定位（含走过的弯路）

### 4.1 沉浸式三步（正确）

**第一步：窗口配置**（`EntryAbility.ets`，必须放在 `loadContent` 成功回调内）

```typescript
const win = windowStage.getMainWindowSync();
win.setWindowLayoutFullScreen(true);              // 内容延伸到状态栏/导航栏
win.setWindowSystemBarEnable(['status']);          // 保留状态栏，隐藏底部导航区
win.setWindowSystemBarProperties({
  statusBarColor: '#00000000',                    // 状态栏透明
  isStatusBarLightIcon: false                     // 深色图标（浅色页面适配）
});
```

> ArkUI-X 跨平台必须 `setWindowLayoutFullScreen` **配合** `setWindowSystemBarEnable`，否则沉浸式异常（华为官方问答确认）。

**第二步：渐变延伸**（`Index.ets`）

```typescript
// 顶部 190vp 渐变 Column
.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
```

> `expandSafeArea` 只延伸绘制、不改变布局，解决的是"背景延伸"，不解决"内容避让"。

**第三步：内容手动避让**

全屏布局后，各页面顶部 padding 加状态栏高度：`top: px2vp(this.statusBarHeightPx) + 基准`，通过 `@StorageProp('statusBarHeightPx')` 读取。

### 4.2 状态栏高度获取的三次尝试（关键弯路）

| 尝试 | 做法 | 结果 |
| --- | --- | --- |
| ① 直接取 | `onWindowStageCreate` 里 `getWindowAvoidArea(TYPE_SYSTEM).topRect.height` | 返回 **0**（窗口未完成布局） |
| ② 移到回调+重试 | 放进 `loadContent` 回调，加 120ms/500ms 延迟重试，并读 `TYPE_CUTOUT` 取较大值 | 仍返回 **0**（ArkUI-X Android 未实现该 API） |
| ③ 密度估算 | `Math.round(24 * display.densityPixels)` = 76px | **错误**，真机实际 138px，误差近一倍 |
| ④ Bridge 原生（最终） | Bridge 调 Android `status_bar_height` 资源 | ✅ **138px，正确** |

### 4.3 最终方案：ArkUI-X Bridge 调原生资源

**为什么不硬编码 24dp？** Android 官方明确：避免硬编码状态栏高度，会因机型差异导致重叠/裁切；刘海/挖孔屏要用系统避让区真值。

**Android 侧**（`StatusBarBridgePlugin.java`，新建）

```java
public class StatusBarBridgePlugin extends BridgePlugin {
    public static final String BRIDGE_NAME = "StatusBarBridge";
    public StatusBarBridgePlugin(Context context, BridgeManager manager) {
        super(context, BRIDGE_NAME, manager);
        this.mContext = context;
    }
    // JS 侧 callMethodSync("getStatusBarHeight") 通过反射调用此方法
    public int getStatusBarHeight() {
        Resources res = mContext.getResources();
        int id = res.getIdentifier("status_bar_height", "dimen", "android");
        if (id > 0) return res.getDimensionPixelSize(id);   // 各机型系统定义真值
        return Math.round(24 * res.getDisplayMetrics().density); // 兜底
    }
}
```

在 `MainActivity.onCreate`（`super.onCreate` 之后）注册：

```java
getBridgeManager().registerBridgePlugin(
    StatusBarBridgePlugin.BRIDGE_NAME,
    new StatusBarBridgePlugin(this, getBridgeManager()));
```

**ArkTS 侧**（`EntryAbility.ets`）

```typescript
import Bridge from '@arkui-x.bridge';
const statusBridge = Bridge.createBridge('StatusBarBridge');
const r = statusBridge.callMethodSync('getStatusBarHeight');  // 同步拿 px
if (typeof r === 'number' && r > 0) {
  AppStorage.setOrCreate('statusBarHeightPx', r as number);
}
```

**降级链**：Bridge 原生值 > `getWindowAvoidArea`（鸿蒙端可用）> display 密度估算。一套代码兼容 Android / 鸿蒙。

### 4.4 修改文件清单

| 文件 | 改动 |
| --- | --- |
| `.arkui-x/android/app/src/main/java/StatusBarBridgePlugin.java` | **新建**：原生状态栏高度 Bridge，读 `status_bar_height` 资源 |
| `.arkui-x/android/app/src/main/java/MainActivity.java` | 注册 BridgePlugin |
| `EntryAbility.ets` | 沉浸式配置（loadContent 回调内）+ Bridge 取高度 + avoidAreaChange 监听 + 降级链 |
| `Index.ets` | 渐变加 expandSafeArea；HomeView 顶部 padding 避让 |
| `Record.ets` / `History.ets` / `Tasks.ets` / `Settings.ets` | 各加 `@StorageProp` + 顶部 padding 避让（4 个主 Tab） |
| `AiRecognize.ets` / `AnnualReport.ets` / `Family.ets` / `Inclusive.ets` / `Knowledge.ets` / `KnowledgeDetail.ets` / `SettingsDetail.ets` / `ShareCard.ets` | 各加 `@StorageProp` + 顶部导航 padding 避让（8 个二级页） |
| `Badges.ets` | 加 `@StorageProp` + 顶部导航 `margin({ top })` 避让（固定高度页特殊处理） |

---

## 五、验证结果

| 检查项 | 结果 |
| --- | --- |
| Bridge 注册 | ✅ `register result = true` |
| JS 调用原生 | ✅ `callMethodSync → getStatusBarHeight` |
| 真实高度 | ✅ `resource = 138` → `height via Bridge = 138`（非兜底 76） |
| 三次读取一致 | ✅ initial / 120ms / 500ms 均为 138 |
| 状态栏透明 + 深色图标 | ✅ |
| 首页/录入页标题避让 | ✅ 在状态栏下方，无重叠 |
| 二级页（双碳科普 padding / 徽章墙 margin）| ✅ 标题在状态栏下方，无重叠 |
| 14 个页面整体编译 | ✅ BUILD SUCCESSFUL |
| JS 错误 / 崩溃 | ✅ 无 |

截图演进：`cf_before.png`（黑色状态栏）→ `cf_after4.png`（透明但用76px估算）→ `cf_bridge.png`（透明 + 真实138px）→ `cf_sub_knowledge.png` / `cf_sub_badges2.png`（二级页避让）。

---

## 六、经验总结与避坑指南

1. **ArkUI-X 沉浸式四要素**：全屏布局 + `setWindowSystemBarEnable` + 内容延伸（`expandSafeArea`）+ 内容手动避让。`expandSafeArea` 只管绘制不管布局，两者别混。

2. **`getWindowAvoidArea` 在 ArkUI-X Android 不可靠**：始终返回 0，与调用时机无关。`avoidAreaChange` 也可能不触发。不要依赖它作为 Android 端的高度来源。

3. **禁止密度估算/硬编码状态栏高度**：本机密度算 76px、真实 138px，误差近一倍。刘海/挖孔屏差距更大。

4. **Bridge 是多机型适配的正解**：Android 原生 `status_bar_height` 资源由各 ROM 按机型定义，是系统真值；Bridge 同步调用开销小、可靠。

5. **降级链保证跨平台**：Bridge（Android）→ getWindowAvoidArea（鸿蒙）→ 密度估算，一份代码多端可用。

6. **每个跨平台 API 单独 try-catch**：iOS/Android/鸿蒙支持度不一，避免一端不支持拖垮启动。

7. **全部页面覆盖**：14 个页面（5 主 Tab + 9 二级页面）均已加顶部避让。二级页面（AiRecognize、AnnualReport、Badges、Family、Inclusive、Knowledge、KnowledgeDetail、SettingsDetail、ShareCard）统一加 `@StorageProp('statusBarHeightPx')` + 顶部 padding；其中 Badges 顶部导航固定 `height(52)`，改用 `margin({ top })` 下推避免压缩内容。已真机抽查双碳科普（padding 方式）与徽章墙（margin 方式），均正确避让。

> 新增页面时务必同步：在 struct 加 `@StorageProp('statusBarHeightPx')` + 顶部导航加避让（padding 或 margin）。这是全屏布局下的强制约定。

---

## 七、附录：可复用代码

见第四章 4.3 的 Java / ArkTS 完整片段。关键 import：`@arkui-x.bridge`（仅 ArkUI-X 工程有，鸿蒙工程需条件处理）。

*本文档记录的问题已解决（主 Tab 页 + 多机型真实高度）。二级页面避让待办见第六章第 7 条。*
