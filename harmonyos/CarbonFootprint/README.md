# 碳足迹 · 全民绿色生活碳积分与减排指南

基于 **HarmonyOS SDK 26.0.0 + ArkTS/ArkUI** 开发的单机版碳足迹记录应用，对应赛题二 PRD 的 5 大主要功能全量实现。

> 当前版本 **v5.0.0**：核心功能全量实现 + UI 多轮重构 + 缺陷修复台账 DF-01~DF-14；逐轮迭代明细与缺陷台账见《碳足迹-版本迭代文档.md》（工程根目录）。

## 一、如何运行

1. 安装 DevEco Studio（5.0 及以上，含 HarmonyOS SDK）。
2. `File > Open` 打开本目录（`CarbonFootprint`），等待 IDE 自动执行 `ohpm install` / Sync。
3. 在 Device Manager 中启动 Phone 模拟器（或连接真机）。
4. 点击 Run 运行 `entry` 模块即可。

> 首次启动会自动建表（5 张表 + 2 个索引）并预置任务、徽章数据；因子库与科普文章从 `resources/rawfile/*.json` 加载。

## 二、功能清单（对照 PRD）

### F1 低碳行为核算（P0 全部完成 + UI 优化）
- 4 大类 19 个子类型：出行 7（步行/骑行/公交/地铁/拼车/私家车/新能源车）、节水节电 3（节水/节电/关空调）、旧物回收 6（纸类/塑料/玻璃/衣物/电子/厨余垃圾）、光盘行动 3（早餐/午餐/晚餐）；行为选择器 **4 列布局**；内置 `factors.json` 因子库。
- **录入校验统一下沉** `BehaviorService.submit`：未知类型 / 非正数 / 超单次上限在任何入口（录入页、AI 识别）都会被拦截。
- 数值校验（非负、按子类型上限）、单位随子类型切换。
- 输入数值实时显示预计减排量（kg CO₂e）与预计积分。
- 行为时间默认当前；「修改」为两步选择：日历选年月日（不可选未来日期）→ 选时分（当天时分不得晚于当前时刻）。
- 备注 ≤ 100 字校验。
- 提交后 Toast 反馈并自动跳转「任务页 → 积分流水」。

### F2 数据可视化看板（P0 全部完成 + P1 + UI 优化）
- 首页今日减排大数字卡片：今日减排、碳积分、待完成任务数、连续打卡天数。
- 趋势图：近 7 天 / 近 4 周 / 近 6 月 / 近 5 年 四档切换（Canvas 自绘）；标注峰值与当期数值；叠加 1/3、2/3 水平基线辅助量级对比；X 轴标签为紧凑数字式——日 `10.1`、周 `9.14-9.20` 起止区间、月 `2026.5` 含年份（防跨年混淆）、年 `2025`；柱数多时间隔抽稀防重叠。
- 分类环形图：当期各大类减排占比（环心总量 + 副标题入环，图例 16fp 带百分比，自动过滤 0 值分类，切换档位后名称与占比一一对应）。
- 目标环：本月减排目标完成度（中心大数字、环下绿色目标文字、右侧达成率/节奏提示）。
- 子类型减排对比：当期子类型按减排量降序，名称+数值一行、下方带浅色轨道的细进度条，第一名深绿其余浅绿，占比右对齐（不足 1% 显示 <1%）；纯 ArkUI 组件自适应宽度。
- 历史记录：日期范围 + 大类筛选（自定义区间在日历内灰显不可选越界日期：起始 ≤ 截止 ≤ 今天；起止同天即查询当天记录）、关键字搜索（输入后点「搜索」按钮或回车才过滤）、时间倒序列表（整页滚动）、详情抽屉（删除 / 修改数值、日期、备注）。
- 图表 Canvas 字号统一按屏幕密度换算（`fpFont()`），与 Text 视觉大小一致。
- 空数据状态：首页 / 历史 / 积分流水均有引导文案 + CTA。

### F3 碳积分激励体系（P0 全部完成 + P1）
- 12 个日常/每周任务（`tasks.json`），基于行为记录自动判定进度、达标自动发积分（周期内只发一次）。
- 积分流水：来源（行为/任务/阅读/兑换）、动作、增减、变动后余额、时间，全量入库；支持按来源筛选；空态按来源给出对应入口——低碳行为→去录入、任务奖励→去低碳任务、阅读奖励→去读科普、积分兑换→去兑换（弹窗选择「碳普惠权益 / 徽章与证书」两个跳转目标），「全部」页不显示按钮。
- 9 枚虚拟徽章（`badges.json`）：累计减排 10/50/100kg、连续打卡 7/30 天、积分 500、任务 10 次、阅读 10 篇、首次记录，自动检测解锁。
- 植树证书：积分达 2000 可兑换（扣积分、生成 Canvas 证书、可保存 PNG 到沙箱）。

