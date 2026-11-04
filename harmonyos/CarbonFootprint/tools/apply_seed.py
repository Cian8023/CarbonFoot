"""把 seed.sql 里的语句逐条通过 hdc sqlite3 执行。"""
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HDC = r"D:/aaaa/SDK/26.0.0/toolchains/hdc.exe"
DB = "/data/app/el2/100/database/com.carbon.footprint/entry/rdb/carbon_footprint.db"

sql_path = os.path.join(ROOT, "tools", "seed.sql")
with open(sql_path, encoding="utf-8") as f:
    raw = f.read()

stmts = []
for line in raw.splitlines():
    s = line.strip()
    if not s or s.startswith("PRAGMA") or s in ("BEGIN TRANSACTION;", "COMMIT;"):
        continue
    stmts.append(s)

print("statements:", len(stmts))
for i, s in enumerate(stmts, 1):
    cmd = [HDC, "-t", "127.0.0.1:5555", "shell", 'sqlite3 %s "%s"' % (DB, s)]
    r = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    err = (r.stderr or "").strip()
    if err:
        print("  [%d] ERR %s" % (i, err[:160]))
    else:
        print("  [%d] ok" % i)

check = [HDC, "-t", "127.0.0.1:5555", "shell",
         "sqlite3 %s 'SELECT COUNT(*),SUM(reduction_g) FROM t_behavior_record; SELECT COUNT(*),SUM(points) FROM t_points_record;'" % DB]
r = subprocess.run(check, capture_output=True, text=True, encoding="utf-8", errors="replace")
print("verify:")
print(r.stdout.strip())
