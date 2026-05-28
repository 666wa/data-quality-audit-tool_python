-- 数据质量稽核 - 批量SQL查询
-- 表名: operation_log
-- 生成时间: 2026-05-28 01:40:23
-- 时间范围: 2026-01-12 00:00:00 ~ 2026-01-13 00:00:00

-- 任务: 日志ID唯一性检查 (log_id_uniqueness) - 统计查询
-- 唯一性核查 - 统计版本（按设备类型分组，优化性能）
-- 统计每个设备类型的重复记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT log_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型和字段值分组，找出重复的
field_counts AS (
    SELECT 
        log_id,
        dst_device_type,
        COUNT(*) AS repeat_count
    FROM all_logs
    GROUP BY log_id, dst_device_type
),
-- 4. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        SUM(repeat_count) AS total_count,
        SUM(CASE WHEN repeat_count > 1 THEN repeat_count ELSE 0 END) AS duplicate_count
    FROM field_counts
    GROUP BY dst_device_type
)
-- 5. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    duplicate_count AS duplicate_records,
    round(duplicate_count * 100.0 / total_count, 4) AS duplicate_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY duplicate_percentage DESC, total_count DESC;

-- 任务: 日志ID唯一性检查 (log_id_uniqueness) - 样例查询
-- 唯一性核查 - 样例版本（只查log_id）
-- 返回一个重复字段值的log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, log_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT log_id, log_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 找出重复的字段值
duplicates AS (
    SELECT log_id, dst_device_type, COUNT(*) AS repeat_count
    FROM all_logs
    GROUP BY log_id, dst_device_type
    HAVING COUNT(*) > 1
    ORDER BY repeat_count DESC
    LIMIT 1
)
-- 4. 返回一个样例log_id
SELECT log_id, dst_device_type
FROM all_logs
WHERE log_id = (SELECT log_id FROM duplicates)
  AND dst_device_type = (SELECT dst_device_type FROM duplicates)
LIMIT 1;

