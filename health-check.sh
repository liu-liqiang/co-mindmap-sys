#!/bin/bash

# 健康检查脚本

echo "🏥 开始健康检查..."

# 检查服务状态
echo "📊 检查容器状态..."
docker-compose -f docker-compose.prod.yml ps

# 检查后端API
echo "🔍 检查后端API..."
for i in {1..10}; do
    if curl -f http://localhost/api/csrf/ > /dev/null 2>&1; then
        echo "✅ 后端API响应正常"
        break
    else
        echo "⏳ 等待后端API启动... ($i/10)"
        sleep 5
    fi
    
    if [ $i -eq 10 ]; then
        echo "❌ 后端API检查失败"
        exit 1
    fi
done

# 检查前端
echo "🔍 检查前端..."
for i in {1..5}; do
    if curl -f http://localhost/ > /dev/null 2>&1; then
        echo "✅ 前端响应正常"
        break
    else
        echo "⏳ 等待前端启动... ($i/5)"
        sleep 3
    fi
    
    if [ $i -eq 5 ]; then
        echo "❌ 前端检查失败"
        exit 1
    fi
done

# 检查数据库连接
echo "🔍 检查数据库连接..."
if docker-compose -f docker-compose.prod.yml exec -T backend python manage.py check --database default > /dev/null 2>&1; then
    echo "✅ 数据库连接正常"
else
    echo "❌ 数据库连接失败"
    exit 1
fi

# 检查Redis连接
echo "🔍 检查Redis连接..."
if docker-compose -f docker-compose.prod.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis连接正常"
else
    echo "❌ Redis连接失败"
    exit 1
fi

echo "✅ 所有健康检查通过！"
echo "🌐 应用可以正常访问: http://localhost"
