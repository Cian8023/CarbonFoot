# 构建与部署速查

> ⚠️ **首次运行前必须先配置签名**
>
> 为满足盲审要求，本工程**未内置任何签名证书**（`build-profile.json5` 中 `signingConfigs` 为空数组）。
> 鸿蒙模拟器与真机**都会校验签名**，直接安装未签名包会报：
>
> ```
> code: 9568332
> error: install sign info inconsistent
> ```
>
> **这不是工程缺陷，而是签名尚未配置。** 按下面第一步操作即可解决。

---

## 一、配置自动签名（必做，只需一次）

**DevEco Studio 图形界面**

1. 菜单 **File → Project Structure**（快捷键 `Ctrl+Alt+Shift+S`）
2. 左侧选 **Project → Signing Configs**
3. 勾选 **Automatically generate signature**（自动生成签名文件）
4. 如提示登录华为账号，按提示完成登录（免费）
5. 点 **OK**，等待右下角提示 "Signing files generated successfully"

完成后会在本机 `C:\Users\<你的用户名>\.ohos\config\` 下生成 `.p12` / `.p7b` / `.cer` 三个证书文件，并回填 `build-profile.json5` 的 `signingConfigs`。

### ⚠️ 关键检查：`products` 是否引用了签名配置

DevEco 有时**只填 `signingConfigs`，不填 `products` 中的引用**，导致证书虽然生成了却不生效。请打开 `build-profile.json5` 确认结构如下：

```json5
{
  "app": {
    "signingConfigs": [
      { "name": "default", "type": "HarmonyOS", "material": { /* ... */ } }
    ],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",   // ← 这行必须在，否则签名不生效
        "compileSdkVersion": "26.0.0",
        // ...
      }
    ]
  }
}
```

**若缺少 `"signingConfig": "default"` 这一行，手动补上并保存。**

判断依据：编译时若出现下述警告，说明该行缺失。

```
WARN: No signingConfig found for product default
```

补上后重新构建，警告消失，产物变为 `entry-default-signed.hap`。

> 无需向任何人索取证书，自动签名会为你的本机生成一套独立的调试证书。

---

## 二、构建

**方式 A：图形界面（推荐）**

菜单 **Build → Build Hap(s)/APP(s) → Build Hap(s)**

成功后的产物位于：

```
entry\build\default\outputs\default\entry-default-signed.hap
```

注意文件名带 **`signed`**。若看到的是 `unsigned`，说明第一步签名未配置成功。

**方式 B：命令行**

在工程根目录执行（PowerShell）：

```powershell
$env:DEVECO_SDK_HOME="<DevEco 安装目录>\sdk"
& "<DevEco 安装目录>\tools\hvigor\bin\hvigorw.bat" assembleHap --no-daemon
```

成功输出应包含：

```
SignHap ...
BUILD SUCCESSFUL
```

若出现 `WARN: No signingConfig found for product default`，说明签名仍未配置，请返回第一步。

---

## 三、安装到模拟器 / 真机

**方式 A：DevEco 一键运行**

选中 `entry` 模块 → 点右上角运行按钮 ▶（或按 `Shift+F10`）

**方式 B：命令行**

```powershell
# hdc 位于 <DevEco 安装目录>\sdk\default\openharmony\toolchains\hdc.exe
$hdc = "<DevEco 安装目录>\sdk\default\openharmony\toolchains\hdc.exe"

# 1. 确认设备已连接（应输出一个端口或序列号）
& $hdc list targets

# 2. 卸载设备上的旧版本（更换过签名时必做，否则会报 9568332）
& $hdc uninstall com.carbon.footprint

# 3. 安装已签名的包
cd entry\build\default\outputs\default
& $hdc install -r entry-default-signed.hap

# 4. 启动应用
& $hdc shell aa start -a EntryAbility -b com.carbon.footprint
```

---

## 四、常见报错对照

| 报错 | 原因 | 处理 |
|---|---|---|
| `9568332 install sign info inconsistent` | 安装了未签名包，或新旧签名冲突 | ① 确认产物为 `entry-default-signed.hap`；② 执行 `hdc uninstall com.carbon.footprint` 后再装 |
| `00303116` 签名配置解析失败 | `signingConfigs` 中残留他人的证书路径或加密密码 | 清空 `signingConfigs` 内容，重新执行第一步自动签名 |
| `00306003 Invalid project path` | 工程所在路径含中文或特殊字符 | 将工程移动到纯英文路径，如 `D:\work\CarbonFootprint` |
| `00303217 Configuration Error` | `DEVECO_SDK_HOME` 未指向 DevEco 内置 SDK | 设置该环境变量，或改用图形界面构建 |

---

## 五、环境要求

| 项 | 要求 |
|---|---|
| DevEco Studio | 5.0 及以上（本项目验证于 26.0） |
| HarmonyOS SDK | API 12 及以上（本项目 compile/target 为 26.0.0，最低兼容 12） |
| 运行设备 | HarmonyOS 手机模拟器或真机 |

工程**不依赖任何第三方运行时库**，`ohpm install` 仅在构建期使用，无需联网下载业务依赖。

---

## 六、开发者本机备忘（打包交付时请删除本节）

开发机签名完整，可直接装机调试。以下为本地实测命令，路径按本机实际情况调整：

```powershell
$env:DEVECO_SDK_HOME="D:\DevecoStudio\DevEco Studio\sdk"
cd D:\aaaa\CarbonFootprint
& "D:\DevecoStudio\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --no-daemon

# 装机（换签名后必须先卸载）
cd entry\build\default\outputs\default
& "D:\aaaa\SDK\26.0.0\toolchains\hdc.exe" uninstall com.carbon.footprint
& "D:\aaaa\SDK\26.0.0\toolchains\hdc.exe" install -r entry-default-signed.hap
& "D:\aaaa\SDK\26.0.0\toolchains\hdc.exe" shell aa start -a EntryAbility -b com.carbon.footprint
```

> 交付包的 `build_in_deveco.md` 不含本节，路径已全部改为 `<DevEco 安装目录>` 占位符。