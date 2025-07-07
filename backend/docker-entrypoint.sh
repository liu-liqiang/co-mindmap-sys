#!/bin/bash

# 等待数据库启动
echo "Waiting for PostgreSQL..."
while ! pg_isready -h db -p 5432 -U ${POSTGRES_USER:-mindmap_user}; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 1
done
echo "PostgreSQL is up - executing command"

# 运行数据库迁移
echo "Running database migrations..."
python manage.py migrate --noinput

# 收集静态文件
echo "Collecting static files..."
python manage.py collectstatic --noinput

# 创建超级用户（如果不存在）
python manage.py shell << EOF
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superuser created')
else:
    print('Superuser already exists')
EOF

# 启动应用
echo "Starting application..."
exec "$@"
