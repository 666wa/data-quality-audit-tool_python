# 自定义SQL模板使用指南

## 概述

本工具支持完全自定义SQL模板路径，用户可以创建自己的SQL模板目录，定义自己的稽核逻辑，然后在任务配置中引用。

## 配置SQL模板根目录

### 1. 在 config.yaml 中配置

```yaml
# SQL模板根目录配置
sql_templates_dir: "./sql_templates"      # 默认路径
# sql_templates_dir: "./my_templates"    # 自定义路径
# sql_templates_dir: "/data/audit/templates"  # 绝对路径
```

### 2. 支持的路径格式

- **相对路径**: `./sql_templates` 或 `sql_templates`
- **绝对路径**: `/data/audit/templates` 或 `D:/templates`
- **默认值**: 如果不配置，默认使用 `./sql_templates`

## 创建自定义SQL模板

### 目录结构示例

```
my_templates/                    # 自定义模板根目录
├── operation_log/               # 操作日志表模板
│   ├── operation_log_null_check_stats.sql
│   ├── operation_log_null_check_sample.sql
│   └── ...
├── gold_log/                    # 金库日志表模板
│   ├── gold_log_null_check_stats.sql
│   └── ...
├── custom_audit/                # 自定义稽核模板
│   ├── custom_audit_my_check_stats.sql
│   ├── custom_audit_my_check_sample.sql
│   └── ...
└── special/                     # 特殊任务模板
    └── special_table_count_stats.sql
```

### SQL模板命名规范

模板文件名格式：`{表名前缀}_{检查类型}_{查询类型}.sql`

- **表名前缀**: 如 `operation_log`, `gold_log`, `custom_audit`
- **检查类型**: 如 `null_check`, `enum_check`, `my_check`
- **查询类型**: `stats` (统计查询) 或 `sample` (样例查询)

示例：
- `operation_log_null_check_stats.sql` - 操作日志表非空检查统计
- `custom_audit_my_check_sample.sql` - 自定义稽核我的检查样例

## 创建自定义稽核任务

### 步骤1: 创建SQL模板目录

```bash
mkdir -p my_templates/custom_audit
```

### 步骤2: 创建SQL模板文件

**my_templates/custom_audit/custom_audit_my_check_stats.sql**
```sql
-- 自定义检查 - 统计查询
WITH 
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
all_logs AS (
    SELECT 
        {field}
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        {field}
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN {field} = '特定值' THEN 1 END) AS match_count,
    round(COUNT(CASE WHEN {field} = '特定值' THEN 1 END) * 100.0 / COUNT(*), 4) AS match_percentage
FROM all_logs;
```

**my_templates/custom_audit/custom_audit_my_check_sample.sql**
```sql
-- 自定义检查 - 样例查询
WITH 
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
all_logs AS (
    SELECT 
        {field},
        log_id
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        {field},
        log_id
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
SELECT 
    {field} AS field_value,
    log_id
FROM all_logs
WHERE {field} = '特定值'
LIMIT 10;
```

### 步骤3: 创建任务配置文件

**config/tasks/custom_audit.yaml**
```yaml
# 自定义稽核任务配置
table_info:
  name: "custom_audit"
  display_name: "自定义稽核任务"
  description: "我的自定义数据质量稽核"
  
  # 表名配置
  standard_table: "argus.my_table_standard"
  error_table: "argus.my_table_error"
  
  # 字段配置
  time_field: "create_time"
  primary_key: "id"
  
  # SQL模板目录（相对于sql_templates_dir）
  template_dir: "custom_audit"

# 任务列表
tasks:
  # 任务1：使用自定义检查
  - task_id: "field1_my_check"
    task_name: "字段1自定义检查"
    enabled: true
    sql_template: "custom_audit_my_check"
    params:
      field: "field1"
      display_name: "字段1"
  
  # 任务2：使用标准检查
  - task_id: "field2_null_check"
    task_name: "字段2非空检查"
    enabled: true
    sql_template: "custom_audit_null_check"
    params:
      field: "field2"
      display_name: "字段2"
```

### 步骤4: 更新 config.yaml

```yaml
# 配置自定义SQL模板目录
sql_templates_dir: "./my_templates"

# 其他配置...
database_host: "10.10.26.93"
database_port: 8123
# ...
```

### 步骤5: 执行稽核

```bash
# 执行自定义稽核任务
python main.py --table custom_audit

# 生成自定义稽核的大SQL
python main.py --gen-sql --table custom_audit
```

## SQL模板变量说明

### 必需变量（由系统自动替换）

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| `{start_time}` | 稽核开始时间 | `2026-01-12 00:00:00` |
| `{end_time}` | 稽核结束时间 | `2026-01-19 00:00:00` |
| `{table_standard}` | 标准表名 | `argus.bg_4a_operation_log_standard` |
| `{table_error}` | 错误表名 | `argus.bg_4a_operation_log_error` |
| `{time_field}` | 时间字段名 | `generic_into_time` |

