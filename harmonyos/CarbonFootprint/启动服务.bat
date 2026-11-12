@echo off
setlocal

echo ============================================================
echo   碳足迹 · 本地服务启动
echo ============================================================
echo.

cd /d "%~dp0"

REM ---------- 检查 Node ----------
where node >nul 2>nul
if errorlevel 1 (
    echo [错误] 未找到 Node.js
    echo.
    echo 请先安装 Node.js（https://nodejs.org/），或确认已加入系统 PATH。
    echo DevEco Studio 内置的 Node 也可以，但需要手动加入 PATH。
    echo.
    pause
    exit /b 1
)

for /f "delims=" %%v in ('node --version') do set NODE_VER=%%v
echo [环境] Node.js %NODE_VER%
echo.

REM ---------- 检查端口占用 ----------
set PORT1_BUSY=0
set PORT2_BUSY=0
for /f "tokens=*" %%p in ('netstat -ano ^| findstr ":8080 " ^| findstr "LISTENING"') do set PORT1_BUSY=1
for /f "tokens=*" %%p in ('netstat -ano ^| findstr ":8081 " ^| findstr "LISTENING"') do set PORT2_BUSY=1

if "%PORT1_BUSY%"=="1" (
    echo [警告] 端口 8080 已被占用，碳普惠 Mock 服务可能启动失败
    echo        如需清理，可先运行 停止服务.bat
    echo.
)
if "%PORT2_BUSY%"=="1" (
    echo [警告] 端口 8081 已被占用，家庭同步服务可能启动失败
    echo        如需清理，可先运行 停止服务.bat
    echo.
)

REM ---------- 启动两个服务 ----------
echo [1/2] 启动 碳普惠 Mock 服务（端口 8080）...
start "碳普惠Mock :8080" cmd /k "cd /d "%~dp0mock" && node server.js 8080"

timeout /t 1 /nobreak >nul

echo [2/2] 启动 家庭同步服务（端口 8081）...
start "家庭同步 :8081" cmd /k "cd /d "%~dp0sync" && node server.js 8081"

timeout /t 2 /nobreak >nul

echo.
echo ============================================================
echo   启动完成
echo ============================================================
echo.
echo   碳普惠 Mock   http://127.0.0.1:8080/api/health
echo   家庭同步      http://127.0.0.1:8081/api/health
echo.
echo   模拟器内访问地址（不要用 127.0.0.1）：
echo     碳普惠 Mock   http://10.0.2.2:8080
echo     家庭同步      http://10.0.2.2:8081
echo.
echo   两个黑色窗口请保持打开，关闭窗口即停止对应服务。
echo   停止全部服务：运行 停止服务.bat
echo.
pause