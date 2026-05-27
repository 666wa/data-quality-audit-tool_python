-- 统计分析 - 样例查询
-- 抽取代表性样例
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
        dst_device_type,
        log_id
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        {field},
        dst_device_type,
        log_id
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
),
-- 获取不同的值（最多10个）
distinct_samples AS (
    SELECT DISTINCT
        {field},
        dst_device_type,
        any(log_id) AS log_id
    FROM all_logs
    WHERE {field} IS NOT NULL
    GROUP BY {field}, dst_device_type
    LIMIT 10
)
-- 返回样例
SELECT 
    {field} AS sample_value,
    dst_device_type,
    log_id
FROM distinct_samples
ORDER BY dst_device_type, sample_value;
