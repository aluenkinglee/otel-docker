# 🚀 OpenTelemetry 监控 Claude Code

在本地 Docker 环境中部署 OpenTelemetry 监控栈，实时监控 Claude Code 的使用情况、成本和性能指标。

![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-0.53.0-blue)
![Claude Code](https://img.shields.io/badge/Claude_Code-2.1.71-purple)
![Docker](https://img.shields.io/badge/Docker-OrbStack-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ 功能特性

- 💰 **成本追踪** - 实时监控 API 使用成本
- 🔢 **Token 统计** - 输入/输出/缓存 token 使用情况
- 📊 **使用趋势** - 会话计数、代码行数、Git 提交等
- 🛠️ **工具分析** - 最常用的工具和操作类型
- 📈 **可视化仪表板** - Grafana 实时展示
- 🐳 **一键部署** - Docker Compose 容器化部署

## 🏗️ 架构

```
Claude Code → OTEL Collector → Prometheus → Grafana
                   ↓
                 Jaeger (可选)
```

## 📦 包含组件

| 组件 | 版本 | 端口 | 功能 |
|------|------|------|------|
| OTEL Collector | contrib:latest | 4317, 4318 | 接收遥测数据 |
| Prometheus | latest | 9090 | 指标存储 |
| Grafana | latest | 3000 | 数据可视化 |
| Jaeger | all-in-one | 16686 | 分布式追踪 |

## 🚀 快速开始

### 1. 前置要求

- macOS 系统
- OrbStack（Docker Desktop 的轻量级替代品）
- Claude Code CLI 已安装

### 2. 克隆或创建项目

```bash
cd ~/otel-docker
```

### 3. 启动监控栈

```bash
docker-compose up -d
```

### 4. 配置 Claude Code

```bash
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

### 5. 访问界面

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686

## 📚 详细文档

查看完整的部署指南和故障排查：

👉 **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)**

## 📊 可监控的指标

| 指标 | 描述 |
|------|------|
| `claude_code_session_count_total` | 启动的会话数 |
| `claude_code_token_usage_total` | Token 使用量 |
| `claude_code_cost_usage_total` | 成本（USD） |
| `claude_code_lines_of_code_count_total` | 修改的代码行数 |
| `claude_code_commit_count_total` | Git 提交数 |
| `claude_code_pull_request_count_total` | Pull Request 数 |
| `claude_code_code_edit_tool_decision_total` | 工具决策统计 |
| `claude_code_active_time_total` | 活跃时间 |

## 🛠️ 常用命令

```bash
# 启动服务
docker-compose up -d

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down

# 完全清理（包括数据）
docker-compose down -v

# 重启服务
docker-compose restart
```

## 🔧 配置文件

- `docker-compose.yml` - Docker 服务编排
- `otel-collector-config.yaml` - OTEL Collector 配置
- `prometheus.yml` - Prometheus 配置
- `grafana/` - Grafana 数据源和仪表板

## 📖 Prometheus 查询示例

```promql
# Token 使用率
rate(claude_code_token_usage_total[5m]) by (type)

# 成本趋势
increase(claude_code_cost_usage_total[1h])

# 代码行数变化
increase(claude_code_lines_of_code_count_total[1h]) by (type)

# Git 提交率
rate(claude_code_commit_count_total[5m])
```

## 🐛 故障排查

### Docker 无法拉取镜像

配置国内镜像加速器（参考 DEPLOYMENT_GUIDE.md）

### OTEL Collector 启动失败

确保配置文件使用 `debug` exporter 而不是已弃用的 `logging`

### Claude Code 没有发送数据

检查环境变量是否正确设置，验证 OTEL Collector 是否正常运行

## 🌟 特色功能

- ✅ 使用 **OrbStack** 而非 Docker Desktop，更轻量
- ✅ 配置**国内镜像加速**，解决网络问题
- ✅ **数据持久化**，重启不丢失
- ✅ **自动更新**配置，无需手动干预
- ✅ 包含**完整文档**和部署指南

## 📝 更新日志

### v1.0.0 (2026-03-17)

- ✨ 初始版本
- ✅ 支持 macOS + OrbStack
- ✅ 配置国内镜像加速
- ✅ 修复 logging exporter 弃用问题
- ✅ 创建详细部署文档

## 🔗 相关资源

- [Claude Code 监控文档](https://code.claude.com/docs/zh-CN/monitoring-usage)
- [OpenTelemetry 官方文档](https://opentelemetry.io/docs/)
- [Prometheus 查询指南](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana 文档](https://grafana.com/docs/)

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**享受监控的乐趣！** 🎉

如有问题，请查看 [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) 获取详细信息。
