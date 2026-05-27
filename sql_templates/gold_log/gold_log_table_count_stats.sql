-- 表数据量统计
-- 统计标准表和错误表的数据量
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 统计标准表
standard_count AS (
    SELECT 
        'standard' AS table_type,
        COUNT(*) AS record_count
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
),
-- 3. 统计错误表
error_count AS (
    SELECT 
        'error' AS table_type,
        COUNT(*) AS record_count
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
-- 4. 合并结果
SELECT 
    table_type,
    record_count
FROM standard_count
UNION ALL
SELECT 
    table_type,
    record_count
FROM error_count
ORDER BY table_type;
