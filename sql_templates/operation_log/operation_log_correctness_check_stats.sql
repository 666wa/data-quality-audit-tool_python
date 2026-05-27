-- 正确性核查 - 统计查询
-- 检查字段值是否在预期范围内
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
-- 按设备类型分组统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_records,
        COUNT(DISTINCT {field}) AS distinct_values,
        COUNT(CASE WHEN {field} IS NULL OR {field} = '' THEN 1 END) AS null_or_empty_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 返回统计结果
SELECT 
    dst_device_type,
    total_records,
    distinct_values,
    null_or_empty_count,
    round(null_or_empty_count * 100.0 / total_records, 4) AS null_percentage
FROM device_stats
ORDER BY dst_device_type;
