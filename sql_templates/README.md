# SQL模板目录

本目录存放所有稽核类型的SQL模板。

## 模板说明

每个模板文件包含一个稽核类型的SQL查询模板，使用占位符来表示可变部分。

### 占位符说明

- `{field}`: 字段名
- `{table_standard}`: 标准日志表名
- `{table_error}`: 错误日志表名
- `{time_field}`: 时间字段名
- `{start_time}`: 开始时间
- `{end_time}`: 结束时间

### 支持的稽核类型

| 模板文件 | 稽核类型 | 说明 |
|---------|---------|------|
| null_check.sql | 非空核查 | 检查字段是否为空、NULL或'null'字符串（字符串字段） |
| time_null_check.sql | 时间字段非空核查 | 检查时间字段是否为NULL（DateTime字段专用） |
| conditional_null_check.sql | 条件非空核查 | 在特定条件下检查字段是否为空 |
| uniqueness_check.sql | 唯一性核查 | 检查字段是否有重复值 |
| enum_check.sql | 枚举值核查 | 统计字段的所有不同值及其数量 |
| locked_accounts.sql | 账号加锁统计 | 统计from_account处于加锁状态的操作记录 |
| semantic_check.sql | 语义抽查 | 检查字段是否包含乱码、特殊字符等 |
| correctness_check.sql | 正确性核查 | 检查字段值是否在预期范围内 |
| statistical_analysis.sql | 统计分析 | 统计字段值的分布情况 |
| exec_result_anomaly_check.sql | exec_result异常占比核查 | 检查exec_result中除"成功"和"失败"外的异常值占比 |

## 如何使用

1. **查看模板**：直接打开对应的.sql文件查看SQL模板
2. **修改模板**：根据实际需求修改SQL模板
3. **重新生成**：修改后运行 `python generate_sql.py` 重新生成大SQL文件

## 如何添加新的稽核类型

1. 在本目录创建新的.sql文件，如 `my_check.sql`
2. 编写SQL模板，使用占位符
3. 在 `src/sql_generator.py` 中添加对应的模板方法
4. 在 `config/audit_tasks.yaml` 中使用新的检查类型

## 示例

### 非空核查模板 (null_check.sql)

```sql
-- 检查{field}是否为空或null
WITH 
filtered_data AS (
    SELECT dst_device_type, log_id, generic_raw_log
    FROM {table_standard}
    WHERE {time_field} >= toDateTime64('{start_time}', 3) 
      AND {time_field} < toDateTime64('{end_time}', 3) 
      AND ({field} IS NULL OR {field} = '' OR {field} IN ('null', 'NULL'))
    ...
)
SELECT ...
```

### 使用示例

在 `config/audit_tasks.yaml` 中配置：

```yaml
audit_tasks:
  - field: log_id
    checks:
      - null_check
      - uniqueness_check
```

运行生成：

```bash
python generate_sql.py
```

## 注意事项

1. 模板文件必须使用UTF-8编码
2. 占位符必须使用 `{变量名}` 格式
3. SQL语句应该包含详细的注释
4. 修改模板后需要重新生成SQL文件
