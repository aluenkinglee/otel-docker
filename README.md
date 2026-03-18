# 🚀 OpenTelemetry 监控 Claude Code - 完整部署历程

> 从零开始的完整部署指南，包含所有踩坑经验、问题解决方案和最佳实践

![OpenTelemetry](https://img.shields.io/badge/OpenTelemetry-0.147.0-blue)
![Claude Code](https://img.shields.io/badge/Claude_Code-2.1.71-purple)
![Docker](https://img.shields.io/badge/Docker-OrbStack-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Production--ready-brightgreen)

## 📖 项目背景

本项目是在本地 Docker 环境中部署 OpenTelemetry 监控栈的**完整实践记录**，用于实时监控 Claude Code 的使用情况、成本和性能指标。

### 为什么需要这个项目？

在使用 Claude Code 的过程中，我们经常会有以下疑问：
- 💰 **这个月我在 Claude Code 上花了多少钱？**
- 🔢 **我总共使用了多少 tokens？**
- 📊 **我的使用趋势是什么？**
- 🛠️ **我最常用哪些工具？**
- ⚡ **Claude Code 的性能如何？**

Claude Code 官方提供了 OpenTelemetry 支持，但是**部署过程并非一帆风顺**。本项目记录了从零开始的完整部署过程，包括遇到的所有问题、解决方案和经验总结。

## ✨ 功能特性

- 💰 **成本追踪** - 实时监控 API 使用成本
- 🔢 **Token 统计** - 输入/输出/缓存 token 使用情况
- ⏱️ **活跃时间** - 跟踪实际使用时间
- 📊 **实时仪表板** - Grafana 可视化展示
- 🐳 **一键部署** - Docker Compose 容器化部署
- 📚 **完整文档** - 详细的部署、排查和优化指南

## 🏗️ 架构

```
Claude Code (环境变量配置)
    ↓ OTLP (gRPC:4317, HTTP:4318)
OTEL Collector (接收和处理)
    ↓ Prometheus Exporter (:8889)
Prometheus (存储和查询)
    ↓
Grafana (可视化展示)
```

### 技术栈

| 组件 | 版本 | 端口 | 用途 |
|------|------|------|------|
| **OrbStack** | 2.0.5 | - | Docker 运行时（轻量级） |
| **OTEL Collector** | contrib:0.147.0 | 4317, 4318, 8889 | 接收和处理遥测数据 |
| **Prometheus** | 3.10.0 | 9090 | 时序数据库 |
| **Grafana** | latest | 3000 | 可视化仪表板 |
| **Jaeger** | all-in-one | 16686 | 分布式追踪（可选） |

## 🎯 完整部署历程

### 第一阶段：基础设施准备（遇到的挑战）

#### 挑战 1：Docker Desktop → OrbStack

**问题**：
- 初始使用 Docker Desktop，但发现资源占用较大
- 切换到 OrbStack 后需要适应新的命令

**解决方案**：
```bash
# 使用 Homebrew 安装 OrbStack
brew install orbstack

# 启动 OrbStack
orb start
```

**经验**：OrbStack 启动更快，资源占用更少，非常适合本地开发。

#### 挑战 2：网络访问问题

**问题**：
- Docker Hub (registry-1.docker.io) 完全无法连接
- 镜像拉取失败（100% 丢包）

**解决方案**：
配置国内镜像加速器：
```bash
# 创建 ~/.docker/daemon.json
cat > ~/.docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live",
    "https://hub.rat.dev"
  ]
}
EOF

# 重启 OrbStack
orb restart
```

**经验**：在中国大陆地区，配置镜像加速器是必需的。

### 第二阶段：服务部署（配置调试）

#### 挑战 3：OTEL Collector Exporter 弃用

**问题**：
```
'exporters' the logging exporter has been deprecated, use the debug exporter instead
```

**解决方案**：
修改 `otel-collector-config.yaml`：
```yaml
exporters:
  debug:              # 不是 logging
    verbosity: detailed
  prometheus:
    endpoint: "0.0.0.0:8889"
```

**经验**：OpenTelemetry 更新频繁，要及时关注弃用警告。

#### 挑战 4：Prometheus Remote Write 404 错误

**问题**：
```
failed to send WriteRequest to remote endpoint
status_code: 404, status: "404 Not Found"
error: "remote write receiver needs to be enabled with --web.enable-remote-write-receiver"
```

**解决方案**：
在 `docker-compose.yml` 中添加启动参数：
```yaml
prometheus:
  command:
    - '--web.enable-remote-write-receiver'  # 关键！
```

**后续优化**：
改用 scrape 方式（更稳定）：
```yaml
# OTEL Collector 配置
exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"

# Prometheus 配置
scrape_configs:
  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8889']
```

**经验**：Scrape 方式比 remote write 更可靠，推荐使用。

### 第三阶段：数据收集验证

#### 挑战 5：环境变量配置困惑

**问题**：
- 在终端 A 中设置环境变量
- 在终端 B 中启动 Claude Code
- 结果：环境变量不生效！

**解决方案**：
```bash
# ✅ 正确做法：在同一终端中
source ~/otel-docker/test-claude-env.sh
claude

# ❌ 错误做法：分开在不同终端
# 终端 1: source ~/otel-docker/test-claude-env.sh
# 终端 2: claude  ← 环境变量不会传递！
```

**经验**：环境变量只在设置它的终端窗口中有效。

### 第四阶段：Dashboard 配置

#### 挑战 6：指标名称不匹配

**问题**：
- Dashboard 中查询：`claude_code_session_count_total`
- 实际指标：`claude_code_active_time_seconds_total`
- 结果：查询失败，没有数据

**发现的实际指标**：
```promql
claude_code_active_time_seconds_total    # 活跃时间
claude_code_cost_usage_USD_total         # 成本
claude_code_token_usage_tokens_total     # Token 使用
```

**解决方案**：
更新 Dashboard 查询使用正确的指标名称：
```json
{
  "targets": [
    {
      "expr": "claude_code_token_usage_tokens_total"
    }
  ]
}
```

**经验**：指标名称必须完全匹配，大小写敏感！

## 🚀 快速开始

### 前置要求

- macOS 系统
- OrbStack 或 Docker Desktop
- Claude Code CLI 已安装
- Homebrew（用于安装工具）

### 5 分钟快速部署

```bash
# 1. 进入项目目录
cd ~/otel-docker

# 2. 启动监控栈
docker-compose up -d

# 3. 验证服务状态
docker-compose ps

# 4. 配置 Claude Code（在新终端中）
source ~/otel-docker/test-claude-env.sh
claude

# 5. 访问监控界面
open http://localhost:3000  # Grafana
```

### 访问地址

| 服务 | URL | 凭据 |
|------|-----|------|
| **Grafana** | http://localhost:3000 | admin/admin |
| **Prometheus** | http://localhost:9090 | - |
| **Jaeger** | http://localhost:16686 | - |
| **Dashboard** | http://localhost:3000/d/claude-code-dashboard/ | - |

## 📊 成功收集的指标

### 当前可用的指标

| 指标名称 | 描述 | 单位 |
|---------|------|------|
| `claude_code_active_time_seconds_total` | 活跃时间总计 | 秒 |
| `claude_code_cost_usage_USD_total` | 成本总计 | 美元 |
| `claude_code_token_usage_tokens_total` | Token 使用总数 | tokens |

### Dashboard 面板

1. **Active Time (seconds)** - 显示总活跃时间
2. **Total Cost (USD)** - 显示累计成本
3. **Total Tokens** - 显示 Token 使用总数
4. **Token Usage Over Time** - Token 使用趋势图
5. **Cost Over Time** - 成本趋势图

所有面板每 10 秒自动刷新。

## 🛠️ 工具和脚本

### 诊断工具

```bash
# 完整诊断
./diagnose-full.sh

# 快速检查
./check-metrics.sh

# 实时监控
./monitor.sh
```

### 环境变量配置

```bash
# 临时配置（推荐）
source ~/otel-docker/test-claude-env.sh

# 永久配置（添加到 ~/.zshrc）
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

## 📚 完整文档索引

### 核心文档

| 文档 | 说明 |
|------|------|
| **[README.md](./README.md)** | 本文档 - 项目概览和快速开始 |
| **[DEPLOYMENT_SUMMARY.md](./DEPLOYMENT_SUMMARY.md)** | 完整部署总结 |
| **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** | 详细部署指南（博客风格） |
| **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** | 故障排查完整指南 |
| **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** | 项目结构说明 |

### 使用指南

| 文档 | 说明 |
|------|------|
| **[CREATE_MANUAL_DASHBOARD.md](./CREATE_MANUAL_DASHBOARD.md)** | 手动创建 Grafana 面板 |
| **[VIEW_DATA_IN_GRAFANA.md](./VIEW_DATA_IN_GRAFANA.md)** | 在 Grafana 中查看数据 |
| **[DASHBOARD_FIX.md](./DASHBOARD_FIX.md)** | Dashboard 修复说明 |
| **[QUICKSTART.md](./QUICKSTART.md)** | 快速开始指南 |

## 💡 经验总结和最佳实践

### 成功要素

1. **逐步验证**
   - 每完成一步就验证一次
   - 不要等到最后才测试

2. **查看日志**
   - 遇到问题首先查看容器日志
   - 使用 `docker-compose logs -f [service]`

3. **使用诊断工具**
   - 利用脚本快速定位问题
   - 不要手动逐个检查

4. **保持耐心**
   - 配置调试需要时间
   - 每个问题都有解决方案

### 常见陷阱

1. **环境变量传递问题**
   - ❌ 在不同终端设置和使用
   - ✅ 在同一终端设置和使用

2. **指标名称大小写**
   - ❌ `claude_code_token_usage_total`
   - ✅ `claude_code_token_usage_tokens_total`

3. **时间范围设置**
   - ❌ 使用太短的时间范围
   - ✅ 使用至少 "Last 1 hour"

4. **容器重启时机**
   - ❌ 修改配置后不重启容器
   - ✅ 修改配置后重启相关容器

### 性能优化建议

1. **使用国内镜像源**
   - 大幅提高镜像拉取速度
   - 解决网络访问问题

2. **选择轻量级运行时**
   - OrbStack 比 Docker Desktop 更轻量
   - 启动更快，资源占用更少

3. **合理设置刷新间隔**
   - Dashboard 设置 10 秒刷新
   - 避免过于频繁的查询

## 🔧 配置文件说明

### docker-compose.yml

- 使用国内镜像源 `docker.m.daocloud.io`
- Prometheus 启用 remote write receiver
- 配置数据持久化 volumes

### otel-collector-config.yaml

- 使用 `debug` exporter（不是 `logging`）
- 配置 `prometheus` exporter 用于 scrape
- 批处理 pipeline 配置

### prometheus.yml

- 配置从 otel-collector:8889 抓取数据
- 15 秒抓取间隔
- 评估间隔 15 秒

### grafana/dashboards/

- 自动配置 Prometheus 数据源
- 自动加载 Claude Code Dashboard
- 使用正确的指标名称

## 📊 Prometheus 查询示例

### 基础查询

```promql
# 查看 Token 使用量
claude_code_token_usage_tokens_total

# 查看成本
claude_code_cost_usage_USD_total

# 查看活跃时间
claude_code_active_time_seconds_total
```

### 高级查询

```promql
# Token 使用率（每秒）
rate(claude_code_token_usage_tokens_total[5m])

# 成本率（美元/秒）
rate(claude_code_cost_usage_USD_total[5m])

# 总 Token
sum(claude_code_token_usage_tokens_total)

# 活跃时间率
rate(claude_code_active_time_seconds_total[5m])
```

## 🐛 故障排查

### 问题：没有指标数据

**检查清单**：
1. 环境变量是否设置？
   ```bash
   env | grep OTEL
   ```
2. Claude Code 是否在运行？
3. OTEL Collector 是否正常？
   ```bash
   docker-compose logs otel-collector
   ```
4. Prometheus 是否有数据？
   访问 http://localhost:9090 查询指标

### 问题：Dashboard 显示 No Data

**解决步骤**：
1. 检查时间范围（使用 "Last 1 hour"）
2. 验证数据源连接
3. 在 Explore 中测试查询
4. 检查指标名称是否正确

### 问题：容器启动失败

**解决步骤**：
1. 查看容器日志：`docker-compose logs [service]`
2. 检查端口占用：`lsof -i :[port]`
3. 验证配置文件语法
4. 完全重启：`docker-compose down && docker-compose up -d`

## 📝 开发历程

### 时间线

- **2026-03-17**: 项目初始化，遇到网络问题
- **2026-03-17**: 配置镜像加速，服务启动
- **2026-03-17**: 解决 exporter 弃用问题
- **2026-03-17**: 修复 Prometheus remote write 问题
- **2026-03-18**: 修复 Dashboard 指标名称
- **2026-03-18**: 数据成功收集，Dashboard 正常显示
- **2026-03-18**: 完善文档，提交到 GitHub

### 提交历史

```
08fa5a0 fix: 修复 OpenTelemetry 监控栈配置和 Dashboard 指标名称
2b87656 feat: 初始化 OpenTelemetry 监控栈项目
```

## 🌟 项目亮点

1. **完整的部署历程** - 从零到成功的完整记录
2. **详细的故障排查** - 每个问题都有解决方案
3. **实用的工具脚本** - 简化日常操作
4. **完善的文档体系** - 覆盖所有使用场景
5. **实际可用** - 真正解决了监控需求

## 🚀 下一步计划

- [ ] 添加更多 Grafana 面板
- [ ] 配置告警规则
- [ ] 添加成本预算告警
- [ ] 优化查询性能
- [ ] 添加更多维度分析

## 🔗 相关资源

- [Claude Code 监控文档](https://code.claude.com/docs/zh-CN/monitoring-usage)
- [OpenTelemetry 官方文档](https://opentelemetry.io/docs/)
- [Prometheus 查询语言](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana 官方文档](https://grafana.com/docs/)
- [OrbStack 官网](https://orbstack.dev/)

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 💬 反馈

如有问题或建议，请：
1. 查看完整文档：[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
2. 运行诊断脚本：`./diagnose-full.sh`
3. 提交 GitHub Issue

---

## 🎉 总结

这个项目不仅是监控工具的部署记录，更是一次完整的**学习和实践过程**。

### 我们学到了什么？

1. **OpenTelemetry 的实际应用**
   - 如何配置和部署
   - 常见问题和解决方案

2. **监控系统的架构设计**
   - 数据流的配置
   - 组件间的协作

3. **问题排查的方法论**
   - 系统化的诊断流程
   - 逐步验证的重要性

4. **文档和知识管理**
   - 完整记录部署过程
   - 创建可复用的指南

### 适用场景

这个项目适合：
- ✅ 想要监控 Claude Code 使用的开发者
- ✅ 学习 OpenTelemetry 的初学者
- ✅ 需要部署监控栈的运维人员
- ✅ 研究可观测性的技术团队

**享受监控的乐趣！** 🎉

如有问题，请查看完整文档或提交 Issue。
