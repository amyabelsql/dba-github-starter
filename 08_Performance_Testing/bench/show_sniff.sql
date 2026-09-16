-- Both rows below ran with StatusId = 1. Only the compile order differed.
SET NOCOUNT ON;
GO

SELECT s.Scenario,
       s.RunWith,
       s.LogicalReads,
       CASE
           WHEN s.LogicalReads > 4 * (SELECT MIN(x.LogicalReads) FROM dbo.SniffResult AS x)
               THEN CONCAT('<-- ',
                           CAST(s.LogicalReads
                                / NULLIF((SELECT MIN(x.LogicalReads) FROM dbo.SniffResult AS x), 0)
                                AS VARCHAR(20)),
                           'x more reads for the same answer')
           ELSE 'healthy'
       END AS Comment
FROM dbo.SniffResult AS s
ORDER BY s.Seq;
GO
