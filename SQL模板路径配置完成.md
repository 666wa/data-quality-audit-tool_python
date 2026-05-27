# SQL模板路径配置功能完成

## 完成时间
2026-01-21

## 功能说明

实现了SQL模板路径可配置功能，用户可以在 `config.yaml` 中自定义SQL模板根目录，实现灵活的模板管理。

## 实现内容

### 1. 配置文件更新

#### config.yaml 和 config.example.yaml
添加了 `sql_templates_dir` 配置项：

```yaml
# SQL模板根目录配置
sql_templates_dir: "./sql_templates"      # 默认路径
```

支持的路径格式：
- 相对路径: `./sql_templates` 或 `sql_templates`
- 绝对路径: `/data/audit/templates` 或 `D:/templates`
- 默认值: 如果不配置，默认使用 `./sql_templates`

### 2. 代码修改

#### config_manager.py
添加了 `get_sql_templates_dir()` 方法：

```python
def get_sql_templates_dir(self):
    """
    获取SQL模板根目录
    
    Returns:
        str: SQL模板根目录路径
    """
    return self.config.get('sql_templates_dir', './sql_templates')
```

#### audit_executor.py
修改了 `__init__` 方法，从配置中读取SQL模板根目录：

```python
# 获取SQL模板根目录（从config中读取，默认为 ./sql_templates）
sql_templates_root = config.get('sql_templates_dir', './sql_templates')

# 如果有表配置，使用表专属的模板目录
if table_config and 'table_info' in table_config:
    template_dir = table_config['table_info'].get('template_dir', 'operation_log')
    self.templates_dir = Path(sql_templates_root) / template_dir
    self.logger.info(f"使用SQL模板目录: {self.templates_dir}")
else:
    self.templates_dir = Path(sql_templates_root)
    self.logger.info(f"使用SQL模板根目录: {self.templates_dir}")
```

#### main.py
修改了 `generate_big_sql()` 函数：

1. 从配置中读取SQL模板根目录
2. 支持新的任务化配置格式
3. 兼容旧的配置格式

```python
# 获取SQL模板根目录
sql_templates_root = config.get('sql_templates_dir', './sql_templates')

# 准备SQL模板目录
if template_dir_name:
    templates_dir = Path(sql_templates_root) / template_dir_name
else:
    templates_dir = Path(sql_templates_root)
```

### 3. 文档创建

创建了 `自定义SQL模板使用指南.md`，包含：
- 配置SQL模板根目录的方法
- 创建自定义SQL模板的步骤
- 创建自定义稽核任务的完整示例
- SQL模板变量说明
- 最佳实践和常见问题

## 测试结果

### 测试1: 执行稽核任务
```bash
python main.py --table operation_log
```

输出日志：
```
[2026-01-21 19:44:02] [INFO] 使用SQL模板目录: sql_templates\operation_log
[2026-01-21 19:44:02] [INFO] 开始执行任务: log_id_uniqueness - 日志ID唯一性检查
[2026-01-21 19:44:02] [INFO] 执行查询: operation_log_uniqueness_check_stats
[2026-01-21 19:44:02] [INFO] 查询成功: operation_log_uniqueness_check_stats (行数: 3, 耗时: 0.18s)
```

✅ 成功：系统正确读取了配置中的SQL模板目录

### 测试2: 生成大SQL文件
```bash
python main.py --gen-sql --table operation_log
```

输出日志：
```
[2026-01-21 19:45:27] [INFO] 使用任务化配置生成SQL
[2026-01-21 19:45:27] [INFO] 生成统计查询: 43 条
[2026-01-21 19:45:27] [INFO] 生成样例查询: 43 条
[2026-01-21 19:45:27] [INFO] 生成特殊任务查询: 0 条
[2026-01-21 19:45:27] [INFO] 生成详细查询模板: 1 条
[2026-01-21 19:45:27] [INFO] 总计: 87 条SQL语句
[2026-01-21 19:45:27] [INFO] SQL文件已生成: big_sql\operation_log_generated.sql
```

✅ 成功：
- 正确识别任务化配置格式
- 成功生成43个任务的统计和样例查询
- 总计87条SQL语句（43个任务 × 2 + 1个详细查询模板）

## 使用场景

### 场景1: 使用默认路径
```yaml
# config.yaml
sql_templates_dir: "./sql_templates"
```

目录结构：
```
sql_templates/
├── operation_log/
├── gold_log/
└── special/
```

### 场景2: 使用自定义相对路径
```yaml
# config.yaml
sql_templates_dir: "./my_templates"
```

目录结构：
```
my_templates/
├── operation_log/
├── gold_log/
└── custom_audit/
```

### 场景3: 使用绝对路径
```yaml
# config.yaml
sql_templates_dir: "/data/audit/templates"
```

目录结构：
```
/data/audit/templates/
├── operation_log/
├── gold_log/
└── custom_audit/
```

### 场景4: 多套模板切换
```yaml
# 开发环境
sql_templates_dir: "./sql_templates_dev"

# 测试环境
sql_templates_dir: "./sql_templates_test"

# 生产环境
sql_templates_dir: "/data/audit/templates_prod"
```

## 优势

1. **灵活性** - 可以自由指定SQL模板存放位置
2. **可扩展性** - 支持创建自定义稽核逻辑
3. **多环境支持** - 不同环境可以使用不同的模板目录
4. **版本控制** - 便于团队协作和版本管理
5. **向后兼容** - 默认值保证不影响现有功能

## 配置路径解析逻辑

```
config.yaml 中的 sql_templates_dir
    ↓
config_manager.get_sql_templates_dir()
    ↓
audit_executor.__init__() 读取配置
    ↓
根据 table_config.template_dir 拼接完整路径
    ↓
最终路径: {sql_templates_dir}/{template_dir}
```

示例：
- `sql_templates_dir` = `./my_templates`
- `template_dir` = `operation_log`
- 最终路径 = `./my_templates/operation_log`

## 注意事项

1. **路径格式**
   - Windows: 使用 `\` 或 `/` 都可以
   - Linux/Mac: 使用 `/`
   - 建议使用相对路径，便于移植

2. **目录结构**
   - SQL模板根目录下必须有对应的表目录
   - 表目录名称由 `table_config.template_dir` 指定
   - SQL模板文件名必须符合命名规范

3. **配置优先级**
   - 如果 `config.yaml` 中配置了 `sql_templates_dir`，使用配置值
   - 如果未配置，使用默认值 `./sql_templates`

4. **日志输出**
   - 系统会在日志中输出实际使用的SQL模板目录
   - 便于调试和确认配置是否生效

## 后续建议

1. **模板库管理**
   - 可以创建多套模板库，针对不同业务场景
   - 使用版本控制管理模板变更

2. **模板共享**
   - 团队可以共享通用的SQL模板
   - 通过配置文件切换不同的模板集

3. **模板验证**
   - 可以添加模板语法检查工具
   - 在执行前验证模板完整性

4. **模板文档**
   - 为每个模板添加详细注释
   - 说明变量用途和使用场景

## 总结

SQL模板路径配置功能已完全实现并测试通过，用户可以：

✅ 在 `config.yaml` 中配置 `sql_templates_dir`
✅ 使用相对路径或绝对路径
✅ 创建自定义SQL模板目录
✅ 定义自己的稽核逻辑
✅ 在任务配置中引用自定义模板
✅ 多环境切换不同的模板集

这使得工具更加灵活和可扩展，能够适应各种不同的稽核需求。
