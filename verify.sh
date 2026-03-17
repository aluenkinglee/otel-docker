#!/bin/bash

# Claude Code OpenTelemetry 监控栈验证脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 验证 Claude Code OpenTelemetry 监控栈..."
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查函数
check_service() {
    local service_name=$1
    local service_port=$2
    local description=$3

    echo -n "检查 $description... "

    if curl -s "http://localhost:$service_port" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ 运行中${NC}"
        return 0
    else
        echo -e "${RED}✗ 未运行${NC}"
        return 1
    fi
}

# 检查 Docker 容器
check_container() {
    local container_name=$1
    echo -n "检查容器 $container_name... "

    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo -e "${GREEN}✓ 运行中${NC}"
        return 0
    else
        echo -e "${RED}✗ 未运行${NC}"
        return 1
    fi
}

# 检查环境变量
check_env_var() {
    local var_name=$1
    local expected_value=$2
    echo -n "检查环境变量 $var_name... "

    local actual_value=$(printenv "$var_name" 2>/dev/null || echo "")

    if [ -z "$actual_value" ]; then
        echo -e "${YELLOW}⚠ 未设置${NC}"
        return 1
    elif [ "$actual_value" = "$expected_value" ]; then
        echo -e "${GREEN}✓ 已设置${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ 值不匹配 (预期: $expected_value, 实际: $actual_value)${NC}"
        return 1
    fi
}

echo "=== 1. 检查 Docker 容器 ==="
check_container "otel-collector"
check_container "prometheus"
check_container "grafana"
# check_container "jaeger"  # Jaeger is optional
echo ""

echo "=== 2. 检查服务端点 ==="
check_service "grafana" 3000 "Grafana"
check_service "prometheus" 9090 "Prometheus"
check_service "otel-collector" 4317 "OTLP Collector (gRPC)"
# check_service "jaeger" 16686 "Jaeger UI"  # Jaeger is optional
echo ""

echo "=== 3. 检查 Claude Code 环境变量 ==="
check_env_var "CLAUDE_CODE_ENABLE_TELEMETRY" "1"
check_env_var "OTEL_METRICS_EXPORTER" "otlp"
check_env_var "OTEL_LOGS_EXPORTER" "otlp"
check_env_var "OTEL_EXPORTER_OTLP_PROTOCOL" "grpc"
check_env_var "OTEL_EXPORTER_OTLP_ENDPOINT" "http://localhost:4317"
echo ""

echo "=== 4. 测试 Prometheus 指标查询 ==="
echo -n "测试 Prometheus 查询... "
if curl -s 'http://localhost:9090/api/v1/query?query=up' | grep -q '"status":"success"'; then
    echo -e "${GREEN}✓ Prometheus 正常工作${NC}"
else
    echo -e "${RED}✗ Prometheus 查询失败${NC}"
fi
echo ""

echo "=== 5. 检查 OpenTelemetry Collector 日志 ==="
echo "最近的 Collector 日志："
docker-compose logs --tail=5 otel-collector 2>/dev/null || echo "无法获取日志"
echo ""

echo "=== 6. 快速测试指南 ==="
echo "要验证数据是否正常接收："
echo ""
echo "1. 在新的终端窗口中运行 Claude Code："
echo "   claude"
echo ""
echo "2. 执行一些操作（如编辑文件、创建提交等）"
echo ""
echo "3. 访问 Grafana 查看实时数据："
echo "   http://localhost:3000"
echo ""
echo "4. 或在 Prometheus 中查询指标："
echo "   http://localhost:9090"
echo ""
echo "   尝试查询："
echo "   - claude_code_session_count_total"
echo "   - claude_code_token_usage_total"
echo "   - claude_code_cost_usage_total"
echo ""
