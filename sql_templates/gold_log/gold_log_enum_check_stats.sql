-- 枚举值核查 - 统计版本
-- 统计枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT {field}
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {field} IS NOT NULL 
      AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT {field}
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND {field} IS NOT NULL 
      AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的数量
value_stats AS (
    SELECT 
        {field} AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY {field}
),
-- 4. 计算总数
total_stats AS (
    SELECT 
        COUNT(*) AS total_count,
        COUNT(DISTINCT {field}) AS distinct_count
    FROM all_logs
)
-- 5. 输出统计结果
SELECT 
    ts.total_count AS total_records,
    ts.distinct_count AS distinct_values,
    vs.field_value,
    vs.value_count,
    round(vs.value_count * 100.0 / ts.total_count, 4) AS percentage
FROM value_stats vs
CROSS JOIN total_stats ts
ORDER BY vs.value_count DESC;
