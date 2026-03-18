# 🎉 OpenTelemetry 监控 Claude Code - 完整部署总结

## 📅 部署日期
2026-03-18

## 🎯 项目概述

成功在本地 Docker 环境中部署了完整的 OpenTelemetry 监控栈，用于实时监控 Claude Code 的使用情况、成本和性能指标。

## ✅ 已完成的工作

### 1. 基础设施部署
- ✅ 使用 OrbStack 替代 Docker Desktop（更轻量）
- ✅ 配置国内镜像源加速（docker.m.daocloud.io）
- ✅ 部署 4 个核心服务：OTEL Collector、Prometheus、Grafana、Jaeger
- ✅ 配置数据持久化（volumes）

### 2. 核心配置修复

#### Prometheus Remote Write 问题
**问题**：OTEL Collector 使用 remote write 时遇到 404 错误
```
remote write receiver needs to be enabled with --web.enable-remote-write-receiver
```

**解决方案**：
- 在 Prometheus 启动参数中添加 `--web.enable-remote-write-receiver`
- 后续改为使用 scrape 方式（更稳定）

#### OTEL Collector Exporter 问题
**问题**：`logging` exporter 已弃用
```
'exporters' the logging exporter has been deprecated, use the debug exporter instead
```

**解决方案**：
- 将所有 `logging` exporter 替换为 `debug` exporter
- 配置 `prometheus` exporter 用于 scrape

### 3. Dashboard 修复

**问题**：Grafana Dashboard 中的指标名称与实际不符

**修复**：
- 更新所有查询使用正确的指标名称
- 创建 5 个新面板：Active Time、Total Cost、Total Tokens、Token Usage Over Time、Cost Over Time

**指标名称对照**：
| 错误名称 | 正确名称 |
|---------|---------|
| `claude_code_session_count_total` | ❌ 不存在 |
| `claude_code_token_usage_total` | `claude_code_token_usage_tokens_total` |
| `claude_code_cost_usage_total` | `claude_code_cost_usage_USD_total` |

### 4. 成功收集的指标

现在 Prometheus 中有以下 Claude Code 指标：
- ✅ `claude_code_active_time_seconds_total` - 活跃时间
- ✅ `claude_code_cost_usage_USD_total` - 成本（USD）
- ✅ `claude_code_token_usage_tokens_total` - Token 使用量

### 5. 文档和工具

创建了完整的文档和诊断工具：
- `DEPLOYMENT_GUIDE.md` - 完整部署指南
- `TROUBLESHOOTING.md` - 故障排查指南
- `CREATE_MANUAL_DASHBOARD.md` - 手动创建面板指南
- `VIEW_DATA_IN_GRAFANA.md` - 在 Grafana 中查看数据
- `DASHBOARD_FIX.md` - Dashboard 修复说明
- `diagnose-full.sh` - 完整诊断脚本
- `monitor.sh` - 实时监控脚本
- `check-metrics.sh` - 快速检查脚本

### 6. 环境变量配置

Claude Code 需要配置以下环境变量：
```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
export OTEL_METRIC_EXPORT_INTERVAL=10000
export OTEL_LOGS_EXPORT_INTERVAL=5000
```

## 🏗️ 最终架构

```
Claude Code (环境变量已配置)
    ↓ OTLP (gRPC/HTTP)
OTEL Collector (0.0.0.0:4317/4318)
    ↓ Prometheus Exporter (:8889)
Prometheus (:9090)
    ↓
Grafana (:3000)
```

## 📊 监控界面

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686
- **Dashboard**: http://localhost:3000/d/claude-code-dashboard/

## 🎨 Dashboard 功能

修复后的 Dashboard 包含：
1. **Active Time (seconds)** - 总活跃时间
2. **Total Cost (USD)** - 累计成本
3. **Total Tokens** - Token 使用总数
4. **Token Usage Over Time** - Token 趋势图
5. **Cost Over Time** - 成本趋势图

自动刷新：10 秒

## 🔧 关键技术决策

### 1. 使用 OrbStack 而非 Docker Desktop
- 更轻量
- 启动更快
- 资源占用更少

### 2. 使用国内镜像源
- 解决网络访问问题
- 大幅提高镜像拉取速度

### 3. 使用 Prometheus Scrape 而非 Remote Write
- 更稳定可靠
- 减少配置复杂度
- 更好的兼容性

### 4. Debug Exporter 替代 Logging
- Logging exporter 已弃用
- Debug exporter 功能更强大

## 📝 使用说明

### 启动监控栈
```bash
cd ~/otel-docker
docker-compose up -d
```

### 配置 Claude Code
```bash
source ~/otel-docker/test-claude-env.sh
claude
```

### 查看监控数据
访问 http://localhost:3000 查看实时数据

### 停止监控栈
```bash
docker-compose down
```

## 🐛 遇到的主要问题和解决方案

### 问题 1：Docker Hub 无法访问
**解决**：配置国内镜像加速器

### 问题 2：OTEL Collector 404 错误
**解决**：启用 Prometheus remote write receiver

### 问题 3：指标名称不匹配
**解决**：更新 Dashboard 查询使用正确的指标名称

### 问题 4：环境变量不生效
**解决**：确保在正确的终端中设置环境变量

## 🎓 经验总结

### 成功要素
1. ✅ 逐步调试和诊断
2. ✅ 查看日志定位问题
3. ✅ 验证每一步的数据流
4. ✅ 使用正确的工具和配置

### 关键教训
1. **配置很重要**：OpenTelemetry 配置需要仔细调试
2. **指标名称要准确**：Dashboard 查询必须匹配实际指标
3. **环境变量必须在正确位置**：在启动 Claude Code 前设置
4. **耐心和系统化排查**：不要跳过验证步骤

## 🚀 下一步优化

可以考虑的改进：
1. 添加更多 Grafana 面板
2. 配置告警规则
3. 添加更多指标（如果可用）
4. 优化查询性能
5. 添加成本预算告警

## 📚 相关资源

- [Claude Code 官方监控文档](https://code.claude.com/docs/zh-CN/monitoring-usage)
- [OpenTelemetry 官方文档](https://opentelemetry.io/docs/)
- [Grafana 文档](https://grafana.com/docs/)
- [Prometheus 查询指南](https://prometheus.io/docs/prometheus/latest/querying/basics/)

---

**部署状态**：✅ 完全成功
**数据流状态**：✅ 正常工作
**Dashboard 状态**：✅ 正确显示数据

🎉 监控系统已完全就绪，可以开始监控 Claude Code 的使用情况了！
