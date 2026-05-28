# -*- coding: utf-8 -*-
"""
数据质量稽核工具 - 主程序
采用三阶段执行策略：统计 -> 样例 -> 详情
按设备类型分组统计

使用方式：
  python main.py              # 执行完整稽核流程
  python main.py --gen-sql    # 生成大SQL文件
"""

import sys
import argparse
from pathlib import Path
from datetime import datetime

# 添加src目录到路径
sys.path.insert(0, str(Path(__file__).parent / 'src'))

from config_manager import ConfigManager
from logger import AuditLogger
from db_executor import DatabaseExecutor
from audit_executor import AuditExecutor
from report_generator import ReportGenerator
from config_validator import ConfigValidator
from init_wizard import InitWizard


def generate_big_sql(config_manager, logger, table_name):
    """
    生成大SQL文件
    
    Args:
        config_manager: 配置管理器
        logger: 日志记录器
        table_name: 表名（必需）
        
    Returns:
        str: 生成的SQL文件路径
    """
    logger.info("=" * 60)
    logger.info("开始生成大SQL文件")
    logger.info("=" * 60)
    
    # 先加载配置文件以获取时间范围
    if not config_manager.load_config():
        logger.error("配置加载失败")
        return None
    
    # 加载表配置
    logger.info(f"使用表配置: {table_name}")
    table_config = config_manager.load_table_config(table_name)
    if not table_config:
        logger.error(f"表配置加载失败: {table_name}")
        return None
    
    audit_tasks = table_config
    
    # 获取配置参数
    config = config_manager.get_all_parameters()
    
    # 获取SQL模板根目录
    sql_templates_root = config.get('sql_templates_dir', './sql_templates')
    
    # 使用表配置中的表名
    table_info = table_config['table_info']
    params = {
        'table_standard': table_info.get('standard_table'),
        'table_error': table_info.get('error_table'),
        'time_field': table_info.get('time_field'),
        'start_time': config.get('start_time'),
        'end_time': config.get('end_time')
    }
    template_dir_name = table_info.get('template_dir', '')
    
    # 准备SQL模板目录
    if template_dir_name:
        templates_dir = Path(sql_templates_root) / template_dir_name
    else:
        templates_dir = Path(sql_templates_root)
    
    # 生成SQL语句列表
    sql_statements = []
    sql_statements.append("-- 数据质量稽核 - 批量SQL查询")
    if table_name:
        sql_statements.append(f"-- 表名: {table_name}")
    sql_statements.append(f"-- 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    sql_statements.append(f"-- 时间范围: {params['start_time']} ~ {params['end_time']}")
    sql_statements.append("")
    
    # 统计计数器
    stats_count = 0
    sample_count = 0
    special_count = 0
    
    # 检查是否使用新的任务化配置
    if 'tasks' in audit_tasks:
        # 新的任务化配置格式
        logger.info("使用任务化配置生成SQL")
        for task in audit_tasks.get('tasks', []):
            if not task.get('enabled', True):
                continue
            
            task_id = task.get('task_id')
            task_name = task.get('task_name')
            sql_template = task.get('sql_template')
            task_params = task.get('params', {})
            
            # 合并参数
            merged_params = {**params, **task_params}
            
            # 生成统计查询
            stats_template_path = templates_dir / f"{sql_template}_stats.sql"
            if stats_template_path.exists():
                with open(stats_template_path, 'r', encoding='utf-8') as f:
                    template = f.read()
                
                # 渲染模板
                sql = template
                for key, value in merged_params.items():
                    sql = sql.replace(f"{{{key}}}", str(value))
                
                sql_statements.append(f"-- 任务: {task_name} ({task_id}) - 统计查询")
                sql_statements.append(sql.strip())
                sql_statements.append("")
                stats_count += 1
            
            # 生成样例查询
            sample_template_path = templates_dir / f"{sql_template}_sample.sql"
            if sample_template_path.exists():
                with open(sample_template_path, 'r', encoding='utf-8') as f:
                    template = f.read()
                
                # 渲染模板
                sql = template
                for key, value in merged_params.items():
                    sql = sql.replace(f"{{{key}}}", str(value))
                
                sql_statements.append(f"-- 任务: {task_name} ({task_id}) - 样例查询")
                sql_statements.append(sql.strip())
                sql_statements.append("")
                sample_count += 1
    else:
        # 旧的配置格式（兼容）
        logger.info("使用旧配置格式生成SQL")
        # 遍历所有普通稽核任务
        for task in audit_tasks.get('audit_tasks', []):
            field = task['field']
            checks = task.get('checks', [])
            
            for check_type in checks:
                # 生成统计查询
                stats_template_path = templates_dir / f"{check_type}_stats.sql"
                if stats_template_path.exists():
                    with open(stats_template_path, 'r', encoding='utf-8') as f:
                        template = f.read()
                    
                    # 渲染模板
                    sql = template
                    for key, value in params.items():
                        sql = sql.replace(f"{{{key}}}", str(value))
                    sql = sql.replace("{field}", field)
                    
                    sql_statements.append(f"-- {field} - {check_type} - 统计查询")
                    sql_statements.append(sql.strip())
                    sql_statements.append("")
                    stats_count += 1
                
                # 生成样例查询
                sample_template_path = templates_dir / f"{check_type}_sample.sql"
                if sample_template_path.exists():
                    with open(sample_template_path, 'r', encoding='utf-8') as f:
                        template = f.read()
                    
                    # 渲染模板
                    sql = template
                    for key, value in params.items():
                        sql = sql.replace(f"{{{key}}}", str(value))
                    sql = sql.replace("{field}", field)
                    
                    sql_statements.append(f"-- {field} - {check_type} - 样例查询")
                    sql_statements.append(sql.strip())
                    sql_statements.append("")
                    sample_count += 1
        
        # 遍历所有特殊任务
        for task in audit_tasks.get('special_tasks', []):
            task_name = task['name']
            task_type = task['type']
            
            # 生成特殊任务查询
            special_template_path = templates_dir / f"{task_type}_stats.sql"
            if special_template_path.exists():
                with open(special_template_path, 'r', encoding='utf-8') as f:
                    template = f.read()
                
                # 渲染模板
                sql = template
                for key, value in params.items():
                    sql = sql.replace(f"{{{key}}}", str(value))
                
                sql_statements.append(f"-- 特殊任务: {task_name} - {task_type}")
                sql_statements.append(sql.strip())
                sql_statements.append("")
                special_count += 1
    
    # 添加详细查询模板
    detail_template_path = templates_dir / "detail_query.sql"
    if detail_template_path.exists():
        with open(detail_template_path, 'r', encoding='utf-8') as f:
            template = f.read()
        
        sql_statements.append("-- 详细查询模板（需要替换 {sample_log_id}）")
        sql_statements.append(template.strip())
        sql_statements.append("")
    
    # 写入文件
    output_dir = Path('big_sql')
    output_dir.mkdir(exist_ok=True)
    
    # 如果指定了表名，在文件名中包含表名
    if table_name:
        output_file = output_dir / f'{table_name}_generated.sql'
    else:
        output_file = output_dir / 'generated.sql'
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql_statements))
    
    logger.info(f"生成统计查询: {stats_count} 条")
    logger.info(f"生成样例查询: {sample_count} 条")
    logger.info(f"生成特殊任务查询: {special_count} 条")
    logger.info(f"生成详细查询模板: 1 条")
    logger.info(f"总计: {stats_count + sample_count + special_count + 1} 条SQL语句")
    logger.info(f"SQL文件已生成: {output_file}")
    logger.info("=" * 60)
    
    return str(output_file)


