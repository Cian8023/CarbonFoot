# 碳足迹 · 全民绿色生活碳积分与减排指南

基于 **HarmonyOS SDK 26.0.0 + ArkTS/ArkUI** 开发的单机版碳足迹记录应用，对应赛题二 PRD 的 5 大主要功能全量实现。

> 当前版本 **v5.0.0**：核心功能全量实现 + UI 多轮重构 + 全项目静态审计 + 应用层多端同步与 AI 票据识别，缺陷修复台账 **DF-01~DF-47**（S1×7、S2×18、S3×22）；逐轮迭代明细与缺陷台账见《碳足迹-版本迭代文档.md》，用例与执行记录见《碳足迹-企业级测试文档.md》《测试执行报告-v5.0.0.md》。

## 一、如何运行

1. 安装 DevEco Studio（5.0 及以上，含 HarmonyOS SDK）。
2. `File > Open` 打开本目录（`CarbonFootprint`），等待 IDE 自动执行 `ohpm install` / Sync。
3. 在 Device Manager 中启动 Phone 模拟器（或连接真机）。
4. 点击 Run 运行 `entry` 模块即可。

> 首次启动会自动建表（5 张表 + 2 个索引）并预置任务、徽章数据；因子库与科普文章从 `resources/rawfile/*.json` 加载。

## 二、功能清单（对照 PRD）

### F1 低碳行为核算（P0 全部完成 + UI 优化）
- 4 大类 19 个子类型：出行 7（步行/骑行/公交/地铁/拼车/私家车/新能源车）、节水节电 3（节水/节电/关空调）、旧物回收 6（纸类/塑料/玻璃/衣物/电子/厨余垃圾）、光盘行动 3（早餐/午餐/晚餐）；行为选择器 **4 列布局**；内置 `factors.json` 因子库。
- **录入校验统一下沉** `BehaviorService`：未知类型 / 非正数 / 超单次上限 / 未来时间在任何入口（录入页、AI 识别、历史页修改）都会被拦截。
- 数值校验（非负、按子类型上限）、单位随子类型切换。
- 输入数值实时显示预计减排量（kg CO₂e）与预计积分。
- 行为时间默认当前；「修改」为两步选择：日历选年月日（不可选未来日期）→ 选时分（当天时分不得晚于当前时刻）。
- 备注 ≤ 100 字校验。
- 提交后 Toast 反馈并自动跳转「任务页 → 积分流水」。

### F2 数据可视化看板（P0 全部完成 + P1 + UI 优化）
- 首页今日减排大数字卡片：今日减排、碳积分、待完成任务数、连续打卡天数；大数字下方给一句**具象换算**（"≈ 少开 5.6 公里车"），累计减排在「我的」与分享海报折算为"≈ 种下 X 棵树"，让克数有参照系。
- 趋势图：近 7 天 / 近 4 周 / 近 6 月 / 近 5 年 四档切换（Canvas 自绘），支持**柱状 / 折线双形态**一键切换（折线为平滑曲线 + 面积渐变 + 关键点标注，形态选择持久化）；默认标注峰值与当期数值，**点击任意一期查看该期数值**（柱状图描边高亮、折线图加竖向指示线，再点一次取消；选中 0 值期也会明确显示 `0g`）；叠加 1/3、2/3 水平基线辅助量级对比；X 轴标签为紧凑数字式——日 `10.1`、周 `9.14-9.20` 起止区间、月 `2026.5` 含年份（防跨年混淆）、年 `2025`；字号随标签长度自适应，柱数多时抽稀并按实际文字宽度做重叠保护，首尾数值自动夹紧防裁切。
- 分类环形图：当期各大类减排占比（环心总量 + 副标题入环，图例 16fp 带百分比，自动过滤 0 值分类，切换档位后名称与占比一一对应）。
- 目标环：本月减排目标完成度（中心大数字、环下绿色目标文字、右侧达成率/节奏提示）。
- 子类型减排对比：当期子类型按减排量降序，名称+数值一行、下方带浅色轨道的细进度条，第一名深绿其余浅绿，占比右对齐（不足 1% 显示 <1%）；纯 ArkUI 组件自适应宽度。
- 历史记录：日期范围 + 大类筛选（自定义区间在日历内灰显不可选越界日期：起始 ≤ 截止 ≤ 今天；起止同天即查询当天记录）、关键字搜索（输入后点「搜索」按钮或回车才过滤）、时间倒序列表（整页滚动）、详情抽屉（删除 / 修改数值、日期、备注）。详情内改日期同样不可选未来（服务层二次校验），改数值受单次上限约束并联动任务回退/补发，账务与删除口径一致。
- 图表 Canvas 字号统一按屏幕密度换算（`fpFont()`），与 Text 视觉大小一致。
- 空数据状态：首页 / 历史 / 积分流水均有引导文案 + CTA。

