#!/bin/bash

# Claude Code OpenTelemetry 监控栈启动脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🚀 启动 Claude Code OpenTelemetry 监控栈..."
echo ""

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker 未运行，请先启动 Docker Desktop"
    exit 1
fi

# 检查 docker-compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose 未安装"
    echo "   请安装: brew install docker-compose"
    exit 1
fi

# 创建必要的目录
echo "📁 创建必要的目录..."
mkdir -p grafana/dashboards
mkdir -p grafana/datasources

# 启动服务
echo "🐳 启动 Docker 服务..."
docker-compose up -d

echo ""
echo "⏳ 等待服务启动..."
sleep 10

# 检查服务状态
echo ""
echo "✅ 检查服务状态..."
docker-compose ps

echo ""
echo "🌐 服务访问地址："
echo "   Grafana:     http://localhost:3000 (admin/admin)"
echo "   Prometheus:  http://localhost:9090"
echo "   Jaeger:      http://localhost:16686"
echo ""
echo "📊 OpenTelemetry Collector 端点："
echo "   OTLP gRPC:  http://localhost:4317"
echo "   OTLP HTTP:  http://localhost:4318"
echo ""
echo "📝 下一步："
echo "   1. 在你的 ~/.zshrc 或 ~/.bashrc 中添加以下环境变量："
echo ""
echo "      # 启用 Claude Code 遥测"
echo "      export CLAUDE_CODE_ENABLE_TELEMETRY=1"
echo "      export OTEL_METRICS_EXPORTER=otlp"
echo "      export OTEL_LOGS_EXPORTER=otlp"
echo "      export OTEL_EXPORTER_OTLP_PROTOCOL=grpc"
echo "      export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317"
echo ""
echo "   2. 重新加载配置: source ~/.zshrc"
echo "   3. 开始使用 Claude Code，数据将自动发送到监控栈"
echo ""
echo "📋 查看日志:"
echo "   docker-compose logs -f [otel-collector|prometheus|grafana|jaeger]"
echo ""
echo "🛑 停止服务:"
echo "   docker-compose down"
echo ""
