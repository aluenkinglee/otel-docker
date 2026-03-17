#!/bin/bash
# Claude Code OpenTelemetry 诊断脚本

echo "🔍 Claude Code OpenTelemetry 诊断工具"
echo "====================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 计数器
PASS=0
FAIL=0
WARN=0

# 检查函数
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    ((WARN++))
}

# 1. 检查 Docker 服务
echo "📋 检查 Docker 服务..."
if docker info >/dev/null 2>&1; then
    check_pass "Docker 服务运行正常"
else
    check_fail "Docker 服务未运行"
fi
echo ""

# 2. 检查容器状态
echo "📋 检查 OpenTelemetry 容器状态..."
cd ~/otel-docker 2>/dev/null || cd "$(dirname "$0")"

CONTAINERS=("otel-collector" "prometheus" "grafana")
for container in "${CONTAINERS[@]}"; do
    if docker-compose ps "$container" 2>/dev/null | grep -q "Up"; then
        check_pass "$container 容器运行中"
    else
        check_fail "$container 容器未运行"
    fi
done
echo ""

# 3. 检查环境变量
echo "📋 检查 Claude Code 环境变量..."
ENV_VARS=(
    "CLAUDE_CODE_ENABLE_TELEMETRY"
    "OTEL_METRICS_EXPORTER"
    "OTEL_LOGS_EXPORTER"
    "OTEL_EXPORTER_OTLP_PROTOCOL"
    "OTEL_EXPORTER_OTLP_ENDPOINT"
)

MISSING_VARS=0
for var in "${ENV_VARS[@]}"; do
    if [ -n "${!var}" ]; then
        echo -e "  ${GREEN}✓${NC} $var=${!var}"
    else
        echo -e "  ${RED}✗${NC} $var 未设置"
        ((MISSING_VARS++))
    fi
done

if [ $MISSING_VARS -eq 0 ]; then
    check_pass "所有环境变量已设置"
else
    check_fail "缺少 $MISSING_VARS 个环境变量"
fi
echo ""

# 4. 检查端口连接
echo "📋 检查端口连接..."
PORTS=(
    "4317:OTLP gRPC"
    "4318:OTLP HTTP"
    "9090:Prometheus"
    "3000:Grafana"
)

for port_info in "${PORTS[@]}"; do
    port="${port_info%%:*}"
    service="${port_info##*:}"
    if curl -s "http://localhost:$port" >/dev/null 2>&1 || nc -z localhost "$port" 2>/dev/null; then
        check_pass "$service (端口 $port) 可访问"
    else
        check_fail "$service (端口 $port) 无法访问"
    fi
done
echo ""

# 5. 检查 Prometheus 数据
echo "📋 检查 Prometheus 指标数据..."
METRIC_COUNT=$(curl -s 'http://localhost:9090/api/v1/label/__name__/values' 2>/dev/null | \
    python3 -c "import sys, json; labels = json.load(sys.stdin)['data']; print(len([l for l in labels if 'claude' in l.lower()]))" 2>/dev/null || echo "0")

if [ "$METRIC_COUNT" -gt 0 ]; then
    check_pass "找到 $METRIC_COUNT 个 Claude Code 指标"

    # 显示部分指标
    echo "  部分指标:"
    curl -s 'http://localhost:9090/api/v1/label/__name__/values' 2>/dev/null | \
        python3 -c "
import sys, json
labels = json.load(sys.stdin)['data']
claude_metrics = [l for l in labels if 'claude' in l.lower()][:5]
for metric in claude_metrics:
    print(f'    • {metric}')
" 2>/dev/null
else
    check_warn "还没有 Claude Code 指标数据"
    echo "  可能原因:"
    echo "    • Claude Code 还没有启动"
    echo "    • 环境变量没有正确设置"
    echo "    • Claude Code 还没有执行任何操作"
fi
echo ""

# 6. 检查 OTEL Collector 错误
echo "📋 检查 OTEL Collector 日志..."
ERROR_LOGS=$(docker-compose logs otel-collector 2>/dev/null | grep -i "error\|failed" | grep -v "level=warning" | tail -3)
if [ -z "$ERROR_LOGS" ]; then
    check_pass "OTEL Collector 日志正常"
else
    check_warn "OTEL Collector 发现错误日志"
    echo "  最近的错误:"
    echo "$ERROR_LOGS" | while read -r line; do
        echo "    $line"
    done
fi
echo ""

# 7. 检查 Grafana 数据源
echo "📋 检查 Grafana 数据源..."
GRAFANA_HEALTH=$(curl -s http://localhost:3000/api/health 2>/dev/null)
if [ -n "$GRAFANA_HEALTH" ]; then
    check_pass "Grafana 服务正常"
else
    check_fail "Grafana 服务异常"
fi
echo ""

# 总结
echo "====================================="
echo "📊 诊断总结:"
echo -e "  ${GREEN}通过${NC}: $PASS"
echo -e "  ${YELLOW}警告${NC}: $WARN"
echo -e "  ${RED}失败${NC}: $FAIL"
echo ""

# 提供建议
if [ $FAIL -gt 0 ]; then
    echo "🔧 建议操作:"
    echo "1. 查看 TROUBLESHOOTING.md 获取详细指导"
    echo "2. 确保 OpenTelemetry 服务正在运行: cd ~/otel-docker && docker-compose up -d"
    echo "3. 在新终端设置环境变量: source ~/otel-docker/test-claude-env.sh"
    echo "4. 启动 Claude Code 并执行一些操作"
elif [ $WARN -gt 0 ]; then
    echo "💡 下一步:"
    echo "1. 在新终端运行: source ~/otel-docker/test-claude-env.sh"
    echo "2. 启动 Claude Code: claude"
    echo "3. 让 Claude Code 做一些操作"
    echo "4. 等待 10-20 秒后重新运行此脚本"
elif [ $METRIC_COUNT -eq 0 ]; then
    echo "💡 下一步:"
    echo "1. 确保 Claude Code 的环境变量已设置"
    echo "2. 启动 Claude Code 并执行一些操作"
    echo "3. 等待至少 10 秒让指标导出"
    echo "4. 重新运行此脚本检查"
else
    echo "🎉 所有检查通过！"
    echo ""
    echo "📊 访问监控界面:"
    echo "  • Grafana: http://localhost:3000 (admin/admin)"
    echo "  • Prometheus: http://localhost:9090"
    echo "  • Jaeger: http://localhost:16686"
fi

echo ""
