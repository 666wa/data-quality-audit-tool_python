-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, {field}
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND ({field} IS NULL OR {field} = '' OR {field} IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, {field}
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND ({field} IS NULL OR {field} = '' OR {field} IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    {field} AS sample_value
FROM all_logs
LIMIT 10;
