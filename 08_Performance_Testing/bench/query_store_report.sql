-- What Query Store saw while all of that was happening.
--
-- This is the view you want on a real server at 9am when somebody says
-- "it was fine yesterday". One query, more than one plan, and wildly
-- different average reads between them, is parameter sniffing on a plate.
--
-- Filtered to queries that came from stored procedures (object_id <> 0),
-- otherwise the data load and the CREATE INDEX statements bury the signal.
SET NOCOUNT ON;
GO

-- Query Store writes asynchronously. Without this, a demo that finished
-- ten seconds ago shows you nothing and you look silly.
EXEC sys.sp_query_store_flush_db;
GO

SELECT CAST(OBJECT_NAME(q.object_id) AS VARCHAR(34))         AS ProcName,
       q.query_id                                           AS QueryId,
       p.plan_id                                            AS PlanId,
       SUM(rs.count_executions)                             AS Execs,
       CAST(AVG(rs.avg_logical_io_reads) AS BIGINT)         AS AvgReads,
       CAST(AVG(rs.avg_duration) / 1000.0 AS DECIMAL(9, 1)) AS AvgMs,
       p.is_forced_plan                                     AS Forced
FROM sys.query_store_query AS q
    INNER JOIN sys.query_store_plan AS p
        ON p.query_id = q.query_id
    INNER JOIN sys.query_store_runtime_stats AS rs
        ON rs.plan_id = p.plan_id
WHERE q.object_id <> 0
GROUP BY q.object_id, q.query_id, p.plan_id, p.is_forced_plan
ORDER BY 1, q.query_id, p.plan_id;
GO

-- Any query that ended up with more than one plan is worth a second look.
-- This is the shortlist you actually investigate on a Monday morning.
SELECT CAST(OBJECT_NAME(q.object_id) AS VARCHAR(34)) AS ProcName,
       q.query_id                    AS QueryId,
       COUNT(DISTINCT p.plan_id)     AS PlanCount,
       MIN(CAST(rs.avg_logical_io_reads AS BIGINT)) AS BestPlanReads,
       MAX(CAST(rs.avg_logical_io_reads AS BIGINT)) AS WorstPlanReads,
       CONCAT('EXEC sys.sp_query_store_force_plan @query_id = ', q.query_id,
              ', @plan_id = <best plan_id from above>;') AS HowToPinTheGoodOne
FROM sys.query_store_query AS q
    INNER JOIN sys.query_store_plan AS p
        ON p.query_id = q.query_id
    INNER JOIN sys.query_store_runtime_stats AS rs
        ON rs.plan_id = p.plan_id
WHERE q.object_id <> 0
GROUP BY q.object_id, q.query_id
HAVING COUNT(DISTINCT p.plan_id) > 1
ORDER BY WorstPlanReads DESC;
GO
