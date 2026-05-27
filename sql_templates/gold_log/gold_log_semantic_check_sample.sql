-- 语义抽查 - 样例查询
-- 优先返回包含异常字符的样例，如果没有则随机抽取10个不同的值进行人工检查
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 合并两个表的数据
all_logs AS (
    SELECT 
        {field},
        gold_grant_result
    FROM {table_standard}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
      AND {field} IS NOT NULL
      AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
    
    UNION ALL
    
    SELECT 
        {field},
        gold_grant_result
    FROM {table_error}
    WHERE {time_field} >= (SELECT start_ts FROM time_range) 
      AND {time_field} < (SELECT end_ts FROM time_range)
      AND {field} IS NOT NULL
      AND {field} != ''
      AND {field} NOT IN ('null', 'NULL')
),
-- 标记异常值
marked_logs AS (
    SELECT 
        {field},
        gold_grant_result,
        CASE 
            WHEN {field} LIKE '%�%'  -- 包含乱码字符
                OR {field} LIKE '%\x00%'  -- 包含空字符
                OR {field} LIKE '%\x01%'  -- 包含控制字符
                OR {field} LIKE '%\x02%'
                OR {field} LIKE '%\x03%'
                OR {field} LIKE '%\x04%'
                OR {field} LIKE '%\x05%'
                OR {field} LIKE '%\x06%'
                OR {field} LIKE '%\x07%'
                OR {field} LIKE '%\x08%'
                OR {field} LIKE '%\x0B%'
                OR {field} LIKE '%\x0C%'
                OR {field} LIKE '%\x0E%'
                OR {field} LIKE '%\x0F%'
                OR {field} LIKE '%null%'  -- 包含null字符串
                OR length({field}) != lengthUTF8({field})  -- 字节长度与字符长度不一致
            THEN 1 
            ELSE 0 
        END AS is_abnormal
    FROM all_logs
),
-- 获取不同的值（优先异常值，最多10个）
distinct_samples AS (
    SELECT DISTINCT
        {field},
        any(gold_grant_result) AS gold_grant_result,
        max(is_abnormal) AS is_abnormal
    FROM marked_logs
    GROUP BY {field}
    ORDER BY is_abnormal DESC, {field}
    LIMIT 10
)
-- 返回样例
SELECT 
    {field} AS sample_value,
    gold_grant_result,
    CASE WHEN is_abnormal = 1 THEN '异常' ELSE '正常' END AS status
FROM distinct_samples
ORDER BY is_abnormal DESC, sample_value;
