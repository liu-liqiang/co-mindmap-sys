#!/bin/bash

# 停止和清理脚本
# 使用方法: ./stop.sh [dev|prod]

ENV=${1:-prod}

echo "🛑 停止 $ENV 环境..."

if [ "$ENV" = "prod" ]; then
    docker-compose -f docker-compose.prod.yml down
else
    docker-compose down
fi

echo "✅ 服务已停止"

# 可选：清理未使用的Docker资源
read -p "是否要清理未使用的Docker资源？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 清理Docker资源..."
    docker system prune -f
    docker volume prune -f
    echo "✅ 清理完成"
fi
