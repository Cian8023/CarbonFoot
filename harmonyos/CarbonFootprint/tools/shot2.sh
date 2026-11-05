#!/bin/bash
# 批量截图：shot.sh <输出名>
HDC="/d/aaaa/SDK/26.0.0/toolchains/hdc.exe"
DEV="${2:-127.0.0.1:5555}"
export MSYS_NO_PATHCONV=1
cd "/d/aaaa/CarbonFootprint/ppt/v2/imgs" || exit 1
"$HDC" -t "$DEV" shell "snapshot_display -f /data/local/tmp/cap.jpeg" >/dev/null 2>&1
sleep 1
"$HDC" -t "$DEV" file recv /data/local/tmp/cap.jpeg "$1.jpeg" >/dev/null 2>&1
if [ -f "$1.jpeg" ]; then
  echo "✓ $1.jpeg ($(( $(stat -c%s "$1.jpeg") / 1024 ))KB)"
else
  echo "✗ $1 失败"
fi