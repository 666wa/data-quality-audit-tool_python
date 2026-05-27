# -*- coding: utf-8 -*-
"""
数据库执行模块 - 使用HTTP方式连接ClickHouse
"""

import time
import requests
from datetime import datetime


class DatabaseExecutor:
    """数据库执行器（HTTP方式）"""
    
    def __init__(self, db_config, logger):
        """
        初始化数据库执行器
        
        Args:
            db_config: 数据库配置字典
            logger: 日志记录器实例
        """
        self.db_config = db_config
        self.logger = logger
        
        # 构建ClickHouse HTTP URL
        host = db_config.get('host', 'localhost')
        port = db_config.get('port', 8123)
        self.base_url = "http://{}:{}".format(host, port)
        
        # 认证信息
        self.auth = None
        if db_config.get('user'):
            self.auth = (
                db_config.get('user'),
                db_config.get('password', '')
            )
        
        # 数据库名称
        self.database = db_config.get('database', 'default')
        
    def test_connection(self):
        """
        测试数据库连接
        
        Returns:
            bool: 连接成功返回True，失败返回False
        """
        self.logger.info("测试数据库连接...")
        
        try:
            response = requests.get(
                self.base_url,
                auth=self.auth,
                params={'query': 'SELECT 1'},
                timeout=10
            )
            
            if response.status_code == 200:
                self.logger.info("数据库连接成功")
                return True
            else:
                self.logger.error("数据库连接失败: HTTP {}".format(response.status_code))
                self.logger.error("响应内容: {}".format(response.text))
                return False
        except Exception as e:
            self.logger.error("数据库连接测试失败", e)
            return False
    
    def execute_query(self, query_name, sql):
        """
        执行单个查询
        
        Args:
            query_name: 查询名称
            sql: SQL语句
            
        Returns:
            dict: 查询结果字典
        """
        self.logger.info("执行查询: {}".format(query_name))
        
        start_time = time.time()
        
        try:
            # 添加FORMAT子句以获取带表头的结果
            # 使用TabSeparatedWithNames格式：第一行是列名，后续行是数据
            sql_with_format = sql.strip()
            if not sql_with_format.upper().endswith(';'):
                sql_with_format += ';'
            # 移除末尾的分号，添加FORMAT子句
            sql_with_format = sql_with_format.rstrip(';').strip()
            sql_with_format += ' FORMAT TabSeparatedWithNames'
            
            # 发送HTTP POST请求执行查询
            response = requests.post(
                self.base_url,
                auth=self.auth,
                params={'database': self.database},
                data=sql_with_format.encode('utf-8'),
                timeout=300  # 5分钟超时
            )
            
            execution_time = time.time() - start_time
            
            if response.status_code == 200:
                # 解析结果
                output = response.text.strip()
                lines = output.split('\n') if output else []
                # 第一行是表头，所以数据行数是总行数-1
                row_count = max(0, len(lines) - 1) if lines else 0
                
                self.logger.info("查询成功: {} (行数: {}, 耗时: {:.2f}s)".format(
                    query_name, row_count, execution_time
                ))
                
                return {
                    'query_name': query_name,
                    'status': 'success',
                    'execution_time': execution_time,
                    'row_count': row_count,
                    'data': output,
                    'error_message': None,
                    'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }
            else:
                error_msg = response.text.strip()
                self.logger.error("查询失败: {} - HTTP {} - {}".format(
                    query_name, response.status_code, error_msg
                ))
                
                return {
                    'query_name': query_name,
                    'status': 'failed',
                    'execution_time': execution_time,
                    'row_count': 0,
                    'data': None,
                    'error_message': error_msg,
                    'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                }
        except requests.exceptions.Timeout:
            execution_time = time.time() - start_time
            error_msg = "查询超时（超过300秒）"
            self.logger.error("查询超时: {}".format(query_name))
            
            return {
                'query_name': query_name,
                'status': 'failed',
                'execution_time': execution_time,
                'row_count': 0,
                'data': None,
                'error_message': error_msg,
                'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
        except Exception as e:
            execution_time = time.time() - start_time
            error_msg = str(e)
            self.logger.error("查询执行异常: {}".format(query_name), e)
            
            return {
                'query_name': query_name,
                'status': 'failed',
                'execution_time': execution_time,
                'row_count': 0,
                'data': None,
                'error_message': error_msg,
                'timestamp': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
    
    def execute_all_queries(self, queries):
        """
        执行所有查询
        
        Args:
            queries: 查询字典 {query_name: query_data}
            
        Returns:
            dict: 所有查询结果字典
        """
        self.logger.info("开始执行查询...")
        
        results = {}
        success_count = 0
        fail_count = 0
        
        for query_name, query_data in queries.items():
            sql = query_data['sql']
            result = self.execute_query(query_name, sql)
            results[query_name] = result
            
            if result['status'] == 'success':
                success_count += 1
            else:
                fail_count += 1
        
        self.logger.info("查询执行完成: 成功 {}, 失败 {}".format(success_count, fail_count))
        
        return results
