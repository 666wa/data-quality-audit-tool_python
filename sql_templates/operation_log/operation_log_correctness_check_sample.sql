-- 正确性核查 - 样例查询
-- 抽取不符合预期的样例数据
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
)
-- 返回异常样例（空值或空字符串）
SELECT 
    {field} AS field_value,
    dst_device_type,
    log_id
FROM all_logs
WHERE {field} IS NULL OR {field} = ''
LIMIT 10;
