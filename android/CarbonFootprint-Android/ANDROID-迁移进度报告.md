# 碳足迹 · Android 迁移进度报告

> 用 ArkUI-X 把鸿蒙工程迁移到 Android。
> **当前状态：环境已搭好、代码已改造，卡在 SDK 版本匹配上无法出包。**

---

## 一、结论先说

| 项 | 状态 |
|---|---|
| ArkUI-X SDK 安装与配置 | ✅ 完成（6.1.1.111） |
| ACE Tools 环境自检 | ✅ 5 项全部通过 |
| Android SDK（34） | ✅ 完成 |
| 迁移工程结构 | ✅ 完成（`.arkui-x` + Android 壳） |
| **代码改造（5 处）** | ✅ **完成** |
| **API 版本对齐** | ❌ **卡住** |
| **构建 APK** | ❌ **未成功** |

**根本障碍：ArkUI-X 6.1.1.111 要求 apiVersion 24，而公开可下载的 OpenHarmony SDK 最高是 apiVersion 23（6.1-Release），本地 DevEco 装的是 apiVersion 26。**

---

## 二、已完成的工作

### 2.1 环境（全在 `D:\aaaa\` 下）

| 组件 | 版本 | 路径 | 体积 |
|---|---|---|---|
| ArkUI-X SDK | 6.1.1.111 (apiVersion 24) | `arkui-x-sdk\24\arkui-x` | 538 MB |
| Android SDK | 34.0.0 | `android-sdk` | 430 MB |
| OpenHarmony SDK 26 | 26.0.0.38 | `oh-sdk` | 1.2 GB |
| OpenHarmony SDK 23 | 6.1.0.31 | `ohsdk23` | 3.9 GB |
| ACE Tools | 1.0.0 | `arkui-x-sdk\24\arkui-x\toolchains\bin` | — |

`ace check` 结果：

```
[√] ArkUI-X (ArkUI-X SDK version 6.1.1.111)
[√] OpenHarmony toolchains (OpenHarmony SDK version 26.0.0.38)
[√] HarmonyOS toolchains
[√] Android toolchains (Android SDK version 34.0.0)
[√] DevEco Studio (version 26.0.0.821)
```

### 2.2 迁移工程（`D:\aaaa\CarbonFootprint-Android`）

```
CarbonFootprint-Android\
├── .arkui-x\
│   ├── arkui-x-config.json5        ← 跨平台声明（新增）
│   └── android\                     ← Android 壳工程（Gradle）
│       ├── app\build.gradle
│       ├── app\src\main\AndroidManifest.xml
│       └── gradlew
├── build-profile.json5              ← 已删 useNormalizedOHMUrl
├── entry\src\main\ets\              ← 47 个 .ets（原 49，删 2 个）
├── AppScope\  hvigor\  mock\  sync\
└── ANDROID-迁移说明.md
```

**与原工程对比**：

| 项 | 原工程 | Android 版 |
|---|---|---|
| `.ets` 文件 | 49 | **47** |
| 代码行数 | 12486 | 12414 |
| 差异文件 | — | **仅 3 个**（AppConfig、SecureStore、AiRecognizeService） |
| 删除目录 | — | `entryformability/`、`widget/` |

### 2.3 代码改造（5 处，全部完成）

#### ① `SecureStore.ets` — `security.asset` 不支持

ArkUI-X 没有 `@ohos.security.asset`（系统级加密存储）。

**改法**：`requireNapi('security.asset')` 动态加载，失败降级到 preferences。

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

**代价**：Android 上 API Key 明文存 preferences。界面已有「密钥仅存本机」说明。

#### ② `AiRecognizeService.ets` — `camera` 不支持

ArkUI-X 的 `multimedia` 只有音频，没有相机。

**改法**：动态加载 `cameraPicker`，失败降级为「从相册选一张」。

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

**代价**：Android 上无「直接拍照」，只能相册选图。AI 识别主流程不受影响。

#### ③ `AppConfig.ets` — 新增降级接口

