#!/bin/bash

# 数据备份脚本

BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "💾 开始数据备份..."

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份数据库
echo "📦 备份数据库..."
docker-compose -f docker-compose.prod.yml exec -T db pg_dump -U mindmap_user mindmap_db > "$BACKUP_DIR/db_backup_$DATE.sql"

# 备份媒体文件
echo "📦 备份媒体文件..."
docker run --rm -v "$(pwd)_media_volume:/source" -v "$(pwd)/$BACKUP_DIR:/backup" alpine tar czf "/backup/media_backup_$DATE.tar.gz" -C /source .

# 备份静态文件
echo "📦 备份静态文件..."
docker run --rm -v "$(pwd)_static_volume:/source" -v "$(pwd)/$BACKUP_DIR:/backup" alpine tar czf "/backup/static_backup_$DATE.tar.gz" -C /source .

# 清理旧备份（保留最近7天）
echo "🧹 清理旧备份..."
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "✅ 备份完成"
echo "📁 备份文件位置: $BACKUP_DIR"
ls -la $BACKUP_DIR/*$DATE*
