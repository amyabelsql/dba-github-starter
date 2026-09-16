-- Before and after, side by side, with the honest verdict.
SET NOCOUNT ON;
GO

SELECT b.TestName,
       b.LogicalReads                     AS BeforeReads,
       a.LogicalReads                     AS AfterReads,
       CAST(100.0 * (b.LogicalReads - a.LogicalReads)
            / NULLIF(b.LogicalReads, 0) AS DECIMAL(5, 1)) AS PctFewerReads,
       CASE
           WHEN a.LogicalReads < b.LogicalReads THEN 'BETTER'
           WHEN a.LogicalReads > b.LogicalReads THEN 'WORSE'
           ELSE 'NO CHANGE'
       END                                AS Verdict
FROM dbo.PerfResult AS b
    INNER JOIN dbo.PerfResult AS a
        ON a.TestName = b.TestName
           AND a.RunLabel = 'after'
WHERE b.RunLabel = 'before'
ORDER BY b.TestName;
GO
