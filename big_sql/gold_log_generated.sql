-- 数据质量稽核 - 批量SQL查询
-- 表名: gold_log
-- 生成时间: 2026-01-21 18:49:00
-- 时间范围: 2026-01-12 00:00:00 ~ 2026-01-19 00:00:00

-- gold_grant_result - uniqueness_check - 统计查询
-- 唯一性核查 - 统计版本
-- 检查gold_grant_result的唯一性（组合键）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表，构建组合键
all_logs AS ( 
    SELECT 
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT 
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
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

-- gold_grant_result - uniqueness_check - 样例查询
-- 唯一性核查 - 样例版本
-- 返回重复记录的样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表，构建组合键
all_logs AS ( 
    SELECT 
        gold_grant_result,
        resource_pool,
        gold_exec_result,
        approved_user_name,
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT 
        gold_grant_result,
        resource_pool,
        gold_exec_result,
        approved_user_name,
        gold_grant_result || '+' || resource_pool || '+' || gold_exec_result || '+' || approved_user_name AS composite_key
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
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

-- gold_grant_result - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT gold_grant_result
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT gold_grant_result
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN gold_grant_result IS NULL 
                OR gold_grant_result = '' 
                OR gold_grant_result IN ('null', 'NULL') 
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

-- gold_grant_result - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, gold_grant_result
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (gold_grant_result IS NULL OR gold_grant_result = '' OR gold_grant_result IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, gold_grant_result
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (gold_grant_result IS NULL OR gold_grant_result = '' OR gold_grant_result IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    gold_grant_result AS sample_value
FROM all_logs
LIMIT 10;

-- resource_pool - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT resource_pool
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT resource_pool
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN resource_pool IS NULL 
                OR resource_pool = '' 
                OR resource_pool IN ('null', 'NULL') 
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

-- resource_pool - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, resource_pool
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (resource_pool IS NULL OR resource_pool = '' OR resource_pool IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, resource_pool
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (resource_pool IS NULL OR resource_pool = '' OR resource_pool IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    resource_pool AS sample_value
FROM all_logs
LIMIT 10;

-- account_id - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT account_id
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT account_id
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN account_id IS NULL 
                OR account_id = '' 
                OR account_id IN ('null', 'NULL') 
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

-- account_id - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, account_id
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (account_id IS NULL OR account_id = '' OR account_id IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, account_id
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (account_id IS NULL OR account_id = '' OR account_id IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    account_id AS sample_value
FROM all_logs
LIMIT 10;

-- natural_name - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT natural_name
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT natural_name
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN natural_name IS NULL 
                OR natural_name = '' 
                OR natural_name IN ('null', 'NULL') 
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

-- natural_name - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, natural_name
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (natural_name IS NULL OR natural_name = '' OR natural_name IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, natural_name
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (natural_name IS NULL OR natural_name = '' OR natural_name IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    natural_name AS sample_value
FROM all_logs
LIMIT 10;

-- account_role - enum_check - 统计查询
-- 枚举值核查 - 统计版本
-- 统计枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT account_role
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND account_role IS NOT NULL 
      AND account_role != ''
      AND account_role NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT account_role
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND account_role IS NOT NULL 
      AND account_role != ''
      AND account_role NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的数量
value_stats AS (
    SELECT 
        account_role AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY account_role
),
-- 4. 计算总数
total_stats AS (
    SELECT 
        COUNT(*) AS total_count,
        COUNT(DISTINCT account_role) AS distinct_count
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

-- account_role - enum_check - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, account_role
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND account_role IS NOT NULL 
      AND account_role != ''
      AND account_role NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_result, account_role
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND account_role IS NOT NULL 
      AND account_role != ''
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
        any(al.gold_grant_result) AS gold_grant_result
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
    gold_grant_result
FROM distinct_values
ORDER BY value_count DESC, enum_value;

-- account_role - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT account_role
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT account_role
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN account_role IS NULL 
                OR account_role = '' 
                OR account_role IN ('null', 'NULL') 
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

-- account_role - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, account_role
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (account_role IS NULL OR account_role = '' OR account_role IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, account_role
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (account_role IS NULL OR account_role = '' OR account_role IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    account_role AS sample_value
FROM all_logs
LIMIT 10;

-- from_account - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT from_account
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT from_account
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN from_account IS NULL 
                OR from_account = '' 
                OR from_account IN ('null', 'NULL') 
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

-- from_account - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, from_account
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (from_account IS NULL OR from_account = '' OR from_account IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, from_account
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (from_account IS NULL OR from_account = '' OR from_account IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    from_account AS sample_value
FROM all_logs
LIMIT 10;

-- req_reason - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT req_reason
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT req_reason
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN req_reason IS NULL 
                OR req_reason = '' 
                OR req_reason IN ('null', 'NULL') 
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

-- req_reason - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, req_reason
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (req_reason IS NULL OR req_reason = '' OR req_reason IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, req_reason
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (req_reason IS NULL OR req_reason = '' OR req_reason IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    req_reason AS sample_value
FROM all_logs
LIMIT 10;

-- gold_grant_type - enum_check - 统计查询
-- 枚举值核查 - 统计版本
-- 统计枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_type
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND gold_grant_type IS NOT NULL 
      AND gold_grant_type != ''
      AND gold_grant_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_type
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND gold_grant_type IS NOT NULL 
      AND gold_grant_type != ''
      AND gold_grant_type NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的数量
value_stats AS (
    SELECT 
        gold_grant_type AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY gold_grant_type
),
-- 4. 计算总数
total_stats AS (
    SELECT 
        COUNT(*) AS total_count,
        COUNT(DISTINCT gold_grant_type) AS distinct_count
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

-- gold_grant_type - enum_check - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, gold_grant_type
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND gold_grant_type IS NOT NULL 
      AND gold_grant_type != ''
      AND gold_grant_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_result, gold_grant_type
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND gold_grant_type IS NOT NULL 
      AND gold_grant_type != ''
      AND gold_grant_type NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        gold_grant_type AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY gold_grant_type
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.gold_grant_result) AS gold_grant_result
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.gold_grant_type
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

-- start_time - time_conditional_null_check - 统计查询
-- 时间字段条件非空核查 - 统计版本
-- 在特定条件下检查时间字段是否为空
-- 注意：某些时间字段可能是字符串类型，需要特殊处理
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查满足条件的记录）
all_logs AS ( 
    SELECT toString(start_time) AS field_value
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {condition}
    
    UNION ALL 
    
    SELECT toString(start_time) AS field_value
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
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

-- start_time - time_conditional_null_check - 样例查询
-- 时间字段条件非空核查 - 样例版本
-- 返回满足条件但时间字段为空的样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, start_time
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {condition}
      AND (start_time IS NULL 
           OR start_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR start_time = toDateTime64('1970-01-01 08:00:00', 3)
           OR start_time < toDateTime64('1971-01-01 00:00:00', 3))
    
    UNION ALL 
    
    SELECT gold_grant_result, start_time
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND {condition}
      AND (start_time IS NULL 
           OR start_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR start_time = toDateTime64('1970-01-01 08:00:00', 3)
           OR start_time < toDateTime64('1971-01-01 00:00:00', 3))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    start_time AS sample_value
FROM all_logs
LIMIT 10;

-- end_time - time_conditional_null_check - 统计查询
-- 时间字段条件非空核查 - 统计版本
-- 在特定条件下检查时间字段是否为空
-- 注意：某些时间字段可能是字符串类型，需要特殊处理
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查满足条件的记录）
all_logs AS ( 
    SELECT toString(end_time) AS field_value
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {condition}
    
    UNION ALL 
    
    SELECT toString(end_time) AS field_value
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
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

-- end_time - time_conditional_null_check - 样例查询
-- 时间字段条件非空核查 - 样例版本
-- 返回满足条件但时间字段为空的样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, end_time
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {condition}
      AND (end_time IS NULL 
           OR end_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR end_time = toDateTime64('1970-01-01 08:00:00', 3)
           OR end_time < toDateTime64('1971-01-01 00:00:00', 3))
    
    UNION ALL 
    
    SELECT gold_grant_result, end_time
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND {condition}
      AND (end_time IS NULL 
           OR end_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR end_time = toDateTime64('1970-01-01 08:00:00', 3)
           OR end_time < toDateTime64('1971-01-01 00:00:00', 3))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    end_time AS sample_value
FROM all_logs
LIMIT 10;

-- reservation_time - time_null_check - 统计查询
-- 时间字段非空核查 - 统计版本
-- 专门用于DateTime类型字段的空值检查
-- 注意：某些时间字段可能是字符串类型，需要特殊处理
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT toString(reservation_time) AS field_value
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT toString(reservation_time) AS field_value
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
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

-- reservation_time - time_null_check - 样例查询
-- 时间字段非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, reservation_time
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (reservation_time IS NULL 
           OR reservation_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR reservation_time = toDateTime64('1970-01-01 08:00:00', 3))
    
    UNION ALL 
    
    SELECT gold_grant_result, reservation_time
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (reservation_time IS NULL 
           OR reservation_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR reservation_time = toDateTime64('1970-01-01 08:00:00', 3))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    reservation_time AS sample_value
FROM all_logs
LIMIT 10;

-- approved_user_id - conditional_null_check - 统计查询
-- 条件非空核查 - 统计版本
-- 在特定条件下检查字段是否为空
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查满足条件的记录）
all_logs AS ( 
    SELECT approved_user_id
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {condition}
    
    UNION ALL 
    
    SELECT approved_user_id
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND {condition}
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN approved_user_id IS NULL 
                OR approved_user_id = '' 
                OR approved_user_id IN ('null', 'NULL') 
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

-- approved_user_id - conditional_null_check - 样例查询
-- 条件非空核查 - 样例版本
-- 返回满足条件但字段为空的样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, approved_user_id
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {condition}
      AND (approved_user_id IS NULL OR approved_user_id = '' OR approved_user_id IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, approved_user_id
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND {condition}
      AND (approved_user_id IS NULL OR approved_user_id = '' OR approved_user_id IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    approved_user_id AS sample_value
FROM all_logs
LIMIT 10;

-- approved_user_name - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT approved_user_name
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT approved_user_name
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN approved_user_name IS NULL 
                OR approved_user_name = '' 
                OR approved_user_name IN ('null', 'NULL') 
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

-- approved_user_name - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, approved_user_name
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (approved_user_name IS NULL OR approved_user_name = '' OR approved_user_name IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, approved_user_name
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (approved_user_name IS NULL OR approved_user_name = '' OR approved_user_name IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    approved_user_name AS sample_value
FROM all_logs
LIMIT 10;

-- approved_time - time_null_check - 统计查询
-- 时间字段非空核查 - 统计版本
-- 专门用于DateTime类型字段的空值检查
-- 注意：某些时间字段可能是字符串类型，需要特殊处理
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT toString(approved_time) AS field_value
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT toString(approved_time) AS field_value
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
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

-- approved_time - time_null_check - 样例查询
-- 时间字段非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, approved_time
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (approved_time IS NULL 
           OR approved_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR approved_time = toDateTime64('1970-01-01 08:00:00', 3))
    
    UNION ALL 
    
    SELECT gold_grant_result, approved_time
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (approved_time IS NULL 
           OR approved_time = toDateTime64('1970-01-01 00:00:00', 3)
           OR approved_time = toDateTime64('1970-01-01 08:00:00', 3))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    approved_time AS sample_value
FROM all_logs
LIMIT 10;

-- gold_exec_result - enum_check - 统计查询
-- 枚举值核查 - 统计版本
-- 统计枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_exec_result
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND gold_exec_result IS NOT NULL 
      AND gold_exec_result != ''
      AND gold_exec_result NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_exec_result
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND gold_exec_result IS NOT NULL 
      AND gold_exec_result != ''
      AND gold_exec_result NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的数量
value_stats AS (
    SELECT 
        gold_exec_result AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY gold_exec_result
),
-- 4. 计算总数
total_stats AS (
    SELECT 
        COUNT(*) AS total_count,
        COUNT(DISTINCT gold_exec_result) AS distinct_count
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

-- gold_exec_result - enum_check - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, gold_exec_result
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND gold_exec_result IS NOT NULL 
      AND gold_exec_result != ''
      AND gold_exec_result NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_result, gold_exec_result
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND gold_exec_result IS NOT NULL 
      AND gold_exec_result != ''
      AND gold_exec_result NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        gold_exec_result AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY gold_exec_result
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.gold_grant_result) AS gold_grant_result
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.gold_exec_result
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

-- gold_exec_result - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT gold_exec_result
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT gold_exec_result
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN gold_exec_result IS NULL 
                OR gold_exec_result = '' 
                OR gold_exec_result IN ('null', 'NULL') 
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

-- gold_exec_result - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, gold_exec_result
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (gold_exec_result IS NULL OR gold_exec_result = '' OR gold_exec_result IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, gold_exec_result
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (gold_exec_result IS NULL OR gold_exec_result = '' OR gold_exec_result IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    gold_exec_result AS sample_value
FROM all_logs
LIMIT 10;

-- auth_mode - enum_check - 统计查询
-- 枚举值核查 - 统计版本
-- 统计枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT auth_mode
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND auth_mode IS NOT NULL 
      AND auth_mode != ''
      AND auth_mode NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT auth_mode
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND auth_mode IS NOT NULL 
      AND auth_mode != ''
      AND auth_mode NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的数量
value_stats AS (
    SELECT 
        auth_mode AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY auth_mode
),
-- 4. 计算总数
total_stats AS (
    SELECT 
        COUNT(*) AS total_count,
        COUNT(DISTINCT auth_mode) AS distinct_count
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

-- auth_mode - enum_check - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, auth_mode
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND auth_mode IS NOT NULL 
      AND auth_mode != ''
      AND auth_mode NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_result, auth_mode
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND auth_mode IS NOT NULL 
      AND auth_mode != ''
      AND auth_mode NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        auth_mode AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY auth_mode
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.gold_grant_result) AS gold_grant_result
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.auth_mode
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

-- auth_mode - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT auth_mode
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT auth_mode
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN auth_mode IS NULL 
                OR auth_mode = '' 
                OR auth_mode IN ('null', 'NULL') 
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

-- auth_mode - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, auth_mode
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (auth_mode IS NULL OR auth_mode = '' OR auth_mode IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, auth_mode
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (auth_mode IS NULL OR auth_mode = '' OR auth_mode IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    auth_mode AS sample_value
FROM all_logs
LIMIT 10;

-- status - enum_check - 统计查询
-- 枚举值核查 - 统计版本
-- 统计枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT status
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND status IS NOT NULL 
      AND status != ''
      AND status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT status
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND status IS NOT NULL 
      AND status != ''
      AND status NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的数量
value_stats AS (
    SELECT 
        status AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY status
),
-- 4. 计算总数
total_stats AS (
    SELECT 
        COUNT(*) AS total_count,
        COUNT(DISTINCT status) AS distinct_count
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

-- status - enum_check - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, status
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND status IS NOT NULL 
      AND status != ''
      AND status NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_result, status
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND status IS NOT NULL 
      AND status != ''
      AND status NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        status AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY status
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.gold_grant_result) AS gold_grant_result
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.status
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

-- gold_scene_name - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT gold_scene_name
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT gold_scene_name
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN gold_scene_name IS NULL 
                OR gold_scene_name = '' 
                OR gold_scene_name IN ('null', 'NULL') 
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

-- gold_scene_name - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, gold_scene_name
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (gold_scene_name IS NULL OR gold_scene_name = '' OR gold_scene_name IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, gold_scene_name
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (gold_scene_name IS NULL OR gold_scene_name = '' OR gold_scene_name IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    gold_scene_name AS sample_value
FROM all_logs
LIMIT 10;

-- trigger_type - null_check - 统计查询
-- 非空核查 - 统计版本
-- 统计空值记录数量和比例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表（只查必要字段）
all_logs AS ( 
    SELECT trigger_type
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL 
    
    SELECT trigger_type
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
),
-- 3. 统计空值
stats AS (
    SELECT 
        COUNT(*) AS total_count,
        SUM(CASE 
            WHEN trigger_type IS NULL 
                OR trigger_type = '' 
                OR trigger_type IN ('null', 'NULL') 
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

-- trigger_type - null_check - 样例查询
-- 非空核查 - 样例版本
-- 返回空值样例（最多10条）
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, trigger_type
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND (trigger_type IS NULL OR trigger_type = '' OR trigger_type IN ('null', 'NULL'))
    
    UNION ALL 
    
    SELECT gold_grant_result, trigger_type
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND (trigger_type IS NULL OR trigger_type = '' OR trigger_type IN ('null', 'NULL'))
)
-- 3. 返回样例（最多10条）
SELECT 
    gold_grant_result,
    trigger_type AS sample_value
FROM all_logs
LIMIT 10;

-- trigger_type - enum_check - 统计查询
-- 枚举值核查 - 统计版本
-- 统计枚举值分布
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT trigger_type
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND trigger_type IS NOT NULL 
      AND trigger_type != ''
      AND trigger_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT trigger_type
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND trigger_type IS NOT NULL 
      AND trigger_type != ''
      AND trigger_type NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的数量
value_stats AS (
    SELECT 
        trigger_type AS field_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY trigger_type
),
-- 4. 计算总数
total_stats AS (
    SELECT 
        COUNT(*) AS total_count,
        COUNT(DISTINCT trigger_type) AS distinct_count
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

-- trigger_type - enum_check - 样例查询
-- 枚举值核查 - 样例版本
-- 返回最多10个不同的枚举值样例
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 联合查询两张表
all_logs AS ( 
    SELECT gold_grant_result, trigger_type
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND trigger_type IS NOT NULL 
      AND trigger_type != ''
      AND trigger_type NOT IN ('null', 'NULL')
    
    UNION ALL 
    
    SELECT gold_grant_result, trigger_type
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND trigger_type IS NOT NULL 
      AND trigger_type != ''
      AND trigger_type NOT IN ('null', 'NULL')
),
-- 3. 统计每个枚举值的出现次数
value_counts AS (
    SELECT 
        trigger_type AS enum_value,
        COUNT(*) AS value_count
    FROM all_logs
    GROUP BY trigger_type
),
-- 4. 获取不同的枚举值（最多10个，按出现次数降序）
distinct_values AS (
    SELECT 
        vc.enum_value,
        vc.value_count,
        any(al.gold_grant_result) AS gold_grant_result
    FROM value_counts vc
    JOIN all_logs al ON vc.enum_value = al.trigger_type
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

-- gold_scene_info - semantic_check - 统计查询
-- 语义抽查 - 统计查询
-- 检查字段是否包含乱码、特殊字符等异常值
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT gold_scene_info
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND gold_scene_info IS NOT NULL
      AND gold_scene_info != ''
      AND gold_scene_info NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT gold_scene_info
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND gold_scene_info IS NOT NULL
      AND gold_scene_info != ''
      AND gold_scene_info NOT IN ('null', 'NULL')
),
-- 统计，检测异常值
stats AS (
    SELECT 
        COUNT(*) AS total_records,
        COUNT(DISTINCT gold_scene_info) AS distinct_values,
        -- 统计包含乱码或异常字符的记录数
        SUM(CASE 
            WHEN gold_scene_info LIKE '%�%'  -- 包含乱码字符
                OR gold_scene_info LIKE '%\x00%'  -- 包含空字符
                OR gold_scene_info LIKE '%\x01%'  -- 包含控制字符
                OR gold_scene_info LIKE '%\x02%'
                OR gold_scene_info LIKE '%\x03%'
                OR gold_scene_info LIKE '%\x04%'
                OR gold_scene_info LIKE '%\x05%'
                OR gold_scene_info LIKE '%\x06%'
                OR gold_scene_info LIKE '%\x07%'
                OR gold_scene_info LIKE '%\x08%'
                OR gold_scene_info LIKE '%\x0B%'
                OR gold_scene_info LIKE '%\x0C%'
                OR gold_scene_info LIKE '%\x0E%'
                OR gold_scene_info LIKE '%\x0F%'
                OR gold_scene_info LIKE '%null%'  -- 包含null字符串
                OR length(gold_scene_info) != lengthUTF8(gold_scene_info)  -- 字节长度与字符长度不一致
            THEN 1 
            ELSE 0 
        END) AS abnormal_count
    FROM all_logs
)
-- 返回统计结果
SELECT 
    total_records,
    distinct_values,
    abnormal_count AS abnormal_records,
    round(abnormal_count * 100.0 / total_records, 4) AS abnormal_percentage
FROM stats
WHERE total_records > 0;

-- gold_scene_info - semantic_check - 样例查询
-- 语义抽查 - 样例查询
-- 优先返回包含异常字符的样例，如果没有则随机抽取10个不同的值进行人工检查
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        gold_scene_info,
        gold_grant_result
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND gold_scene_info IS NOT NULL
      AND gold_scene_info != ''
      AND gold_scene_info NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        gold_scene_info,
        gold_grant_result
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND gold_scene_info IS NOT NULL
      AND gold_scene_info != ''
      AND gold_scene_info NOT IN ('null', 'NULL')
),
-- 标记异常值
marked_logs AS (
    SELECT 
        gold_scene_info,
        gold_grant_result,
        CASE 
            WHEN gold_scene_info LIKE '%�%'  -- 包含乱码字符
                OR gold_scene_info LIKE '%\x00%'  -- 包含空字符
                OR gold_scene_info LIKE '%\x01%'  -- 包含控制字符
                OR gold_scene_info LIKE '%\x02%'
                OR gold_scene_info LIKE '%\x03%'
                OR gold_scene_info LIKE '%\x04%'
                OR gold_scene_info LIKE '%\x05%'
                OR gold_scene_info LIKE '%\x06%'
                OR gold_scene_info LIKE '%\x07%'
                OR gold_scene_info LIKE '%\x08%'
                OR gold_scene_info LIKE '%\x0B%'
                OR gold_scene_info LIKE '%\x0C%'
                OR gold_scene_info LIKE '%\x0E%'
                OR gold_scene_info LIKE '%\x0F%'
                OR gold_scene_info LIKE '%null%'  -- 包含null字符串
                OR length(gold_scene_info) != lengthUTF8(gold_scene_info)  -- 字节长度与字符长度不一致
            THEN 1 
            ELSE 0 
        END AS is_abnormal
    FROM all_logs
),
-- 获取不同的值（优先异常值，最多10个）
distinct_samples AS (
    SELECT DISTINCT
        gold_scene_info,
        any(gold_grant_result) AS gold_grant_result,
        max(is_abnormal) AS is_abnormal
    FROM marked_logs
    GROUP BY gold_scene_info
    ORDER BY is_abnormal DESC, gold_scene_info
    LIMIT 10
)
-- 返回样例
SELECT 
    gold_scene_info AS sample_value,
    gold_grant_result,
    CASE WHEN is_abnormal = 1 THEN '异常' ELSE '正常' END AS status
FROM distinct_samples
ORDER BY is_abnormal DESC, sample_value;

-- 特殊任务: table_count_statistics - table_count
-- 表数据量统计
-- 统计标准表和错误表的数据量
WITH 
-- 1. 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('2026-01-12 00:00:00', 3) AS start_ts,
        toDateTime64('2026-01-19 00:00:00', 3) AS end_ts
),
-- 2. 统计标准表
standard_count AS (
    SELECT 
        'standard' AS table_type,
        COUNT(*) AS record_count
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
),
-- 3. 统计错误表
error_count AS (
    SELECT 
        'error' AS table_type,
        COUNT(*) AS record_count
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
)
-- 4. 合并结果
SELECT 
    table_type,
    record_count
FROM standard_count
UNION ALL
SELECT 
    table_type,
    record_count
FROM error_count
ORDER BY table_type;