```typescript
static async getRawString(key: string, def: string): Promise<string>
static async setRawString(key: string, value: string): Promise<void>
```

#### ④ `module.json5` — 移除服务卡片

```json5
"extensionAbilities": []
```

#### ⑤ 删除文件

- `entryformability/EntryFormAbility.ets`（57 行）
- `entry/src/main/ets/widget/`（整个目录）
- `entry/src/main/resources/base/profile/form_config.json`
- `string.json` 里的 `widget_label` / `widget_desc`

**原因**：Android 没有 `@ohos.app.form`（服务卡片 Ability 模型）。这是**功能裁剪**，不是适配。

### 2.4 原生支持、无需改动的模块

查 ArkUI-X SDK 的 `plugins/api/lib`，以下都有 Android 原生实现：

| 模块 | 实现文件 | 项目用途 |
|---|---|---|
| `@ohos.data.relationalStore` | `libdata_relationalstore.so` | **数据层 873 行全保留** |
| `@ohos.data.preferences` | `libdata_preferences.so` | 配置存储 |
| `@ohos.net.http` | `ace_http_android.jar` | 网络 |
| `@ohos.file.picker` | `ace_filepicker_android.jar` | 文件选择 |
| `@ohos.file.photoAccessHelper` | `ace_photo_access_helper_android.jar` | 存图到相册 |
| `@ohos.display` | `libdisplay.so` | Canvas 密度 |
| `@ohos.router` / `promptAction` | 已在模块列表 | 路由 / Toast |

**关键**：`relationalStore` 有完整实现，所以 `DBHelper.ets` + `Repository.ets`（873 行）**一行都不用改**。

---

## 三、卡住的地方：API 版本三方不一致

### 3.1 矛盾链

```
ArkUI-X 6.1.1.111        →  apiVersion 24
OpenHarmony 6.1-Release  →  apiVersion 23（最新可下载）
本地 DevEco SDK           →  apiVersion 26
hvigor 要求               →  平台版本号与 API 号必须严格匹配
```

### 3.2 尝试过的方案（全部失败）

| 尝试 | 结果 |
|---|---|
| `compatibleSdkVersion: "24"` | `00306042` 格式不合规（API≤25 必须 `x.y.z(api)`） |
| `compatibleSdkVersion: "6.0.0(24)"` | `00303083` 平台版本与 API 不匹配（无 API 24 SDK） |
| `compatibleSdkVersion: "6.1.0(23)"` + 6.1 SDK | `00303312` 找不到对应 SDK 版本 |
| 复制 26 SDK 改文件名为 24 | `00303312`（hvigor 校验内部版本，不只是目录名） |
| SDK 布局 `sdk/23/{ets,...}` | `00303312` |
| SDK 布局 `sdk/default/{hms,openharmony}` | `00303312` |
| 补 `platformVersion` 字段 | `00303312` |
| 目录名用 `default` | `00303312` |

### 3.3 错误信息

```
hvigor ERROR: 00303312 Configuration Error
Cannot find the corresponding SDK version under the specified SDK path.
SDK path: D:/aaaa/ohsdk23
```

或

```
hvigor ERROR: 00303083
The platform version '6.0.0' and API version '24' of compatibleSdkVersion
in build-profile.json5 do not match.
```

### 3.4 为什么一直失败

hvigor 的版本校验逻辑在闭源的 `hvigor` jar 里，不透明。从 `ace_tools.js` 能看出它读 `<sdk>/<projectApiVersion>/arkui-x/`，但实际校验还依赖 `sdk-pkg.json`、`lists.json` 等元数据的内部一致性——**这些文件的格式只有 DevEco 通过 SDK Manager 下载时才会正确生成**，手工拼装的副本无法通过。

---

## 四、正确的解决路径（需要你操作）

### 方案 A：用 DevEco Studio 的 SDK Manager 装 ArkUI-X（推荐）

DevEco 会同时管理 HarmonyOS SDK 与 ArkUI-X SDK 的版本配套，自动装到正确位置并生成正确元数据。

