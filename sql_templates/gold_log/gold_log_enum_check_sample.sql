-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例
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
      AND {field} IS NOT NULL 
      AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_result, {field}
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND {field} IS NOT NULL 
      AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        {field} AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY {field}
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.gold_grant_result) AS gold_grant_result
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.{field}
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    gold_grant_result
FROM distinct_values
ORDER BY value_count DESC, enum_value;
