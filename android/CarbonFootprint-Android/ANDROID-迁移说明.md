# 碳足迹 · Android 迁移说明

> 用 ArkUI-X 把鸿蒙工程迁移到 Android。本文记录环境搭建、代码改造和踩过的坑。

---

## 一、环境清单（已就位）

| 组件 | 版本 | 路径 |
|---|---|---|
| ArkUI-X SDK | 6.1.1.111（apiVersion 24） | `D:\aaaa\arkui-x-sdk\24\arkui-x` |
| ACE Tools | 1.0.0 | 同上的 `toolchains\bin` |
| Android SDK | 34.0.0（platform-tools + build-tools） | `D:\aaaa\android-sdk` |
| JDK | 17.0.12 | `D:\jdk` |
| DevEco Studio | 26.0.0.821（HarmonyOS SDK 26） | `D:\DevecoStudio\DevEco Studio` |

### 版本对应关系（关键）

```
ArkUI-X 6.1.1.111  →  apiVersion 24  →  需要 API 24 的 OpenHarmony SDK
本地 DevEco 只有     →  apiVersion 26  →  平台版本 26.0.0
```

**这是本次迁移最大的障碍**：ArkUI-X 只支持 API 24，而项目原始配置是 API 26。

---

## 二、SDK 目录结构（踩坑重点）

### ACE Tools 的校验规则

ACE Tools 对 SDK 目录结构有**非常严格且不直观**的要求：

| SDK | 要求结构 | 说明 |
|---|---|---|
| ArkUI-X | `<root>/<apiVersion>/arkui-x/` | 目录名必须是**纯数字**（如 `24`） |
| OpenHarmony | `<root>/<apiVersion>/{ets,js,toolchains}` | 同上，且根目录需 `licenses/` |
| HarmonyOS | `<root>/<ver>/{hmscore,openharmony}` + `<root>/licenses` | `hmscore` 和 `openharmony` 下还要再套一层版本号 |

**目录名必须能通过 `isNaN()` 判断**——`24` 可以，`6.1.1.111` 不行，`26.0.0` 也不行。

### 实际配置

```bash
# ArkUI-X
ace config --arkui-x-sdk "D:/aaaa/CarbonFoot/android/arkui-x-sdk-26"

# OpenHarmony（26）
ace config --openharmony-sdk "D:/aaaa/CarbonFoot/harmonyos/oh-sdk"

# HarmonyOS
ace config --harmonyos-sdk "D:/aaaa/CarbonFoot/harmonyos/ace-hos-sdk/26.0.0"

# Android
ace config --android-sdk "D:/aaaa/CarbonFoot/android/android-sdk"
```

### 环境自检

```bash
ace check
```

输出应全部为 `[√]`：

```
[√] ArkUI-X (ArkUI-X SDK version 6.1.1.111)
[√] OpenHarmony toolchains (OpenHarmony SDK version 26.0.0.38)
[√] HarmonyOS toolchains
[√] Android toolchains (Android SDK version 34.0.0)
[√] DevEco Studio (version 26.0.0.821)
```

---

## 三、工程结构改造

### 3.1 工程根目录变动

| 项 | 变化 |
|---|---|
| `build-profile.json5` | 删除 `useNormalizedOHMUrl`（ArkUI-X 强制要求） |
| `build-profile.json5` | `compatibleSdkVersion` 改为 API 24 格式 |
| `.arkui-x/arkui-x-config.json5` | **新增**，声明跨平台模块 |
| `.arkui-x/android/` | **新增**，Android 壳工程（Gradle 项目） |

### 3.2 `arkui-x-config.json5`

位置：**`.arkui-x/arkui-x-config.json5`**（不是工程根目录）

```json5
{
  "crossplatform": true,
  "modules": [
    "entry"
  ]
}
```

### 3.3 Android 壳工程配置

`.arkui-x/android/app/build.gradle`：

```gradle
applicationId "com.carbon.footprint"
minSdkVersion 26
targetSdkVersion 34
compileSdkVersion 34
```

`.arkui-x/android/app/src/main/AndroidManifest.xml`：

```xml
package="com.carbon.footprint"

<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
```

---

## 四、代码改造（已完成的 5 处）

### 4.1 `common/SecureStore.ets` — `security.asset` 不支持

**问题**：ArkUI-X 没有 `@ohos.security.asset`（密钥加密存储）。

**改造**：用 `requireNapi('security.asset')` 动态加载，失败则降级到 preferences 明文存储。

```typescript
private static loadAsset(): ESObject | null {
  try {
    const mod: ESObject = requireNapi('security.asset');
    return mod ?? null;
  } catch (e) {
    return null;
  }
}
```

**代价**：Android 上 API Key 是明文存在 preferences 里，安全性低于鸿蒙的 Asset Store。界面上已有「密钥仅存本机」的说明，可接受。

### 4.2 `service/AiRecognizeService.ets` — `camera` 不支持

**问题**：ArkUI-X 的 `multimedia` 只支持音频，没有相机。

**改造**：动态加载 `ability.cameraPicker`，失败则降级为「从相册选一张」。

```typescript
let picker: ESObject = null;
try {
  picker = requireNapi('ability.cameraPicker');
} catch (e) {
  picker = null;
}
if (picker === null) {
  const uris: string[] = await AiRecognizeService.pickImages(1);
  if (uris.length === 0) throw new Error('未选择图片');
  return uris[0];
}
```

**代价**：Android 上没有「直接拍照」按钮，只能从相册选。AI 识别主流程不受影响。

### 4.3 `common/AppConfig.ets` — 新增降级存储接口

为配合 SecureStore 降级，新增两个通用方法：

