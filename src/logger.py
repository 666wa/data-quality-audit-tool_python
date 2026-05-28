"""
日志记录模块
"""

import logging
import os
from datetime import datetime
from pathlib import Path


class ColoredFormatter(logging.Formatter):
    """带ANSI颜色的日志格式化器
    
    控制台输出带颜色，日志文件保持纯文本。
    可通过设置环境变量 NO_COLOR=1 禁用颜色。
    """
    
    # ANSI 颜色代码
    COLORS = {
        'DEBUG': '\033[36m',      # 青色
        'INFO': '\033[32m',       # 绿色
        'WARNING': '\033[33m',    # 黄色
        'ERROR': '\033[31m',      # 红色
        'CRITICAL': '\033[41;37m', # 红底白字
    }
    RESET = '\033[0m'
    
    def __init__(self, fmt=None, datefmt=None, use_color=True):
        super().__init__(fmt, datefmt)
        self.use_color = use_color and not os.environ.get('NO_COLOR')
    
    def format(self, record):
        # 保存原始levelname
        original_levelname = record.levelname
        
        if self.use_color and record.levelname in self.COLORS:
            color = self.COLORS[record.levelname]
            record.levelname = f"{color}{original_levelname}{self.RESET}"
        
        result = super().format(record)
        
        # 恢复原始levelname
        record.levelname = original_levelname
        
        return result



class AuditLogger:
    """稽核系统日志记录器"""
    
    def __init__(self, log_dir="./logs", log_level="INFO"):
        """
        初始化日志记录器
        
        Args:
            log_dir: 日志目录路径
            log_level: 日志级别（DEBUG、INFO、WARNING、ERROR）
        """
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        # 生成日志文件名（包含时间戳）
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = self.log_dir / f"audit_{timestamp}.log"
        
        # 配置日志格式
        log_format = "[%(asctime)s] [%(levelname)s] %(message)s"
        date_format = "%Y-%m-%d %H:%M:%S"
        
        # 配置日志记录器
        self.logger = logging.getLogger("DataQualityAudit")
        self.logger.setLevel(getattr(logging, log_level.upper()))
        
        # 清除现有的处理器
        self.logger.handlers.clear()
        
        # 文件处理器（纯文本，无颜色）
        file_handler = logging.FileHandler(log_file, encoding='utf-8')
        file_handler.setFormatter(logging.Formatter(log_format, date_format))
        self.logger.addHandler(file_handler)
        
        # 控制台处理器（带颜色）
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(ColoredFormatter(log_format, date_format))
        self.logger.addHandler(console_handler)
        
        self.info(f"日志初始化完成: {log_file}")
    
    def debug(self, message):
        """记录调试信息"""
        self.logger.debug(message)
    
    def info(self, message):
        """记录一般信息"""
        self.logger.info(message)
    
    def warning(self, message):
        """记录警告信息"""
        self.logger.warning(message)
    
    def error(self, message, exception=None):
        """记录错误信息"""
        if exception:
            self.logger.error(f"{message}: {str(exception)}", exc_info=True)
        else:
            self.logger.error(message)
