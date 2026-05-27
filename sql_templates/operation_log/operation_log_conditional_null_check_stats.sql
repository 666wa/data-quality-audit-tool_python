-- 条件非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型在特定条件下为空的记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT {field}, dst_device_type
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT {field}, dst_device_type
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN {field} IS NULL OR {field} = '' OR {field} IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;