### 任务参数变量（由任务配置传递）

| 变量名 | 说明 | 示例值 |
|--------|------|--------|
| `{field}` | 检查的字段名 | `log_id`, `account_name` |
| `{display_name}` | 字段显示名称 | `日志ID`, `账号名称` |
| `{condition}` | 条件表达式 | `dst_device_type != 'unknown'` |

### 自定义变量

你可以在任务配置的 `params` 中定义任何自定义变量：

```yaml
tasks:
  - task_id: "my_task"
    task_name: "我的任务"
    enabled: true
    sql_template: "custom_audit_my_check"
    params:
      field: "status"
      display_name: "状态"
      target_value: "成功"        # 自定义变量
      threshold: "90"             # 自定义变量
```

在SQL模板中使用：
```sql
WHERE {field} = '{target_value}'
  AND percentage > {threshold}
```

## 完整示例：创建IP地址格式检查

### 1. 创建SQL模板

**my_templates/network_audit/network_audit_ip_format_check_stats.sql**
```sql
-- IP地址格式检查 - 统计查询
WITH 
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
all_logs AS (
    SELECT 
        {field}
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        {field}
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE 
        WHEN {field} NOT REGEXP '^([0-9]{1,3}\.){3}[0-9]{1,3}$' 
        THEN 1 
    END) AS invalid_ip_count,
    round(COUNT(CASE 
        WHEN {field} NOT REGEXP '^([0-9]{1,3}\.){3}[0-9]{1,3}$' 
        THEN 1 
    END) * 100.0 / COUNT(*), 4) AS invalid_percentage
FROM all_logs
WHERE {field} IS NOT NULL AND {field} != '';
```

**my_templates/network_audit/network_audit_ip_format_check_sample.sql**
```sql
-- IP地址格式检查 - 样例查询
WITH 
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
all_logs AS (
    SELECT 
        {field},
        log_id
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        {field},
        log_id
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
SELECT 
    {field} AS invalid_ip,
    log_id
FROM all_logs
WHERE {field} IS NOT NULL 
  AND {field} != ''
  AND {field} NOT REGEXP '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
LIMIT 10;
```

### 2. 创建任务配置

**config/tasks/network_audit.yaml**
```yaml
table_info:
  name: "network_audit"
  display_name: "网络日志稽核"
  description: "网络相关字段的数据质量稽核"
  standard_table: "argus.bg_4a_operation_log_standard"
  error_table: "argus.bg_4a_operation_log_error"
  time_field: "generic_into_time"
  primary_key: "log_id"
  template_dir: "network_audit"

tasks:
  - task_id: "custom_ip_format"
    task_name: "客户端IP格式检查"
    enabled: true
    sql_template: "network_audit_ip_format_check"
    params:
      field: "custom_ip"
      display_name: "客户端IP"
  
  - task_id: "server_ip_format"
    task_name: "服务器IP格式检查"
    enabled: true
    sql_template: "network_audit_ip_format_check"
    params:
      field: "server_ip"
      display_name: "服务器IP"
```

### 3. 更新配置并执行

```bash
# 更新 config.yaml
# sql_templates_dir: "./my_templates"

# 执行稽核
python main.py --table network_audit
```

## 最佳实践

### 1. 模板组织
- 按业务领域或表分组创建目录
- 使用清晰的命名规范
- 添加详细的注释说明

### 2. 变量使用
- 尽量使用标准变量名
- 自定义变量要在配置中明确定义
- 避免硬编码值，使用变量替换

### 3. SQL优化
- 使用CTE提高可读性
- 合理使用索引字段
- 避免全表扫描

### 4. 测试验证
- 先在小数据集上测试
- 验证SQL语法正确性
- 检查结果准确性

## 常见问题

### Q1: 如何复用现有模板？

A: 可以在不同的表配置中使用相同的 `template_dir`，或者创建符号链接。

### Q2: 模板文件找不到怎么办？

A: 检查以下几点：
1. `config.yaml` 中的 `sql_templates_dir` 配置是否正确
2. 任务配置中的 `template_dir` 是否正确
3. SQL模板文件名是否符合命名规范
4. 文件路径是否存在

### Q3: 如何调试SQL模板？

A: 
1. 使用 `--gen-sql` 生成大SQL文件查看渲染结果
2. 在ClickHouse客户端中直接执行SQL验证
3. 查看日志文件中的错误信息

### Q4: 可以使用绝对路径吗？

A: 可以，在 `config.yaml` 中配置绝对路径即可：
```yaml
sql_templates_dir: "/data/audit/templates"
```

## 总结

通过配置 `sql_templates_dir`，你可以：
1. ✅ 自定义SQL模板存放位置
2. ✅ 创建自己的稽核逻辑
3. ✅ 灵活组织模板文件
4. ✅ 支持多套模板切换
5. ✅ 便于版本控制和团队协作

这使得工具更加灵活，可以适应各种不同的稽核需求。
