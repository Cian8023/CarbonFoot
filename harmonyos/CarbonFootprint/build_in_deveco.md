# 构建与部署速查

## 命令行构建（已验证可用）

工程根目录执行（PowerShell / cmd）：

```powershell
$env:DEVECO_SDK_HOME="D:\DevecoStudio\DevEco Studio\sdk"
cd D:\aaaa\CarbonFootprint
& "D:\DevecoStudio\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap
```

- 产物：`entry\build\default\outputs\default\entry-default-unsigned.hap`
- 输出 "No signingConfig found" 警告属正常现象（模拟器直装不校验签名）。
- 若报 00303217 Configuration Error，说明 `DEVECO_SDK_HOME` 未指向 DevEco 内置 SDK（如上）。

## 模拟器安装与启动

```powershell
& "D:\aaaa\SDK\26.0.0\toolchains\hdc.exe" install -r "D:\aaaa\CarbonFootprint\entry\build\default\outputs\default\entry-default-unsigned.hap"
& "D:\aaaa\SDK\26.0.0\toolchains\hdc.exe" shell aa force-stop com.carbon.footprint
& "D:\aaaa\SDK\26.0.0\toolchains\hdc.exe" shell aa start -a EntryAbility -b com.carbon.footprint
```

## DevEco Studio 图形界面构建

等效操作：**Build > Clean Project** → **Build > Build Hap(s)**。
