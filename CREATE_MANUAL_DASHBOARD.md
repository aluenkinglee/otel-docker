# 🎨 手动创建 Grafana 面板指南

## 🚀 快速步骤

### 1️⃣ 登录 Grafana

访问：http://localhost:3000
- 用户名：`admin`
- 密码：`admin`

### 2️⃣ 验证数据源

1. 点击左侧菜单的齿轮图标 ⚙️ (Configuration)
2. 点击 "Data sources"
3. 找到 "Prometheus" 数据源
4. 点击 "Test" 按钮

**预期结果**：应该显示 "Data source is working"

如果测试失败：
- URL 应该是：`http://prometheus:9090`
- 访问模式：Server (default)

### 3️⃣ 创建新面板

#### 方法 A: 使用 Explore (推荐，最简单)

1. 点击左侧菜单的 **Explore** 图标 (🔍)
2. 确保左上角选择的是 "Prometheus" 数据源
3. 在查询框中输入以下查询之一：

```promql
# 查询所有 Claude Code 相关指标
{__name__=~"claude_.*"}

# 或查询特定指标
claude_code_token_usage_total

# 或查看会话数
claude_code_session_count_total
```

4. 点击 "Run query" 按钮
5. 如果有数据，你应该看到图表或数据点

#### 方法 B: 创建新仪表板

1. 点击左侧菜单的 **+** 号
2. 选择 "New dashboard"
3. 点击 "Add visualization"
4. 选择 "Prometheus" 数据源
5. 在查询框中输入：`claude_code_token_usage_total`
6. 设置时间范围：Last 5 minutes
7. 点击 "Run query"
8. 点击右上角的 "Save" 保存面板

### 4️⃣ 常用查询示例

#### Token 使用情况

```promql
# 总 Token 使用量
sum(claude_code_token_usage_total)

# 按 type 分组的 Token 使用量
sum(claude_code_token_usage_total) by (type)

# Token 使用率
rate(claude_code_token_usage_total[5m])
```

#### 成本统计

```promql
# 总成本
claude_code_cost_usage_total

# 每小时成本
rate(claude_code_cost_usage_total[1h])

# 累计成本（过去1小时）
increase(claude_code_cost_usage_total[1h])
```

#### 会话统计

```promql
# 会话总数
claude_code_session_count_total

# 会话创建率
rate(claude_code_session_count_total[5m])
```

#### 代码编辑统计

```promql
# 代码行数变化
increase(claude_code_lines_of_code_count_total[1h])

# 按类型分组（added/removed）
increase(claude_code_lines_of_code_count_total[1h]) by (type)
```

### 5️⃣ 面板配置建议

#### 面板 1: Token 使用趋势

- **标题**: Token Usage Trend
- **查询**: `sum(rate(claude_code_token_usage_total[5m])) by (type)`
- **可视化**: Time series
- **时间范围**: Last 1 hour
- **刷新**: 10s

#### 面板 2: 成本统计

- **标题**: Total Cost
- **查询**: `sum(claude_code_cost_usage_total)`
- **可视化**: Stat (数值)
- **时间范围**: Last 24 hours
- **单位**: Currency USD

#### 面板 3: 会话活动

- **标题**: Session Count
- **查询**: `claude_code_session_count_total`
- **可视化**: Stat
- **时间范围**: Last 1 hour

### 6️⃣ 导入预配置面板（可选）

如果您想使用预配置的面板：

1. 点击左侧菜单 **+** → "Import"
2. 在 "Import via panel json" 粘贴 JSON 配置
3. 点击 "Load"
4. 选择 "Prometheus" 数据源
5. 点击 "Import"

## 🔍 故障排查

### 问题 A: 查询返回 "No data"

**可能原因**：
1. 指标名称不正确
2. 时间范围内没有数据
3. 环境变量没有设置

**解决方案**：
1. 先查询：`{__name__=~".*claude.*"}` 查看所有相关指标
2. 扩大时间范围到 Last 24 hours
3. 运行诊断脚本：`~/otel-docker/diagnose.sh`

### 问题 B: 数据源测试失败

**检查**：
1. Prometheus 是否正常运行：`docker-compose ps prometheus`
2. 数据源 URL：`http://prometheus:9090`
3. 访问模式：Server (default)

### 问题 C: 面板显示但无数据

**检查**：
1. 时间范围是否正确（可能需要扩大范围）
2. 查询语句是否正确
3. 是否真的有指标数据：在 Prometheus UI 查询

## 📊 快速验证步骤

### Step 1: 验证 Prometheus 有数据

访问：http://localhost:9090

在查询框输入：
```promql
{__name__=~"claude_.*"}
```

如果看到指标列表，说明 Prometheus 有数据。

### Step 2: 验证 Grafana 数据源

在 Grafana 中：
1. Configuration → Data sources → Prometheus
2. 点击 "Test"

应该显示 "Data source is working"。

### Step 3: 在 Grafana Explore 中查询

1. 点击 Explore
2. 选择 Prometheus 数据源
3. 查询：`{__name__=~"claude_.*"}`

应该看到数据。

## 🎯 推荐的工作流程

1. **先在 Prometheus UI 中验证**有数据
2. **在 Grafana Explore 中测试**查询
3. **创建简单的仪表板**开始
4. **逐步添加更多面板**

## 💡 提示

- 从简单的查询开始
- 使用 Explore 功能测试查询
- 保存常用的查询
- 设置合理的时间范围
- 定期保存面板配置

---

如果以上步骤都完成了，但仍然看不到数据，请：
1. 运行 `~/otel-docker/diagnose.sh`
2. 提供诊断结果
3. 说明具体在哪一步遇到问题
