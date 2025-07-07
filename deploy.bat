@echo off
REM Windows 部署脚本
REM 使用方法: deploy.bat [dev|prod]

setlocal

set ENV=%1
if "%ENV%"=="" set ENV=prod

echo 🚀 开始部署 %ENV% 环境...

REM 检查必要文件
if not exist ".env" (
    echo ❌ .env 文件不存在，请复制 .env.example 并配置相应的值
    exit /b 1
)

REM 检查Docker是否安装
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker 未安装，请先安装 Docker Desktop
    exit /b 1
)

docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose 未安装，请先安装 Docker Compose
    exit /b 1
)

REM 创建必要的目录
echo 📁 创建必要的目录...
if not exist "nginx\ssl" mkdir nginx\ssl
if not exist "data\postgres" mkdir data\postgres
if not exist "data\redis" mkdir data\redis

REM 启用站点配置
echo 🌐 配置 Nginx...
if not exist "nginx\sites-enabled\default" (
    mklink "nginx\sites-enabled\default" "..\sites-available\default"
)

if "%ENV%"=="prod" (
    echo 🏭 部署生产环境...
    
    REM 停止旧容器
    echo ⏹️ 停止旧容器...
    docker-compose -f docker-compose.prod.yml down 2>nul
    
    REM 构建并启动新容器
    echo 🔨 构建并启动容器...
    docker-compose -f docker-compose.prod.yml build --no-cache
    docker-compose -f docker-compose.prod.yml up -d
    
    REM 等待服务启动
    echo ⏳ 等待服务启动...
    timeout /t 30 /nobreak >nul
    
    REM 检查服务状态
    echo 🔍 检查服务状态...
    docker-compose -f docker-compose.prod.yml ps
    
    REM 运行健康检查
    echo 🏥 运行健康检查...
    call health-check.bat
    
) else (
    echo 🛠️ 部署开发环境...
    
    REM 停止旧容器
    echo ⏹️ 停止旧容器...
    docker-compose down 2>nul
    
    REM 构建并启动新容器
    echo 🔨 构建并启动容器...
    docker-compose build
    docker-compose up -d
    
    REM 等待服务启动
    echo ⏳ 等待服务启动...
    timeout /t 20 /nobreak >nul
    
    REM 检查服务状态
    echo 🔍 检查服务状态...
    docker-compose ps
)

echo ✅ 部署完成！

if "%ENV%"=="prod" (
    echo 🌐 应用访问地址: http://localhost
    echo 🔧 管理后台: http://localhost/admin
) else (
    echo 🌐 应用访问地址: http://localhost
    echo 🔧 管理后台: http://localhost:8000/admin
)

if "%ENV%"=="prod" (
    echo 📋 查看日志: docker-compose -f docker-compose.prod.yml logs -f
) else (
    echo 📋 查看日志: docker-compose logs -f
)

pause
