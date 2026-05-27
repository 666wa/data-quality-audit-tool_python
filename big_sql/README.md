# 大SQL文件存放目录

## 目录说明

此目录用于存放包含多个查询的大SQL文件，这些文件将被SQL分割工具处理并分割成独立的查询模板。

## 使用方法

### 1. 放置SQL文件

将你的大SQL文件放在此目录下：

```bash
# 复制SQL文件到此目录
cp /path/to/your/big_sql_file.sql big_sql/

# 或直接在此目录创建SQL文件
vim big_sql/my_audit_queries.sql
```

### 2. 分割SQL文件

使用SQL分割工具处理此目录下的文件：

```bash
# 方式1: 使用命令行参数
python split_sql.py -i big_sql/your_file.sql -o queries

# 方式2: 使用配置文件
# 编辑 config/splitter_config.yaml，设置 input_sql_file
python split_sql.py --config config/splitter_config.yaml
```

## SQL文件格式要求

大SQL文件必须遵循特定的格式规范才能被正确解析。

### 基本结构

```sql
============================================================================字段名 稽核sql
#############检查类型

[SQL查询语句]

#############另一个检查类型

[SQL查询语句]
```

### 详细格式说明

请参考以下文档了解完整的格式规范：

- 📖 [SQL文件格式规范](../SQL_FILE_FORMAT.md) - 完整的格式定义
- ⚡ [格式快速参考](../SQL_FORMAT_QUICK_REFERENCE.md) - 快速查阅
- 📝 [SQL模板示例](../examples/sample_sql_template.sql) - 可用的模板

### 核心要素

1. **字段分隔符**: 至少50个等号 + 字段名 + "稽核sql"
2. **检查类型注释**: 至少3个井号 + 检查类型关键字
3. **时间格式**: `toDateTime64('YYYY-MM-DD HH:MM:SS', 3)`

## 示例文件

### 示例1: 基本结构

```sql
============================================================================log_id稽核sql
#############非空核查

SELECT COUNT(*) AS invalid_count
FROM argus.bg_4a_operation_log_standard
WHERE generic_into_time >= toDateTime64('2025-12-08 00:00:00', 3)
  AND generic_into_time < toDateTime64('2025-12-15 00:00:00', 3)
  AND (log_id IS NULL OR log_id = '');
```

### 示例2: 多个检查类型

```sql
============================================================================log_id稽核sql
#############数据唯一性稽核

WITH a AS (
    SELECT log_id FROM table1
    UNION ALL
    SELECT log_id FROM table2
)
SELECT log_id, COUNT(*) as count
FROM a
GROUP BY log_id
HAVING COUNT(*) > 1;

#############非空核查

SELECT COUNT(*) FROM table1
WHERE log_id IS NULL;
```

## 文件命名建议

建议使用有意义的文件名：

- ✅ `audit_queries_2025.sql` - 包含年份
- ✅ `log_audit_queries.sql` - 说明用途
- ✅ `sheet4.sql` - 原始文件名
- ❌ `temp.sql` - 不明确
- ❌ `test.sql` - 不明确

## 注意事项

1. **文件编码**: 确保使用UTF-8编码
2. **格式规范**: 严格遵循格式要求，否则无法正确解析
3. **时间格式**: 使用标准的时间格式，工具会自动替换为变量
4. **备份**: 建议保留原始文件的备份

## 工作流程

```
big_sql/
└── your_file.sql          # 1. 放置大SQL文件

        ↓ (运行分割工具)

queries/                   # 2. 生成查询模板
├── field1/
│   ├── uniqueness_check.sql
│   └── null_check.sql
└── field2/
    └── enum_check.sql

        ↓ (运行主程序)

generated_sql/             # 3. 生成可执行SQL
├── field1/
│   ├── uniqueness_check.sql
│   └── null_check.sql
└── field2/
    └── enum_check.sql

        ↓ (执行稽核)

output/                    # 4. 生成报告
└── audit_report_YYYYMMDD_HHMMSS.txt
```

## 常见问题

### Q: 我的SQL文件没有被正确分割？

**A**: 检查以下几点：
1. 字段分隔符是否有至少50个等号
2. 检查类型注释是否有至少3个井号
3. 是否包含可识别的检查类型关键字
4. SQL语句是否完整

### Q: 时间没有被替换为变量？

**A**: 确保时间格式为 `toDateTime64('YYYY-MM-DD HH:MM:SS', 3)`

### Q: 如何验证SQL文件格式是否正确？

**A**: 运行分割工具并查看日志：
```bash
python split_sql.py -i big_sql/your_file.sql -o queries
# 查看日志文件: logs/audit_*.log
```

## 相关文档

- [SQL分割工具使用说明](../SQL_SPLITTER_README.md)
- [SQL文件格式规范](../SQL_FILE_FORMAT.md)
- [配置文件指南](../CONFIG_GUIDE.md)
- [快速开始指南](../QUICKSTART.md)

## 获取帮助

如有问题：
1. 查看日志文件: `logs/audit_*.log`
2. 参考格式文档: `SQL_FILE_FORMAT.md`
3. 查看示例模板: `examples/sample_sql_template.sql`
4. 联系数据质量团队
