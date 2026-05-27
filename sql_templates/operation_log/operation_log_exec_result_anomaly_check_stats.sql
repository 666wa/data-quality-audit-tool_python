-- exec_result异常占比核查 - 统计查询
-- 检查除"成功"和"失败"外的异常值占比
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
        exec_result
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        exec_result
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
-- 统计异常值
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN exec_result NOT IN ('成功', '失败', 'success', 'failed', 'SUCCESS', 'FAILED') 
               AND exec_result IS NOT NULL 
               AND exec_result != '' 
               AND exec_result NOT IN ('null', 'NULL') THEN 1 END) AS anomaly_count,
    round(COUNT(CASE WHEN exec_result NOT IN ('成功', '失败', 'success', 'failed', 'SUCCESS', 'FAILED') 
                     AND exec_result IS NOT NULL 
                     AND exec_result != '' 
                     AND exec_result NOT IN ('null', 'NULL') THEN 1 END) * 100.0 / COUNT(*), 4) AS anomaly_percentage
FROM all_logs;
