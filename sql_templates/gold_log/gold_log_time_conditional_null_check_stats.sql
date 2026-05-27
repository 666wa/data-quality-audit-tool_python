-- 时间字段条件非空核查 - 统计版本
-- 在特定条件下检查时间字段是否为空
-- 注意：某些时间字段可能是字符串类型，需要特殊处理
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表（只查满足条件的记录）
all_logs AS ( 
    SELECT toString({field}) AS field_value
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {condition}
    
    UNION ALL 
    
    SELECT toString({field}) AS field_value
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND {condition}
),
-- 3. 统计空值（转换为字符串后检查）
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN field_value IS NULL 
                OR field_value = ''
                OR field_value = '1970-01-01 00:00:00.000'
                OR field_value = '1970-01-01 08:00:00.000'
                OR field_value < '1971-01-01 00:00:00'
            THEN 1 
            ELSE 0 
        END) AS null_count
    FROM all_logs
)
-- 4. 输出统计结果
SELECT 
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM stats
WHERE total_count > 0;
