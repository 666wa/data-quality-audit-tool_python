-- 金库日志表数据量统计 - 样例查询
-- 对于统计类任务，样例查询返回与统计查询相同的结果
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
)
-- 统计各表数据量
SELECT 
    'standard' AS table_type,
    COUNT(*) AS record_count
FROM {table_standard}
WHERE {time_field} >= (SELECT start_ts FROM time_range) 
  AND {time_field} < (SELECT end_ts FROM time_range)
  AND standby1 IS NULL

UNION ALL

SELECT 
    'error' AS table_type,
    COUNT(*) AS record_count
FROM {table_error}
WHERE {time_field} >= (SELECT start_ts FROM time_range) 
  AND {time_field} < (SELECT end_ts FROM time_range)

ORDER BY table_type;
