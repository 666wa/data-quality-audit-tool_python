#!/bin/bash
# 数据质量稽核工具 - 部署脚本

echo "=========================================="
echo "数据质量稽核工具 - 部署脚本"
echo "=========================================="

# 检查Python版本
echo "检查Python版本..."
python3 --version
if [ $? -ne 0 ]; then
    echo "错误: 未找到Python3，请先安装Python 3.7+"
    exit 1
fi

# 创建虚拟环境（可选）
read -p "是否创建Python虚拟环境? (y/n): " create_venv
if [ "$create_venv" = "y" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
    source venv/bin/activate
    echo "虚拟环境已激活"
fi

# 安装依赖
echo "安装依赖包..."
if [ -d "offline_packages" ]; then
    echo "使用离线依赖包..."
    pip3 install --no-index --find-links=offline_packages -r requirements.txt
else
    echo "在线安装依赖包..."
    pip3 install -r requirements.txt
fi

if [ $? -ne 0 ]; then
    echo "错误: 依赖安装失败"
    exit 1
fi

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p logs
mkdir -p output
mkdir -p big_sql

# 设置权限
echo "设置执行权限..."
chmod +x main.py
chmod +x run.sh

# 配置检查
echo "检查配置文件..."
if [ ! -f "config/config.yaml" ]; then
    echo "警告: config/config.yaml 不存在，请从 config.example.yaml 复制并修改"
    cp config/config.example.yaml config/config.yaml
fi

echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo "1. 编辑 config/config.yaml 配置数据库连接"
echo "2. 编辑 config/audit_tasks.yaml 配置稽核任务"
echo "3. 运行: ./run.sh 或 python3 main.py"
echo ""
