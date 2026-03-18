# 🔧 Claude Code Dashboard 修复指南

## 🐛 问题原因

Grafana Dashboard 中使用了**错误的指标名称**，导致查询不到数据。

### 错误的指标名称（Dashboard 中）：
```promql
claude_code_session_count_total         # ❌ 不存在
claude_code_token_usage_total           # ❌ 名称不对
claude_code_cost_usage_total            # ❌ 名称不对
claude_code_lines_of_code_count_total   # ❌ 不存在
```

### 正确的指标名称（Prometheus 中）：
```promql
claude_code_active_time_seconds_total     # ✅ 存在
claude_code_token_usage_tokens_total     # ✅ 存在
claude_code_cost_usage_USD_total         # ✅ 存在
```

## ✅ 修复内容

### 修复的 Dashboard 包含以下面板：

1. **Active Time (seconds)** - 活跃时间
   - 查询：`claude_code_active_time_seconds_total`
   - 显示：总活跃秒数

2. **Total Cost (USD)** - 总成本
   - 查询：`claude_code_cost_usage_USD_total`
   - 显示：累计成本（美元）

3. **Total Tokens** - Token 总数
   - 查询：`sum(claude_code_token_usage_tokens_total)`
   - 显示：Token 使用总数

4. **Token Usage Over Time** - Token 使用趋势
   - 查询：`claude_code_token_usage_tokens_total`
   - 显示：按 type 分组的时间序列图

5. **Cost Over Time** - 成本趋势
   - 查询：`claude_code_cost_usage_USD_total`
   - 显示：成本的时间序列图

## 🎯 验证修复

### 步骤 1：访问修复后的 Dashboard

打开浏览器访问：
```
http://localhost:3000/d/claude-code-dashboard/claude-code-dashboard?orgId=1
```

### 步骤 2：验证数据

应该能看到：
- ✅ Active Time 显示具体的秒数
- ✅ Total Cost 显示美元金额
- ✅ Total Tokens 显示 token 数量
- ✅ 时间序列图显示趋势

### 步骤 3：如果仍然没有数据

**检查时间范围**：
- 点击右上角的时间选择器
- 选择 "Last 1 hour" 或更大范围
- 确保覆盖了您使用 Claude Code 的时间段

**检查数据源**：
- 点击齿轮图标 → Data sources → Prometheus
- 点击 "Test" 按钮
- 应该显示 "Data source is working"

**手动查询**：
- 在 Grafana Explore 中测试查询
- 输入：`claude_code_token_usage_tokens_total`
- 点击 "Run query"
- 如果有数据，说明查询正确

## 🔄 自动重新加载

Dashboard 已配置为每 10 秒自动刷新：
```json
"refresh": "10s"
```

## 📊 额外的有用查询

### 在 Grafana Explore 中尝试：

```promql
# 1. 所有 Claude Code 指标
{__name__=~".*claude.*"}

# 2. Token 使用率（每秒）
rate(claude_code_token_usage_tokens_total[5m])

# 3. 成本率（每秒美元）
rate(claude_code_cost_usage_USD_total[5m])

# 4. 活跃时间率（每秒）
rate(claude_code_active_time_seconds_total[5m])

# 5. 按类型分组的 Token
sum(claude_code_token_usage_tokens_total) by (type)
```

## 🎨 自定义 Dashboard

如果您想添加更多面板：

1. 打开 Dashboard
2. 点击右上角 "+" → "Add panel"
3. 选择 "Prometheus" 数据源
4. 输入查询（参考上面的有用查询）
5. 配置可视化类型
6. 点击 "Apply" 和 "Save"

## 💡 提示

- **指标名称很重要**：确保使用正确的指标名称
- **时间范围**：调整时间范围以查看数据
- **自动刷新**：Dashboard 每 10 秒自动更新
- **数据验证**：先在 Explore 中测试查询，再添加到 Dashboard

---

修复完成！现在 Dashboard 应该能正确显示数据了。🎉
