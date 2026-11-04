"""生成演示用历史数据的 SQL（6 条行为 + 对应积分流水）。"""
import os
from datetime import datetime, timedelta, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TZ = timezone(timedelta(hours=8))


def ts(y, m, d, hh, mm):
    return int(datetime(y, m, d, hh, mm, tzinfo=TZ).timestamp() * 1000)


# (年,月,日,时,分, 大类, 子类, 数值, 单位, 因子, 积分)
ROWS = [
    (2026, 10, 28, 9, 15, "出行", "骑行", 8.5, "km", 180, 10),
    (2026, 10, 29, 18, 40, "出行", "公交", 12.0, "km", 80, 10),
    (2026, 10, 30, 8, 5, "出行", "骑行", 6.2, "km", 180, 10),
    (2026, 10, 31, 12, 30, "光盘行动", "午餐", 1.0, "次", 100, 10),
    (2026, 11, 1, 17, 20, "出行", "骑行", 5.6, "km", 180, 10),
    (2026, 11, 2, 7, 50, "节水节电", "节电", 2.0, "kWh", 785, 10),
]

lines = [
    "PRAGMA foreign_keys=OFF;",
    "BEGIN TRANSACTION;",
    "DELETE FROM t_behavior_record;",
    "DELETE FROM t_points_record;",
    "DELETE FROM t_task_completion;",
    "DELETE FROM sqlite_sequence WHERE name IN ('t_behavior_record','t_points_record','t_task_completion');",
]

balance = 0
for i, (y, m, d, hh, mm, tp, sub, val, unit, fac, pts) in enumerate(ROWS, start=1):
    t = ts(y, m, d, hh, mm)
    g = int(round(val * fac))
    kg = g / 1000.0
    lines.append(
        "INSERT INTO t_behavior_record (id,type,sub_type,value,unit,factor,reduction_g,created_at,note,source) "
        "VALUES (%d,'%s','%s',%s,'%s',%s,%d,%d,'','manual');"
        % (i, tp, sub, val, unit, fac, g, t)
    )
    balance += pts
    kg_txt = ("%.2f" % kg).rstrip("0").rstrip(".")
    val_txt = ("%g" % val)
    lines.append(
        "INSERT INTO t_points_record (id,source,ref_id,action,points,balance_after,created_at) "
        "VALUES (%d,'behavior',%d,'%s %s%s，减排%skg',%d,%d,%d);"
        % (i, i, sub, val_txt, unit, kg_txt, pts, balance, t + 2)
    )

lines.append("COMMIT;")

out = os.path.join(ROOT, "tools", "seed.sql")
with open(out, "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

print("\n".join(lines))
print()
print("total points:", balance)