### F3 碳积分激励体系（P0 全部完成 + P1）
- 12 个日常/每周任务（`tasks.json`），基于行为记录自动判定进度、达标自动发积分（周期内只发一次）；删除或调小记录导致不再达标时，自动撤销完成记录并扣回任务积分。
- 积分流水：来源（行为/任务/阅读/兑换）、动作、增减、变动后余额、时间，全量入库；支持按来源筛选；空态按来源给出对应入口——低碳行为→去录入、任务奖励→去低碳任务、阅读奖励→去读科普、积分兑换→去兑换（弹窗选择「碳普惠权益 / 徽章与证书」两个跳转目标），「全部」页不显示按钮。
- 9 枚虚拟徽章（`badges.json`）：累计减排 10/50/100kg、连续打卡 7/30 天、积分 500、任务 10 次、阅读 10 篇、首次记录，自动检测解锁。
- 植树证书：积分达 2000 可兑换（扣积分、生成 Canvas 证书、可保存 PNG 到沙箱）。

### F4 双碳科普专栏（P0 全部完成 + P1 + UI 优化）
- 内置 16 篇图文文章（政策解读 / 生活技巧 / 行业动态 三类筛选）。
- 详情页滚动阅读，读到底部可领 5 积分（每篇仅一次）。

### F5 本地数据管理（P0 全部完成 + P1 + 备份增强）
- 首次启动自动建表 + 预置数据。
- 一键 JSON 备份：**由系统文件选择器指定保存位置**（可存到「文件管理」等用户可访问目录），包含行为记录、积分流水、任务完成记录与徽章解锁状态；导入按同口径整体恢复（原 id 原样，流水引用不断链；旧版备份文件仍兼容，缺省段自动跳过）。
- CSV 报表导出：同样由文件选择器指定保存位置（UTF-8 BOM，Excel 可直接打开），内容为月度减排汇总 + 分类月度汇总两段。
- 「清空所有数据」二次确认：同时重置徽章、植树证书兑换状态与碳普惠权益记录，账务口径完全归零。

## 三、技术架构

```
entry/src/main/ets/
├── pages/        Index(首页 + 5 Tab 容器) / Badges / Knowledge / KnowledgeDetail
│                 SettingsDetail / AiRecognize / Inclusive / Family / ShareCard
│                 AnnualReport（年度报告）
│                 └ Record / History / Tasks / Settings 为 @Component 内嵌 Tab，
│                   不占路由；其余 10 个为 @Entry 路由页（与 main_pages.json 一致）
├── components/   Chart(Canvas 柱状图 / 环形图 / 目标环 + 纯 ArkUI 细进度条)
│                 EmptyState / BehaviorPicker / BadgeUnlock
├── service/      Calculation / Points / Behavior / Task / Badge / Knowledge
│                 Stats / Export / Seed / Recommend / Sync / AiRecognize / Inclusive
├── db/           DBHelper(relationalStore) / Repository
├── model/        Models.ets（实体与接口）
├── network/      HttpClient（GET/POST JSON 封装）
├── utils/        DateUtil / EcoUtil（减排量具象换算）
├── common/       Theme / Constants / AppInit / PrefsService / AppConfig / CardSnapshot
├── entryability/ EntryAbility
├── entryformability/ EntryFormAbility（桌面卡片数据供给与定时刷新）
└── widget/       WidgetCard（2×2 桌面卡片，读快照渲染）
```

