-- 唯一性核查 - 样例版本
-- 返回重复记录的样例
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
        gold_grant_result,
        resource_pool,
        gold_exec_result,
        approved_user_name,
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT 
        gold_grant_result,
        resource_pool,
        gold_exec_result,
        approved_user_name,
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
),
-- 3. 找出重复的组合键
duplicate_keys AS (
    SELECT 
        composite_key,
        COUNT(*) AS duplicate_count
    FROM all_logs
    GROUP BY composite_key
    HAVING COUNT(*) > 1
)
-- 4. 返回样例（最多10个重复键）
SELECT 
    composite_key,
    duplicate_count
FROM duplicate_keys
ORDER BY duplicate_count DESC
LIMIT 10;
