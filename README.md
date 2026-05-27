# 数据质量稽核工具

数据质量稽核工具，采用三阶段执行策略（统计 → 样例 → 详情），按设备类型分组统计异常数据。

## 核心特性

- **三阶段执行策略**：统计查询 → 样例查询 → 详细查询，性能优化
- **设备类型分组**：所有统计结果按 `dst_device_type` 分组展示
- **灵活的SQL模板系统**：支持多种检查类型，易于扩展
- **完整的日志记录**：详细的执行日志，便于问题排查
- **大SQL文件生成**：支持生成批量SQL文件用于手动执行

## 快速开始

### 1. 配置数据库连接

编辑 `config/config.yaml`：

```yaml
database:
  host: "10.10.26.93"
  port: 8123
  user: "default"
  password: ""
  
table_standard: "argus.bg_4a_operation_log_standard"
table_error: "argus.bg_4a_operation_log_error"
time_field: "generic_into_time"

time_range:
  start_time: "2024-12-16 00:00:00"
  end_time: "2024-12-16 23:59:59"
```

### 2. 配置稽核任务

编辑 `config/audit_tasks.yaml`，定义需要稽核的字段和检查类型：

```yaml
audit_tasks:
  - field: log_id
    checks:
      - uniqueness_check
      - null_check
  
  - field: account_id
    checks:
      - null_check
```

### 3. 执行稽核

```bash
# 执行完整稽核流程
python main.py

# 生成大SQL文件（不执行稽核）
python main.py --gen-sql
```

## 使用模式

### 模式1：自动执行稽核（推荐）

```bash
python main.py
```

程序会：
1. 读取配置和稽核任务
2. 连接数据库
3. 按三阶段策略执行所有稽核
4. 生成稽核报告到 `output/` 目录
5. 记录详细日志到 `logs/` 目录

### 模式2：生成大SQL文件

```bash
python main.py --gen-sql
```

程序会：
1. 读取配置和稽核任务
2. 生成所有SQL语句到 `big_sql/generated.sql`
3. 可以手动复制SQL到数据库客户端执行

## 支持的检查类型

| 检查类型 | 说明 | 模板文件 |
|---------|------|---------|
| `null_check` | 非空核查 | `null_check_stats.sql`, `null_check_sample.sql` |
| `time_null_check` | 时间字段非空核查 | `time_null_check_stats.sql`, `time_null_check_sample.sql` |
| `conditional_null_check` | 条件非空核查 | `conditional_null_check_stats.sql`, `conditional_null_check_sample.sql` |
| `uniqueness_check` | 数据唯一性核查 | `uniqueness_check_stats.sql`, `uniqueness_check_sample.sql` |
| `enum_check` | 枚举值核查 | `enum_check_stats.sql`, `enum_check_sample.sql` |

## 三阶段执行策略

### 第一阶段：统计查询
- 查询异常数据的总数和按设备类型分组的统计
- 如果没有异常，跳过后续阶段
- 性能高，快速判断是否有问题

### 第二阶段：样例查询
- 查询一个异常数据的 `log_id`
- 只查询 `log_id`，不查询大字段 `generic_raw_log`
- 性能优化，避免传输大量数据

### 第三阶段：详细查询
- 根据 `log_id` 查询完整的 `generic_raw_log`
- 只查询一条记录，用于报告展示
- 完整显示异常数据详情

## 项目结构

```
data-quality-audit-py/
├── main.py                    # 主程序（支持两种模式）
├── config/
│   ├── config.yaml           # 数据库和时间配置
│   └── audit_tasks.yaml      # 稽核任务配置
├── sql_templates/            # SQL模板目录
│   ├── null_check_stats.sql
│   ├── null_check_sample.sql
│   ├── uniqueness_check_stats.sql
│   ├── uniqueness_check_sample.sql
│   └── detail_query.sql
├── src/                      # 源代码
│   ├── config_manager.py     # 配置管理
│   ├── logger.py             # 日志记录
│   ├── db_executor.py        # 数据库执行
│   ├── audit_executor.py     # 稽核执行器
│   └── report_generator.py   # 报告生成
├── logs/                     # 日志文件
├── output/                   # 稽核报告
└── big_sql/                  # 生成的大SQL文件
```

## 输出说明

### 稽核报告
- 位置：`output/audit_report_YYYYMMDD_HHMMSS.txt`
- 包含：统计结果、设备类型分组、样例数据详情

### 日志文件
- 位置：`logs/audit_YYYYMMDD_HHMMSS.log`
- 包含：详细的执行过程、SQL语句、错误信息

### 大SQL文件
- 位置：`big_sql/generated.sql`
- 包含：所有统计查询、样例查询、详细查询模板

## 性能优化

1. **样例查询只查log_id**：避免传输大字段 `generic_raw_log`，性能提升约10倍
2. **WHERE条件前置**：在CTE中直接过滤，减少数据量
3. **按需执行详细查询**：只有在需要时才查询完整记录
4. **设备类型分组**：使用高效的GROUP BY统计

## 常见问题

### 1. 数据库连接失败
检查 `config/config.yaml` 中的数据库配置是否正确。

### 2. 缺少SQL模板
如果某个检查类型缺少模板，程序会跳过该检查并记录警告日志。

### 3. 样例数据未完整显示
已优化，所有样例数据都会完整显示，无论字段多大。

## 更多文档

- [快速使用指南](快速使用指南.md)
- [SQL模板系统说明](docs/SQL_TEMPLATE_SYSTEM.md)
- [时间配置指南](docs/TIME_CONFIG_GUIDE.md)
- [SQL优化总结](SQL_OPTIMIZATION_SUMMARY.md)
