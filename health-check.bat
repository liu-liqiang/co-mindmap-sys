@echo off
REM Windows 健康检查脚本

echo 🏥 开始健康检查...

REM 检查服务状态
echo 📊 检查容器状态...
docker-compose -f docker-compose.prod.yml ps

REM 检查后端API
echo 🔍 检查后端API...
for /l %%i in (1,1,10) do (
    curl -f http://localhost/api/csrf/ >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ 后端API响应正常
        goto :check_frontend
    ) else (
        echo ⏳ 等待后端API启动... (%%i/10)
        timeout /t 5 /nobreak >nul
    )
    if %%i equ 10 (
        echo ❌ 后端API检查失败
        exit /b 1
    )
)

:check_frontend
REM 检查前端
echo 🔍 检查前端...
for /l %%i in (1,1,5) do (
    curl -f http://localhost/ >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ 前端响应正常
        goto :check_database
    ) else (
        echo ⏳ 等待前端启动... (%%i/5)
        timeout /t 3 /nobreak >nul
    )
    if %%i equ 5 (
        echo ❌ 前端检查失败
        exit /b 1
    )
)

:check_database
REM 检查数据库连接
echo 🔍 检查数据库连接...
docker-compose -f docker-compose.prod.yml exec -T backend python manage.py check --database default >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 数据库连接正常
) else (
    echo ❌ 数据库连接失败
    exit /b 1
)

REM 检查Redis连接
echo 🔍 检查Redis连接...
docker-compose -f docker-compose.prod.yml exec -T redis redis-cli ping >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Redis连接正常
) else (
    echo ❌ Redis连接失败
    exit /b 1
)

echo ✅ 所有健康检查通过！
echo 🌐 应用可以正常访问: http://localhost

pause
