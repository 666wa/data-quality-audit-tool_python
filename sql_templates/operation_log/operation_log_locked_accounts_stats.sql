-- 账号加锁统计 - 统计查询
-- 统计加锁账号的数量和占比
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
        from_account_status,
        dst_device_type
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        from_account_status,
        dst_device_type
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
-- 统计加锁账号
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED') THEN 1 END) AS locked_count,
    round(COUNT(CASE WHEN from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED') THEN 1 END) * 100.0 / COUNT(*), 4) AS locked_percentage
FROM all_logs;
