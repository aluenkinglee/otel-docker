# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 目录用途

这是一个 **Claude Code CLI 的 OpenTelemetry 监控栈**。它使用 Docker Compose 提供完整的可观测性解决方案，用于追踪 Claude Code 的使用情况、成本、token 和性能指标。

## 架构

监控管道的数据流如下：
```
Claude Code → OTEL Collector → Prometheus → Grafana
                   ↓
                 Jaeger (可选的链路追踪)
```

**组件说明：**
- **OTEL Collector** (端口 4317/gRPC, 4318/HTTP) - 通过 OTLP 协议接收遥测数据
- **Prometheus** (端口 9090) - 时序数据库，存储指标数据
- **Grafana** (端口 3000) - 可视化仪表板
- **Jaeger** (端口 16686) - 分布式链路追踪（可选）

## 常用命令

### 服务管理

```bash
# 启动所有服务
./start.sh
# 或者
docker-compose up -d

# 停止服务
./stop.sh
# 或者
docker-compose down

# 停止并删除所有数据（包括指标历史）
docker-compose down -v

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [服务名]
docker-compose logs -f otel-collector  # 仅查看 collector 日志
```

### 验证和测试

```bash
# 验证所有服务和配置
./verify.sh

# 快速检查 Prometheus 中的 Claude Code 指标
./check-metrics.sh

# 在当前 shell 中测试 Claude Code 环境变量
source ./test-claude-env.sh
```

### Claude Code 环境配置

启用遥测收集时需要配置以下环境变量：

```bash
# 临时配置（仅当前 shell 有效）
source ./claude-code-env.sh

# 永久配置（添加到 ~/.zshrc 或 ~/.bashrc）
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

## 配置文件

| 文件 | 用途 |
|------|------|
| `docker-compose.yml` | 服务编排配置，使用国内镜像源 `docker.m.daocloud.io` |
| `otel-collector-config.yaml` | OTEL 管道配置：指标 → Prometheus，日志/追踪 → debug |
| `prometheus.yml` | Prometheus 抓取配置 |
| `grafana/datasources/prometheus.yml` | 自动配置的 Prometheus 数据源 |
| `grafana/dashboards/` | 仪表板配置文件 |

## 重要配置说明

### Docker 镜像源
所有镜像使用 `docker.m.daocloud.io` 国内镜像源以加快访问速度。请勿随意更改为 `docker.io`，除非网络环境允许。

### OTEL Collector 导出器
- 使用 `debug` 导出器（不要使用已弃用的 `logging`）
- 指标管道：`prometheusremotewrite` + `debug`
- 日志/追踪管道：仅 `debug`

### 数据持久化
- `prometheus-data`：Prometheus 时序数据
- `grafana-data`：Grafana 仪表板和设置
- 数据卷在 `docker-compose down` 时保留，但使用 `-v` 参数会被删除

## 可用指标

Claude Code 发布以下 OpenTelemetry 指标：

- `claude_code_session_count_total` - 启动的 CLI 会话数
- `claude_code_token_usage_total` - Token 使用量（按类型：input、output、cache_read、cache_creation）
- `claude_code_cost_usage_total` - API 成本（美元）
- `claude_code_lines_of_code_count_total` - 修改的代码行数（按类型）
- `claude_code_commit_count_total` - 创建的 Git 提交数
- `claude_code_pull_request_count_total` - 创建的 Pull Request 数
- `claude_code_code_edit_tool_decision_total` - 工具使用统计
- `claude_code_active_time_total` - 活跃会话时间（秒）

## Prometheus 查询示例

```promql
# 按 type 分组的 Token 使用率
rate(claude_code_token_usage_total[5m]) by (type)

# 过去一小时的成本
increase(claude_code_cost_usage_total[1h])

# 代码行数变化
increase(claude_code_lines_of_code_count_total[1h]) by (type)

# Git 提交率
rate(claude_code_commit_count_total[5m])
```

## 开发工作流

修改监控栈时：

1. **测试配置更改**：使用 `docker-compose config` 验证 YAML 语法
2. **重启相关服务**：`docker-compose restart [服务名]`
3. **立即查看日志**：`docker-compose logs -f [服务名]`
4. **验证指标收集**：更改后运行 `./check-metrics.sh`
5. **访问仪表板**：Grafana 位于 http://localhost:3000 (admin/admin)

## 故障排查

### 没有指标出现
1. 验证 Claude Code 环境变量：`env | grep OTEL`
2. 检查 OTEL Collector 是否接收数据：`docker-compose logs -f otel-collector`
3. 确认 Prometheus 正在抓取：`curl http://localhost:9090/api/v1/targets`
4. 确保 Claude Code 已执行操作（指标在有活动时才会导出）

### 容器启动失败
- 查看日志：`docker-compose logs [服务名]`
- 验证 YAML：`docker-compose config`
- 检查端口占用：`lsof -i :[端口号]`

### OTEL Collector 错误
- 确保 `otel-collector-config.yaml` 使用 `debug` 导出器（不是已弃用的 `logging`）
- 检查网络连接：`docker network inspect otel-docker_otel-network`
- 验证 Collector 可访问 Prometheus：`docker exec otel-collector wget -O- http://prometheus:9090`

## 访问地址

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger UI**: http://localhost:16686
- **OTLP 端点**: http://localhost:4317 (gRPC), http://localhost:4318 (HTTP)
