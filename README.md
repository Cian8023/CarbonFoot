# CarbonFootprint（碳足迹）

基于 ArkUI-X / HarmonyOS 的跨平台碳足迹记录应用，**一套 ArkTS 代码同时构建 HarmonyOS 与 Android 两端**。

## 仓库结构（分支隔离）

本仓库用**不同分支**管理两个平台，共用同一工作区：

| 分支 | 内容 | 平台 |
| --- | --- | --- |
| `android` | `android/CarbonFootprint-Android/` | Android（ArkUI-X）+ HarmonyOS 源码 |
| `harmony` | `harmonyos/CarbonFootprint/` | HarmonyOS 原生 |
| `harmonyos-legacy` | 鸿蒙历史版本留存 | 归档 |

> 各分支只提交各自平台目录；SDK、构建产物、安装包、签名材料不入库。

## 远程仓库

- GitHub：`https://github.com/Cian8023/CarbonFoot.git`
- Gitee：`https://gitee.com/fashionlan/huawei_harmonyos.git`

两个远程均使用 SSH，推送时需同时覆盖（可配置 `pushall` 别名）。

## 快速开始

### Android 端（android 分支）

工程目录：`android/CarbonFootprint-Android/`

构建 APK：

```bash
export PATH="<arkui-x-sdk>/26.0.0/arkui-x/toolchains/bin:$PATH"
export ANDROID_HOME="<本地 android-sdk>"
export ANDROID_SDK_ROOT="<本地 android-sdk>"
export JAVA_HOME="<JDK 17>"
unset NODE_OPTIONS          # ace build 不能设 NODE_OPTIONS
cd android/CarbonFootprint-Android
ace build apk --debug --target-platform arm64
```

安装到真机：

```bash
adb install -r app-debug.apk
```

详细说明见 `android/CarbonFootprint-Android/README.md`。

### HarmonyOS 端（harmony 分支）

用 DevEco Studio 打开 `harmonyos/CarbonFootprint/` 即可。

## 版权与许可

本项目由 **Cian8023** 开发，**以 Apache License 2.0 开源**（详见仓库根目录 [LICENSE](./LICENSE)）。

- 所有源码文件头部均带有 `Copyright (c) 2026 Cian8023 · Licensed under Apache-2.0` 权属声明，请保留。
- 依据 Apache-2.0：你可以自由使用、修改、分发，但**须保留版权与许可声明，并在修改过的文件中注明变更**。
- 版权头是权属声明与法律凭据，用于确立作者身份、防止恶意窃取署名；它不构成技术层面的复制限制。

## 配置说明

仓库中带 `example` 的模板文件需按本机环境复制填写，真实配置不入库：

- `build-profile.example.json5` → 复制为 `build-profile.json5` 并填写本机签名路径与密码（**勿提交**）
- `local.properties`（含 `nodejs.dir` / `arkui-x.dir` / `hwsdk.dir`）按本机 SDK 路径配置（**勿提交**）

## 问题排查记录

开发中遇到的典型问题与完整复盘见各工程下的 `TROUBLESHOOTING/` 目录，例如：

- ArkUI-X Android 白屏（`setInstanceName` 实例名未替换）
- 沉浸式状态栏与多机型适配（Bridge 读取原生 `status_bar_height`）

## 版本管理规范

推送前必须检查：移除截图/临时文件/敏感信息，确保 `.gitignore` 与 README 完整，确认 GitHub/Gitee 双远程地址。不确定处先确认再操作。
