@echo off
setlocal

echo ============================================================
echo   碳足迹 · 停止本地服务
echo ============================================================
echo.

set FOUND=0

REM ---------- 查找占用 8080 的进程 ----------
echo [检查] 端口 8080（碳普惠 Mock）...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8080 " ^| findstr "LISTENING"') do (
    echo        找到进程 PID=%%a，正在结束...
    taskkill /PID %%a /F >nul 2>nul
    if errorlevel 1 (
        echo        [失败] 可能权限不足，请右键以管理员身份运行本脚本
    ) else (
        echo        [成功] PID %%a 已结束
    )
    set FOUND=1
)

REM ---------- 查找占用 8081 的进程 ----------
echo [检查] 端口 8081（家庭同步）...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8081 " ^| findstr "LISTENING"') do (
    echo        找到进程 PID=%%a，正在结束...
    taskkill /PID %%a /F >nul 2>nul
    if errorlevel 1 (
        echo        [失败] 可能权限不足，请右键以管理员身份运行本脚本
    ) else (
        echo        [成功] PID %%a 已结束
    )
    set FOUND=1
)

REM ---------- 兜底：按窗口标题清理 ----------
echo [检查] 残留的服务窗口...
taskkill /FI "WINDOWTITLE eq 碳普惠Mock :8080*" /F >nul 2>nul
if not errorlevel 1 (
    echo        [成功] 已关闭 碳普惠Mock 窗口
    set FOUND=1
)
taskkill /FI "WINDOWTITLE eq 家庭同步 :8081*" /F >nul 2>nul
if not errorlevel 1 (
    echo        [成功] 已关闭 家庭同步 窗口
    set FOUND=1
)

echo.
if "%FOUND%"=="0" (
    echo   未发现运行中的服务，端口 8080 / 8081 均为空闲。
) else (
    echo   清理完成。可重新运行 启动服务.bat 启动。
)
echo.
pause