- **存储**：`@ohos.data.relationalStore`（SQLite），表：`t_behavior_record`、`t_points_record`、`t_task`、`t_task_completion`、`t_badge`（在 PRD 基础上为任务表增加了 `check_json` 列用于任务判定规则，徽章表增加 `description` 列）。
- **事务**：行为录入写 `t_behavior_record` + `t_points_record` 使用 `beginTransaction/commit/rollback` 保证一致性。
- **图表**：鸿蒙三方图表生态弱，按 PRD 备选方案用 Canvas 自绘，无三方依赖。
- **主题**：`common/Theme.ets` 设计令牌（v4.1 账本质感，主色深松绿 #2F6B4F），含颜色、圆角、间距、**语义化字号阶梯**（`FS_MICRO/CAPTION/SECONDARY/TERTIARY/BODY/CONTENT/TITLE/HEAD/HERO/DISPLAY`）。配色策略：暖米白纸底 #FAF8F3 + 白卡 #FFFFFF + **1px 细边框 #E5E0D4**（卡片不用阴影，改以边框与底色分区）+ 自然色系图表 8 色；圆角按用途分化（数据卡 12vp、chip 8vp、按钮药丸形），刻意不做统一样式。全站字号已收敛为令牌，新代码不得写裸数字。注：ArkTS 卡片（`widget/` 下）无法 import 项目内主题文件，其中色值为字面量，需与令牌手动同步。

## 四、积分与核算规则

| 规则 | 说明 |
|---|---|
| 减排量 | `数值 × 因子(g/单位)`，因子冗余存入行为记录 |
| 行为积分 | `max(1, 减排克数 / 100)`，私家车等 0 减排行为不计分 |
| 阅读积分 | 每篇 5 分，一次性 |
| 证书兑换 | 2000 积分，扣减记入 `exchange` 流水 |

> **因子出处与估算声明**：`factors.json` 每个子类型都带 `source`（出处说明）、`year`（整理年份）、`basis`（适用条件与计算边界），文件头 `meta` 有整体免责声明。界面三处呼应：录入页显示「按 180 g/km 系数估算，结果为估算值」；记录详情显示完整算式 `15km × 180g/km = 2.70 kg CO₂e` + 口径 + 系数出处 + 「不用于碳交易、碳核查或认证」；设置页脚注写明「公开核算资料整理的常用取值（2024），仅作生活估算」。
>
> 已知偏高项：节电因子取 785 g/kWh，高于近年全国电网平均值（约 570 g/kWh），核算结果偏乐观，`basis` 中已注明。所有数值均为公开资料整理后的常用量级，**不是**官方发布的认证口径。

## 五、加分项实现说明（E1-E5 全部落地）

