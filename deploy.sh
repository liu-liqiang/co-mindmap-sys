#!/bin/bash

# 部署脚本
# 使用方法: ./deploy.sh [dev|prod]

set -e

ENV=${1:-prod}

echo "🚀 开始部署 $ENV 环境..."

# 检查必要文件
if [ ! -f ".env" ]; then
    echo "❌ .env 文件不存在，请复制 .env.example 并配置相应的值"
    exit 1
fi

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装 Docker Compose"
    exit 1
fi

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p nginx/ssl
mkdir -p data/postgres
mkdir -p data/redis

# 设置权限
echo "🔧 设置权限..."
chmod +x backend/docker-entrypoint.sh
chmod +x frontend/docker-entrypoint.sh

# 设置代码目录权限（确保容器可以访问）
echo "📂 设置代码目录权限..."
sudo chown -R 1001:1001 backend/ 2>/dev/null || echo "⚠️ 无法设置后端目录权限，如遇问题请手动执行: sudo chown -R 1001:1001 backend/"
sudo chown -R 1001:1001 frontend/ 2>/dev/null || echo "⚠️ 无法设置前端目录权限，如遇问题请手动执行: sudo chown -R 1001:1001 frontend/"

# 启用站点配置
echo "🌐 配置 Nginx..."
if [ ! -L "nginx/sites-enabled/default" ]; then
    ln -sf ../sites-available/default nginx/sites-enabled/default
fi

if [ "$ENV" = "prod" ]; then
    echo "🏭 部署生产环境..."
    
    # 停止旧容器
    echo "⏹️ 停止旧容器..."
    docker-compose -f docker-compose.prod.yml down || true
    
    # 构建并启动新容器
    echo "🔨 构建并启动容器..."
    docker-compose -f docker-compose.prod.yml build --no-cache
    docker-compose -f docker-compose.prod.yml up -d
    
    # 等待服务启动
    echo "⏳ 等待服务启动..."
    sleep 30
    
    # 检查服务状态
    echo "🔍 检查服务状态..."
    docker-compose -f docker-compose.prod.yml ps
    
    # 运行健康检查
    echo "🏥 运行健康检查..."
    ./health-check.sh
    
else
    echo "🛠️ 部署开发环境..."
    
    # 停止旧容器
    echo "⏹️ 停止旧容器..."
    docker-compose down || true
    
    # 构建并启动新容器
    echo "🔨 构建并启动容器..."
    docker-compose build
    docker-compose up -d
    
    # 等待服务启动
    echo "⏳ 等待服务启动..."
    sleep 20
    
    # 检查服务状态
    echo "🔍 检查服务状态..."
    docker-compose ps
fi

echo "✅ 部署完成！"

if [ "$ENV" = "prod" ]; then
    echo "🌐 应用访问地址: http://localhost"
    echo "🔧 管理后台: http://localhost/admin"
else
    echo "🌐 应用访问地址: http://localhost"
    echo "🔧 管理后台: http://localhost:8000/admin"
fi

echo "📋 查看日志: docker-compose -f docker-compose$([ "$ENV" = "prod" ] && echo ".prod").yml logs -f"
