#!/bin/bash
# 快速检查 Claude Code 监控数据

echo "🔍 检查 OpenTelemetry 监控状态..."
echo ""

# 1. 检查服务状态
echo "📊 服务状态："
cd ~/otel-docker
docker-compose ps otel-collector prometheus grafana | grep -E "NAME|otel-collector|prometheus|grafana"
echo ""

# 2. 检查是否有 Claude Code 指标
echo "📈 Prometheus 中的 Claude Code 指标："
METRICS=$(curl -s 'http://localhost:9090/api/v1/label/__name__/values' | python3 -c "
import sys, json
labels = json.load(sys.stdin)['data']
claude_metrics = [l for l in labels if 'claude' in l.lower()]
if claude_metrics:
    for metric in claude_metrics:
        print(metric)
" 2>/dev/null)

if [ -n "$METRICS" ]; then
    echo "✅ 找到以下指标："
    echo "$METRICS" | while read metric; do
        echo "  • $metric"
    done
else
    echo "⚠️  还没有 Claude Code 指标数据"
    echo "   请确保："
    echo "   1. Claude Code 正在运行"
    echo "   2. 环境变量已正确设置"
    echo "   3. Claude Code 已经执行了一些操作"
fi
echo ""

# 3. 检查最近的 OTEL Collector 日志
echo "📋 OTEL Collector 最近的活动："
docker-compose logs --tail=5 otel-collector 2>/dev/null | grep -v "level=warning" | tail -3
echo ""

# 4. 提供下一步建议
echo "💡 下一步："
if [ -z "$METRICS" ]; then
    echo "1. 在新终端运行: source ~/otel-docker/test-claude-env.sh"
    echo "2. 然后运行: claude"
    echo "3. 让 Claude Code 做一些操作"
    echo "4. 等待 10-20 秒后重新运行此脚本"
else
    echo "✅ 监控正常工作！"
    echo "📊 查看 Grafana 仪表板: http://localhost:3000"
    echo "🔍 在 Prometheus 查询: http://localhost:9090"
fi