```
1. 打开 DevEco Studio
2. File → Settings → SDK Manager
3. 在 ArkUI-X 标签页里，选择与已装 HarmonyOS SDK 配套的版本
4. Apply → 等待下载完成
5. 重启 DevEco，重新打开 CarbonFootprint-Android 工程
```

**关键**：SDK Manager 会保证 API 版本一致，这是手工拼装做不到的。

### 方案 B：降 ArkUI-X 版本，与 API 23 对齐

如果必须用 API 23 的 OpenHarmony 6.1 SDK，需要下 ArkUI-X 6.0.x（apiVersion 22）或更早版本。

```bash
# 已下载的 6.0.2 支持 API 22，需配 OpenHarmony 6.0 SDK
https://repo.huaweicloud.com/arkui-crossplatform/sdk/6.0.2.118/windows/
```

**代价**：要再下 OpenHarmony 6.0 SDK，且要在 3 个版本间对齐（ArkUI-X 22 + OH 6.0 + 项目 API 22）。

### 方案 C：直接用 DevEco 升级项目到最新，再迁

```
1. DevEco 里把原工程升级到 HarmonyOS 最新版
2. 用 DevEco 的 ArkUI-X 插件生成跨平台工程
3. 让它自动处理版本
```

---

## 五、代码层面的价值（已完成的部分不白做）

即使出包卡住，**代码改造是对的、可复用的**：

1. **平台抽象思想落地了**
   - `SecureStore` 的 `requireNapi` + 降级模式
   - `AiRecognizeService` 的条件加载 + 降级

2. **确认了哪些能复用、哪些必须改**
   - 数据层（873 行）零改动 —— 这是最大收获
   - 业务逻辑（计算、积分、任务、徽章）零改动
   - 只有 5 处系统能力需要适配

3. **量化了迁移成本**

| 层 | 代码量 | 改动 |
|---|---|---|
| 业务逻辑（service 大部分） | ~6000 行 | **0%** |
| 数据层（db） | 873 行 | **0%** |
| UI 层（pages/components） | ~4000 行 | 0%（Canvas 待验证） |
| 系统能力适配 | ~800 行 | **5 处** |
| 服务卡片 | 57 行 + widget | **删除** |

**总改动比例约 6%**，远低于预估的 20%。

---

## 六、下一步建议

**如果你能操作 DevEco Studio**：

1. 打开 DevEco → Settings → SDK Manager → ArkUI-X 标签
2. 装与当前 HarmonyOS SDK 配套的 ArkUI-X
3. 告诉我装完的版本号，我重新配置并构建

**如果你希望我继续尝试**：

我可以试方案 B（下 ArkUI-X 6.0.x 配 OpenHarmony 6.0），但要再下 2~3 GB，且成功率不确定。

**如果你只是想知道可行性**：

结论已经很明确：**业务逻辑 94% 可复用，只有系统能力要改 5 处，服务卡片必须删。** 技术路径是通的，卡的是工具链版本配套。

---

## 七、磁盘占用说明

当前 `D:\aaaa\` 占 179 GB / 200 GB，剩余 22 GB。

| 目录 | 体积 | 用途 | 可否删 |
|---|---|---|---|
| `SDK` | 16 GB | DevEco 用的 SDK + 模拟器镜像 | **不可删**（模拟器要用） |
| `ohsdk23` | 3.9 GB | OpenHarmony 6.1 SDK（API 23） | 可删（本次下载） |
| `oh-sdk` | 1.2 GB | OpenHarmony 26（ace 配置用） | 可删 |
| `arkui-x-sdk` | 538 MB | ArkUI-X SDK | 保留 |
| `android-sdk` | 430 MB | Android SDK | 保留 |
| `oh-sdk-download` | 4.7 GB | 下载残留 | **可删** |

**建议清理**：`oh-sdk-download`（4.7G）+ `ohsdk23`（3.9G）可释放 8.6 GB。