-- 任务: 日志ID非空检查 (log_id_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT log_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN log_id IS NULL OR log_id = '' OR log_id IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 日志ID非空检查 (log_id_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, log_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (log_id IS NULL OR log_id = '' OR log_id IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, log_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (log_id IS NULL OR log_id = '' OR log_id IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 会话ID非空检查 (session_id_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT session_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT session_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN session_id IS NULL OR session_id = '' OR session_id IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 会话ID非空检查 (session_id_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, session_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (session_id IS NULL OR session_id = '' OR session_id IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, session_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (session_id IS NULL OR session_id = '' OR session_id IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 日志来源枚举值检查 (log_source_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND log_source IS NOT NULL AND log_source != ''
      AND log_source NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND log_source IS NOT NULL AND log_source != ''
      AND log_source NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        log_source AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, log_source
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT log_source) AS distinct_count
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

-- 任务: 日志来源枚举值检查 (log_source_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, log_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND log_source IS NOT NULL AND log_source != ''
      AND log_source NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, log_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND log_source IS NOT NULL AND log_source != ''
      AND log_source NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        log_source AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY log_source
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.log_source
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 日志来源非空检查 (log_source_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT log_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT log_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN log_source IS NULL OR log_source = '' OR log_source IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 日志来源非空检查 (log_source_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, log_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (log_source IS NULL OR log_source = '' OR log_source IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, log_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (log_source IS NULL OR log_source = '' OR log_source IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 操作来源枚举值检查 (operate_source_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND operate_source IS NOT NULL AND operate_source != ''
      AND operate_source NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND operate_source IS NOT NULL AND operate_source != ''
      AND operate_source NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        operate_source AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, operate_source
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT operate_source) AS distinct_count
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

-- 任务: 操作来源枚举值检查 (operate_source_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND operate_source IS NOT NULL AND operate_source != ''
      AND operate_source NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND operate_source IS NOT NULL AND operate_source != ''
      AND operate_source NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        operate_source AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY operate_source
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.operate_source
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 操作来源非空检查 (operate_source_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN operate_source IS NULL OR operate_source = '' OR operate_source IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 操作来源非空检查 (operate_source_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_source IS NULL OR operate_source = '' OR operate_source IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, operate_source, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_source IS NULL OR operate_source = '' OR operate_source IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 自然人组织路径非空检查 (natural_org_path_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT natural_org_path, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT natural_org_path, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN natural_org_path IS NULL OR natural_org_path = '' OR natural_org_path IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 自然人组织路径非空检查 (natural_org_path_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, natural_org_path, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (natural_org_path IS NULL OR natural_org_path = '' OR natural_org_path IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, natural_org_path, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (natural_org_path IS NULL OR natural_org_path = '' OR natural_org_path IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 自然人姓名非空检查 (natural_name_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT natural_name, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT natural_name, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN natural_name IS NULL OR natural_name = '' OR natural_name IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 自然人姓名非空检查 (natural_name_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, natural_name, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (natural_name IS NULL OR natural_name = '' OR natural_name IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, natural_name, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (natural_name IS NULL OR natural_name = '' OR natural_name IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 自然人状态非空检查 (natural_status_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN natural_status IS NULL OR natural_status = '' OR natural_status IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 自然人状态非空检查 (natural_status_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (natural_status IS NULL OR natural_status = '' OR natural_status IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (natural_status IS NULL OR natural_status = '' OR natural_status IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 自然人状态枚举值检查 (natural_status_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND natural_status IS NOT NULL AND natural_status != ''
      AND natural_status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND natural_status IS NOT NULL AND natural_status != ''
      AND natural_status NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        natural_status AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, natural_status
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT natural_status) AS distinct_count
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

-- 任务: 自然人状态枚举值检查 (natural_status_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND natural_status IS NOT NULL AND natural_status != ''
      AND natural_status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, natural_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND natural_status IS NOT NULL AND natural_status != ''
      AND natural_status NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        natural_status AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY natural_status
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.natural_status
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 账号ID非空检查 (account_id_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT account_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT account_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN account_id IS NULL OR account_id = '' OR account_id IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 账号ID非空检查 (account_id_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, account_id, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_id IS NULL OR account_id = '' OR account_id IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, account_id, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_id IS NULL OR account_id = '' OR account_id IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 账号名称非空检查 (account_name_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT account_name, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT account_name, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN account_name IS NULL OR account_name = '' OR account_name IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 账号名称非空检查 (account_name_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, account_name, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_name IS NULL OR account_name = '' OR account_name IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, account_name, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_name IS NULL OR account_name = '' OR account_name IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 账号状态枚举值检查 (account_status_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_status IS NOT NULL AND account_status != ''
      AND account_status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_status IS NOT NULL AND account_status != ''
      AND account_status NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        account_status AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, account_status
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT account_status) AS distinct_count
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

-- 任务: 账号状态枚举值检查 (account_status_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_status IS NOT NULL AND account_status != ''
      AND account_status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_status IS NOT NULL AND account_status != ''
      AND account_status NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        account_status AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY account_status
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.account_status
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 账号状态非空检查 (account_status_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN account_status IS NULL OR account_status = '' OR account_status IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 账号状态非空检查 (account_status_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_status IS NULL OR account_status = '' OR account_status IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_status IS NULL OR account_status = '' OR account_status IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 账号角色枚举值检查 (account_role_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT account_role, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_role IS NOT NULL AND account_role != ''
      AND account_role NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT account_role, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_role IS NOT NULL AND account_role != ''
      AND account_role NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        account_role AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, account_role
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT account_role) AS distinct_count
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

-- 任务: 账号角色枚举值检查 (account_role_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, account_role, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_role IS NOT NULL AND account_role != ''
      AND account_role NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, account_role, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND account_role IS NOT NULL AND account_role != ''
      AND account_role NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        account_role AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY account_role
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.account_role
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 账号角色非空检查 (account_role_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT account_role, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT account_role, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN account_role IS NULL OR account_role = '' OR account_role IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 账号角色非空检查 (account_role_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, account_role, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_role IS NULL OR account_role = '' OR account_role IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, account_role, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (account_role IS NULL OR account_role = '' OR account_role IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 责任人条件非空检查 (person_liable_conditional_null) - 统计查询
-- 条件非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型在特定条件下为空的记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT person_liable, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT person_liable, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN person_liable IS NULL OR person_liable = '' OR person_liable IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 责任人条件非空检查 (person_liable_conditional_null) - 样例查询
-- 条件非空核查 - 样例版本（只查log_id）
-- 返回一个在特定条件下为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, person_liable, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (person_liable IS NULL OR person_liable = '' OR person_liable IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, person_liable, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (person_liable IS NULL OR person_liable = '' OR person_liable IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 来源账号条件非空检查 (from_account_conditional_null) - 统计查询
-- 条件非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型在特定条件下为空的记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT from_account, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT from_account, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN from_account IS NULL OR from_account = '' OR from_account IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 来源账号条件非空检查 (from_account_conditional_null) - 样例查询
-- 条件非空核查 - 样例版本（只查log_id）
-- 返回一个在特定条件下为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, from_account, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (from_account IS NULL OR from_account = '' OR from_account IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, from_account, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (from_account IS NULL OR from_account = '' OR from_account IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 来源账号状态枚举值检查 (from_account_status_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_status IS NOT NULL AND from_account_status != ''
      AND from_account_status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_status IS NOT NULL AND from_account_status != ''
      AND from_account_status NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        from_account_status AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, from_account_status
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT from_account_status) AS distinct_count
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

-- 任务: 来源账号状态枚举值检查 (from_account_status_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_status IS NOT NULL AND from_account_status != ''
      AND from_account_status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_status IS NOT NULL AND from_account_status != ''
      AND from_account_status NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        from_account_status AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY from_account_status
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.from_account_status
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 来源账号状态条件非空检查 (from_account_status_conditional_null) - 统计查询
-- 条件非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型在特定条件下为空的记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN from_account_status IS NULL OR from_account_status = '' OR from_account_status IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 来源账号状态条件非空检查 (from_account_status_conditional_null) - 样例查询
-- 条件非空核查 - 样例版本（只查log_id）
-- 返回一个在特定条件下为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (from_account_status IS NULL OR from_account_status = '' OR from_account_status IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, from_account_status, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (from_account_status IS NULL OR from_account_status = '' OR from_account_status IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 来源账号类型枚举值检查 (from_account_type_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_type IS NOT NULL AND from_account_type != ''
      AND from_account_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_type IS NOT NULL AND from_account_type != ''
      AND from_account_type NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        from_account_type AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, from_account_type
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT from_account_type) AS distinct_count
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

-- 任务: 来源账号类型枚举值检查 (from_account_type_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_type IS NOT NULL AND from_account_type != ''
      AND from_account_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND from_account_type IS NOT NULL AND from_account_type != ''
      AND from_account_type NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        from_account_type AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY from_account_type
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.from_account_type
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 来源账号类型条件非空检查 (from_account_type_conditional_null) - 统计查询
-- 条件非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型在特定条件下为空的记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN from_account_type IS NULL OR from_account_type = '' OR from_account_type IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 来源账号类型条件非空检查 (from_account_type_conditional_null) - 样例查询
-- 条件非空核查 - 样例版本（只查log_id）
-- 返回一个在特定条件下为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (from_account_type IS NULL OR from_account_type = '' OR from_account_type IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, from_account_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (from_account_type IS NULL OR from_account_type = '' OR from_account_type IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 客户端IP非空检查 (custom_ip_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT custom_ip, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT custom_ip, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN custom_ip IS NULL OR custom_ip = '' OR custom_ip IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 客户端IP非空检查 (custom_ip_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, custom_ip, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (custom_ip IS NULL OR custom_ip = '' OR custom_ip IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, custom_ip, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (custom_ip IS NULL OR custom_ip = '' OR custom_ip IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 客户端语义检查 (client_semantic) - 统计查询
-- 语义抽查 - 统计查询
-- 检查字段是否包含乱码、特殊字符等异常值
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        client,
        dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND client IS NOT NULL
      AND client != ''
      AND client NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        client,
        dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND client IS NOT NULL
      AND client != ''
      AND client NOT IN ('null', 'NULL')
),
-- 按设备类型分组统计，检测异常值
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_records,
        COUNT(DISTINCT client) AS distinct_values,
        -- 统计包含乱码或异常字符的记录数
        SUM(CASE 
            WHEN client LIKE '%�%'  -- 包含乱码字符
                OR client LIKE '%\x00%'  -- 包含空字符
                OR client LIKE '%\x01%'  -- 包含控制字符
                OR client LIKE '%\x02%'
                OR client LIKE '%\x03%'
                OR client LIKE '%\x04%'
                OR client LIKE '%\x05%'
                OR client LIKE '%\x06%'
                OR client LIKE '%\x07%'
                OR client LIKE '%\x08%'
                OR client LIKE '%\x0B%'
                OR client LIKE '%\x0C%'
                OR client LIKE '%\x0E%'
                OR client LIKE '%\x0F%'
                OR length(client) != lengthUTF8(client)  -- 字节长度与字符长度不一致（可能是乱码）
            THEN 1 
            ELSE 0 
        END) AS abnormal_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 返回统计结果
SELECT 
    dst_device_type,
    total_records,
    distinct_values,
    abnormal_count AS abnormal_records,
    round(abnormal_count * 100.0 / total_records, 4) AS abnormal_percentage
FROM device_stats
WHERE total_records > 0
ORDER BY abnormal_percentage DESC, total_records DESC;

-- 任务: 客户端语义检查 (client_semantic) - 样例查询
-- 语义抽查 - 样例查询
-- 优先返回包含异常字符的样例，如果没有则随机抽取10个不同的值进行人工检查
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        client,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND client IS NOT NULL
      AND client != ''
      AND client NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        client,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND client IS NOT NULL
      AND client != ''
      AND client NOT IN ('null', 'NULL')
),
-- 标记异常值
marked_logs AS (
    SELECT 
        client,
        dst_device_type,
        log_id,
        CASE 
            WHEN client LIKE '%�%'  -- 包含乱码字符
                OR client LIKE '%\x00%'  -- 包含空字符
                OR client LIKE '%\x01%'  -- 包含控制字符
                OR client LIKE '%\x02%'
                OR client LIKE '%\x03%'
                OR client LIKE '%\x04%'
                OR client LIKE '%\x05%'
                OR client LIKE '%\x06%'
                OR client LIKE '%\x07%'
                OR client LIKE '%\x08%'
                OR client LIKE '%\x0B%'
                OR client LIKE '%\x0C%'
                OR client LIKE '%\x0E%'
                OR client LIKE '%\x0F%'
                OR length(client) != lengthUTF8(client)  -- 字节长度与字符长度不一致
            THEN 1 
            ELSE 0 
        END AS is_abnormal
    FROM all_logs
),
-- 获取不同的值（优先异常值，最多10个）
distinct_samples AS (
    SELECT DISTINCT
        client,
        dst_device_type,
        any(log_id) AS log_id,
        max(is_abnormal) AS is_abnormal
    FROM marked_logs
    GROUP BY client, dst_device_type
    ORDER BY is_abnormal DESC, dst_device_type, client
    LIMIT 10
)
-- 返回样例
SELECT 
    client AS sample_value,
    dst_device_type,
    log_id,
    CASE WHEN is_abnormal = 1 THEN '异常' ELSE '正常' END AS status
FROM distinct_samples
ORDER BY is_abnormal DESC, dst_device_type, sample_value;

-- 任务: 操作时间非空检查 (operate_time_time_null) - 统计查询
-- 时间字段非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的时间字段空值情况
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT operate_time, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT operate_time, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计（时间字段只检查IS NULL）
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN operate_time IS NULL THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 操作时间非空检查 (operate_time_time_null) - 样例查询
-- 时间字段非空核查 - 样例版本（只查log_id）
-- 返回一个时间字段为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, operate_time, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND operate_time IS NULL
    
    UNION ALL 
    
    SELECT log_id, operate_time, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND operate_time IS NULL
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 采集时间非空检查 (collect_time_time_null) - 统计查询
-- 时间字段非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的时间字段空值情况
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT collect_time, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT collect_time, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计（时间字段只检查IS NULL）
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN collect_time IS NULL THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 采集时间非空检查 (collect_time_time_null) - 样例查询
-- 时间字段非空核查 - 样例版本（只查log_id）
-- 返回一个时间字段为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, collect_time, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND collect_time IS NULL
    
    UNION ALL 
    
    SELECT log_id, collect_time, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND collect_time IS NULL
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 服务器IP非空检查 (server_ip_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT server_ip, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT server_ip, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN server_ip IS NULL OR server_ip = '' OR server_ip IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 服务器IP非空检查 (server_ip_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, server_ip, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (server_ip IS NULL OR server_ip = '' OR server_ip IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, server_ip, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (server_ip IS NULL OR server_ip = '' OR server_ip IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 目标设备类型枚举值检查 (dst_device_type_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND dst_device_type IS NOT NULL AND dst_device_type != ''
      AND dst_device_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND dst_device_type IS NOT NULL AND dst_device_type != ''
      AND dst_device_type NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        dst_device_type AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, dst_device_type
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT dst_device_type) AS distinct_count
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

-- 任务: 目标设备类型枚举值检查 (dst_device_type_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND dst_device_type IS NOT NULL AND dst_device_type != ''
      AND dst_device_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND dst_device_type IS NOT NULL AND dst_device_type != ''
      AND dst_device_type NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        dst_device_type AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.dst_device_type
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 目标设备类型非空检查 (dst_device_type_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN dst_device_type IS NULL OR dst_device_type = '' OR dst_device_type IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 目标设备类型非空检查 (dst_device_type_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (dst_device_type IS NULL OR dst_device_type = '' OR dst_device_type IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, dst_device_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (dst_device_type IS NULL OR dst_device_type = '' OR dst_device_type IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 协议条件非空检查 (protocol_conditional_null) - 统计查询
-- 条件非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型在特定条件下为空的记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT protocol, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT protocol, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN protocol IS NULL OR protocol = '' OR protocol IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 协议条件非空检查 (protocol_conditional_null) - 样例查询
-- 条件非空核查 - 样例版本（只查log_id）
-- 返回一个在特定条件下为空的样例log_id
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, protocol, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (protocol IS NULL OR protocol = '' OR protocol IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, protocol, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (protocol IS NULL OR protocol = '' OR protocol IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 操作名称语义检查 (operate_name_semantic) - 统计查询
-- 语义抽查 - 统计查询
-- 检查字段是否包含乱码、特殊字符等异常值
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        operate_name,
        dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_name IS NOT NULL
      AND operate_name != ''
      AND operate_name NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        operate_name,
        dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_name IS NOT NULL
      AND operate_name != ''
      AND operate_name NOT IN ('null', 'NULL')
),
-- 按设备类型分组统计，检测异常值
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_records,
        COUNT(DISTINCT operate_name) AS distinct_values,
        -- 统计包含乱码或异常字符的记录数
        SUM(CASE 
            WHEN operate_name LIKE '%�%'  -- 包含乱码字符
                OR operate_name LIKE '%\x00%'  -- 包含空字符
                OR operate_name LIKE '%\x01%'  -- 包含控制字符
                OR operate_name LIKE '%\x02%'
                OR operate_name LIKE '%\x03%'
                OR operate_name LIKE '%\x04%'
                OR operate_name LIKE '%\x05%'
                OR operate_name LIKE '%\x06%'
                OR operate_name LIKE '%\x07%'
                OR operate_name LIKE '%\x08%'
                OR operate_name LIKE '%\x0B%'
                OR operate_name LIKE '%\x0C%'
                OR operate_name LIKE '%\x0E%'
                OR operate_name LIKE '%\x0F%'
                OR length(operate_name) != lengthUTF8(operate_name)  -- 字节长度与字符长度不一致（可能是乱码）
            THEN 1 
            ELSE 0 
        END) AS abnormal_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 返回统计结果
SELECT 
    dst_device_type,
    total_records,
    distinct_values,
    abnormal_count AS abnormal_records,
    round(abnormal_count * 100.0 / total_records, 4) AS abnormal_percentage
FROM device_stats
WHERE total_records > 0
ORDER BY abnormal_percentage DESC, total_records DESC;

-- 任务: 操作名称语义检查 (operate_name_semantic) - 样例查询
-- 语义抽查 - 样例查询
-- 优先返回包含异常字符的样例，如果没有则随机抽取10个不同的值进行人工检查
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        operate_name,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_name IS NOT NULL
      AND operate_name != ''
      AND operate_name NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        operate_name,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_name IS NOT NULL
      AND operate_name != ''
      AND operate_name NOT IN ('null', 'NULL')
),
-- 标记异常值
marked_logs AS (
    SELECT 
        operate_name,
        dst_device_type,
        log_id,
        CASE 
            WHEN operate_name LIKE '%�%'  -- 包含乱码字符
                OR operate_name LIKE '%\x00%'  -- 包含空字符
                OR operate_name LIKE '%\x01%'  -- 包含控制字符
                OR operate_name LIKE '%\x02%'
                OR operate_name LIKE '%\x03%'
                OR operate_name LIKE '%\x04%'
                OR operate_name LIKE '%\x05%'
                OR operate_name LIKE '%\x06%'
                OR operate_name LIKE '%\x07%'
                OR operate_name LIKE '%\x08%'
                OR operate_name LIKE '%\x0B%'
                OR operate_name LIKE '%\x0C%'
                OR operate_name LIKE '%\x0E%'
                OR operate_name LIKE '%\x0F%'
                OR length(operate_name) != lengthUTF8(operate_name)  -- 字节长度与字符长度不一致
            THEN 1 
            ELSE 0 
        END AS is_abnormal
    FROM all_logs
),
-- 获取不同的值（优先异常值，最多10个）
distinct_samples AS (
    SELECT DISTINCT
        operate_name,
        dst_device_type,
        any(log_id) AS log_id,
        max(is_abnormal) AS is_abnormal
    FROM marked_logs
    GROUP BY operate_name, dst_device_type
    ORDER BY is_abnormal DESC, dst_device_type, operate_name
    LIMIT 10
)
-- 返回样例
SELECT 
    operate_name AS sample_value,
    dst_device_type,
    log_id,
    CASE WHEN is_abnormal = 1 THEN '异常' ELSE '正常' END AS status
FROM distinct_samples
ORDER BY is_abnormal DESC, dst_device_type, sample_value;

-- 任务: 操作命令非空检查 (operate_command_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT operate_command, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT operate_command, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN operate_command IS NULL OR operate_command = '' OR operate_command IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 操作命令非空检查 (operate_command_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, operate_command, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_command IS NULL OR operate_command = '' OR operate_command IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, operate_command, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_command IS NULL OR operate_command = '' OR operate_command IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 操作命令语义检查 (operate_command_semantic) - 统计查询
-- 语义抽查 - 统计查询
-- 检查字段是否包含乱码、特殊字符等异常值
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        operate_command,
        dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_command IS NOT NULL
      AND operate_command != ''
      AND operate_command NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        operate_command,
        dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_command IS NOT NULL
      AND operate_command != ''
      AND operate_command NOT IN ('null', 'NULL')
),
-- 按设备类型分组统计，检测异常值
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_records,
        COUNT(DISTINCT operate_command) AS distinct_values,
        -- 统计包含乱码或异常字符的记录数
        SUM(CASE 
            WHEN operate_command LIKE '%�%'  -- 包含乱码字符
                OR operate_command LIKE '%\x00%'  -- 包含空字符
                OR operate_command LIKE '%\x01%'  -- 包含控制字符
                OR operate_command LIKE '%\x02%'
                OR operate_command LIKE '%\x03%'
                OR operate_command LIKE '%\x04%'
                OR operate_command LIKE '%\x05%'
                OR operate_command LIKE '%\x06%'
                OR operate_command LIKE '%\x07%'
                OR operate_command LIKE '%\x08%'
                OR operate_command LIKE '%\x0B%'
                OR operate_command LIKE '%\x0C%'
                OR operate_command LIKE '%\x0E%'
                OR operate_command LIKE '%\x0F%'
                OR length(operate_command) != lengthUTF8(operate_command)  -- 字节长度与字符长度不一致（可能是乱码）
            THEN 1 
            ELSE 0 
        END) AS abnormal_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 返回统计结果
SELECT 
    dst_device_type,
    total_records,
    distinct_values,
    abnormal_count AS abnormal_records,
    round(abnormal_count * 100.0 / total_records, 4) AS abnormal_percentage
FROM device_stats
WHERE total_records > 0
ORDER BY abnormal_percentage DESC, total_records DESC;

-- 任务: 操作命令语义检查 (operate_command_semantic) - 样例查询
-- 语义抽查 - 样例查询
-- 优先返回包含异常字符的样例，如果没有则随机抽取10个不同的值进行人工检查
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        operate_command,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_command IS NOT NULL
      AND operate_command != ''
      AND operate_command NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        operate_command,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_command IS NOT NULL
      AND operate_command != ''
      AND operate_command NOT IN ('null', 'NULL')
),
-- 标记异常值
marked_logs AS (
    SELECT 
        operate_command,
        dst_device_type,
        log_id,
        CASE 
            WHEN operate_command LIKE '%�%'  -- 包含乱码字符
                OR operate_command LIKE '%\x00%'  -- 包含空字符
                OR operate_command LIKE '%\x01%'  -- 包含控制字符
                OR operate_command LIKE '%\x02%'
                OR operate_command LIKE '%\x03%'
                OR operate_command LIKE '%\x04%'
                OR operate_command LIKE '%\x05%'
                OR operate_command LIKE '%\x06%'
                OR operate_command LIKE '%\x07%'
                OR operate_command LIKE '%\x08%'
                OR operate_command LIKE '%\x0B%'
                OR operate_command LIKE '%\x0C%'
                OR operate_command LIKE '%\x0E%'
                OR operate_command LIKE '%\x0F%'
                OR length(operate_command) != lengthUTF8(operate_command)  -- 字节长度与字符长度不一致
            THEN 1 
            ELSE 0 
        END AS is_abnormal
    FROM all_logs
),
-- 获取不同的值（优先异常值，最多10个）
distinct_samples AS (
    SELECT DISTINCT
        operate_command,
        dst_device_type,
        any(log_id) AS log_id,
        max(is_abnormal) AS is_abnormal
    FROM marked_logs
    GROUP BY operate_command, dst_device_type
    ORDER BY is_abnormal DESC, dst_device_type, operate_command
    LIMIT 10
)
-- 返回样例
SELECT 
    operate_command AS sample_value,
    dst_device_type,
    log_id,
    CASE WHEN is_abnormal = 1 THEN '异常' ELSE '正常' END AS status
FROM distinct_samples
ORDER BY is_abnormal DESC, dst_device_type, sample_value;

-- 任务: 操作内容非空检查 (operate_content_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT operate_content, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT operate_content, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN operate_content IS NULL OR operate_content = '' OR operate_content IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 操作内容非空检查 (operate_content_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, operate_content, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_content IS NULL OR operate_content = '' OR operate_content IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, operate_content, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_content IS NULL OR operate_content = '' OR operate_content IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 操作内容语义检查 (operate_content_semantic) - 统计查询
-- 语义抽查 - 统计查询
-- 检查字段是否包含乱码、特殊字符等异常值
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        operate_content,
        dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_content IS NOT NULL
      AND operate_content != ''
      AND operate_content NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        operate_content,
        dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_content IS NOT NULL
      AND operate_content != ''
      AND operate_content NOT IN ('null', 'NULL')
),
-- 按设备类型分组统计，检测异常值
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_records,
        COUNT(DISTINCT operate_content) AS distinct_values,
        -- 统计包含乱码或异常字符的记录数
        SUM(CASE 
            WHEN operate_content LIKE '%�%'  -- 包含乱码字符
                OR operate_content LIKE '%\x00%'  -- 包含空字符
                OR operate_content LIKE '%\x01%'  -- 包含控制字符
                OR operate_content LIKE '%\x02%'
                OR operate_content LIKE '%\x03%'
                OR operate_content LIKE '%\x04%'
                OR operate_content LIKE '%\x05%'
                OR operate_content LIKE '%\x06%'
                OR operate_content LIKE '%\x07%'
                OR operate_content LIKE '%\x08%'
                OR operate_content LIKE '%\x0B%'
                OR operate_content LIKE '%\x0C%'
                OR operate_content LIKE '%\x0E%'
                OR operate_content LIKE '%\x0F%'
                OR length(operate_content) != lengthUTF8(operate_content)  -- 字节长度与字符长度不一致（可能是乱码）
            THEN 1 
            ELSE 0 
        END) AS abnormal_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 返回统计结果
SELECT 
    dst_device_type,
    total_records,
    distinct_values,
    abnormal_count AS abnormal_records,
    round(abnormal_count * 100.0 / total_records, 4) AS abnormal_percentage
FROM device_stats
WHERE total_records > 0
ORDER BY abnormal_percentage DESC, total_records DESC;

-- 任务: 操作内容语义检查 (operate_content_semantic) - 样例查询
-- 语义抽查 - 样例查询
-- 优先返回包含异常字符的样例，如果没有则随机抽取10个不同的值进行人工检查
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        operate_content,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_content IS NOT NULL
      AND operate_content != ''
      AND operate_content NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        operate_content,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND operate_content IS NOT NULL
      AND operate_content != ''
      AND operate_content NOT IN ('null', 'NULL')
),
-- 标记异常值
marked_logs AS (
    SELECT 
        operate_content,
        dst_device_type,
        log_id,
        CASE 
            WHEN operate_content LIKE '%�%'  -- 包含乱码字符
                OR operate_content LIKE '%\x00%'  -- 包含空字符
                OR operate_content LIKE '%\x01%'  -- 包含控制字符
                OR operate_content LIKE '%\x02%'
                OR operate_content LIKE '%\x03%'
                OR operate_content LIKE '%\x04%'
                OR operate_content LIKE '%\x05%'
                OR operate_content LIKE '%\x06%'
                OR operate_content LIKE '%\x07%'
                OR operate_content LIKE '%\x08%'
                OR operate_content LIKE '%\x0B%'
                OR operate_content LIKE '%\x0C%'
                OR operate_content LIKE '%\x0E%'
                OR operate_content LIKE '%\x0F%'
                OR length(operate_content) != lengthUTF8(operate_content)  -- 字节长度与字符长度不一致
            THEN 1 
            ELSE 0 
        END AS is_abnormal
    FROM all_logs
),
-- 获取不同的值（优先异常值，最多10个）
distinct_samples AS (
    SELECT DISTINCT
        operate_content,
        dst_device_type,
        any(log_id) AS log_id,
        max(is_abnormal) AS is_abnormal
    FROM marked_logs
    GROUP BY operate_content, dst_device_type
    ORDER BY is_abnormal DESC, dst_device_type, operate_content
    LIMIT 10
)
-- 返回样例
SELECT 
    operate_content AS sample_value,
    dst_device_type,
    log_id,
    CASE WHEN is_abnormal = 1 THEN '异常' ELSE '正常' END AS status
FROM distinct_samples
ORDER BY is_abnormal DESC, dst_device_type, sample_value;

-- 任务: 操作类型非空检查 (operate_type_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT operate_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT operate_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN operate_type IS NULL OR operate_type = '' OR operate_type IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 操作类型非空检查 (operate_type_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, operate_type, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_type IS NULL OR operate_type = '' OR operate_type IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, operate_type, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (operate_type IS NULL OR operate_type = '' OR operate_type IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 执行结果枚举值检查 (exec_result_enum) - 统计查询
-- 枚举值核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND exec_result IS NOT NULL AND exec_result != ''
      AND exec_result NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND exec_result IS NOT NULL AND exec_result != ''
      AND exec_result NOT IN ('null', 'NULL')
),
-- 3. 按设备类型和字段值统计
device_value_stats AS (
    SELECT 
        dst_device_type,
        exec_result AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY dst_device_type, exec_result
),
-- 4. 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        COUNT(DISTINCT exec_result) AS distinct_count
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

-- 任务: 执行结果枚举值检查 (exec_result_enum) - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例供人工检查
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT log_id, exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND exec_result IS NOT NULL AND exec_result != ''
      AND exec_result NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT log_id, exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND exec_result IS NOT NULL AND exec_result != ''
      AND exec_result NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        exec_result AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY exec_result
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.dst_device_type) AS dst_device_type,
        any(al.log_id) AS log_id
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.exec_result
    GROUP BY vc.enum_value, vc.value_count
    ORDER BY vc.value_count DESC, vc.enum_value
    LIMIT 10
)
-- 5. 返回样例
SELECT 
    enum_value,
    value_count,
    dst_device_type,
    log_id
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- 任务: 执行结果非空检查 (exec_result_null) - 统计查询
-- 非空核查 - 统计版本（按设备类型分组）
-- 统计每个设备类型的空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段，不查generic_raw_log）
all_logs AS ( 
    SELECT exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
    
    UNION ALL 
    
    SELECT exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
),
-- 3. 按设备类型统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_count,
        SUM(CASE WHEN exec_result IS NULL OR exec_result = '' OR exec_result IN ('null', 'NULL') THEN 1 ELSE 0 END) AS null_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 4. 输出按设备类型分组的统计结果
SELECT 
    dst_device_type,
    total_count AS total_records,
    null_count AS null_records,
    round(null_count * 100.0 / total_count, 4) AS null_percentage
FROM device_stats
WHERE total_count > 0
ORDER BY null_percentage DESC, total_count DESC;

-- 任务: 执行结果非空检查 (exec_result_null) - 样例查询
-- 非空核查 - 样例版本（只查log_id，不查generic_raw_log）
-- 返回一个空值记录的log_id和设备类型
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查log_id和dst_device_type，不查generic_raw_log）
all_logs AS ( 
    SELECT log_id, exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (exec_result IS NULL OR exec_result = '' OR exec_result IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT log_id, exec_result, dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range) 
      AND (exec_result IS NULL OR exec_result = '' OR exec_result IN ('null', 'NULL'))
)
-- 3. 返回一个样例（只返回log_id）
SELECT log_id, dst_device_type
FROM all_logs
LIMIT 1;

-- 任务: 执行结果异常占比检查 (exec_result_anomaly) - 统计查询
-- exec_result异常占比核查 - 统计查询
-- 检查除"成功"和"失败"外的异常值占比
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        exec_result
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        exec_result
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
)
-- 统计异常值
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN exec_result NOT IN ('成功', '失败', 'success', 'failed', 'SUCCESS', 'FAILED') 
               AND exec_result IS NOT NULL 
               AND exec_result != '' 
               AND exec_result NOT IN ('null', 'NULL') THEN 1 END) AS anomaly_count,
    round(COUNT(CASE WHEN exec_result NOT IN ('成功', '失败', 'success', 'failed', 'SUCCESS', 'FAILED') 
                     AND exec_result IS NOT NULL 
                     AND exec_result != '' 
                     AND exec_result NOT IN ('null', 'NULL') THEN 1 END) * 100.0 / COUNT(*), 4) AS anomaly_percentage
FROM all_logs;

-- 任务: 执行结果异常占比检查 (exec_result_anomaly) - 样例查询
-- exec_result异常占比核查 - 样例查询
-- 抽取除"成功"和"失败"外的异常值样例
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        exec_result,
        log_id,
        operate_command
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        exec_result,
        log_id,
        operate_command
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
)
-- 返回异常值样例
SELECT 
    exec_result,
    log_id,
    operate_command
FROM all_logs
WHERE exec_result NOT IN ('成功', '失败', 'success', 'failed', 'SUCCESS', 'FAILED')
  AND exec_result IS NOT NULL 
  AND exec_result != ''
  AND exec_result NOT IN ('null', 'NULL')
LIMIT 10;

-- 任务: 数据库服务正确性检查 (database_service_correctness) - 统计查询
-- 正确性核查 - 统计查询
-- 检查字段值是否在预期范围内
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        database_service,
        dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        database_service,
        dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 按设备类型分组统计
device_stats AS (
    SELECT 
        dst_device_type,
        COUNT(*) AS total_records,
        COUNT(DISTINCT database_service) AS distinct_values,
        COUNT(CASE WHEN database_service IS NULL OR database_service = '' THEN 1 END) AS null_or_empty_count
    FROM all_logs
    GROUP BY dst_device_type
)
-- 返回统计结果
SELECT 
    dst_device_type,
    total_records,
    distinct_values,
    null_or_empty_count,
    round(null_or_empty_count * 100.0 / total_records, 4) AS null_percentage
FROM device_stats
ORDER BY dst_device_type;

-- 任务: 数据库服务正确性检查 (database_service_correctness) - 样例查询
-- 正确性核查 - 样例查询
-- 抽取不符合预期的样例数据
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        database_service,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        database_service,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
)
-- 返回异常样例（空值或空字符串）
SELECT 
    database_service AS field_value,
    dst_device_type,
    log_id
FROM all_logs
WHERE database_service IS NULL OR database_service = ''
LIMIT 10;

-- 任务: 来源账号加锁统计 (from_account_status_locked) - 统计查询
-- 账号加锁统计 - 统计查询
-- 统计加锁账号的数量和占比
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        from_account_status,
        dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        from_account_status,
        dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
)
-- 统计加锁账号
SELECT 
    COUNT(*) AS total_records,
    COUNT(CASE WHEN from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED') THEN 1 END) AS locked_count,
    round(COUNT(CASE WHEN from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED') THEN 1 END) * 100.0 / COUNT(*), 4) AS locked_percentage
FROM all_logs;

-- 任务: 来源账号加锁统计 (from_account_status_locked) - 样例查询
-- 账号加锁统计 - 样例查询
-- 抽取加锁账号样例
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        from_account_status,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED')
    
    UNION ALL
    
    SELECT 
        from_account_status,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND from_account_status IN ('锁定', '加锁', 'locked', 'LOCKED')
)
-- 返回样例
SELECT 
    from_account_status AS locked_status,
    dst_device_type,
    log_id
FROM all_logs
LIMIT 10;

-- 任务: 黄金授权结果统计分析 (gold_grant_result_statistical) - 统计查询
-- 统计分析 - 统计查询
-- 对字段进行统计分析
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        gold_grant_result,
        dst_device_type
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        gold_grant_result,
        dst_device_type
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 按设备类型和字段值分组统计
value_stats AS (
    SELECT 
        dst_device_type,
        gold_grant_result,
        COUNT(*) AS value_count
    FROM all_logs
    WHERE gold_grant_result IS NOT NULL
    GROUP BY dst_device_type, gold_grant_result
),
-- 计算每个设备类型的总数
device_totals AS (
    SELECT 
        dst_device_type,
        SUM(value_count) AS total_count
    FROM value_stats
    GROUP BY dst_device_type
)
-- 返回统计结果（显示前10个最常见的值）
SELECT 
    vs.dst_device_type,
    vs.gold_grant_result AS field_value,
    vs.value_count,
    round(vs.value_count * 100.0 / dt.total_count, 4) AS percentage
FROM value_stats vs
JOIN device_totals dt ON vs.dst_device_type = dt.dst_device_type
ORDER BY vs.dst_device_type, vs.value_count DESC
LIMIT 30;

-- 任务: 黄金授权结果统计分析 (gold_grant_result_statistical) - 样例查询
-- 统计分析 - 样例查询
-- 抽取代表性样例
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-13 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        gold_grant_result,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT 
        gold_grant_result,
        dst_device_type,
        log_id
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 获取不同的值（最多10个）
distinct_samples AS (
    SELECT DISTINCT
        gold_grant_result,
        dst_device_type,
        any(log_id) AS log_id
    FROM all_logs
    WHERE gold_grant_result IS NOT NULL
    GROUP BY gold_grant_result, dst_device_type
    LIMIT 10
)
-- 返回样例
SELECT 
    gold_grant_result AS sample_value,
    dst_device_type,
    log_id
FROM distinct_samples
ORDER BY dst_device_type, sample_value;
