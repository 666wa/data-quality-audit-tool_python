-- 条件非空核查 - 样例版本（只查log_id）
-- 返回一个在特定条件下为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
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
