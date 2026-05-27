-- 账号加锁统计 - 样例查询
-- 抽取加锁账号样例
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
        dst_device_type,
        log_id
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED')
    
    UNION ALL
    
    SELECT 
        from_account_status,
        dst_device_type,
        log_id
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED')
)
-- 返回样例
SELECT 
    from_account_status AS locked_status,
    dst_device_type,
    log_id
FROM all_logs
LIMIT 10;
