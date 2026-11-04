"""为第二台设备（妈妈）造 4 条历史记录，用于镜头 7 家庭多端同步。"""
import os
import subprocess
from datetime import datetime, timedelta, timezone

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HDC = r"D:/aaaa/SDK/26.0.0/toolchains/hdc.exe"
DEV = ["-t", "127.0.0.1:5557"]
DB = "/data/app/el2/100/database/com.carbon.footprint/entry/rdb/carbon_footprint.db"
TZ = timezone(timedelta(hours=8))


def ts(y, m, d, hh, mm):
    return int(datetime(y, m, d, hh, mm, tzinfo=TZ).timestamp() * 1000)


# (年,月,日,时,分, 大类, 子类, 数值, 单位, 因子, 积分)
ROWS = [
    (2026, 10, 30, 7, 40, "出行", "公交", 9.0, "km", 80, 10),
    (2026, 10, 31, 19, 10, "出行", "地铁", 15.0, "km", 100, 10),
    (2026, 11, 1, 11, 20, "光盘行动", "午餐", 2.0, "次", 100, 10),
    (2026, 11, 2, 20, 30, "节水节电", "节电", 3.0, "kWh", 785, 10),
]

sql = ["PRAGMA foreign_keys=OFF;"]
sql.append("DELETE FROM t_behavior_record;")
sql.append("DELETE FROM t_points_record;")
sql.append("DELETE FROM t_task_completion;")
sql.append("DELETE FROM sqlite_sequence WHERE name IN ('t_behavior_record','t_points_record','t_task_completion');")

balance = 0
for i, (y, m, d, hh, mm, tp, sub, val, unit, fac, pts) in enumerate(ROWS, start=1):
    t = ts(y, m, d, hh, mm)
    g = int(round(val * fac))
    kg_txt = ("%.2f" % (g / 1000.0)).rstrip("0").rstrip(".")
    val_txt = "%g" % val
    sql.append(
        "INSERT INTO t_behavior_record (id,type,sub_type,value,unit,factor,reduction_g,created_at,note,source) "
        "VALUES (%d,'%s','%s',%s,'%s',%s,%d,%d,'','manual');"
        % (i, tp, sub, val, unit, fac, g, t)
    )
    balance += pts
    sql.append(
        "INSERT INTO t_points_record (id,source,ref_id,action,points,balance_after,created_at) "
        "VALUES (%d,'behavior',%d,'%s %s%s，减排%skg',%d,%d,%d);"
        % (i, i, sub, val_txt, unit, kg_txt, pts, balance, t + 2)
    )

total_g = sum(int(round(r[7] * r[9])) for r in ROWS)
print("rows:", len(ROWS), "total_g:", total_g, "points:", balance)

for stmt in sql:
    r = subprocess.run(
        [HDC] + DEV + ["shell", "sqlite3 %s \"%s\"" % (DB, stmt)],
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        env={**os.environ, "MSYS_NO_PATHCONV": "1"},
    )
    if r.stdout.strip() or r.stderr.strip():
        print(">>", stmt[:60], "|", r.stdout.strip(), r.stderr.strip()[:120])

print("--- verify ---")
v = subprocess.run(
    [HDC] + DEV + ["shell", "sqlite3 %s 'select count(*),sum(reduction_g) from t_behavior_record;'" % DB],
    capture_output=True, text=True, encoding="utf-8", errors="replace",
    env={**os.environ, "MSYS_NO_PATHCONV": "1"},
)
print(v.stdout.strip() or v.stderr.strip())