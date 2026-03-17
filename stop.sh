#!/bin/bash

# Claude Code OpenTelemetry 监控栈停止脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🛑 停止 Claude Code OpenTelemetry 监控栈..."
echo ""

docker-compose down

echo ""
echo "✅ 所有服务已停止"
echo ""
echo "💡 提示：如果要删除所有数据（包括 Prometheus 和 Grafana 的历史数据），请运行："
echo "   docker-compose down -v"
echo ""