def run_audit(config_manager, logger, table_name):
    """
    执行完整稽核流程
    
    Args:
        config_manager: 配置管理器
        logger: 日志记录器
        table_name: 表名（必需）
        
    Returns:
        int: 退出码
    """
    logger.info("=" * 60)
    logger.info("数据质量稽核工具启动")
    logger.info("=" * 60)
    
    # 加载配置
    logger.info("加载配置文件...")
    if not config_manager.load_config():
        logger.error("配置加载失败，程序退出")
        return 1
    
    # 获取配置
    config = config_manager.get_all_parameters()
    
    # 加载表配置
    logger.info(f"使用表配置: {table_name}")
    table_config = config_manager.load_table_config(table_name)
    if not table_config:
        logger.error(f"表配置加载失败: {table_name}")
        return 1
    
    audit_tasks = table_config
    
    # 获取稽核任务名称（优先使用第一级的 task_name）
    task_display_name = table_config.get('task_name') or table_config.get('table_info', {}).get('display_name', table_name)
    
    # 统计任务数量
    task_count = len(audit_tasks.get('tasks', []))
    logger.info(f"稽核任务: {task_display_name}")
    logger.info(f"共加载 {task_count} 个子任务")
    
    # 初始化数据库执行器
    logger.info("初始化数据库连接...")
    db_config = config_manager.get_db_config()
    logger.info(f"连接到: {db_config['host']}:{db_config['port']}")
    db_executor = DatabaseExecutor(db_config, logger)
    
    # 测试连接
    if not db_executor.test_connection():
        logger.error("数据库连接失败，程序退出")
        return 1
    
    # 初始化稽核执行器
    logger.info("初始化稽核执行器...")
    audit_executor = AuditExecutor(db_executor, config, logger, table_config)
    
    # 执行稽核
    logger.info("开始执行稽核任务...")
    results = audit_executor.execute_all_audits(audit_tasks)
    
    # 生成报告
    logger.info("生成稽核报告...")
    report_generator = ReportGenerator(logger)
    
    # 如果有表名，在报告文件名中包含表名
    if table_name:
        report_file = report_generator.generate_report(results, table_name)
    else:
        report_file = report_generator.generate_report(results)
    
    if report_file:
        logger.info(f"稽核报告已生成: {report_file}")
    else:
        logger.error("报告生成失败")
    
    # 完成
    logger.info("=" * 60)
    logger.info("数据质量稽核完成")
    logger.info("=" * 60)
    
    return 0


