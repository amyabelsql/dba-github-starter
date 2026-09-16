-- Faster is only a win if the answer did not change.
-- Runs the original and the rewritten proc, and compares every column.
SET NOCOUNT ON;
GO

CREATE TABLE #Original (CustomerName NVARCHAR(100), OrderCount INT, TotalAmount DECIMAL(38, 2));
CREATE TABLE #Fixed    (CustomerName NVARCHAR(100), OrderCount INT, TotalAmount DECIMAL(38, 2));

INSERT #Original EXEC dbo.usp_CustomerOrderSummary_Original @CustomerId = 42;
INSERT #Fixed    EXEC dbo.usp_CustomerOrderSummary          @CustomerId = 42;

SELECT o.CustomerName,
       o.OrderCount  AS OriginalCount,
       f.OrderCount  AS FixedCount,
       o.TotalAmount AS OriginalTotal,
       f.TotalAmount AS FixedTotal
FROM #Original AS o
    FULL JOIN #Fixed AS f
        ON f.CustomerName = o.CustomerName;

IF EXISTS (SELECT CustomerName, OrderCount, TotalAmount FROM #Original
           EXCEPT
           SELECT CustomerName, OrderCount, TotalAmount FROM #Fixed)
    OR EXISTS (SELECT CustomerName, OrderCount, TotalAmount FROM #Fixed
               EXCEPT
               SELECT CustomerName, OrderCount, TotalAmount FROM #Original)
BEGIN
    RAISERROR('RESULTS DIFFER - the rewrite changed the answer.', 16, 1);
END
ELSE
BEGIN
    PRINT 'Identical results. The rewrite is safe.';
END

DROP TABLE #Original;
DROP TABLE #Fixed;
GO
