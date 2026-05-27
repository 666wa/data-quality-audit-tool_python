-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, {field}, dst_device_type
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
      AND ({field} IS NULL OR {field} = '' OR {field} IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, {field}, dst_device_type
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
      AND ({field} IS NULL OR {field} = '' OR {field} IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;
