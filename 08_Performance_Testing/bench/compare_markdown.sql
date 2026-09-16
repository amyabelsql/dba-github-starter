-- Same comparison as compare.sql, emitted as markdown table rows so a
-- workflow can paste it straight into a pull request summary.
-- Run with sqlcmd -h -1 -W so there are no headers and no padding.
SET NOCOUNT ON;
GO

SELECT CONCAT('| ', b.TestName,
              ' | ', b.LogicalReads,
              ' | ', a.LogicalReads,
              ' | ', CAST(CAST(100.0 * (b.LogicalReads - a.LogicalReads)
                                / NULLIF(b.LogicalReads, 0) AS DECIMAL(5, 1)) AS VARCHAR(10)),
              '% | ', CASE
                          WHEN a.LogicalReads < b.LogicalReads THEN 'BETTER'
                          WHEN a.LogicalReads > b.LogicalReads THEN 'WORSE'
                          ELSE 'NO CHANGE'
                      END,
              ' |')
FROM dbo.PerfResult AS b
    INNER JOIN dbo.PerfResult AS a
        ON a.TestName = b.TestName
           AND a.RunLabel = 'after'
WHERE b.RunLabel = 'before'
ORDER BY b.TestName;
GO
