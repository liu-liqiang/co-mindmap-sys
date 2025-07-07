#!/bin/sh

# 前端启动脚本

echo "🔧 前端启动脚本开始执行..."

# 检查是否有源代码
if [ ! -f "/app/package.json" ]; then
    echo "❌ 未找到 package.json，请确保代码已挂载到 /app"
    exit 1
fi

# 进入应用目录
cd /app

# 检查是否需要安装依赖
if [ ! -d "node_modules" ] || [ "package.json" -nt "node_modules" ]; then
    echo "📦 安装 npm 依赖..."
    npm install
fi

# 构建生产版本
echo "🔨 构建生产版本..."
npm run build

# 复制构建结果到nginx目录
echo "📁 复制构建结果..."
if [ -d "dist" ]; then
    cp -r dist/* /usr/share/nginx/html/
    echo "✅ 构建结果已复制到 /usr/share/nginx/html/"
else
    echo "❌ 构建失败，未找到 dist 目录"
    exit 1
fi

# 设置权限
chown -R nginx:nginx /usr/share/nginx/html/

echo "🚀 启动 Nginx..."

# 启动nginx
exec "$@"
