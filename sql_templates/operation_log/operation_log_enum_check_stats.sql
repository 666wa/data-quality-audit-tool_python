-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT {field}, dst_device_type
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
      AND {field} IS NOT NULL AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT {field}, dst_device_type
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range) 
      AND {field} IS NOT NULL AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        {field} AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, {field}
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT {field}) AS distinct_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 5. 输出按设备类型分组的统计结果
SELECT 
    dvs.dst_device_type,
    dt.total_count AS total_records,
    dt.distinct_count AS distinct_values,
    dvs.field_value,
    dvs.value_count,
    round(dvs.value_count * 100.0 / dt.total_count, 4) AS percentage
FROM device_value_stats dvs
JOIN device_totals dt ON dvs.dst_device_type = dt.dst_device_type
ORDER BY dvs.dst_device_type, dvs.value_count DESC;
