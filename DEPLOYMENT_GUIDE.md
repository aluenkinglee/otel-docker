# 在本地部署 OpenTelemetry 监控 Claude Code 完全指南

> 作者：Claude Code & AI Assistant
> 日期：2026-03-17
> 标签：#OpenTelemetry #ClaudeCode #监控 #Docker #OrbStack

## 📖 目录

- [为什么需要监控 Claude Code？](#为什么需要监控-claude-code)
- [OpenTelemetry 简介](#opentelemetry-简介)
- [前置要求](#前置要求)
- [部署架构](#部署架构)
- [详细部署步骤](#详细部署步骤)
- [配置 Claude Code](#配置-claude-code)
- [使用指南](#使用指南)
- [故障排查](#故障排查)
- [总结](#总结)

---

## 为什么需要监控 Claude Code？

作为一名开发者，我经常使用 Claude Code 来辅助编程。但是，我经常会有以下疑问：

- 💰 **这个月我在 Claude Code 上花了多少钱？**
- 🔢 **我总共使用了多少 tokens？**
- 📊 **我的使用趋势是什么？**
- 🛠️ **我最常用哪些工具？**
- ⚡ **Claude Code 的性能如何？**

Claude Code 官方提供了 OpenTelemetry 支持，可以很好地解决这些问题！

## OpenTelemetry 简介

[OpenTelemetry](https://opentelemetry.io/) (简称 OTel) 是一个开源的可观测性框架，用于生成、收集、分析和导出遥测数据（指标、日志和分布式追踪）。它是云原生计算基金会（CNCF）的孵化项目。

### 为什么选择 OpenTelemetry？

- 🔓 **开源免费**：无需付费，完全开源
- 🌐 **厂商无关**：不绑定任何特定厂商
- 🔧 **标准化**：业界标准，广泛支持
- 📊 **全面可观测性**：指标、日志、追踪三位一体

## 前置要求

在开始部署之前，请确保您有以下环境：

### 必需组件

- ✅ **macOS 操作系统**（本指南基于 macOS）
- ✅ **OrbStack**（Docker Desktop 的轻量级替代品）
- � **Claude Code CLI** 已安装
- � **Homebrew**（用于安装工具）

### 可选组件

- Node.js 或 Bun（用于运行某些工具）
- gh CLI（用于 GitHub 操作）

## 部署架构

我们的 OpenTelemetry 监控栈包含以下组件：

```
┌─────────────────┐    OTLP    ┌──────────────────┐
│   Claude Code   │ ──────────>│ OTEL Collector   │
│                 │  (gRPC/HTTP)│                  │
└─────────────────┘             └────────┬─────────┘
                                          │
                                          ↓
                            ┌──────────────────────────┐
                            │   Prometheus (指标存储)  │
                            └────────────┬─────────────┘
                                         │
                                         ↓
                            ┌──────────────────────────┐
                            │   Grafana (可视化)       │
                            └──────────────────────────┘
```

### 组件说明

| 组件 | 版本 | 端口 | 功能 |
|------|------|------|------|
| **OTEL Collector** | contrib:latest | 4317, 4318 | 接收和处理遥测数据 |
| **Prometheus** | latest | 9090 | 时序数据库，存储指标 |
| **Grafana** | latest | 3000 | 可视化仪表板 |
| **Jaeger** | all-in-one | 16686 | 分布式追踪（可选） |

## 详细部署步骤

### Step 1: 安装 OrbStack

如果还没有安装 OrbStack：

```bash
# 使用 Homebrew 安装
brew install orbstack

# 启动 OrbStack
orb start
```

> 💡 **为什么选择 OrbStack？**
> OrbStack 是 Docker Desktop 的轻量级替代品，启动速度快，资源占用少，非常适合本地开发。

### Step 2: 创建项目目录

```bash
cd ~
mkdir otel-docker
cd otel-docker
```

### Step 3: 配置 Docker 镜像加速

由于网络原因，中国大陆地区需要配置 Docker 镜像加速：

```bash
# 创建配置目录
mkdir -p ~/.docker

# 配置镜像加速器
cat > ~/.docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live",
    "https://hub.rat.dev",
    "https://docker.anyhub.us.kg",
    "https://docker.chenby.cn",
    "https://docker.awsl9527.cn"
  ],
  "dns": ["8.8.8.8", "114.114.114.114"]
}
EOF

# 重启 OrbStack
orb restart
```

### Step 4: 创建 docker-compose.yml

创建完整的 Docker Compose 配置文件：

```yaml
services:
  # OpenTelemetry Collector
  otel-collector:
    image: docker.m.daocloud.io/otel/opentelemetry-collector-contrib:latest
    container_name: otel-collector
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml:ro
    ports:
      - "4317:4317"   # OTLP gRPC receiver
      - "4318:4318"   # OTLP HTTP receiver
      - "8888:8888"   # Prometheus metrics exporter
    depends_on:
      - prometheus
    networks:
      - otel-network

  # Prometheus
  prometheus:
    image: docker.m.daocloud.io/prom/prometheus:latest
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    ports:
      - "9090:9090"
    networks:
      - otel-network

  # Grafana
  grafana:
    image: docker.m.daocloud.io/grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana-data:/var/lib/grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    networks:
      - otel-network

  # Jaeger (可选)
  jaeger:
    image: docker.m.daocloud.io/jaegertracing/all-in-one:latest
    container_name: jaeger
    environment:
      - COLLECTOR_OTLP_ENABLED=true
    ports:
      - "16686:16686" # Jaeger UI
      - "14250:14250"
    networks:
      - otel-network

volumes:
  prometheus-data:
  grafana-data:

networks:
  otel-network:
    driver: bridge
```

### Step 5: 创建 OTEL Collector 配置

创建 `otel-collector-config.yaml`：

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  prometheusremotewrite:
    endpoint: http://prometheus:9090/api/v1/write
    tls:
      insecure: true

  debug:
    verbosity: detailed

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheusremotewrite, debug]

    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]

    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
```

> ⚠️ **注意**：旧版本使用 `logging` exporter，但已弃用。新版本应使用 `debug` exporter。

### Step 6: 创建 Prometheus 配置

创建 `prometheus.yml`：

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'otel-collector'
    static_configs:
      - targets: ['otel-collector:8888']
```

### Step 7: 启动监控栈

```bash
# 启动所有服务
docker-compose up -d

# 查看容器状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### Step 8: 验证部署

访问以下 URL 验证服务是否正常：

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Jaeger**: http://localhost:16686

## 配置 Claude Code

### 临时配置（推荐先测试）

在当前终端设置环境变量：

```bash
# 启用遥测
export CLAUDE_CODE_ENABLE_TELEMETRY=1

# 配置导出器
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp

# 配置 OTLP 端点
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# （可选）减少导出间隔用于调试
export OTEL_METRIC_EXPORT_INTERVAL=10000  # 10秒
export OTEL_LOGS_EXPORT_INTERVAL=5000     # 5秒
```

### 永久配置

编辑 `~/.zshrc`，添加上述环境变量：

```bash
echo 'export CLAUDE_CODE_ENABLE_TELEMETRY=1' >> ~/.zshrc
echo 'export OTEL_METRICS_EXPORTER=otlp' >> ~/.zshrc
echo 'export OTEL_LOGS_EXPORTER=otlp' >> ~/.zshrc
echo 'export OTEL_EXPORTER_OTLP_PROTOCOL=grpc' >> ~/.zsh_export
echo 'export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317' >> ~/.zshrc
source ~/.zshrc
```

### 环境变量说明

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | 启用遥测（必需） | - |
| `OTEL_METRICS_EXPORTER` | 指标导出器 | - |
| `OTEL_LOGS_EXPORTER` | 日志导出器 | - |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | OTLP 协议 | grpc |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP 端点 | http://localhost:4317 |
| `OTEL_METRIC_EXPORT_INTERVAL` | 指标导出间隔（毫秒） | 60000 |
| `OTEL_LOGS_EXPORT_INTERVAL` | 日志导出间隔（毫秒） | 5000 |

## 使用指南

### 1. 开始监控

配置好环境变量后，正常使用 Claude Code：

```bash
claude
```

所有使用数据会自动发送到 OpenTelemetry Collector。

### 2. 在 Prometheus 中查询指标

访问 http://localhost:9090，尝试以下查询：

```promql
# 会话计数率
rate(claude_code_session_count_total[5m])

# Token 使用率（按类型分组）
rate(claude_code_token_usage_total[5m]) by (type)

# 成本累计
increase(claude_code_cost_usage_total[1h])

# 代码行数变化
increase(claude_code_lines_of_code_count_total[1h]) by (type)
```

### 3. 在 Grafana 中创建仪表板

1. 访问 http://localhost:3000
2. 登录（admin/admin）
3. 添加 Prometheus 数据源：http://prometheus:9090
4. 创建新的仪表板
5. 添加可视化面板

### 4. 可用的指标

根据 Claude Code 官方文档，以下指标会被收集：

| 指标名称 | 描述 | 单位 |
|---------|------|------|
| `claude_code_session_count_total` | 启动的 CLI 会话计数 | count |
| `claude_code_lines_of_code_count_total` | 修改的代码行数 | count |
| `claude_code_pull_request_count_total` | 创建的拉取请求数 | count |
| `claude_code_commit_count_total` | 创建的 git 提交数 | count |
| `claude_code_cost_usage_total` | Claude Code 会话的成本 | USD |
| `claude_code_token_usage_total` | 使用的令牌数 | tokens |
| `claude_code_code_edit_tool_decision_total` | 代码编辑工具决策 | count |
| `claude_code_active_time_total` | 总活跃时间 | s |

## 故障排查

### 问题 1: Docker 无法拉取镜像

**症状**: `Error response from daemon: Get "https://registry-1.docker.io/v2": EOF`

**解决方案**: 配置国内镜像加速器（参见 Step 3）

### 问题 2: otel-collector 启动失败

**症状**: 容器反复重启，日志显示 `logging exporter has been deprecated`

**解决方案**: 修改配置文件，将 `logging` 改为 `debug`：

```yaml
exporters:
  debug:              # 不是 logging
    verbosity: detailed
```

### 问题 3: Claude Code 没有发送数据

**检查步骤**:

1. 验证环境变量是否设置：
   ```bash
   env | grep CLAUDE_CODE
   env | grep OTEL
   ```

2. 检查 OTEL Collector 日志：
   ```bash
   docker-compose logs otel-collector
   ```

3. 测试连接：
   ```bash
   curl http://localhost:4317
   ```

### 问题 4: Grafana 无法连接 Prometheus

**解决方案**:
1. 确认 Prometheus 正常运行：`docker-compose ps prometheus`
2. 在 Grafana 中配置数据源为：`http://prometheus:9090`

## 总结

通过本次部署，我们成功实现了：

✅ **完整的监控栈**：OpenTelemetry Collector + Prometheus + Grafana
✅ **Docker 容器化部署**：一键启动，易于管理
✅ **国内镜像优化**：解决了网络访问问题
✅ **全面的指标收集**：成本、tokens、使用趋势等
✅ **可视化仪表板**：直观的数据展示

### 关键收获

1. **OrbStack 比 Docker Desktop 更轻量**：启动快，资源占用少
2. **国内镜像加速很重要**：大大提高了镜像拉取速度
3. **OpenTelemetry 配置需要更新**：注意 `logging` → `debug` 的变化
4. **环境变量配置是关键**：确保正确设置才能收集数据

### 下一步

- 📊 **创建自定义 Grafana 仪表板**：根据个人需求定制
- 🚨 **配置告警规则**：异常使用或成本超标时通知
- 📈 **长期数据分析**：了解使用趋势和优化方向
- 🔗 **团队协作**：多人共享监控数据

## 参考资源

- [Claude Code 官方监控文档](https://code.claude.com/docs/zh-CN/monitoring-usage)
- [OpenTelemetry 官方文档](https://opentelemetry.io/docs/)
- [Prometheus 查询语言](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana 文档](https://grafana.com/docs/)
- [OrbStack 官网](https://orbstack.dev/)

---

**祝您监控愉快！** 🎉

如有问题，欢迎在评论区讨论或提交 Issue。
