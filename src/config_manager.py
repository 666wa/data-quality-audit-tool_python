"""
配置管理模块
"""

import yaml
from pathlib import Path
from datetime import datetime


class ConfigManager:
    """配置管理器"""
    
    def __init__(self, config_path, logger):
        """
        初始化配置管理器
        
        Args:
            config_path: 配置文件路径
            logger: 日志记录器实例
        """
        self.config_path = Path(config_path)
        self.logger = logger
        self.config = {}
        
    def load_config(self):
        """
        加载配置文件
        
        Returns:
            bool: 加载成功返回True，失败返回False
        """
        if not self.config_path.exists():
            self.logger.error(f"配置文件不存在: {self.config_path}")
            return False
        
        try:
            self.logger.info(f"加载配置文件: {self.config_path}")
            with open(self.config_path, 'r', encoding='utf-8') as f:
                self.config = yaml.safe_load(f)
            return True
        except Exception as e:
            self.logger.error(f"加载配置文件失败", e)
            return False
    
    def validate_config(self):
        """
        验证配置
        
        Returns:
            bool: 验证成功返回True，失败返回False
        """
        required_fields = [
            'database_host',
            'database_port',
            'database_name',
            'database_user',
            'start_time',
            'end_time'
        ]
        
        for field in required_fields:
            if field not in self.config or not self.config[field]:
                self.logger.error(f"缺失必需的配置字段: {field}")
                return False
        
        # 验证时间格式
        if not self._validate_time_format():
            return False
        
        self.logger.info("配置验证成功")
        return True
    
    def _validate_time_format(self):
        """验证时间格式"""
        try:
            start_time = self.config['start_time']
            end_time = self.config['end_time']
            
            # 尝试解析时间
            datetime.strptime(start_time, "%Y-%m-%d %H:%M:%S")
            datetime.strptime(end_time, "%Y-%m-%d %H:%M:%S")
            
            self.logger.info(f"时间范围: {start_time} 到 {end_time}")
            return True
        except ValueError as e:
            self.logger.error(f"无效的时间格式", e)
            return False
    
    def get_parameter(self, key, default=None):
        """
        获取配置参数
        
        Args:
            key: 参数键
            default: 默认值
            
        Returns:
            参数值
        """
        return self.config.get(key, default)
    
    def get_all_parameters(self):
        """
        获取所有配置参数
        
        Returns:
            所有配置参数的字典
        """
        return self.config.copy()
    
    def get_db_config(self):
        """
        获取数据库配置
        
        Returns:
            数据库配置字典
        """
        return {
            'host': self.config.get('database_host'),
            'port': self.config.get('database_port'),
            'database': self.config.get('database_name'),
            'user': self.config.get('database_user'),
            'password': self.config.get('database_password', '')
        }
    
    def get_time_range(self):
        """
        获取时间范围
        
        Returns:
            (start_time, end_time) 元组
        """
        return (
            self.config.get('start_time'),
            self.config.get('end_time')
        )
    
    def get_queries_dir(self):
        """
        获取查询模板目录
        
        Returns:
            str: 查询模板目录路径
        """
        return self.config.get('queries_dir', './queries')
    
    def get_generated_sql_dir(self):
        """
        获取生成SQL目录
        
        Returns:
            str: 生成SQL目录路径
        """
        return self.config.get('generated_sql_dir', './generated_sql')
    
    def get_report_output_dir(self):
        """
        获取报告输出目录
        
        Returns:
            str: 报告输出目录路径
        """
        return self.config.get('report_output_dir', './output')
    
    def get_log_output_dir(self):
        """
        获取日志输出目录
        
        Returns:
            str: 日志输出目录路径
        """
        return self.config.get('log_output_dir', './logs')
    
    def get_tasks_dir(self):
        """
        获取任务配置目录
        
        Returns:
            str: 任务配置目录路径
        """
        return self.config.get('tasks_dir', './config/tasks')
    
    def get_sql_templates_dir(self):
        """
        获取SQL模板根目录
        
        Returns:
            str: SQL模板根目录路径
        """
        return self.config.get('sql_templates_dir', './sql_templates')
    
    def show_config(self):
        """显示配置信息（隐藏密码）"""
        self.logger.info("当前配置:")
        for key, value in self.config.items():
            if 'password' in key.lower():
                self.logger.info(f"  {key} = ****")
            else:
                self.logger.info(f"  {key} = {value}")
    

    
    def load_table_config(self, table_name):
        """
        加载指定表的配置
        
        Args:
            table_name: 表名（如 gold_log, operation_log, special_statistics）
            
        Returns:
            dict: 表配置字典，失败返回None
        """
        # 获取任务配置目录
        tasks_dir = self.get_tasks_dir()
        table_config_path = Path(tasks_dir) / f"{table_name}.yaml"
        
        if not table_config_path.exists():
            self.logger.error(f"表配置文件不存在: {table_config_path}")
            return None
        
        try:
            self.logger.info(f"加载表配置: {table_config_path}")
            with open(table_config_path, 'r', encoding='utf-8') as f:
                table_config = yaml.safe_load(f)
            
            # 验证必需字段
            if 'table_info' not in table_config:
                self.logger.error(f"表配置缺少 table_info 字段")
                return None
            
            table_info = table_config['table_info']
            required_fields = ['name', 'template_dir']
            for field in required_fields:
                if field not in table_info:
                    self.logger.error(f"表配置缺少必需字段: table_info.{field}")
                    return None
            
            self.logger.info(f"成功加载表配置: {table_info.get('display_name', table_name)}")
            return table_config
        except Exception as e:
            self.logger.error(f"加载表配置失败", e)
            return None
    
    def list_all_tables(self):
        """
        列出所有可用的表配置
        
        Returns:
            list: 表名列表
        """
        tables = []
        
        # 获取任务配置目录
        tasks_dir = self.get_tasks_dir()
        tasks_path = Path(tasks_dir)
        
        if tasks_path.exists():
            for f in tasks_path.glob("*.yaml"):
                tables.append(f.stem)
        
        if tables:
            self.logger.info(f"找到 {len(tables)} 个表配置: {', '.join(tables)}")
        else:
            self.logger.warning(f"未找到任何表配置")
        
        return tables
