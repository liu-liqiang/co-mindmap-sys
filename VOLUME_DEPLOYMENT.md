# 📋 Volume挂载部署方案说明

## 🔄 部署方式对比

### 原来的方式 vs 新的方式

| 特性 | 代码打包进镜像 | Volume挂载代码 |
|------|----------------|----------------|
| 🔧 代码修改 | 需要重新构建镜像 | 直接修改文件即可 |
| 🚀 部署速度 | 慢（每次都要构建） | 快（只构建环境） |
| 📦 镜像大小 | 大（包含代码） | 小（只有环境） |
| 🔒 安全性 | 高（代码封装） | 中（代码暴露） |
| 🛠️ 维护性 | 低 | 高 |
| 🔄 回滚 | 困难 | 简单（Git回滚） |

## 📁 新的目录结构

```
项目根目录/
├── backend/                    # 后端代码（挂载到容器）
│   ├── manage.py
│   ├── requirements.txt        # 依赖列表
│   ├── Dockerfile.prod        # 环境镜像（不含代码）
│   └── docker-entrypoint.sh   # 启动脚本
├── frontend/                   # 前端代码（挂载到容器）
│   ├── package.json
│   ├── Dockerfile.prod        # 环境镜像（不含代码）
│   └── docker-entrypoint.sh   # 构建和启动脚本
├── docker-compose.prod.yml    # Volume挂载配置
└── .env                       # 环境变量
```

## 🔧 工作原理

### 后端容器

1. **镜像内容**: Python环境 + 依赖包 + 启动脚本
2. **代码挂载**: `./backend:/app`
3. **启动流程**:
   - 等待数据库
   - 运行迁移
   - 收集静态文件
   - 启动Gunicorn

### 前端容器

1. **镜像内容**: Node.js + Nginx + 构建工具
2. **代码挂载**: `./frontend:/app`
3. **启动流程**:
   - 安装npm依赖
   - 构建生产版本
   - 复制到Nginx目录
   - 启动Nginx

## 🚀 部署命令

```bash
# 首次部署
./deploy.sh prod

# 代码更新（无需重新构建镜像）
docker-compose -f docker-compose.prod.yml restart backend
docker-compose -f docker-compose.prod.yml restart frontend

# 只重启后端（Python代码修改）
docker-compose -f docker-compose.prod.yml restart backend

# 只重启前端（Vue代码修改）
docker-compose -f docker-compose.prod.yml restart frontend
```

## 🔄 代码更新流程

### 后端代码更新

```bash
# 1. 修改Python代码
vim backend/views.py

# 2. 重启后端容器
docker-compose -f docker-compose.prod.yml restart backend

# 3. 查看日志确认
docker-compose -f docker-compose.prod.yml logs -f backend
```

### 前端代码更新

```bash
# 1. 修改Vue代码
vim frontend/src/views/LoginView.vue

# 2. 重启前端容器（会自动重新构建）
docker-compose -f docker-compose.prod.yml restart frontend

# 3. 查看日志确认
docker-compose -f docker-compose.prod.yml logs -f frontend
```

### 依赖更新

```bash
# 后端依赖更新
echo "new-package==1.0.0" >> backend/requirements.txt
docker-compose -f docker-compose.prod.yml build backend
docker-compose -f docker-compose.prod.yml restart backend

# 前端依赖更新
cd frontend && npm install new-package
docker-compose -f docker-compose.prod.yml restart frontend
```

## ⚡ 优势

### 1. 快速迭代

- ✅ 代码修改立即生效
- ✅ 无需重新构建镜像
- ✅ 节省大量时间

### 2. 灵活部署

- ✅ 支持热重载
- ✅ 易于调试
- ✅ 快速回滚

### 3. 资源节省

- ✅ 镜像体积更小
- ✅ 构建时间更短
- ✅ 磁盘占用更少

### 4. 开发友好

- ✅ 本地开发体验一致
- ✅ 容器化环境隔离
- ✅ 团队协作便利

## ⚠️ 注意事项

### 1. 文件权限

```bash
# 确保容器用户可以访问代码
sudo chown -R 1001:1001 backend/
sudo chown -R 1001:1001 frontend/
```

### 2. 环境变量

- 前端需要重新构建才能应用环境变量变化
- 后端环境变量可以通过重启容器应用

### 3. 数据持久化

- 数据库数据仍然持久化在Volume中
- 静态文件和媒体文件独立存储

### 4. 安全考虑

- 生产环境确保代码目录权限正确
- 敏感文件不要暴露在挂载目录中

## 🔍 故障排除

### 权限问题

```bash
# 检查文件权限
ls -la backend/ frontend/

# 修复权限
sudo chown -R 1001:1001 backend/ frontend/
```

### 前端构建失败

```bash
# 查看前端日志
docker-compose -f docker-compose.prod.yml logs frontend

# 手动构建测试
docker-compose -f docker-compose.prod.yml exec frontend npm run build
```

### 后端启动失败

```bash
# 查看后端日志
docker-compose -f docker-compose.prod.yml logs backend

# 检查数据库连接
docker-compose -f docker-compose.prod.yml exec backend python manage.py check --database default
```

这种部署方式更适合需要频繁更新代码的生产环境，特别是敏捷开发团队。
