-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT {field}
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT {field}
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN {field} IS NULL 
                OR {field} = '' 
                OR {field} IN ('null', 'NULL') 
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