```typescript
static async getRawString(key: string, def: string): Promise<string>
static async setRawString(key: string, value: string): Promise<void>
```

### 4.4 `module.json5` — 移除服务卡片

**问题**：Android 没有 `@ohos.app.form`（服务卡片 Ability 模型）。

**改造**：

```json5
"extensionAbilities": []
```

同时删除：
- `entry/src/main/ets/entryformability/EntryFormAbility.ets`（57 行）
- `entry/src/main/ets/widget/`（整个目录）
- `entry/src/main/resources/base/profile/form_config.json`

**代价**：桌面小组件功能在 Android 上完全消失。这是**功能裁剪**，不是适配。

### 4.5 保留但不再使用

`common/CardSnapshot.ets` 保留——它是纯 preferences 操作，不依赖 form 模块。Android 上没有卡片消费它，但 `Index.ets` 和 `ExportService.ets` 仍调用，不会报错。

---

## 五、原生支持的 API（无需改动）

查过 ArkUI-X SDK 的 `plugins/api/lib`，以下模块都有 Android 原生实现：

| 模块 | 实现文件 | 项目用途 |
|---|---|---|
| `@ohos.data.relationalStore` | `libdata_relationalstore.so` | **数据层 873 行全部保留** |
| `@ohos.data.preferences` | `libdata_preferences.so` | 配置存储 |
| `@ohos.net.http` | `ace_http_android.jar` | 网络请求 |
| `@ohos.file.picker` | `ace_filepicker_android.jar` | 文件选择器 |
| `@ohos.file.photoAccessHelper` | `ace_photo_access_helper_android.jar` | 保存图片到相册 |
| `@kit.MediaLibraryKit` | 同上 | 相册访问 |
| `@ohos.display` | `libdisplay.so` | Canvas 屏幕密度 |
| `@ohos.router` | 已在模块列表 | 页面路由 |
| `@ohos.promptAction` | 已在模块列表 | Toast 提示 |

**最重要的发现**：`relationalStore` 有完整 Android 实现，所以 `DBHelper.ets` + `Repository.ets`（873 行）**一行都不用改**。

---

## 六、构建命令

```bash
cd D:\aaaa\CarbonFootprint-Android

export PATH="/d/aaaa/arkui-x-sdk/24/arkui-x/toolchains/bin:$PATH"
export ANDROID_HOME="D:/aaaa/CarbonFoot/android/android-sdk"
export JAVA_HOME="D:/jdk"
export DEVECO_SDK_HOME="D:/DevecoStudio/DevEco Studio/sdk"

ace build apk
```

产物位置：`entry/build/default/outputs/apk/`

---

## 七、待解决问题

### 7.1 版本冲突（阻塞中）

```
ArkUI-X 6.1.1.111  →  支持 API 24
项目原始配置        →  API 26
hvigor 严格要求      →  平台版本号和 API 号必须匹配
本地已装 SDK        →  只有 API 26
```

**解决方案**：下载 OpenHarmony 6.1-Release SDK（API 24），与 ArkUI-X 对齐。

### 7.2 Canvas 渲染一致性（待验证）

`components/Chart.ets`（776 行）用 Canvas 手绘四类图表。ArkUI-X 的 Canvas 实现基于 Skia，理论上一致，但**必须实测**：

- 柱状图、折线图、饼图、目标环的位置和颜色
- `fpFont()` 的密度换算（`display.getDefaultDisplaySync().densityPixels`）

### 7.3 AI 识别降级体验

Android 上无相机直拍，只有相册选图。如果要做完整功能，需在 Android 壳工程里用 Java 实现相机，通过 `@arkui-x.bridge` 暴露给 ArkTS。**这属于后续增强，不是迁移必需。**

---

## 八、文件清单一览

### 建成的目录

```
D:\aaaa\
├── arkui-x-sdk\          538 MB   ArkUI-X SDK 6.1.1
├── arkui-x-download\     217 MB   原始 zip（可删）
├── android-sdk\          ~1 GB    Android SDK 34
├── android-sdk-download\ 136 MB   原始 zip（可删）
├── oh-sdk\               1.2 GB   OpenHarmony 26 SDK（ace 用）
├── hos-sdk\              6.8 GB   HarmonyOS SDK（ace 校验用）
├── oh-sdk-download\      ~4 GB    OpenHarmony 6.1（下载中）
└── CarbonFootprint-Android\  701 KB   迁移工程
```

### 迁移工程结构

```
CarbonFootprint-Android\
├── .arkui-x\
│   ├── arkui-x-config.json5    跨平台声明
│   └── android\                Android 壳工程
│       ├── app\build.gradle
│       ├── app\src\main\AndroidManifest.xml
│       └── gradlew
├── build-profile.json5         API 24 配置
├── entry\src\main\ets\         47 个 .ets（原 51 个，删了 4 个 form 相关）
├── AppScope\
├── hvigor\
└── mock\ sync\                 本地服务（原样保留）
```

---

## 九、与原工程的差异对比

| 项 | 原工程 | Android 版 |
|---|---|---|
| `.ets` 文件数 | 51 | **47** |
| 服务卡片 | 有（EntryFormAbility + WidgetCard） | **无** |
| 密钥存储 | Asset Store（加密） | **preferences（明文）** |
| 拍照识别 | 直接调相机 | **只能相册选图** |
| API 版本 | 26 | **24** |
| 数据层 | relationalStore | **relationalStore（不变）** |
| 业务逻辑 | 纯 ArkTS | **纯 ArkTS（不变）** |

**核心结论：业务逻辑几乎零改动，系统能力层做了 5 处降级改造。**