### F4 双碳科普专栏（P0 全部完成 + P1 + UI 优化）
- 内置 16 篇图文文章（政策解读 / 生活技巧 / 行业动态 三类筛选）。
- 详情页滚动阅读，读到底部可领 5 积分（每篇仅一次）。

### F5 本地数据管理（P0 全部完成 + P1 + 备份增强）
- 首次启动自动建表 + 预置数据。
- 一键 JSON 备份到 `files/backup/`：包含行为记录、积分流水、任务完成记录与徽章解锁状态；导入按同口径整体恢复（原 id 原样，流水引用不断链；旧版备份文件仍兼容，缺省段自动跳过）。
- CSV 报表导出到 `files/export/`（UTF-8 BOM，Excel 可直接打开）：月度减排汇总 + 分类月度汇总两段。
- 「清空所有数据」二次确认：同时重置徽章、植树证书兑换状态与碳普惠权益记录，账务口径完全归零。

## 三、技术架构

```
entry/src/main/ets/
├── pages/        Index(首页+5Tab) / Record / History / Tasks / Badges
│                 Knowledge / KnowledgeDetail / Settings(我的)
├── components/   Chart(Canvas 折线/饼图/条形图) / EmptyState / BehaviorPicker
├── service/      Calculation / Points / Behavior / Task / Badge
│                 Knowledge / Stats / Export / Seed
├── db/           DBHelper(relationalStore) / Repository
├── model/        Models.ets（实体与接口）
├── common/       Theme / Constants / AppInit / PrefsService
└── entryability/ EntryAbility
```

- **存储**：`@ohos.data.relationalStore`（SQLite），表：`t_behavior_record`、`t_points_record`、`t_task`、`t_task_completion`、`t_badge`（在 PRD 基础上为任务表增加了 `check_json` 列用于任务判定规则，徽章表增加 `description` 列）。
- **事务**：行为录入写 `t_behavior_record` + `t_points_record` 使用 `beginTransaction/commit/rollback` 保证一致性。
- **图表**：鸿蒙三方图表生态弱，按 PRD 备选方案用 Canvas 自绘，无三方依赖。
- **主题**：`common/Theme.ets` 设计令牌（主绿 #00B96B，Arco 风格），含颜色、圆角、间距、**字号**（FS_*）与**卡片阴影**（CARD_SHADOW）规范。配色策略：中性底 #F4F6F6 + 白卡大圆角轻阴影 + 绿→青渐变主卡 + 多彩图标容器；卡片一律去边框。

## 四、积分与核算规则

| 规则 | 说明 |
|---|---|
| 减排量 | `数值 × 因子(g/单位)`，因子冗余存入行为记录 |
| 行为积分 | `max(1, 减排克数 / 100)`，私家车等 0 减排行为不计分 |
| 阅读积分 | 每篇 5 分，一次性 |
| 证书兑换 | 2000 积分，扣减记入 `exchange` 流水 |

> ⚠️ 因子数值为演示用估算值（公交 80g/km、节电 785g/kWh、纸类 1300g/kg 等），正式参赛版本请按 PRD 要求引用生态环境部、GB/T 32150 等公开数据并在设计方案文档中列明出处。

## 五、加分项实现说明（E1-E4 全部落地）

- **E1 家庭多端同步（演示模式）**：`pages/Family.ets` + `service/SyncService.ets`，家庭组/邀请码/合并统计/成员排行链路完整可演示（合并口径逐人相加）；真机分布式 `distributedDataObject` 为后续迭代方向。
- **E2 端侧 AI 识别**：`pages/AiRecognize.ets` + `service/AiRecognizeService.ets` + `network/HttpClient.ets`，拍照/选图 → OpenAI 兼容视觉接口 → 行为字典映射 → **识别数值可手动修改**后录入；未配置 Key 或接口异常自动降级离线演示；提交统一走 `BehaviorService` 校验。
- **E3 城市碳普惠**：`pages/Inclusive.ets` + `service/InclusiveService.ets`，优先对接可配置真实接口；仓库自带 `mock/server.js` 开箱即用的 Node Mock 服务（GET /api/benefits、POST /api/exchange）；平台不可达自动降级内置权益池。
- **E4 成果分享**：`pages/ShareCard.ets` Canvas 海报 + `SaveButton` 零权限保存相册；Canvas 字号按屏幕密度换算，屏显与导出 PNG 均为高清比例。

## 六、材料合规提醒

- 所有参赛材料（docx/视频/PPT）中不得出现团队、院校信息（匿名要求）。
- 打包命名：`赛题二+全民绿色生活碳积分与减排指南+XX学校XX队.rar`。
