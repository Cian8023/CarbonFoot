# 碳足迹 · 全民绿色生活碳积分与减排指南

基于 **OpenHarmony（API 12）+ ArkTS/ArkUI** 开发的单机版碳足迹记录应用，对应赛题二 PRD 的 5 大主要功能全量实现。

## 一、如何运行

1. 安装 DevEco Studio（5.0 及以上，含 OpenHarmony SDK API 12+）。
2. `File > Open` 打开本目录（`CarbonFootprint`），等待 IDE 自动执行 `ohpm install` / Sync。
3. 在 Device Manager 中启动 Phone 模拟器（或连接真机）。
4. 点击 Run 运行 `entry` 模块即可。

> 首次启动会自动建表（5 张表 + 2 个索引）并预置任务、徽章数据；因子库与科普文章从 `resources/rawfile/*.json` 加载。

## 二、功能清单（对照 PRD）

### F1 低碳行为核算（P0 全部完成）
- 4 大类 16 个子类型（出行 6 / 节水节电 3 / 旧物回收 5 / 光盘行动 2+1），内置 `factors.json` 因子库。
- 数值校验（非负、按子类型上限）、单位随子类型切换。
- 输入数值实时显示预计减排量（kg CO₂e）与预计积分。
- 行为时间默认当前，可改为今日内任意时刻（不可选未来）。
- 备注 ≤ 100 字校验。
- 提交后 Toast 反馈并自动跳转「任务页 → 积分流水」。

### F2 数据可视化看板（P0 全部完成 + P1）
- 首页今日减排大数字卡片：今日减排、碳积分、待完成任务数、连续打卡天数。
- 趋势折线图：近 7 天 / 8 周 / 12 月 / 5 年切换（Canvas 自绘，面积渐变）。
- 分类环形图：当期各大类减排占比（带图例与百分比）。
- 子类型条形图：历史页当期子类型减排对比。
- 历史记录：日期范围 + 大类筛选、时间倒序列表、详情抽屉（删除 / 修改备注）。
- 空数据状态：首页 / 历史 / 积分流水均有引导文案 + CTA。

### F3 碳积分激励体系（P0 全部完成 + P1）
- 12 个日常/每周任务（`tasks.json`），基于行为记录自动判定进度、达标自动发积分（周期内只发一次）。
- 积分流水：来源（行为/任务/阅读/兑换）、动作、增减、变动后余额、时间，全量入库。
- 9 枚虚拟徽章（`badges.json`）：累计减排 10/50/100kg、连续打卡 7/30 天、积分 500、任务 10 次、阅读 10 篇、首次记录，自动检测解锁。
- 植树证书：积分达 2000 可兑换（扣积分、生成 Canvas 证书、可保存 PNG 到沙箱）。

### F4 双碳科普专栏（P0 全部完成 + P1）
- 内置 10 篇图文文章（政策解读 / 生活技巧 / 行业动态 三类筛选）。
- 详情页滚动阅读，读到底部可领 5 积分（每篇仅一次）。

### F5 本地数据管理（P0 全部完成 + P1）
- 首次启动自动建表 + 预置数据。
- 一键 JSON 备份到 `files/backup/`。
- CSV 月度减排汇总导出到 `files/export/`（UTF-8 BOM，Excel 可直接打开）。
- 「清空所有数据」二次确认。

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
- **主题**：主绿 #2E7D32 / 辅绿 #81C784 / 警告 #FF7043，遵循 HarmonyOS 设计风格。

## 四、积分与核算规则

| 规则 | 说明 |
|---|---|
| 减排量 | `数值 × 因子(g/单位)`，因子冗余存入行为记录 |
| 行为积分 | `max(1, 减排克数 / 100)`，私家车等 0 减排行为不计分 |
| 阅读积分 | 每篇 5 分，一次性 |
| 证书兑换 | 2000 积分，扣减记入 `exchange` 流水 |

> ⚠️ 因子数值为演示用估算值（公交 80g/km、节电 785g/kWh、纸类 1300g/kg 等），正式参赛版本请按 PRD 要求引用生态环境部、GB/T 32150 等公开数据并在设计方案文档中列明出处。

## 五、加分项说明（未实现，建议后续迭代）

PRD 加分项为选做（4 选 1-2），本工程预留了扩展位：
- **E2 端侧 AI 识别（推荐）**：在 `service/` 下新增 `AiRecognizeService.ets`，拍照/选图 → DeepSeek Vision API → 映射到 `factors.json` 行为字典 → 预填 Record 表单；需在 `module.json5` 声明 `ohos.permission.INTERNET`。
- **E1 多端同步**：`SyncService.ets` 预留，接入 `distributedDataObject`。
- **E3 碳普惠 Mock / E4 分享卡片**：接口层与图片生成可复用 ExportService、Canvas 证书的实现思路。

## 六、材料合规提醒

- 所有参赛材料（docx/视频/PPT）中不得出现团队、院校信息（匿名要求）。
- 打包命名：`赛题二+全民绿色生活碳积分与减排指南+XX学校XX队.rar`。
