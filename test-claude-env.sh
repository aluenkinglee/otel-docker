#!/bin/bash
# Claude Code OpenTelemetry 测试脚本
# 在新终端窗口中运行此脚本来测试监控

echo "🚀 设置 Claude Code 监控环境变量..."

# 设置环境变量
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_METRIC_EXPORT_INTERVAL=10000  # 10秒
export OTEL_LOGS_EXPORT_INTERVAL=5000     # 5秒

echo "✅ 环境变量已设置！"
echo ""
echo "📋 当前配置："
echo "  • CLAUDE_CODE_ENABLE_TELEMETRY=$CLAUDE_CODE_ENABLE_TELEMETRY"
echo "  • OTEL_METRICS_EXPORTER=$OTEL_METRICS_EXPORTER"
echo "  • OTEL_LOGS_EXPORTER=$OTEL_LOGS_EXPORTER"
echo "  • OTEL_EXPORTER_OTLP_ENDPOINT=$OTEL_EXPORTER_OTLP_ENDPOINT"
echo "  • OTEL_METRIC_EXPORT_INTERVAL=${OTEL_METRIC_EXPORT_INTERVAL}ms"
echo "  • OTEL_LOGS_EXPORT_INTERVAL=${OTEL_LOGS_EXPORT_INTERVAL}ms"
echo ""
echo "🎯 现在你可以："
echo "  1. 运行 'claude' 启动 Claude Code"
echo "  2. 让 Claude Code 做一些操作（编辑文件、运行命令等）"
echo "  3. 等待 10-20 秒让数据发送"
echo "  4. 在 Grafana (http://localhost:3000) 或 Prometheus (http://localhost:9090) 查看指标"
echo ""
echo "📊 要查看实时数据，可以在另一个终端运行："
echo "   watch -n 5 'curl -s http://localhost:9090/api/v1/query?query=claude_code_token_usage_total'"
echo ""
echo "🔍 要查看 OTEL Collector 日志，运行："
echo "   cd ~/otel-docker && docker-compose logs -f otel-collector"
echo ""
echo "✨ 享受监控！"
