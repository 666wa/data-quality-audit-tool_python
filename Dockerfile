# 数据质量稽核工具 Docker 镜像
FROM python:3.11-slim

LABEL maintainer="数据质量稽核工具"
LABEL description="ClickHouse数据质量稽核工具 - 支持配置验证、任务执行、报告生成"

# 安装编译依赖（PyYAML需要）
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libyaml-dev \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 先复制依赖文件，利用Docker缓存
COPY requirements.txt .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 创建必要目录（这些目录会被挂载覆盖）
RUN mkdir -p /app/config/tasks /app/sql_templates /app/output /app/logs /app/big_sql

# 复制源码到容器
COPY main.py .
COPY src/ ./src/

# 设置环境变量
ENV PYTHONUNBUFFERED=1
ENV NO_COLOR=0

# 工作目录
WORKDIR /app

# 默认命令
ENTRYPOINT ["python", "main.py"]
CMD ["--help"]
