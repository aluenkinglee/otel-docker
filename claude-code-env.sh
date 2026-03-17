# Claude Code OpenTelemetry 环境变量配置
# 将此文件内容添加到你的 ~/.zshrc 或 ~/.bashrc 中

# 启用遥测（必需）
export CLAUDE_CODE_ENABLE_TELEMETRY=1

# 选择导出器
export OTEL_METRICS_EXPORTER=otlp       # 指标导出器
export OTEL_LOGS_EXPORTER=otlp          # 日志/事件导出器

# 配置 OTLP 端点
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc # 使用 gRPC 协议
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# （可选）调试选项 - 减少导出间隔
# export OTEL_METRIC_EXPORT_INTERVAL=10000  # 10秒（默认：60000ms）
# export OTEL_LOGS_EXPORT_INTERVAL=5000     # 5秒（默认：5000ms）

# （可选）指标基数控制
# export OTEL_METRICS_INCLUDE_SESSION_ID=true   # 包含会话 ID（默认：true）
# export OTEL_METRICS_INCLUDE_VERSION=false     # 包含版本号（默认：false）
# export OTEL_METRICS_INCLUDE_ACCOUNT_UUID=true # 包含账户 UUID（默认：true）

# （可选）自定义属性（用于多团队组织）
# export OTEL_RESOURCE_ATTRIBUTES="department=engineering,team.id=platform"

# （可选）启用用户提示内容日志记录（默认禁用，仅记录长度）
# export OTEL_LOG_USER_PROMPTS=1

# （可选）动态标头刷新间隔（默认：29分钟）
# export CLAUDE_CODE_OTEL_HEADERS_HELPER_DEBOUNCE_MS=900000
