# 快速开始指南

## 📋 前提条件

- 已安装 Docker Desktop
- 已安装 docker-compose
- 已安装 Claude Code CLI

## 🚀 三步快速启动

### 步骤 1: 启动监控栈

```bash
cd /Users/aluen/otel-docker
./start.sh
```

### 步骤 2: 配置 Claude Code

**选项 A: 临时配置（推荐用于测试）**

在当前终端中运行：

```bash
source claude-code-env.sh
```

**选项 B: 永久配置**

将以下内容添加到 `~/.zshrc` 或 `~/.bashrc`：

```bash
# 启用 Claude Code 遥测
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

然后重新加载：

```bash
source ~/.zshrc
```

### 步骤 3: 验证安装

```bash
./verify.sh
```

## 🎯 开始使用

1. **打开新的终端窗口**（或使用配置了环境变量的当前窗口）

2. **启动 Claude Code**：

```bash
claude
```

3. **执行一些操作**：
   - 让 Claude 编辑一个文件
   - 创建一个 git commit
   - 运行一些命令

4. **查看监控数据**：
   - 打开 http://localhost:3000 (Grafana)
   - 登录：admin/admin
   - 选择 "Claude Code Dashboard"

## 📊 查看数据

### Grafana 仪表板

访问 http://localhost:3000

预配置的仪表板包含：
- 会话计数（最近 1 小时）
- Token 使用量（最近 1 小时）
- 成本统计（最近 1 小时）
- 代码行数变化（最近 1 小时）

### Prometheus 查询

访问 http://localhost:9090

常用查询：

```promql
# 所有会话
claude_code_session_count_total

# Token 使用率
rate(claude_code_token_usage_total[5m])

# 成本累计
increase(claude_code_cost_usage_total[1h])

# 按类型分组的 Token 使用
rate(claude_code_token_usage_total[5m]) by (type)

# 代码行数变化
increase(claude_code_lines_of_code_count_total[1h]) by (type)
```

## 🔧 故障排查

### 问题：Grafana 没有数据

**解决方案：**

1. 检查 Claude Code 环境变量：
```bash
env | grep OTEL
```

2. 验证 Collector 日志：
```bash
docker-compose logs -f otel-collector
```

3. 在 Prometheus 中检查是否有数据：
```bash
curl 'http://localhost:9090/api/v1/label/__name__/values' | grep claude
```

### 问题：端口被占用

**解决方案：**

编辑 `docker-compose.yml`，修改端口映射：

```yaml
ports:
  - "新端口:容器端口"
```

然后重启：

```bash
docker-compose down
./start.sh
```

### 问题：Docker 容器无法启动

**解决方案：**

1. 检查 Docker 是否运行：
```bash
docker info
```

2. 查看容器日志：
```bash
docker-compose logs
```

3. 重建容器：
```bash
docker-compose down -v
./start.sh
```

## 🛑 停止服务

```bash
./stop.sh
```

要完全删除所有数据（包括历史数据）：

```bash
docker-compose down -v
```

## 📝 下一步

- [ ] 自定义 Grafana 仪表板
- [ ] 设置 Prometheus 告警规则
- [ ] 配置 Jaeger 进行分布式追踪
- [ ] 添加更多指标和图表
- [ ] 配置数据保留策略

## 📚 更多信息

- 查看 [README.md](./README.md) 了解详细配置
- 查看 [Claude Code 监控文档](https://code.claude.com/docs/zh-CN/monitoring-usage)
