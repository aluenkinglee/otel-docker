#!/bin/bash
# 完整的数据流诊断脚本

echo "🔍 Claude Code OpenTelemetry 数据流诊断"
echo "=========================================="
echo ""

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd ~/otel-docker 2>/dev/null || cd "$(dirname "$0")"

echo "📊 Step 1: 检查 Prometheus 中的所有指标"
echo "------------------------------------------"
METRICS=$(curl -s "http://localhost:9090/api/v1/label/__name__/values" | python3 -c "
import sys, json
data = json.load(sys.stdin)
claude = [m for m in data['data'] if 'claude' in m.lower()]
if claude:
    print('FOUND')
else:
    print('NOT_FOUND')
" 2>/dev/null)

if [ "$METRICS" = "FOUND" ]; then
    echo -e "${GREEN}✅ 找到 Claude Code 指标${NC}"
    curl -s "http://localhost:9090/api/v1/label/__name__/values" | python3 -c "
import sys, json
data = json.load(sys.stdin)
claude = [m for m in data['data'] if 'claude' in m.lower()]
for m in sorted(claude):
    print(f'  • {m}')
"
else
    echo -e "${RED}❌ Prometheus 中没有 Claude Code 指标${NC}"
    echo ""
    echo "可能原因:"
    echo "  1. Claude Code 还没有发送数据"
    echo "  2. 环境变量没有正确设置"
    echo "  3. OTEL Collector 没有接收到数据"
    echo "  4. OTEL Collector 没有转发数据给 Prometheus"
fi
echo ""

echo "📋 Step 2: 检查 Claude Code 环境变量"
echo "------------------------------------------"
ENV_VARS=(CLAUDE_CODE_ENABLE_TELEMETRY OTEL_METRICS_EXPORTER OTEL_EXPORTER_OTLP_ENDPOINT)
ALL_SET=true
for var in "${ENV_VARS[@]}"; do
    if [ -n "${!var}" ]; then
        echo -e "  ${GREEN}✓${NC} $var=${!var}"
    else
        echo -e "  ${RED}✗${NC} $var 未设置"
        ALL_SET=false
    fi
done
echo ""

if [ "$ALL_SET" = false ]; then
    echo -e "${YELLOW}⚠️  环境变量未设置！${NC}"
    echo "请在新终端运行: source ~/otel-docker/test-claude-env.sh"
fi
echo ""

echo "📡 Step 3: 检查 OTEL Collector 状态"
echo "------------------------------------------"
COLLECTOR_LOGS=$(docker-compose logs otel-collector --tail=50 2>/dev/null)
if echo "$COLLECTOR_LOGS" | grep -q "Everything is ready"; then
    echo -e "${GREEN}✅ OTEL Collector 运行正常${NC}"
else
    echo -e "${RED}❌ OTEL Collector 可能有问题${NC}"
fi
echo ""

echo "📡 Step 4: 检查数据传输情况"
echo "------------------------------------------"
# 检查最近的日志活动
RECEIVED=$(echo "$COLLECTOR_LOGS" | grep -i "received\|spans\|metrics" | tail -5)
if [ -n "$RECEIVED" ]; then
    echo -e "${GREEN}✅ OTEL Collector 有数据活动${NC}"
    echo "$COLLECTOR_LOGS" | grep -i "received\|spans\|metrics" | tail -3 | sed 's/^/  /'
else
    echo -e "${YELLOW}⚠️  OTEL Collector 没有显示接收到数据${NC}"
    echo ""
    echo "实时日志 (按 Ctrl+C 退出):"
    echo "  cd ~/otel-docker && docker-compose logs -f otel-collector"
fi
echo ""

echo "📊 Step 5: 测试查询建议"
echo "------------------------------------------"
echo "在 Prometheus UI (http://localhost:9090) 中尝试以下查询:"
echo ""
echo "1. 查看所有指标 (不使用正则):"
echo "   输入: up"
echo "   这会显示所有目标的状态"
echo ""
echo "2. 直接查询 (假设指标存在):"
echo "   claude_code_token_usage_total"
echo "   claude_code_session_count_total"
echo ""

echo "💡 下一步操作:"
echo "------------------------------------------"
if [ "$METRICS" != "FOUND" ]; then
    echo "1. 在新终端中设置环境变量:"
    echo "   source ~/otel-docker/test-claude-env.sh"
    echo ""
    echo "2. 启动 Claude Code:"
    echo "   claude"
    echo ""
    echo "3. 在 Claude Code 中执行一些操作"
    echo ""
    echo "4. 等待 10-20 秒"
    echo ""
    echo "5. 在另一个终端监控日志:"
    echo "   cd ~/otel-docker && docker-compose logs -f otel-collector"
    echo ""
    echo "6. 重新运行此脚本验证:"
    echo "   ~/otel-docker/diagnose-full.sh"
else
    echo "✅ 数据已到达 Prometheus！"
    echo ""
    echo "在 Grafana 中创建面板:"
    echo "1. 访问 http://localhost:3000/explore"
    echo "2. 选择 Prometheus 数据源"
    echo "3. 输入查询: claude_code_token_usage_total"
    echo "4. 点击 Run query"
fi
echo ""
