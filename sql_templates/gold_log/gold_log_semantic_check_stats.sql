-- 语义抽查 - 统计查询
-- 检查字段是否包含乱码、特殊字符等异常值
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 合并两个表的数据
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
-- 统计，检测异常值
stats AS (
    SELECT 
        COUNT(*) AS total_records,
        COUNT(DISTINCT {field}) AS distinct_values,
        -- 统计包含乱码或异常字符的记录数
        SUM(CASE 
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