def main():
    """主函数"""
    
    # 解析命令行参数
    parser = argparse.ArgumentParser(
        description='数据质量稽核工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  python main.py --task operation_log              # 执行操作日志稽核任务
  python main.py --task gold_log                   # 执行金库日志稽核任务
  python main.py --gen-sql --task operation_log    # 生成大SQL文件
  python main.py --all-tasks                       # 执行所有稽核任务
  python main.py --validate                        # 验证所有配置
  python main.py --init-task my_new_task            # 交互式生成新任务配置
        """
    )
    parser.add_argument(
        '--gen-sql',
        action='store_true',
        help='生成大SQL文件（不执行稽核）'
    )
    parser.add_argument(
        '--task',
        type=str,
        help='指定要执行的稽核任务（如 gold_log, operation_log）'
    )
    # 保留 --table 作为别名，向后兼容
    parser.add_argument(
        '--table',
        type=str,
        dest='task',
        help=argparse.SUPPRESS  # 隐藏此选项，但保持兼容性
    )
    parser.add_argument(
        '--all-tasks',
        action='store_true',
        help='执行所有稽核任务'
    )
    # 保留 --all-tables 作为别名，向后兼容
    parser.add_argument(
        '--all-tables',
        action='store_true',
        dest='all_tasks',
        help=argparse.SUPPRESS  # 隐藏此选项，但保持兼容性
    )
    parser.add_argument(
        '--validate',
        action='store_true',
        help='验证所有配置文件的完整性和一致性'
    )
    parser.add_argument(
        '--init-task',
        type=str,
        metavar='TASK_NAME',
        help='交互式生成新的稽核任务配置和SQL模板'
    )
    
    args = parser.parse_args()
    
    # 初始化日志
    logger = AuditLogger()
    
    try:
        # 初始化配置管理器
        config_manager = ConfigManager('config/config.yaml', logger)
        
        # 根据参数选择执行模式
        
        # 1. 配置生成向导模式（最高优先级）
        if args.init_task:
            wizard = InitWizard(logger)
            success = wizard.run(args.init_task)
            return 0 if success else 1
        
        # 2. 配置验证模式
        if args.validate:
            if not config_manager.load_config():
                logger.error("配置加载失败")
                return 1
            validator = ConfigValidator(config_manager, logger)
            success = validator.validate_all()
            return 0 if success else 1
        
        # 2. 生成大SQL文件模式
        if args.gen_sql:
            # 生成大SQL文件模式
            if not args.task:
                logger.error("生成大SQL需要指定稽核任务，请使用 --task 参数")
                logger.info("示例: python main.py --gen-sql --task operation_log")
                return 1
            result = generate_big_sql(config_manager, logger, args.task)
            return 0 if result else 1
        elif args.all_tasks:
            # 稽核所有表
            logger.info("=" * 60)
            logger.info("总体稽核任务启动")
            logger.info("=" * 60)
            
            config_manager.load_config()
            tables = config_manager.list_all_tables()
            if not tables:
                logger.error("未找到任何稽核任务配置")
                return 1
            
            # 统计总体任务信息
            logger.info(f"发现 {len(tables)} 个稽核任务配置:")
            total_tasks = 0
            table_display_names = {}  # 存储稽核任务的显示名称
            for table in tables:
                table_config = config_manager.load_table_config(table)
                if table_config:
                    task_count = len(table_config.get('tasks', []))
                    total_tasks += task_count
                    # 优先使用第一级的 task_name，如果没有则使用 table_info.display_name
                    table_display_name = table_config.get('task_name') or table_config.get('table_info', {}).get('display_name', table)
                    table_display_names[table] = table_display_name
                    logger.info(f"  - {table_display_name} ({task_count} 个子任务)")
            
            logger.info(f"\n总体稽核任务统计:")
            logger.info(f"  稽核任务数量: {len(tables)}")
            logger.info(f"  子任务总数: {total_tasks}")
            logger.info("=" * 60)
            
            # 执行稽核
            success_count = 0
            failed_count = 0
            for i, table in enumerate(tables, 1):
                display_name = table_display_names.get(table, table)
                logger.info(f"\n{'='*60}")
                logger.info(f"[{i}/{len(tables)}] 执行稽核任务: {display_name}")
                logger.info(f"{'='*60}\n")
                result = run_audit(config_manager, logger, table)
                if result == 0:
                    success_count += 1
                else:
                    failed_count += 1
                    logger.error(f"稽核任务 {display_name} 执行失败")
            
            # 输出总体结果
            logger.info("\n" + "=" * 60)
            logger.info("总体稽核任务完成")
            logger.info("=" * 60)
            logger.info(f"稽核任务总数: {len(tables)}")
            logger.info(f"成功: {success_count}")
            logger.info(f"失败: {failed_count}")
            logger.info(f"成功率: {success_count * 100.0 / len(tables):.2f}%")
            logger.info("=" * 60)
            
            return 0 if failed_count == 0 else 1
        elif args.task:
            # 稽核指定任务
            return run_audit(config_manager, logger, args.task)
        else:
            # 必须指定任务或使用 --all-tasks
            logger.error("请指定要执行的稽核任务或使用 --all-tasks 参数")
            logger.info("使用示例:")
            logger.info("  python main.py --task operation_log    # 执行操作日志稽核任务")
            logger.info("  python main.py --task gold_log         # 执行金库日志稽核任务")
            logger.info("  python main.py --all-tasks             # 执行所有稽核任务")
            return 1
    
    except KeyboardInterrupt:
        logger.info("用户中断程序")
        return 130
    
    except Exception as e:
        logger.error("程序执行异常", e)
        return 1


if __name__ == '__main__':
    sys.exit(main())
