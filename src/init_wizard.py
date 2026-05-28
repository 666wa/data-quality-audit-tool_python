# -*- coding: utf-8 -*-
"""
配置生成向导
交互式CLI向导，帮助用户快速生成新的稽核任务配置和SQL模板
"""

import sys
from pathlib import Path
from datetime import datetime


class InitWizard:
    """配置生成向导"""
    
    # 支持的检查类型
    CHECK_TYPES = [
        ('null_check', '非空检查', '检查字段是否为NULL或空字符串'),
        ('uniqueness_check', '唯一性检查', '检查字段是否有重复值'),
        ('enum_check', '枚举值检查', '检查字段值是否在预定义的枚举范围内'),
        ('conditional_null_check', '条件非空检查', '在特定条件下检查字段是否非空'),
        ('time_null_check', '时间非空检查', '检查时间字段是否为NULL'),
        ('correctness_check', '正确性检查', '检查字段值是否符合业务规则'),
    ]
    
    def __init__(self, logger):
        """
        初始化配置生成向导
        
        Args:
            logger: 日志记录器实例
        """
        self.logger = logger
    
    def run(self, task_name):
        """
        运行配置生成向导
        
        Args:
            task_name: 任务名称（用于文件名）
        
        Returns:
            bool: 成功返回True，失败返回False
        """
        self.logger.info("=" * 60)
        self.logger.info("配置生成向导")
        self.logger.info("=" * 60)
        
        # 检查任务是否已存在
        task_file = Path('config/tasks') / f"{task_name}.yaml"
        if task_file.exists():
            self.logger.error(f"任务配置已存在: {task_file}")
            if not self._prompt_confirm("是否覆盖?", default=False):
                self.logger.info("已取消")
                return False
        
        # 1. 收集基本信息
        self.logger.info("\n[1/5] 请输入任务基本信息")
        display_name = self._prompt("任务显示名称", default=task_name)
        
        # 2. 收集表信息
        self.logger.info("\n[2/5] 请输入表信息")
        standard_table = self._prompt("标准表名 (如 argus.bg_xxx_standard)")
        error_table = self._prompt("错误表名 (如 argus.bg_xxx_error)")
        time_field = self._prompt("时间字段", default="generic_into_time")
        primary_key = self._prompt("主键字段", default="log_id")
        
        # 3. 选择检查类型
        self.logger.info("\n[3/5] 选择需要的检查类型")
        selected_types = self._prompt_multiselect(self.CHECK_TYPES)
        
        if not selected_types:
            self.logger.error("至少选择一个检查类型")
            return False
        
        # 4. 配置字段（针对每个检查类型）
        self.logger.info("\n[4/5] 配置每个检查类型的字段")
        tasks = []
        task_id_counter = 1
        
        for check_type, check_name, _ in selected_types:
            self.logger.info(f"\n--- {check_name} ({check_type}) ---")
            fields = self._prompt(f"要检查的字段 (逗号分隔，如: field1,field2)")
            
            if not fields.strip():
                self.logger.warning(f"跳过 {check_type}: 未指定字段")
                continue
            
            field_list = [f.strip() for f in fields.split(',') if f.strip()]
            
            for field in field_list:
                task_id = f"{task_name}_{field}_{check_type}"
                task_name_str = f"{field} {check_name}"
                
                task = {
                    'task_id': task_id,
                    'task_name': task_name_str,
                    'enabled': True,
                    'sql_template': f"{task_name}_{check_type}",
                    'params': {
                        'field': field,
                        'display_name': field
                    }
                }
                tasks.append(task)
                task_id_counter += 1
        
        # 5. 确认生成
        self.logger.info("\n[5/5] 配置预览")
        self.logger.info(f"任务名称: {display_name}")
        self.logger.info(f"标准表: {standard_table}")
        self.logger.info(f"错误表: {error_table}")
        self.logger.info(f"时间字段: {time_field}")
        self.logger.info(f"检查任务数: {len(tasks)}")
        
        if not self._prompt_confirm("确认生成?", default=True):
            self.logger.info("已取消")
            return False
        
        # 6. 生成文件
        try:
            # 生成任务配置
            config = self._generate_task_config(task_name, display_name, {
                'standard_table': standard_table,
                'error_table': error_table,
                'time_field': time_field,
                'primary_key': primary_key,
            }, tasks)
            
            # 写入YAML
            self._write_yaml(task_file, config)
            self.logger.info(f"[OK] 配置文件已生成: {task_file}")
            
            # 生成SQL模板
            template_dir = Path('sql_templates') / task_name
            self._generate_sql_templates(template_dir, selected_types, task_name)
            self.logger.info(f"[OK] SQL模板已生成: {template_dir}/")
            
            self.logger.info("\n" + "=" * 60)
            self.logger.info("配置生成完成!")
            self.logger.info("=" * 60)
            self.logger.info(f"请编辑配置文件: {task_file}")
            self.logger.info(f"请编辑SQL模板: {template_dir}/")
            
            return True
            
        except Exception as e:
            self.logger.error(f"生成失败: {e}")
            return False
    
    def _generate_task_config(self, task_name, display_name, table_info, tasks):
        """
        生成任务配置字典
        
        Args:
            task_name: 任务名称
            display_name: 显示名称
            table_info: 表信息字典
            tasks: 任务列表
        
        Returns:
            dict: 配置字典
        """
        return {
            'task_name': display_name,
            'table_info': {
                'name': task_name,
                'display_name': display_name,
                'description': f"{display_name}数据质量稽核",
                'standard_table': table_info['standard_table'],
                'error_table': table_info['error_table'],
                'time_field': table_info['time_field'],
                'primary_key': table_info['primary_key'],
                'template_dir': task_name,
            },
            'tasks': tasks
        }
    
    def _generate_sql_templates(self, template_dir, check_types, task_name):
        """
        生成SQL模板文件
        
        Args:
            template_dir: 模板目录路径
            check_types: 检查类型列表
            task_name: 任务名称
        """
        template_dir = Path(template_dir)
        template_dir.mkdir(parents=True, exist_ok=True)
        
        for check_type, check_name, _ in check_types:
            # 生成 stats 模板
            stats_template = self._generate_stats_template(check_type)
            stats_file = template_dir / f"{task_name}_{check_type}_stats.sql"
            with open(stats_file, 'w', encoding='utf-8') as f:
                f.write(stats_template)
            
            # 生成 sample 模板
            sample_template = self._generate_sample_template(check_type)
            sample_file = template_dir / f"{task_name}_{check_type}_sample.sql"
            with open(sample_file, 'w', encoding='utf-8') as f:
                f.write(sample_template)
    
    def _generate_stats_template(self, check_type):
        """生成统计查询模板"""
        templates = {
            'null_check': """-- 非空检查 - 统计查询
SELECT 
    '{field}' AS field_name,
    COUNT(*) AS total_count,
    SUM(CASE WHEN {field} IS NULL OR {field} = '' THEN 1 ELSE 0 END) AS null_count,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
UNION ALL
SELECT 
    '{field}' AS field_name,
    COUNT(*) AS total_count,
    SUM(CASE WHEN {field} IS NULL OR {field} = '' THEN 1 ELSE 0 END) AS null_count,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM {table_error}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'""",
            
            'uniqueness_check': """-- 唯一性检查 - 统计查询
SELECT 
    '{field}' AS field_name,
    COUNT(*) AS total_count,
    COUNT(*) - COUNT(DISTINCT {field}) AS duplicate_count,
    round(duplicate_count * 100.0 / total_count, 4) AS duplicate_percentage
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
UNION ALL
SELECT 
    '{field}' AS field_name,
    COUNT(*) AS total_count,
    COUNT(*) - COUNT(DISTINCT {field}) AS duplicate_count,
    round(duplicate_count * 100.0 / total_count, 4) AS duplicate_percentage
FROM {table_error}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'""",
            
            'enum_check': """-- 枚举值检查 - 统计查询
SELECT 
    '{field}' AS field_name,
    {field} AS field_value,
    COUNT(*) AS count
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
GROUP BY {field}
ORDER BY count DESC""",
            
            'conditional_null_check': """-- 条件非空检查 - 统计查询
SELECT 
    '{field}' AS field_name,
    COUNT(*) AS total_count,
    SUM(CASE WHEN {field} IS NULL OR {field} = '' THEN 1 ELSE 0 END) AS null_count
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
    AND condition_field IS NOT NULL""",
            
            'time_null_check': """-- 时间非空检查 - 统计查询
SELECT 
    '{field}' AS field_name,
    COUNT(*) AS total_count,
    SUM(CASE WHEN {field} IS NULL THEN 1 ELSE 0 END) AS null_count,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'""",
            
            'correctness_check': """-- 正确性检查 - 统计查询
SELECT 
    '{field}' AS field_name,
    COUNT(*) AS total_count,
    SUM(CASE WHEN condition THEN 1 ELSE 0 END) AS error_count
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'""",
        }
        
        return templates.get(check_type, templates['null_check'])
    
    def _generate_sample_template(self, check_type):
        """生成样例查询模板"""
        templates = {
            'null_check': """-- 非空检查 - 样例查询
SELECT {primary_key}, {field}
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
    AND ({field} IS NULL OR {field} = '')
LIMIT 5""",
            
            'uniqueness_check': """-- 唯一性检查 - 样例查询
SELECT {primary_key}, {field}
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
    AND {field} IN (
        SELECT {field}
        FROM {table_standard}
        WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
        GROUP BY {field}
        HAVING COUNT(*) > 1
    )
LIMIT 5""",
            
            'enum_check': """-- 枚举值检查 - 样例查询
SELECT {primary_key}, {field}
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
    AND {field} NOT IN ('value1', 'value2', 'value3')
LIMIT 5""",
            
            'conditional_null_check': """-- 条件非空检查 - 样例查询
SELECT {primary_key}, {field}
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
    AND condition_field IS NOT NULL
    AND ({field} IS NULL OR {field} = '')
LIMIT 5""",
            
            'time_null_check': """-- 时间非空检查 - 样例查询
SELECT {primary_key}, {field}
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
    AND {field} IS NULL
LIMIT 5""",
            
            'correctness_check': """-- 正确性检查 - 样例查询
SELECT {primary_key}, {field}
FROM {table_standard}
WHERE {time_field} >= '{start_time}' AND {time_field} <= '{end_time}'
    AND condition
LIMIT 5""",
        }
        
        return templates.get(check_type, templates['null_check'])
    
    def _prompt(self, message, default=None):
        """
        提示用户输入
        
        Args:
            message: 提示信息
            default: 默认值
        
        Returns:
            str: 用户输入
        """
        if default:
            prompt_str = f"{message} [{default}]: "
        else:
            prompt_str = f"{message}: "
        
        try:
            user_input = input(prompt_str).strip()
        except (EOFError, KeyboardInterrupt):
            self.logger.info("\n用户中断")
            sys.exit(1)
        
        if not user_input and default:
            return default
        
        return user_input
    
    def _prompt_confirm(self, message, default=True):
        """
        提示用户确认
        
        Args:
            message: 提示信息
            default: 默认值
        
        Returns:
            bool: 用户确认返回True
        """
        if default:
            prompt_str = f"{message} [Y/n]: "
        else:
            prompt_str = f"{message} [y/N]: "
        
        try:
            user_input = input(prompt_str).strip().lower()
        except (EOFError, KeyboardInterrupt):
            self.logger.info("\n用户中断")
            sys.exit(1)
        
        if not user_input:
            return default
        
        return user_input in ('y', 'yes')
    
    def _prompt_multiselect(self, options):
        """
        提示用户多选
        
        Args:
            options: 选项列表 [(value, display, description), ...]
        
        Returns:
            list: 选中的选项列表
        """
        self.logger.info("\n请选择检查类型 (输入序号，逗号分隔，如: 1,3,5 或直接回车全选)")
        for i, (value, display, desc) in enumerate(options, 1):
            self.logger.info(f"  {i}. {display} - {desc}")
        
        try:
            user_input = input("你的选择: ").strip()
        except (EOFError, KeyboardInterrupt):
            self.logger.info("\n用户中断")
            sys.exit(1)
        
        if not user_input:
            # 默认全选
            return options
        
        selected = []
        try:
            indices = [int(x.strip()) for x in user_input.split(',')]
            for idx in indices:
                if 1 <= idx <= len(options):
                    selected.append(options[idx - 1])
        except ValueError:
            self.logger.warning("输入格式错误，使用默认值")
            return options
        
        return selected
    
    def _write_yaml(self, path, data):
        """
        写入YAML文件
        
        Args:
            path: 文件路径
            data: 数据字典
        """
        import yaml
        
        path = Path(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(path, 'w', encoding='utf-8') as f:
            yaml.dump(data, f, allow_unicode=True, sort_keys=False)
