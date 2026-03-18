# 🎨 在 Grafana 中查看 Claude Code 数据

## ✅ 好消息：数据已经在 Prometheus 中！

Prometheus 中现在有以下指标：
- `claude_code_active_time_seconds_total`
- `claude_code_cost_usage_USD_total`
- `claude_code_token_usage_tokens_total`

## 🎯 方法 1: 使用 Grafana Explore（最简单）

### 步骤：

1. **打开 Grafana Explore**
   - 访问：http://localhost:3000/explore
   - 登录：admin / admin

2. **选择数据源**
   - 确保左上角选择了 "Prometheus"

3. **输入查询语句**

   **查询 1: Token 使用量**
   ```promql
   claude_code_token_usage_tokens_total
   ```
   - 点击 "Run query"
   - 应该看到数据！

   **查询 2: 成本统计**
   ```promql
   claude_code_cost_usage_USD_total
   ```
   - 点击 "Run query"
   - 显示总成本

   **查询 3: 按 type 分组的 Token 使用**
   ```promql
   sum(claude_code_token_usage_tokens_total) by (type)
   ```
   - 显示不同类型的 token 使用量

4. **调整时间范围**
   - 右上角选择时间范围（例如 Last 1 hour）
   - 或使用 "Last 5 minutes" 查看最近的数据

## 🎯 方法 2: 创建新仪表板

### 步骤：

1. **创建新仪表板**
   - 点击左上角 "+" 号
   - 选择 "New dashboard"
   - 点击 "Add visualization"

2. **配置面板**

   **面板 1: Token 使用量（表格）**
   - 数据源：Prometheus
   - 查询：`claude_code_token_usage_tokens_total`
   - 可视化：Table
   - 点击 "Run query"
   - 点击 "Save"

   **面板 2: 成本统计（统计数值）**
   - 数据源：Prometheus
   - 查询：`claude_code_cost_usage_USD_total`
   - 可视化：Stat
   - 单位：Currency USD
   - 点击 "Run query"
   - 点击 "Save"

   **面板 3: 活跃时间（时间序列）**
   - 数据源：Prometheus
   - 查询：`rate(claude_code_active_time_seconds_total[5m])`
   - 可视化：Time series
   - 点击 "Run query"
   - 点击 "Save"

## 🎯 方法 3: 使用 PromQL 查询

### 常用查询语句：

```promql
# 1. 总 Token 使用量
claude_code_token_usage_tokens_total

# 2. 按 type 分组
sum(claude_code_token_usage_tokens_total) by (type)

# 3. Token 使用率
rate(claude_code_token_usage_tokens_total[5m])

# 4. 累计成本
claude_code_cost_usage_USD_total

# 5. 成本率
rate(claude_code_cost_usage_USD_total[5m])

# 6. 活跃时间
claude_code_active_time_seconds_total

# 7. 活跃时间率
rate(claude_code_active_time_seconds_total[5m])
```

## 🔧 故障排查

### 如果在 Grafana Explore 中看不到数据：

1. **检查数据源连接**
   - Configuration → Data sources → Prometheus
   - 点击 "Test" 按钮
   - 应该显示 "Data source is working"

2. **检查时间范围**
   - 确保时间范围覆盖了数据产生的时间
   - 尝试使用 "Last 1 hour" 或更大范围

3. **验证查询语法**
   - 在 Prometheus UI (http://localhost:9090) 中先测试查询
   - 确认查询能返回数据后，再在 Grafana 中使用

4. **检查数据刷新**
   - 确保 Grafana 的刷新间隔设置合理
   - 默认是关闭的，可以设置为 10s 或 30s

## 📊 验证数据存在

首先在 Prometheus UI 中验证：

访问：http://localhost:9090/graph

输入查询：
```promql
claude_code_token_usage_tokens_total
```

如果看到数据，说明数据流正常！

然后在 Grafana 中使用相同的查询。

## 💡 提示

- **先在 Prometheus UI 中测试查询**，确认有数据
- **然后在 Grafana Explore 中使用相同的查询**
- **最后再创建仪表板保存常用的查询**

---

**关键点**：数据已经成功收集并在 Prometheus 中了！现在只需要在 Grafana 中正确查询和显示。
