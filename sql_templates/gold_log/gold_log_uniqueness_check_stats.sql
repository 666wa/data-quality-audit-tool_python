-- 唯一性核查 - 统计版本
-- 检查gold_grant_result的唯一性（组合键）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表，构建组合键
all_logs AS ( 
    SELECT 
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT 
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
),
-- 3. 统计重复记录
duplicate_stats AS (
    SELECT 
        composite_key,
        COUNT(*) AS duplicate_count
    FROM all_logs
    GROUP BY composite_key
    HAVING COUNT(*) > 1
)
-- 4. 输出统计结果
SELECT 
    COUNT(*) AS duplicate_keys,
    SUM(duplicate_count) AS total_duplicate_records
FROM duplicate_stats;
