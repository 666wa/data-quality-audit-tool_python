-- 详细查询模板
-- 根据log_id查询完整的generic_raw_log记录（只返回一条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 合并两个表的数据
all_records AS (
    SELECT generic_raw_log
    FROM {table_standard}
    WHERE log_id = '{sample_log_id}'
      AND {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT generic_raw_log
    FROM {table_error}
    WHERE log_id = '{sample_log_id}'
      AND {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
)
-- 3. 只返回一条记录
SELECT generic_raw_log
FROM all_records
LIMIT 1;
