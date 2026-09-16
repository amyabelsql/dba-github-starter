-- Fix 1: delete the two joins nobody uses.
--
-- Watch what happens to OrderNote. It is the join that costs real money,
-- because there is no index on OrderNote.OrderId and nothing in the SELECT
-- list, the WHERE clause or the GROUP BY refers to it.
--
-- Region is the interesting half. SQL Server throws that join away by itself,
-- because RegionId is a primary key and the foreign key guarantees a match
-- exists. That is called join elimination. It cannot do the same trick for
-- OrderNote, because nothing promises there is at most one note per order.
-- Same "unused" join, only one of them is free.
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CustomerOrderSummary
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.CustomerName,
           COUNT(*)      AS OrderCount,
           SUM(o.Amount) AS TotalAmount
    FROM dbo.Customer AS c
        INNER JOIN dbo.Orders AS o
            ON o.CustomerId = c.CustomerId
    WHERE c.CustomerId = @CustomerId
          AND o.IsCancelled = 0
    GROUP BY c.CustomerName;
END
GO
