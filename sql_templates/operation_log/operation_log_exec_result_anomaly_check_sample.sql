-- exec_result异常占比核查 - 样例查询
-- 抽取除"成功"和"失败"外的异常值样例
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
        exec_result,
        log_id,
        operate_command
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        exec_result,
        log_id,
        operate_command
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
-- 返回异常值样例
SELECT 
    exec_result,
    log_id,
    operate_command
FROM all_logs
WHERE exec_result NOT IN ('成功', '失败', 'success', 'failed', 'SUCCESS', 'FAILED')
  AND exec_result IS NOT NULL 
  AND exec_result != ''
  AND exec_result NOT IN ('null', 'NULL')
LIMIT 10;
