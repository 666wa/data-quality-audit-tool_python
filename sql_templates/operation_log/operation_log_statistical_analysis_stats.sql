-- 统计分析 - 统计查询
-- 对字段进行统计分析
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        {field},
        dst_device_type
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        {field},
        dst_device_type
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
),
-- 按设备类型和字段值分组统计
value_stats AS (
    SELECT 
        dst_device_type,
        {field},
        COUNT(*) AS value_count
    FROM all_logs
    WHERE {field} IS NOT NULL
    GROUP BY dst_device_type, {field}
),
-- 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        SUM(value_count) AS total_count
    FROM value_stats
    GROUP BY dst_device_type
)
-- 返回统计结果（显示前10个最常见的值）
SELECT 
    vs.dst_device_type,
    vs.{field} AS field_value,
    vs.value_count,
    round(vs.value_count * 100.0 / dt.total_count, 4) AS percentage
FROM value_stats vs
JOIN device_totals dt ON vs.dst_device_type = dt.dst_device_type
ORDER BY vs.dst_device_type, vs.value_count DESC
LIMIT 30;
