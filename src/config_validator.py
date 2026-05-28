# -*- coding: utf-8 -*-
"""
配置验证器
验证所有配置文件的完整性和一致性
"""

from pathlib import Path
from datetime import datetime


class ConfigValidator:
    """配置验证器"""
    
    def __init__(self, config_manager, logger):
        """
        初始化配置验证器
        
        Args:
            config_manager: 配置管理器实例
            logger: 日志记录器实例
        """
        self.config_manager = config_manager
        self.logger = logger
        self.errors = []
        self.warnings = []
        self.ok_count = 0
    
    def _add_ok(self, message):
        """添加通过项"""
        self.ok_count += 1
        self.logger.info(f"[OK] {message}")
    
    def _add_error(self, message):
        """添加错误项"""
        self.errors.append(message)
        self.logger.error(f"[ERR] {message}")
    
    def _add_warning(self, message):
        """添加警告项"""
        self.warnings.append(message)
        self.logger.warning(f"[WARN] {message}")
    
    def validate_all(self):
        """
        验证所有配置
        
        Returns:
            bool: 全部通过返回True，有错误返回False
        """
        self.logger.info("=" * 60)
        self.logger.info("开始验证配置...")
        self.logger.info("=" * 60)
        
        # 1. 验证主配置 config.yaml
        self.validate_config_yaml()
        
        # 2. 验证所有任务配置
        self.validate_task_configs()
        
        # 3. 输出汇总
        self.logger.info("=" * 60)
        self.logger.info("配置验证完成")
        self.logger.info(f"通过: {self.ok_count}, 警告: {len(self.warnings)}, 错误: {len(self.errors)}")
        self.logger.info("=" * 60)
        
        return len(self.errors) == 0
    
    def validate_config_yaml(self):
        """验证主配置文件 config.yaml"""
        config = self.config_manager.get_all_parameters()
        
        if not config:
            self._add_error("config.yaml 加载失败或为空")
            return False
        
        # 必填字段检查
        required_fields = [
            'database_host', 'database_port', 'database_name',
            'database_user', 'start_time', 'end_time'
        ]
        
        has_error = False
        for field in required_fields:
            if field not in config or not config[field]:
                self._add_error(f"config.yaml 缺少必填字段: {field}")
                has_error = True
        
        # 时间格式验证
        if 'start_time' in config and config['start_time']:
            if not self._validate_time_format(config['start_time'], 'start_time'):
                has_error = True
        
        if 'end_time' in config and config['end_time']:
            if not self._validate_time_format(config['end_time'], 'end_time'):
                has_error = True
        
        if not has_error:
            self._add_ok("config.yaml 校验通过")
        
        return not has_error
    
    def _validate_time_format(self, time_str, field_name):
        """
        验证时间格式
        
        Args:
            time_str: 时间字符串
            field_name: 字段名（用于错误提示）
        
        Returns:
            bool: 格式正确返回True
        """
        try:
            datetime.strptime(time_str, "%Y-%m-%d %H:%M:%S")
            return True
        except ValueError:
            self._add_error(f"{field_name} 时间格式无效: '{time_str}' (应为 YYYY-MM-DD HH:MM:SS)")
            return False
    
    def validate_task_configs(self):
        """验证所有任务配置"""
        tasks_dir = self.config_manager.get_tasks_dir()
        tasks_path = Path(tasks_dir)
        
        if not tasks_path.exists():
            self._add_error(f"任务配置目录不存在: {tasks_dir}")
            return False
        
        task_files = list(tasks_path.glob("*.yaml"))
        
        if not task_files:
            self._add_warning(f"任务配置目录为空: {tasks_dir}")
            return True
        
        all_passed = True
        for task_file in sorted(task_files):
            passed, _ = self.validate_task_config(task_file)
            if not passed:
                all_passed = False
        
        return all_passed
    
    def validate_task_config(self, task_path):
        """
        验证单个任务配置
        
        Args:
            task_path: 任务配置文件路径
        
        Returns:
            tuple: (bool, list) - (是否通过, 错误列表)
        """
        task_name = task_path.stem
        errors = []
        
        # 加载配置
        try:
            task_config = self.config_manager.load_table_config(task_name)
            if task_config is None:
                self._add_error(f"{task_name}.yaml 加载失败")
                return False, [f"加载失败"]
        except Exception as e:
            self._add_error(f"{task_name}.yaml 加载异常: {e}")
            return False, [str(e)]
        
        has_error = False
        
        # 1. 检查 task_name 字段（可选，但有则更好）
        if 'task_name' not in task_config:
            self._add_warning(f"{task_name}.yaml 缺少 task_name 字段（建议使用）")
        
        # 2. 检查 table_info 字段
        if 'table_info' not in task_config:
            self._add_error(f"{task_name}.yaml 缺少 table_info 字段")
            has_error = True
        else:
            table_info = task_config['table_info']
            required_table_fields = ['name', 'template_dir', 'standard_table', 'error_table', 'time_field']
            for field in required_table_fields:
                if field not in table_info:
                    self._add_error(f"{task_name}.yaml: table_info 缺少 {field} 字段")
                    has_error = True
        
        # 3. 检查 tasks 列表
        if 'tasks' not in task_config or not task_config['tasks']:
            self._add_error(f"{task_name}.yaml 缺少 tasks 列表或为空")
            has_error = True
        else:
            tasks = task_config['tasks']
            task_ids = set()
            
            for i, task in enumerate(tasks):
                # 检查必需字段
                if 'task_id' not in task:
                    self._add_error(f"{task_name}.yaml: tasks[{i}] 缺少 task_id")
                    has_error = True
                elif task['task_id'] in task_ids:
                    self._add_error(f"{task_name}.yaml: task_id '{task['task_id']}' 重复")
                    has_error = True
                else:
                    task_ids.add(task['task_id'])
                
                if 'task_name' not in task:
                    self._add_error(f"{task_name}.yaml: tasks[{i}] 缺少 task_name")
                    has_error = True
                
                if 'sql_template' not in task:
                    self._add_error(f"{task_name}.yaml: tasks[{i}] 缺少 sql_template")
                    has_error = True
                
                # 检查 enabled 字段（可选，但建议有）
                if 'enabled' not in task:
                    self._add_warning(f"{task_name}.yaml: tasks[{i}] 缺少 enabled 字段（默认true）")
            
            # 4. 验证SQL模板文件
            if not has_error and 'table_info' in task_config:
                template_passed = self.validate_sql_templates(task_config, task_name)
                if not template_passed:
                    has_error = True
        
        if not has_error:
            self._add_ok(f"{task_name}.yaml 校验通过 ({len(tasks)} 个任务)")
        
        return not has_error, errors
    
    def validate_sql_templates(self, task_config, task_name):
        """
        验证SQL模板文件存在
        
        Args:
            task_config: 任务配置字典
            task_name: 任务名称
        
        Returns:
            bool: 全部通过返回True
        """
        table_info = task_config.get('table_info', {})
        template_dir_name = table_info.get('template_dir', '')
        
        if not template_dir_name:
            self._add_error(f"{task_name}.yaml: table_info.template_dir 为空")
            return False
        
        # 获取SQL模板根目录
        config = self.config_manager.get_all_parameters()
        sql_templates_root = config.get('sql_templates_dir', './sql_templates')
        templates_dir = Path(sql_templates_root) / template_dir_name
        
        if not templates_dir.exists():
            self._add_error(f"{task_name}.yaml: SQL模板目录不存在: {templates_dir}")
            return False
        
        tasks = task_config.get('tasks', [])
        has_error = False
        
        for task in tasks:
            if not task.get('enabled', True):
                continue
            
            sql_template = task.get('sql_template', '')
            if not sql_template:
                continue
            
            # 检查 stats 模板
            stats_path = templates_dir / f"{sql_template}_stats.sql"
            if not stats_path.exists():
                self._add_error(
                    f"{task_name}.yaml: task '{task.get('task_id')}' "
                    f"缺少SQL模板: {stats_path.name}"
                )
                has_error = True
            
            # 检查 sample 模板
            sample_path = templates_dir / f"{sql_template}_sample.sql"
            if not sample_path.exists():
                self._add_error(
                    f"{task_name}.yaml: task '{task.get('task_id')}' "
                    f"缺少SQL模板: {sample_path.name}"
                )
                has_error = True
        
        return not has_error
