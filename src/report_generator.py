# -*- coding: utf-8 -*-
"""
报告生成器
生成稽核报告，包含统计、样例和详情
按设备类型分组展示
"""

from datetime import datetime
from pathlib import Path


class ASCIITable:
    """ASCII 表格生成器
    
    生成标准的 ASCII 边框表格，支持中文字符宽度计算。
    """
    
    def __init__(self, padding=1):
        """
        初始化 ASCII 表格
        
        Args:
            padding: 单元格内容与边框的间距（默认1）
        """
        self.padding = padding
        self.headers = []
        self.rows = []
    
    def set_headers(self, headers):
        """设置表头"""
        self.headers = [str(h) for h in headers]
    
    def add_row(self, row):
        """添加数据行"""
        self.rows.append([str(cell) for cell in row])
    
    @staticmethod
    def _display_width(text):
        """计算文本显示宽度（中文算2，英文算1）"""
        width = 0
        for char in str(text):
            if ord(char) > 127:
                width += 2
            else:
                width += 1
        return width
    
    def _calc_column_widths(self):
        """计算每列最优宽度"""
        if not self.headers and not self.rows:
            return []
        
        num_cols = len(self.headers) if self.headers else len(self.rows[0])
        widths = [0] * num_cols
        
        # 考虑表头
        for i, header in enumerate(self.headers):
            widths[i] = max(widths[i], self._display_width(header))
        
        # 考虑数据行
        for row in self.rows:
            for i, cell in enumerate(row):
                if i < num_cols:
                    widths[i] = max(widths[i], self._display_width(cell))
        
        return widths
    
    def _pad_cell(self, text, width, align='l'):
        """填充单元格到指定宽度"""
        text_width = self._display_width(text)
        padding = width - text_width
        
        if padding <= 0:
            return text
        
        if align == 'r':
            return ' ' * padding + text
        else:
            return text + ' ' * padding
    
    def _build_separator(self, widths):
        """构建分隔行"""
        parts = []
        for w in widths:
            parts.append('-' * (w + self.padding * 2))
        return '+' + '+'.join(parts) + '+'
    
    def _build_row(self, cells, widths, align='l'):
        """构建数据行"""
        parts = []
        for i, cell in enumerate(cells):
            if i < len(widths):
                padded = self._pad_cell(cell, widths[i], align)
                parts.append(' ' * self.padding + padded + ' ' * self.padding)
        return '|' + '|'.join(parts) + '|'
    
    def render(self):
        """渲染完整表格"""
        if not self.headers and not self.rows:
            return ""
        
        widths = self._calc_column_widths()
        lines = []
        
        # 顶部分隔线
        lines.append(self._build_separator(widths))
        
        # 表头
        if self.headers:
            lines.append(self._build_row(self.headers, widths, 'l'))
            lines.append(self._build_separator(widths))
        
        # 数据行
        for row in self.rows:
            lines.append(self._build_row(row, widths, 'l'))
        
        # 底部分隔线
        lines.append(self._build_separator(widths))
        
        return '\n'.join(lines)


