-- 统计各个日志表的数据量 - 样例查询
-- 对于统计类任务，样例查询返回与统计查询相同的结果
WITH 
-- 定义时间范围
time_range AS (
    SELECT 
        toDateTime64('{start_time}', 3) AS start_ts,
        toDateTime64('{end_time}', 3) AS end_ts
),
-- 统计各表数据量
log_counts AS (
    -- 4A 操作日志
    SELECT '4A操作日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_4a_operation_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT '4A操作日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_4a_operation_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 4A 金库日志
    SELECT '4A金库日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_4a_gold_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
      AND standby1 IS NULL
    
    UNION ALL
    
    SELECT '4A金库日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_4a_gold_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 4A 金库申请日志
    SELECT '4A金库申请日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_4a_goldapply_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 4A 回显日志
    SELECT '4A回显日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_4a_screen_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT '4A回显日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_4a_screen_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 梧桐工单日志
    SELECT '梧桐工单日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_wt_order_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    SELECT '梧桐工单日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_wt_order_log_error
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 云桌面客户端操作日志
    SELECT '云桌面客户端操作日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_yunxuan_operation_log
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 云桌面配置策略对操作稽核日志
    SELECT '云桌面配置策略对操作稽核日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_yunxuan_audit_log
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 云桌面管理平台操作日志
    SELECT '云桌面管理平台操作日志' AS log_type, COUNT(*) AS cnt
    FROM argus.bg_yunxuan_manage_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 数管平台明文传输敏感数据预警日志
    SELECT '数管平台明文传输敏感数据预警日志' AS log_type, COUNT(*) AS cnt
    FROM bg_dsmc_sensTransfer_log
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 数管平台对外接口监测预警日志
    SELECT '数管平台对外接口监测预警日志' AS log_type, COUNT(*) AS cnt
    FROM bg_dsmc_outerTraffic_log
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 数管平台业务系统备案信息日志
    SELECT '数管平台业务系统备案信息日志' AS log_type, COUNT(*) AS cnt
    FROM bg_dsmc_busSystem_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 4A防绕行预警信息日志
    SELECT '4A防绕行预警信息日志' AS log_type, COUNT(*) AS cnt
    FROM bg_dsmc_detourAlarm_log
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 数管平台数据资产清单日志
    SELECT '数管平台数据资产清单日志' AS log_type, COUNT(*) AS cnt
    FROM bs_view_dsmc_assetList_log_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 天空卫士
    SELECT '天空卫士日志' AS log_type, COUNT(*) AS cnt
    FROM argus.tkws_endpoint_incident_standard
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    
    UNION ALL
    
    -- 北信源日志（按 local_type 分组）
    SELECT '北信源日志-' || local_type AS log_type, COUNT(*) AS cnt
    FROM argus.bxy_dlp
    WHERE generic_into_time >= (SELECT start_ts FROM time_range) 
      AND generic_into_time < (SELECT end_ts FROM time_range)
    GROUP BY local_type
)
-- 汇总统计（限制返回前10条作为样例）
SELECT 
    log_type,
    SUM(cnt) AS total_count
FROM log_counts
GROUP BY log_type
ORDER BY 
    CASE 
        WHEN log_type = '4A操作日志' THEN 1
        WHEN log_type = '4A金库日志' THEN 2
        WHEN log_type = '4A金库申请日志' THEN 3
        WHEN log_type = '4A回显日志' THEN 4
        WHEN log_type = '梧桐工单日志' THEN 5
        WHEN log_type = '云桌面客户端操作日志' THEN 6
        WHEN log_type = '云桌面配置策略对操作稽核日志' THEN 7
        WHEN log_type = '云桌面管理平台操作日志' THEN 8
        WHEN log_type = '数管平台明文传输敏感数据预警日志' THEN 9
        WHEN log_type = '数管平台对外接口监测预警日志' THEN 10
        WHEN log_type = '数管平台业务系统备案信息日志' THEN 11
        WHEN log_type = '4A防绕行预警信息日志' THEN 12
        WHEN log_type = '数管平台数据资产清单日志' THEN 13
        WHEN log_type = '天空卫士日志' THEN 14
        WHEN log_type LIKE '北信源日志-进程监控%' THEN 15
        WHEN log_type LIKE '北信源日志-上网行为%' THEN 16
        WHEN log_type LIKE '北信源日志-移动存储%' THEN 17
        WHEN log_type LIKE '北信源日志-安全基线%' THEN 18
        WHEN log_type LIKE '北信源日志-病毒软件监控%' THEN 19
        WHEN log_type LIKE '北信源日志-杀毒软件监控%' THEN 19.5
        WHEN log_type LIKE '北信源日志-病毒查杀策略（病毒扫描审计）%' THEN 20
        WHEN log_type LIKE '北信源日志-病毒查杀策略（病毒处理审计）%' THEN 21
        WHEN log_type LIKE '北信源日志-文件分发策略审计%' THEN 22
        WHEN log_type LIKE '北信源日志-外发通道%' THEN 23
        WHEN log_type LIKE '北信源日志-操作系统用户监控%' THEN 24
        WHEN log_type LIKE '北信源日志-协议防火墙%' THEN 25
        ELSE 99
    END,
    log_type
LIMIT 10;