- **E1 家庭多端同步（应用层真实同步）**：`pages/Family.ets` + `service/SyncService.ets` + `sync/server.js`。两台设备（模拟器或真机）都连宿主机的同步服务，各自上报「减排总量 / 积分余额 / 本周减排」快照，再拉取组内其他成员合并展示；每台设备有持久化 `deviceId`，服务端按组号聚合。**录入后立即自动上报**（不用延迟定时器，避免切后台被冻结），「立即同步」保留为补拉入口；**退出会通知服务端移除本机（组空自动解散）**；服务不可达时降级本地缓存并标记「离线」，建组/加入会明确报错（不产生别人加不进来的幽灵组）。数据落盘 `sync/data.json`，重启不丢组。`distributedDataObject` 受模拟器 NAT 隔离与同账号互信限制不可用，因此采用应用层同步。
- **E2 AI 识别（票据 OCR + 场景候选）**：`pages/AiRecognize.ets` + `service/AiRecognizeService.ets` + `network/HttpClient.ets`。拍照/选图 → 压到长边 **1600** 的 JPEG（票据小字需更高分辨率）→ OpenAI 兼容视觉接口（默认 `deepseek-flash`，原生多模态，prompt 内附 19 个子类型的单位与单次上限；官方端点额外开启 `response_format: json_object` 提升解析成功率），**一次调用先分流**：① 行程单/外卖单/电费单/水费单 → 读出里程/份数/度数/水量（**数值取自图片原文**；电费→节电 kWh、水费→节水 L，不串用；**按票据日期入库**，避免历史行程全记成今天）；② 普通照片 → 最多 3 个候选 + 置信度，≥0.7 才自动选中，否则由用户点选；③ 完全无关 → 「没看出低碳行为」；④ **相册可多选（最多 5 张）**，逐张识别后汇总成一张确认卡，一次录入全部（票据按各自日期、场景按当前时间）。**未配置 Key 或调用失败时不编造结果**，按原因分级给出路（去填 Key / 换一张 / 重试 / 手动录入）；网络抖动与 5xx 自动重试一次；识别中可**取消**（真正中止在途请求）；票据与候选卡均可**查看原图**核对；入库带**来源标识**（`ai_ticket` / `ai_scene`）。API Key 优先存 **Asset Store 安全存储**，不可用时才退回 preferences。
- **E3 城市碳普惠**：`pages/Inclusive.ets` + `service/InclusiveService.ets`，优先对接可配置真实接口；仓库自带 `mock/server.js` 开箱即用的零依赖 Node Mock 服务（GET `/api/benefits`、POST `/api/exchange`、GET `/api/orders`、GET `/api/health`、GET `/api/behavior`），`cd mock && node server.js` 即可启动；地址留空时按「用户配置 → `http://10.0.2.2:8080`（模拟器访问宿主机）→ `http://127.0.0.1:8080`」依次尝试，全不可达才降级内置权益池。另提供 `GET /api/behavior` 行程数据，App 可在「设置 → 服务配置 → 从平台导入行为记录」一键导入（`service/PlatformSourceService.ets`，**适配器模式**，接真实平台只需新增实现类），导入记录来源标记为 `platform`。
- **E4 成果分享**：`pages/ShareCard.ets` Canvas 海报 + `SaveButton` 零权限保存相册；Canvas 字号按屏幕密度换算，屏显与导出 PNG 均为高清比例。
- **E5 桌面万能卡片（鸿蒙特色）**：`entryformability/EntryFormAbility.ets` + `widget/pages/WidgetCard.ets` + `profile/form_config.json`，2×2 卡片显示今日减排、具象换算、本月目标进度与连续打卡，点击直达应用。数据走"主应用写快照 → 卡片读快照"的解耦方案（`common/CardSnapshot.ets`），卡片冷启动无需初始化数据库。
- **年度报告（附加功能）**：`pages/AnnualReport.ets` 按当前年聚合行为记录，Swiper 四屏展示年度总量、记录密度（笔数 / 活跃天数 / 年度最长连续）、高光项（最强子类型、最活跃月）与意义换算，入口在「我的」页。

## 六、工程质量

- **单元测试**：`entry/src/test/`（@ohos/hypium），入口 `List.test.ets` → `Unit.test.ets`。运行 `hvigorw test`（本地执行，无需设备），覆盖 DateUtil 与 `CalculationService.valueToPoints` 共 **8 个纯函数用例**，当前全部通过。依赖 DB / preferences / 网络的服务按测试文档第 4 章人工走查。
- **版本控制**：Git 仓库已初始化（`.gitignore` 排除构建产物、`oh_modules`、`entry/.test`、`sync/data.json`），首次提交含完整源码与文档。
- **本地服务**：`sync/`（家庭同步，8081）与 `mock/`（碳普惠模拟，8080）均为零依赖 Node 脚本，`node <dir>/server.js` 直接跑。
- **无三方运行时依赖**：除测试框架 `@ohos/hypium`（devDependency）外，应用本体只用系统 API。

## 七、材料合规提醒

- 所有参赛材料（docx/视频/PPT）中不得出现团队、院校信息（匿名要求）。
- 打包命名：`赛题二+全民绿色生活碳积分与减排指南+XX学校XX队.rar`。
