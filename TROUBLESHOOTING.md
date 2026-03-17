# 🔍 Claude Code 监控故障排查指南

## 问题：在 Grafana 中看不到指标

### ✅ 检查清单

#### 1️⃣ 确认环境变量已正确设置

在新终端中运行：

```bash
# 检查环境变量
env | grep -E "CLAUDE_CODE|OTEL_"
```

**预期输出：**
```
CLAUDE_CODE_ENABLE_TELEMETRY=1
OTEL_METRICS_EXPORTER=otlp
OTEL_LOGS_EXPORTER=otlp
OTEL_EXPORTER_OTLP_PROTOCOL=grpc
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

**如果没有输出**：说明环境变量没有设置，运行：

```bash
source ~/otel-docker/test-claude-env.sh
```

#### 2️⃣ 验证 Claude Code 是否在使用环境变量

启动 Claude Code 前，确保环境变量已设置：

```bash
# 1. 设置环境变量
source ~/otel-docker/test-claude-env.sh

# 2. 验证（应该能看到环境变量）
env | grep OTEL

# 3. 启动 Claude Code
claude
```

#### 3️⃣ 测试 OTEL Collector 连接

在 Claude Code 运行的同时，在另一个终端运行：

```bash
# 实时监控 OTEL Collector 日志
cd ~/otel-docker
docker-compose logs -f otel-collector
```

**预期**：当 Claude Code 执行操作时，应该能看到日志活动。

#### 4️⃣ 检查 Prometheus 是否收到数据

```bash
# 方法 1: 使用检查脚本
~/otel-docker/check-metrics.sh

# 方法 2: 直接查询 Prometheus API
curl -s 'http://localhost:9090/api/v1/label/__name__/values' | python3 -c "
import sys, json
labels = json.load(sys.stdin)['data']
claude_metrics = [l for l in labels if 'claude' in l.lower()]
print('Claude Code 指标:')
for metric in claude_metrics:
    print(f'  {metric}')
"
```

#### 5️⃣ 验证 Grafana 数据源配置

1. 打开 http://localhost:3000
2. 登录（admin/admin）
3. 点击齿轮图标 ⚙️ → "Data sources"
4. 找到 "Prometheus" 数据源
5. 点击 "Test" 按钮

**预期**：应该显示 "Data source is working"

### 🔧 常见问题和解决方案

#### 问题 A: 环境变量没有设置

**症状**：`env | grep OTEL` 没有输出

**解决方案**：

```bash
# 临时设置（当前终端有效）
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317

# 或使用脚本
source ~/otel-docker/test-claude-env.sh
```

#### 问题 B: OTEL Collector 没有收到数据

**症状**：`docker-compose logs otel-collector` 没有新日志

**可能原因**：
1. 环境变量没有在 Claude Code 启动前设置
2. Claude Code 还没有执行任何操作

**解决方案**：
1. 确保先设置环境变量，再启动 Claude Code
2. 在 Claude Code 中执行一些操作（编辑文件、运行命令等）
3. 等待至少 10 秒（指标导出间隔）

#### 问题 C: Prometheus 没有数据

**症状**：Grafana 数据源正常，但查询不到指标

**检查**：
```bash
# 查看 Prometheus 目标
curl -s http://localhost:9090/api/v1/targets | python3 -m json.tool

# 直接查询指标
curl -s 'http://localhost:9090/api/v1/query?query=up' | python3 -m json.tool
```

#### 问题 D: Grafana 数据源配置错误

**症状**：Grafana 中 "Test" 按钮失败

**解决方案**：
1. 数据源 URL 应该是：`http://prometheus:9090`
2. 不是 `http://localhost:9090`
3. 访问模式：Server (default)

### 🧪 快速测试流程

完整的测试流程：

```bash
# 终端 1: 启动监控栈（如果还没启动）
cd ~/otel-docker
docker-compose up -d

# 终端 2: 设置环境变量并启动 Claude Code
source ~/otel-docker/test-claude-env.sh
claude

# 在 Claude Code 中执行一些操作
# 例如：让 AI 创建一个文件、运行一些命令等

# 终端 3: 监控日志
cd ~/otel-docker
docker-compose logs -f otel-collector

# 终端 4: 检查指标
watch -n 5 '~/otel-docker/check-metrics.sh'
```

### 📊 验证指标是否正常工作

如果一切正常，在 Prometheus 中执行以下查询应该有数据：

```promql
# 查看所有 Claude Code 指标
{__name__=~"claude_.*"}

# Token 使用量
claude_code_token_usage_total

# 成本
claude_code_cost_usage_total

# 会话计数
claude_code_session_count_total
```

### 🎯 调试技巧

#### 实时监控 OTEL 流量

```bash
# 使用 tcpdump 监控 OTLP 流量（需要 sudo）
sudo tcpdump -i lo port 4317 -n

# 或使用 netstat
netstat -an | grep 4317
```

#### 手动发送测试数据到 OTEL Collector

```bash
# 发送简单的测试数据
echo '{"test": "data"} | curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d @-
```

#### 查看 Prometheus 抓取目标

访问：http://localhost:9090/targets

应该看到 `otel-collector` 目标状态为 "UP"。

### 📝 环境变量永久配置

为了避免每次都设置，可以添加到 shell 配置：

```bash
# 添加到 ~/.zshrc
cat >> ~/.zshrc << 'EOF'

# Claude Code OpenTelemetry 监控
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_LOGS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=grpc
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
EOF

# 重新加载配置
source ~/.zshrc
```

### 🆘 仍然无法工作？

1. **检查服务状态**：
   ```bash
   cd ~/otel-docker
   docker-compose ps
   ```

2. **查看所有服务日志**：
   ```bash
   docker-compose logs
   ```

3. **重启所有服务**：
   ```bash
   docker-compose restart
   ```

4. **完全重置**（会删除所有数据）：
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

### 📞 获取帮助

如果以上步骤都无法解决问题，请提供以下信息：

1. `docker-compose ps` 输出
2. `docker-compose logs otel-collector` 输出
3. `env | grep OTEL` 输出
4. Prometheus UI 截图
5. Grafana 数据源配置截图

---

**记住**：监控数据只有在 Claude Code **执行操作后**才会出现！
