-- 唯一性核查 - 样例版本（只查log_id）
-- 返回一个重复字段值的log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, {field}, dst_device_type
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT log_id, {field}, dst_device_type
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
),
-- 3. 找出重复的字段值
duplicates AS (
    SELECT {field}, dst_device_type, COUNT(*) AS repeat_count
    FROM all_logs
    GROUP BY {field}, dst_device_type
    HAVING COUNT(*) > 1
    ORDER BY repeat_count DESC
    LIMIT 1
)
-- 4. 返回一个样例log_id
SELECT log_id, dst_device_type
FROM all_logs
WHERE {field} = (SELECT {field} FROM duplicates)
  AND dst_device_type = (SELECT dst_device_type FROM duplicates)
LIMIT 1;
