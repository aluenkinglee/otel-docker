#!/bin/bash
# 实时监控 Claude Code 数据流

echo "🔍 实时监控 Claude Code OpenTelemetry 数据"
echo "=========================================="
echo ""

cd ~/otel-docker

echo "📡 监控 OTEL Collector 接收的数据..."
echo "按 Ctrl+C 停止"
echo ""

docker-compose logs -f otel-collector | grep --line-buffered -E "api_request|token|cost|session|claude" | while read -r line; do
    # 高亮关键信息
    if echo "$line" | grep -q "api_request"; then
        echo -e "\033[0;32m📊 $line\033[0m"
    elif echo "$line" | grep -q "token"; then
        echo -e "\033[0;33m🔢 $line\033[0m"
    elif echo "$line" | grep -q "cost"; then
        echo -e "\033[0;31m💰 $line\033[0m"
    elif echo "$line" | grep -q "session"; then
        echo -e "\033[0;34m👤 $line\033[0m"
    else
        echo "$line"
    fi
done
