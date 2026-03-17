# 📁 项目结构说明

```
otel-docker/
├── 📄 README.md                 # 项目主文档
├── 📖 DEPLOYMENT_GUIDE.md       # 详细部署指南（博客文章）
├── ⚡ QUICKSTART.md            # 快速开始指南
├── 📂 PROJECT_STRUCTURE.md     # 本文件 - 项目结构说明
│
├── 🐳 docker-compose.yml       # Docker 服务编排配置
├── ⚙️  otel-collector-config.yaml  # OpenTelemetry Collector 配置
├── 📊 prometheus.yml           # Prometheus 配置
│
├── 🎨 grafana/                 # Grafana 配置目录
│   ├── datasources/           # 数据源配置
│   │   └── prometheus.yml     # Prometheus 数据源
│   └── dashboards/            # 仪表板配置
│       ├── dashboards.yml     # 仪表板提供者
│       └── claude-code-dashboard.json  # Claude Code 仪表板
│
├── 🔧 scripts/                 # 实用脚本
│   ├── start.sh              # 启动脚本
│   ├── stop.sh               # 停止脚本
│   └── verify.sh             # 验证脚本
│
└── 🔐 .gitignore              # Git 忽略文件
```

## 📄 文件说明

### 核心文档

| 文件 | 大小 | 说明 |
|------|------|------|
| **README.md** | 4.6KB | 项目主文档，包含功能介绍、快速开始、常用命令 |
| **DEPLOYMENT_GUIDE.md** | 13KB | **重点推荐**：完整的部署指南博客文章，包含详细步骤和故障排查 |
| **QUICKSTART.md** | 3.1KB | 快速开始指南，适合有经验的用户 |
| **PROJECT_STRUCTURE.md** | 本文件 | 项目结构说明 |

### 配置文件

| 文件 | 说明 | 关键配置 |
|------|------|----------|
| **docker-compose.yml** | Docker 服务编排 | 定义 4 个服务（otel-collector, prometheus, grafana, jaeger） |
| **otel-collector-config.yaml** | OTEL Collector 配置 | 接收器、处理器、导出器配置 |
| **prometheus.yml** | Prometheus 配置 | 数据抓取配置 |

### Grafana 配置

| 目录/文件 | 说明 |
|-----------|------|
| `grafana/datasources/` | 数据源自动配置 |
| `grafana/dashboards/` | 仪表板自动加载 |
| `grafana/dashboards/claude-code-dashboard.json` | Claude Code 专用仪表板 |

### 脚本文件

| 脚本 | 权限 | 功能 |
|------|------|------|
| **start.sh** | 可执行 | 一键启动所有服务 |
| **stop.sh** | 可执行 | 一键停止所有服务 |
| **verify.sh** | 可执行 | 验证服务状态和配置 |
| **claude-code-env.sh** | - | Claude Code 环境变量配置 |

## 🚀 快速导航

### 🎯 我想...

- **快速部署** → 查看 [QUICKSTART.md](./QUICKSTART.md)
- **详细了解** → 阅读 [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)
- **了解架构** → 查看上面的架构图
- **故障排查** → 参考 DEPLOYMENT_GUIDE.md 中的"故障排查"章节
- **自定义配置** → 修改相应的 YAML 配置文件

### 📊 核心功能

1. **成本监控** 💰
   - 实时追踪 API 使用成本
   - 查询：`claude_code_cost_usage_total`

2. **Token 统计** 🔢
   - 输入/输出/缓存 token
   - 查询：`claude_code_token_usage_total`

3. **使用分析** 📈
   - 会话计数、代码行数、提交数
   - 查询：`claude_code_session_count_total`

4. **工具使用** 🛠️
   - 最常用的工具和操作
   - 查询：`claude_code_code_edit_tool_decision_total`

## 🔧 配置要点

### 1. Docker 镜像源

所有镜像使用国内加速器 `docker.m.daocloud.io`：

```yaml
image: docker.m.daocloud.io/prom/prometheus:latest
```

### 2. OTEL Collector

- 使用 `debug` exporter（不是已弃用的 `logging`）
- 监听端口：4317 (gRPC), 4318 (HTTP)
- 导出到 Prometheus via Remote Write

### 3. 数据持久化

使用 Docker volumes 持久化数据：

```yaml
volumes:
  prometheus-data:   # Prometheus 时序数据
  grafana-data:      # Grafana 配置和仪表板
```

## 📝 使用建议

### 初次使用

1. 阅读 [QUICKSTART.md](./QUICKSTART.md) 快速上手
2. 运行 `./start.sh` 启动服务
3. 配置 Claude Code 环境变量
4. 访问 Grafana: http://localhost:3000

### 深度定制

1. 阅读 [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) 了解细节
2. 修改配置文件满足个人需求
3. 创建自定义 Grafana 仪表板
4. 配置告警规则

### 生产环境

1. 修改默认密码（admin/admin）
2. 配置数据备份策略
3. 设置资源限制
4. 启用访问控制

## 🎓 学习资源

- [OpenTelemetry 官方文档](https://opentelemetry.io/docs/)
- [Prometheus 查询语言](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana 仪表板指南](https://grafana.com/docs/grafana/latest/dashboards/)
- [Claude Code 监控文档](https://code.claude.com/docs/zh-CN/monitoring-usage)

---

**享受监控的乐趣！** 🎉
