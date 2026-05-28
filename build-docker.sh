#!/bin/bash

# 数据质量稽核工具 Docker 构建脚本

set -e

IMAGE_NAME="data-quality-audit"
IMAGE_TAG="latest"

echo "============================================"
echo "  数据质量稽核工具 Docker 构建"
echo "============================================"
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "[错误] Docker 未安装或未启动"
    exit 1
fi

# 构建镜像
echo "[1/2] 正在构建 Docker 镜像..."
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "[2/2] Docker 镜像构建完成"
echo ""
echo "镜像信息:"
echo "  名称: ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "使用方式:"
echo "  验证配置:    docker run --rm -v \$(pwd)/config:/app/config -v \$(pwd)/sql_templates:/app/sql_templates ${IMAGE_NAME}:${IMAGE_TAG} --validate"
echo "  执行稽核:    docker run --rm -v \$(pwd)/config:/app/config -v \$(pwd)/sql_templates:/app/sql_templates -v \$(pwd)/output:/app/output -v \$(pwd)/logs:/app/logs ${IMAGE_NAME}:${IMAGE_TAG} --task operation_log"
echo "  生成SQL:     docker run --rm -v \$(pwd)/config:/app/config -v \$(pwd)/sql_templates:/app/sql_templates -v \$(pwd)/big_sql:/app/big_sql ${IMAGE_NAME}:${IMAGE_TAG} --gen-sql --task operation_log"
