# Docker 部署指南

## 快速开始

### 1. 构建 Docker 镜像

**Linux / macOS:**
```bash
chmod +x build-docker.sh
./build-docker.sh
```

**Windows:**
```cmd
build-docker.bat
```

或者直接使用 docker build:
```bash
docker build -t data-quality-audit:latest .
```

### 2. 使用 docker-compose 运行（推荐）

```bash
# 验证配置
docker-compose run --rm audit --validate

# 执行稽核任务
docker-compose run --rm audit --task operation_log

# 生成SQL文件
docker-compose run --rm audit --gen-sql --task operation_log

# 执行所有任务
docker-compose run --rm audit --all-tasks
```

### 3. 直接使用 docker run

```bash
# 验证配置
docker run --rm \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/sql_templates:/app/sql_templates \
  data-quality-audit:latest --validate

# 执行稽核任务
docker run --rm \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/sql_templates:/app/sql_templates \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/logs:/app/logs \
  data-quality-audit:latest --task operation_log

# 生成SQL文件
docker run --rm \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/sql_templates:/app/sql_templates \
  -v $(pwd)/big_sql:/app/big_sql \
  data-quality-audit:latest --gen-sql --task operation_log
```

### 4. 目录映射说明

| 本地目录 | 容器路径 | 说明 |
|---------|---------|------|
| `./config` | `/app/config` | 配置文件（必需） |
| `./sql_templates` | `/app/sql_templates` | SQL模板（必需） |
| `./output` | `/app/output` | 报告输出 |
| `./logs` | `/app/logs` | 日志文件 |
| `./big_sql` | `/app/big_sql` | 生成的大SQL文件 |

### 5. 部署前准备

确保本地目录结构完整：
```
data-quality-audit-py/
├── config/
│   ├── config.yaml          # 主配置（含数据库连接）
│   └── tasks/               # 任务配置
├── sql_templates/           # SQL模板
│   ├── operation_log/
│   ├── gold_log/
│   └── special/
├── output/                  # 报告输出（自动创建）
├── logs/                    # 日志文件（自动创建）
├── big_sql/                 # 生成的大SQL（自动创建）
├── Dockerfile
├── docker-compose.yml
└── build-docker.sh / .bat
```

### 6. 网络配置

如果数据库在内网，需要确保容器能够访问内网数据库：

**方式1: 使用 host 网络模式（Linux）**
```bash
docker run --rm --network host \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/sql_templates:/app/sql_templates \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/logs:/app/logs \
  data-quality-audit:latest --task operation_log
```

**方式2: 指定 DNS**
```bash
docker run --rm --dns 10.10.26.1 \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/sql_templates:/app/sql_templates \
  -v $(pwd)/output:/app/output \
  -v $(pwd)/logs:/app/logs \
  data-quality-audit:latest --task operation_log
```

### 7. 常用命令

```bash
# 查看帮助
docker run --rm data-quality-audit:latest --help

# 进入容器调试
docker run --rm -it \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/sql_templates:/app/sql_templates \
  data-quality-audit:latest /bin/bash

# 查看容器日志
docker logs data-quality-audit

# 删除镜像
docker rmi data-quality-audit:latest
```
