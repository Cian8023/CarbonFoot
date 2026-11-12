@echo off
setlocal

echo ============================================================
echo   碳足迹 · 重置同步数据
echo ============================================================
echo.
echo   本操作会清空 sync/data.json，即删除所有家庭组与成员记录。
echo   行为记录、积分、徽章等应用数据不受影响（那些存在手机里）。
echo.
echo   适用场景：
echo     - 演示前希望从零开始创建家庭组
echo     - 邀请码重复冲突
echo     - 成员列表出现测试残留
echo.
echo   当前数据文件状态：
if exist "sync\data.json" (
    for %%f in ("sync\data.json") do echo     sync\data.json 存在（%%~zf 字节）
) else (
    echo     sync\data.json 不存在（无需重置）
)
echo.
set /p CONFIRM=确认清空？(输入 Y 回车确认，其他键取消)：
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo 已取消，未做任何修改。
    pause
    exit /b 0
)

echo.
cd /d "%~dp0"

REM ---------- 备份现有数据 ----------
if exist "sync\data.json" (
    for /f "tokens=1-4 delims=/:. " %%a in ("%date% %time%") do (
        set TS=%%a%%b%%c_%%d
    )
    copy /y "sync\data.json" "sync\data.bak.json" >nul
    echo [1/2] 已备份现有数据到 sync\data.bak.json
) else (
    echo [1/2] 无现有数据，跳过备份
)

REM ---------- 清空 ----------
del /q "sync\data.json" 2>nul
echo [2/2] 已删除 sync\data.json

echo.
echo ============================================================
echo   重置完成
echo ============================================================
echo.
echo   下次启动 家庭同步服务 时，会自动创建空的 data.json。
echo   若需恢复，把 sync\data.bak.json 改名为 data.json 即可。
echo.
pause