# -*- coding: utf-8 -*-
"""
数据质量稽核执行器
采用三阶段执行策略：统计 -> 样例 -> 详情
按设备类型分组统计
"""

import os
from pathlib import Path
from datetime import datetime


class AuditExecutor:
    """数据质量稽核执行器"""
    
    def __init__(self, db_executor, config, logger, table_config=None):
        """
        初始化稽核执行器
        
        Args:
            db_executor: 数据库执行器实例
            config: 配置字典
            logger: 日志记录器实例
            table_config: 表配置字典（可选，用于多表支持）
        """
        self.db_executor = db_executor
        self.config = config
        self.logger = logger
        self.table_config = table_config
        
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
        
    def load_template(self, template_name):
        """
        加载SQL模板
        
        Args:
            template_name: 模板名称（不含.sql后缀）
            
        Returns:
            str: 模板内容
        """
        template_path = self.templates_dir / f"{template_name}.sql"
        
        if not template_path.exists():
            self.logger.error(f"模板文件不存在: {template_path}")
            return None
        
        try:
            with open(template_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            self.logger.error(f"读取模板失败: {template_path}", e)
            return None
    
    def render_template(self, template_content, params):
        """
        渲染SQL模板
        
        Args:
            template_content: 模板内容
            params: 参数字典
            
        Returns:
            str: 渲染后的SQL
        """
        result = template_content
        for key, value in params.items():
            placeholder = f"{{{key}}}"
            result = result.replace(placeholder, str(value))
        return result
    
    def execute_stats_query(self, field, check_type, params):
        """
        执行统计查询（第一阶段）
        
        Args:
            field: 字段名
            check_type: 检查类型
            params: 参数字典
            
        Returns:
            dict: 统计结果
        """
        # 加载统计模板
        template_name = f"{check_type}_stats"
        template = self.load_template(template_name)
        
        if not template:
            self.logger.warning(f"未找到统计模板: {template_name}，跳过")
            return None
        
        # 渲染SQL
        sql = self.render_template(template, params)
        
        # 执行查询
        query_name = f"{field}_{check_type}_stats"
        result = self.db_executor.execute_query(query_name, sql)
        
        return result
    
    def execute_sample_query(self, field, check_type, params):
        """
        执行样例查询（第二阶段）
        
        Args:
            field: 字段名
            check_type: 检查类型
            params: 参数字典
            
        Returns:
            dict: 样例结果（包含log_id）
        """
        # 加载样例模板
        template_name = f"{check_type}_sample"
        template = self.load_template(template_name)
        
        if not template:
            self.logger.warning(f"未找到样例模板: {template_name}，跳过")
            return None
        
        # 渲染SQL
        sql = self.render_template(template, params)
        
        # 执行查询
        query_name = f"{field}_{check_type}_sample"
        result = self.db_executor.execute_query(query_name, sql)
        
        return result
    
    def execute_detail_query(self, sample_log_id, params):
        """
        执行详细查询（第三阶段）
        
        Args:
            sample_log_id: 样例log_id
            params: 参数字典
            
        Returns:
            dict: 详细记录
        """
        # 加载详细查询模板
        template = self.load_template('detail_query')
        
        if not template:
            self.logger.error("未找到详细查询模板")
            return None
        
        # 添加sample_log_id到参数
        detail_params = params.copy()
        detail_params['sample_log_id'] = sample_log_id
        
        # 渲染SQL
        sql = self.render_template(template, detail_params)
        
        # 执行查询
        query_name = f"detail_{sample_log_id}"
        result = self.db_executor.execute_query(query_name, sql)
        
        return result
    
    def parse_sample_result(self, result):
        """
        解析样例查询结果，提取log_id
        
        Args:
            result: 查询结果字典
            
        Returns:
            str: log_id或None
        """
        if not result or result['status'] != 'success':
            return None
        
        data = result.get('data', '')
        if not data:
            return None
        
        # 解析TabSeparatedWithNames格式
        lines = data.strip().split('\n')
        if len(lines) < 2:  # 至少需要表头和一行数据
            return None
        
        # 第一行是表头，第二行是数据
        headers = lines[0].split('\t')
        values = lines[1].split('\t')
        
        # 找到log_id列
        try:
            log_id_index = headers.index('log_id')
            return values[log_id_index]
        except (ValueError, IndexError):
            self.logger.warning("样例结果中未找到log_id")
            return None
    
    def execute_field_audit(self, field, check_type, condition=None):
        """
        执行单个字段的稽核（三阶段）
        
        Args:
            field: 字段名
            check_type: 检查类型
            condition: 条件（用于条件非空核查）
            
        Returns:
            dict: 稽核结果
        """
        self.logger.info(f"开始稽核: {field} - {check_type}")
        
        # 准备参数
        params = {
            'field': field,
            'start_time': self.config.get('start_time'),
            'end_time': self.config.get('end_time')
        }
        
        # 如果有表配置，使用表配置中的表名
        if self.table_config and 'table_info' in self.table_config:
            table_info = self.table_config['table_info']
            params['table_standard'] = table_info.get('standard_table')
            params['table_error'] = table_info.get('error_table')
            params['time_field'] = table_info.get('time_field')
        else:
            # 使用默认配置
            params['table_standard'] = self.config.get('table_standard', 'argus.bg_4a_operation_log_standard')
            params['table_error'] = self.config.get('table_error', 'argus.bg_4a_operation_log_error')
            params['time_field'] = self.config.get('time_field', 'generic_into_time')
        
        # 如果有条件，添加到参数中
        if condition:
            params['condition'] = condition
        
        audit_result = {
            'field': field,
            'check_type': check_type,
            'stats': None,
            'sample': None,
            'detail': None,
            'status': 'pending'
        }
        
        # 第一阶段：统计查询
        stats_result = self.execute_stats_query(field, check_type, params)
        audit_result['stats'] = stats_result
        
        if not stats_result or stats_result['status'] != 'success':
            audit_result['status'] = 'failed'
            self.logger.error(f"统计查询失败: {field} - {check_type}")
            return audit_result
        
        # 检查是否有异常数据
        # 解析统计结果判断是否需要继续
        if stats_result.get('row_count', 0) == 0:
            audit_result['status'] = 'no_issues'
            self.logger.info(f"未发现异常: {field} - {check_type}")
            return audit_result
        
        # 第二阶段：样例查询
        sample_result = self.execute_sample_query(field, check_type, params)
        audit_result['sample'] = sample_result
        
        if not sample_result or sample_result['status'] != 'success':
            audit_result['status'] = 'partial'
            self.logger.warning(f"样例查询失败: {field} - {check_type}")
            return audit_result
        
        # 提取log_id
        sample_log_id = self.parse_sample_result(sample_result)
        
        if not sample_log_id:
            audit_result['status'] = 'partial'
            self.logger.warning(f"未能提取样例log_id: {field} - {check_type}")
            return audit_result
        
        # 第三阶段：详细查询
        detail_result = self.execute_detail_query(sample_log_id, params)
        audit_result['detail'] = detail_result
        
        if detail_result and detail_result['status'] == 'success':
            audit_result['status'] = 'success'
            self.logger.info(f"稽核完成: {field} - {check_type}")
        else:
            audit_result['status'] = 'partial'
            self.logger.warning(f"详细查询失败: {field} - {check_type}")
        
        return audit_result
    
    def execute_special_task(self, task_name, task_type):
        """
        执行特殊稽核任务（不针对单个字段）
        
        Args:
            task_name: 任务名称
            task_type: 任务类型
            
        Returns:
            dict: 稽核结果
        """
        self.logger.info(f"开始执行特殊任务: {task_name} - {task_type}")
        
        # 准备参数
        params = {
            'start_time': self.config.get('start_time'),
            'end_time': self.config.get('end_time')
        }
        
        # 如果有表配置，使用表配置中的表名
        if self.table_config and 'table_info' in self.table_config:
            table_info = self.table_config['table_info']
            params['table_standard'] = table_info.get('standard_table')
            params['table_error'] = table_info.get('error_table')
            params['time_field'] = table_info.get('time_field')
        else:
            # 使用默认配置
            params['table_standard'] = self.config.get('table_standard', 'argus.bg_4a_operation_log_standard')
            params['table_error'] = self.config.get('table_error', 'argus.bg_4a_operation_log_error')
            params['time_field'] = self.config.get('time_field', 'generic_into_time')
        
        audit_result = {
            'field': task_name,
            'check_type': task_type,
            'stats': None,
            'sample': None,
            'detail': None,
            'status': 'pending',
            'is_special': True  # 标记为特殊任务
        }
        
        # 加载模板
        template_name = f"{task_type}_stats"
        template = self.load_template(template_name)
        
        if not template:
            self.logger.warning(f"未找到特殊任务模板: {template_name}，跳过")
            audit_result['status'] = 'failed'
            return audit_result
        
        # 渲染SQL
        sql = self.render_template(template, params)
        
        # 执行查询
        query_name = f"{task_name}_{task_type}"
        result = self.db_executor.execute_query(query_name, sql)
        
        audit_result['stats'] = result
        
        if result and result['status'] == 'success':
            audit_result['status'] = 'success'
            self.logger.info(f"特殊任务完成: {task_name} - {task_type}")
        else:
            audit_result['status'] = 'failed'
            self.logger.error(f"特殊任务失败: {task_name} - {task_type}")
        
        return audit_result
    
    def execute_task(self, task):
        """
        执行单个任务（新的任务化配置）
        
        Args:
            task: 任务配置字典
            
        Returns:
            dict: 稽核结果
        """
        task_id = task.get('task_id', 'unknown')
        task_name = task.get('task_name', 'Unknown Task')
        sql_template = task.get('sql_template', '')
        params = task.get('params', {})
        
        self.logger.info(f"开始执行任务: {task_id} - {task_name}")
        
        # 准备参数
        exec_params = {
            'start_time': self.config.get('start_time'),
            'end_time': self.config.get('end_time')
        }
        
        # 添加表配置参数
        if self.table_config and 'table_info' in self.table_config:
            table_info = self.table_config['table_info']
            exec_params['table_standard'] = table_info.get('standard_table')
            exec_params['table_error'] = table_info.get('error_table')
            exec_params['time_field'] = table_info.get('time_field')
        else:
            exec_params['table_standard'] = self.config.get('table_standard', 'argus.bg_4a_operation_log_standard')
            exec_params['table_error'] = self.config.get('table_error', 'argus.bg_4a_operation_log_error')
            exec_params['time_field'] = self.config.get('time_field', 'generic_into_time')
        
        # 添加任务参数
        exec_params.update(params)
        
        # 构建结果
        audit_result = {
            'task_id': task_id,
            'task_name': task_name,
            'field': params.get('field', task_id),
            'check_type': sql_template,
            'stats': None,
            'sample': None,
            'detail': None,
            'status': 'pending'
        }
        
        # 执行统计查询
        stats_result = self.execute_stats_query_by_template(sql_template, exec_params)
        audit_result['stats'] = stats_result
        
        if not stats_result or stats_result['status'] != 'success':
            audit_result['status'] = 'failed'
            self.logger.error(f"任务失败: {task_id}")
            return audit_result
        
        # 检查是否有异常数据
        if stats_result.get('row_count', 0) == 0:
            audit_result['status'] = 'no_issues'
            self.logger.info(f"任务完成（无异常）: {task_id}")
            return audit_result
        
        # 执行样例查询
        sample_result = self.execute_sample_query_by_template(sql_template, exec_params)
        audit_result['sample'] = sample_result
        
        if sample_result and sample_result['status'] == 'success':
            audit_result['status'] = 'success'
            self.logger.info(f"任务完成: {task_id}")
        else:
            audit_result['status'] = 'partial'
            self.logger.warning(f"任务部分完成: {task_id}")
        
        return audit_result
    
    def execute_stats_query_by_template(self, template_name, params):
        """
        根据模板名称执行统计查询
        
        Args:
            template_name: 模板名称（如 gold_log_null_check）
            params: 参数字典
            
        Returns:
            dict: 统计结果
        """
        template = self.load_template(f"{template_name}_stats")
        if not template:
            return None
        
        sql = self.render_template(template, params)
        query_name = f"{template_name}_stats"
        return self.db_executor.execute_query(query_name, sql)
    
    def execute_sample_query_by_template(self, template_name, params):
        """
        根据模板名称执行样例查询
        
        Args:
            template_name: 模板名称（如 gold_log_null_check）
            params: 参数字典
            
        Returns:
            dict: 样例结果
        """
        template = self.load_template(f"{template_name}_sample")
        if not template:
            return None
        
        sql = self.render_template(template, params)
        query_name = f"{template_name}_sample"
        return self.db_executor.execute_query(query_name, sql)
    
    def execute_all_audits(self, audit_tasks):
        """
        执行所有稽核任务（兼容新旧配置格式）
        
        Args:
            audit_tasks: 稽核任务配置（可以是旧格式或新格式）
            
        Returns:
            list: 所有稽核结果
        """
        self.logger.info("=" * 60)
        self.logger.info("开始执行数据质量稽核")
        self.logger.info("=" * 60)
        
        all_results = []
        
        # 检查是否是新的任务化配置
        if 'tasks' in audit_tasks:
            # 新格式：任务化配置
            self.logger.info("使用任务化配置")
            for task in audit_tasks.get('tasks', []):
                if task.get('enabled', True):  # 只执行启用的任务
                    result = self.execute_task(task)
                    all_results.append(result)
                else:
                    self.logger.info(f"跳过已禁用的任务: {task.get('task_id', 'unknown')}")
        else:
            # 旧格式：字段+检查类型
            self.logger.info("使用旧格式配置")
            
            # 执行普通字段稽核任务
            for task in audit_tasks.get('audit_tasks', []):
                field = task['field']
                checks = task.get('checks', [])
                condition = task.get('condition', None)
                
                for check_type in checks:
                    result = self.execute_field_audit(field, check_type, condition)
                    all_results.append(result)
            
            # 执行特殊任务
            for task in audit_tasks.get('special_tasks', []):
                task_name = task['name']
                task_type = task['type']
                result = self.execute_special_task(task_name, task_type)
                all_results.append(result)
        
        self.logger.info("=" * 60)
        self.logger.info("稽核执行完成")
        self.logger.info("=" * 60)
        
        return all_results