class ReportGenerator:
    """报告生成器"""
    
    def __init__(self, logger):
        """
        初始化报告生成器
        
        Args:
            logger: 日志记录器实例
        """
        self.logger = logger
        self.column_width = 10  # 每列固定宽度（字符数）
    
    def get_display_width(self, text):
        """
        计算文本的显示宽度（中文字符算2个宽度，英文算1个）
        
        Args:
            text: 文本字符串
            
        Returns:
            int: 显示宽度
        """
        width = 0
        for char in str(text):
            # 中文字符、全角字符占2个宽度
            if ord(char) > 127:
                width += 2
            else:
                width += 1
        return width
    
    def format_cell(self, text, width=10):
        """
        格式化单元格内容，固定宽度
        
        Args:
            text: 单元格文本
            width: 目标宽度（默认10）
            
        Returns:
            list: 格式化后的行列表（可能多行）
        """
        text = str(text)
        lines = []
        current_line = ""
        current_width = 0
        
        for char in text:
            char_width = 2 if ord(char) > 127 else 1
            
            # 如果加上当前字符会超出宽度，换行
            if current_width + char_width > width:
                # 补齐当前行
                padding = width - current_width
                lines.append(current_line + ' ' * padding)
                current_line = char
                current_width = char_width
            else:
                current_line += char
                current_width += char_width
        
        # 处理最后一行
        if current_line:
            padding = width - current_width
            lines.append(current_line + ' ' * padding)
        
        # 如果没有内容，返回空行
        if not lines:
            lines.append(' ' * width)
        
        return lines
    
    def format_table_line(self, cells, widths=None):
        """
        格式化表格的一行（支持多行单元格）
        
        Args:
            cells: 单元格列表
            widths: 每列宽度列表（默认都是10）
            
        Returns:
            list: 格式化后的行列表
        """
        if widths is None:
            widths = [self.column_width] * len(cells)
        
        # 格式化每个单元格
        formatted_cells = []
        max_lines = 1
        for i, cell in enumerate(cells):
            width = widths[i] if i < len(widths) else self.column_width
            cell_lines = self.format_cell(cell, width)
            formatted_cells.append(cell_lines)
            max_lines = max(max_lines, len(cell_lines))
        
        # 组合成多行
        result_lines = []
        for line_idx in range(max_lines):
            line_parts = []
            for cell_lines in formatted_cells:
                if line_idx < len(cell_lines):
                    line_parts.append(cell_lines[line_idx])
                else:
                    # 补空行
                    line_parts.append(' ' * self.column_width)
            result_lines.append('  '.join(line_parts))
        
        return result_lines
    
    def parse_stats_data(self, stats_result):
        """
        解析统计结果
        
        Args:
            stats_result: 统计查询结果
            
        Returns:
            dict: 解析后的统计数据
        """
        if not stats_result or stats_result['status'] != 'success':
            return None
        
        data = stats_result.get('data', '')
        if not data:
            return None
        
        lines = data.strip().split('\n')
        if len(lines) < 2:
            return None
        
        headers = lines[0].split('\t')
        values = lines[1].split('\t')
        
        # 构建字典
        stats = {}
        for i, header in enumerate(headers):
            if i < len(values):
                stats[header] = values[i]
        
        return stats
    
    def _render_stats_table(self, stats_data):
        """
        使用 ASCIITable 渲染统计数据
        
        Args:
            stats_data: 原始统计数据字符串（TabSeparatedWithNames格式）
            
        Returns:
            str: 格式化后的 ASCII 表格字符串
        """
        if not stats_data:
            return ""
        
        stats_lines = stats_data.strip().split('\n')
        if len(stats_lines) == 0:
            return ""
        
        table = ASCIITable(padding=1)
        
        # 表头
        headers = stats_lines[0].split('\t')
        table.set_headers(headers)
        
        # 数据行
        for data_line in stats_lines[1:]:
            cells = data_line.split('\t')
            table.add_row(cells)
        
        return table.render()
    
    def format_audit_result(self, result):
        """
        格式化单个稽核结果
        
        Args:
            result: 稽核结果字典
            
        Returns:
            str: 格式化后的文本
        """
        lines = []
        lines.append("-" * 80)
        
        # 检查是否是特殊任务
        if result.get('is_special', False):
            lines.append(f"特殊任务: {result['field']}")
            lines.append(f"任务类型: {result['check_type']}")
            lines.append(f"状态: {result['status']}")
            lines.append("")
            
            # 显示统计结果
            if result['stats'] and result['stats']['status'] == 'success':
                lines.append("【统计结果】")
                stats_data = result['stats'].get('data', '')
                if stats_data:
                    table_str = self._render_stats_table(stats_data)
                    if table_str:
                        for line in table_str.split('\n'):
                            lines.append(f"  {line}")
                lines.append("")
            
            return '\n'.join(lines)
        
        # 普通字段稽核任务
        lines.append(f"字段: {result['field']}")
        lines.append(f"检查类型: {result['check_type']}")
        lines.append(f"状态: {result['status']}")
        lines.append("")
        
        # 统计信息（按设备类型分组）
        if result['stats']:
            lines.append("【统计结果 - 按设备类型分组】")
            stats_data = result['stats'].get('data', '')
            if stats_data:
                table_str = self._render_stats_table(stats_data)
                if table_str:
                    for line in table_str.split('\n'):
                        lines.append(f"  {line}")
                    # 计算汇总
                    stats_lines = stats_data.strip().split('\n')
                    if len(stats_lines) > 1:
                        lines.append("")
                        lines.append(f"  共 {len(stats_lines) - 1} 个设备类型")
            lines.append("")
        
        # 样例信息（保持原样，不格式化表格）
        if result['sample'] and result['sample']['status'] == 'success':
            lines.append("【样例数据】")
            sample_data = result['sample'].get('data', '')
            if sample_data:
                # 直接显示原始内容，不做表格格式化
                sample_lines = sample_data.strip().split('\n')
                for line in sample_lines:
                    lines.append(f"  {line}")
            lines.append("")
        
        # 详细信息（完整显示，不截断，不格式化表格）
        if result['detail'] and result['detail']['status'] == 'success':
            lines.append("【详细记录】")
            detail_data = result['detail'].get('data', '')
            if detail_data:
                # 完整显示所有内容，不做任何截断或格式化
                detail_lines = detail_data.strip().split('\n')
                for line in detail_lines:
                    # 如果行中包含 generic_raw_log，尝试解码 Unicode 转义
                    if 'generic_raw_log' in line and '\\u' in line:
                        try:
                            # 提取 generic_raw_log 的值
                            parts = line.split('\t')
                            decoded_parts = []
                            for part in parts:
                                # 尝试解码 JSON 字符串中的 Unicode 转义
                                if '\\u' in part:
                                    try:
                                        # 使用 unicode_escape 解码
                                        decoded = part.encode('utf-8').decode('unicode_escape')
                                        decoded_parts.append(decoded)
                                    except:
                                        decoded_parts.append(part)
                                else:
                                    decoded_parts.append(part)
                            line = '\t'.join(decoded_parts)
                        except:
                            pass  # 解码失败则使用原始内容
                    # 直接输出原始内容，不做表格格式化
                    lines.append(f"  {line}")
            lines.append("")
        
        return '\n'.join(lines)
    
    def generate_summary(self, results):
        """
        生成汇总信息
        
        Args:
            results: 所有稽核结果列表
            
        Returns:
            str: 汇总文本
        """
        lines = []
        lines.append("=" * 80)
        lines.append("数据质量稽核报告")
        lines.append("=" * 80)
        lines.append(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        lines.append("")
        
        # 统计各状态数量
        status_count = {}
        for result in results:
            status = result['status']
            status_count[status] = status_count.get(status, 0) + 1
        
        lines.append("【执行汇总】")
        lines.append(f"总任务数: {len(results)}")
        for status, count in status_count.items():
            lines.append(f"  {status}: {count}")
        lines.append("")
        lines.append("=" * 80)
        lines.append("")
        
        return '\n'.join(lines)
    
    def generate_report(self, results, table_name=None, output_dir='output'):
        """
        生成完整报告
        
        Args:
            results: 所有稽核结果列表
            table_name: 表名（可选，用于生成带表名的报告文件）
            output_dir: 输出目录
            
        Returns:
            str: 报告文件路径
        """
        self.logger.info("开始生成稽核报告...")
        
        # 创建输出目录
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        # 生成报告文件名
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        if table_name:
            report_file = output_path / f"{table_name}_report_{timestamp}.txt"
        else:
            report_file = output_path / f"audit_report_{timestamp}.txt"
        
        try:
            with open(report_file, 'w', encoding='utf-8') as f:
                # 写入汇总
                f.write(self.generate_summary(results))
                
                # 写入详细结果
                for result in results:
                    f.write(self.format_audit_result(result))
                    f.write("\n")
                
                # 写入结束标记
                f.write("=" * 80)
                f.write("\n报告生成完成\n")
                f.write("=" * 80)
            
            self.logger.info(f"报告已生成: {report_file}")
            return str(report_file)
        
        except Exception as e:
            self.logger.error(f"生成报告失败", e)
            return None
