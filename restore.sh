#!/bin/bash

# 数据恢复脚本
# 使用方法: ./restore.sh <backup_date>
# 示例: ./restore.sh 20231207_143000

BACKUP_DATE=$1
BACKUP_DIR="./backups"

if [ -z "$BACKUP_DATE" ]; then
    echo "❌ 请提供备份日期"
    echo "使用方法: ./restore.sh <backup_date>"
    echo "可用的备份："
    ls -1 $BACKUP_DIR/db_backup_*.sql | sed 's/.*db_backup_\(.*\)\.sql/\1/'
    exit 1
fi

DB_BACKUP="$BACKUP_DIR/db_backup_$BACKUP_DATE.sql"
MEDIA_BACKUP="$BACKUP_DIR/media_backup_$BACKUP_DATE.tar.gz"
STATIC_BACKUP="$BACKUP_DIR/static_backup_$BACKUP_DATE.tar.gz"

echo "🔄 开始数据恢复..."

# 检查备份文件是否存在
if [ ! -f "$DB_BACKUP" ]; then
    echo "❌ 数据库备份文件不存在: $DB_BACKUP"
    exit 1
fi

# 确认恢复操作
read -p "⚠️ 此操作将覆盖现有数据，确定要继续吗？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ 操作已取消"
    exit 1
fi

# 停止服务
echo "⏹️ 停止服务..."
docker-compose -f docker-compose.prod.yml down

# 恢复数据库
echo "📥 恢复数据库..."
docker-compose -f docker-compose.prod.yml up -d db
sleep 10
docker-compose -f docker-compose.prod.yml exec -T db psql -U mindmap_user -d mindmap_db -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
cat "$DB_BACKUP" | docker-compose -f docker-compose.prod.yml exec -T db psql -U mindmap_user -d mindmap_db

# 恢复媒体文件
if [ -f "$MEDIA_BACKUP" ]; then
    echo "📥 恢复媒体文件..."
    docker run --rm -v "$(pwd)_media_volume:/target" -v "$(pwd)/$BACKUP_DIR:/backup" alpine sh -c "rm -rf /target/* && tar xzf /backup/media_backup_$BACKUP_DATE.tar.gz -C /target"
fi

# 恢复静态文件
if [ -f "$STATIC_BACKUP" ]; then
    echo "📥 恢复静态文件..."
    docker run --rm -v "$(pwd)_static_volume:/target" -v "$(pwd)/$BACKUP_DIR:/backup" alpine sh -c "rm -rf /target/* && tar xzf /backup/static_backup_$BACKUP_DATE.tar.gz -C /target"
fi

# 重启服务
echo "🚀 重启服务..."
docker-compose -f docker-compose.prod.yml up -d

echo "✅ 数据恢复完成"
