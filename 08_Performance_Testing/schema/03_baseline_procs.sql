-- The "before" code. Every one of these ships in real shops.
SET NOCOUNT ON;
GO

-- Problem 1: two LEFT JOINs that nothing in the SELECT list ever uses.
-- Somebody needed the note text once, in 2019, and it never came back out.
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
        LEFT JOIN dbo.OrderNote AS n
            ON n.OrderId = o.OrderId
        LEFT JOIN dbo.Region AS r
            ON r.RegionId = c.RegionId
    WHERE c.CustomerId = @CustomerId
          AND o.IsCancelled = 0
    GROUP BY c.CustomerName;
END
GO

-- A frozen copy of the slow version. The fix script never touches this one,
-- so we can prove afterwards that both return the same answer.
CREATE OR ALTER PROCEDURE dbo.usp_CustomerOrderSummary_Original
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
        LEFT JOIN dbo.OrderNote AS n
            ON n.OrderId = o.OrderId
        LEFT JOIN dbo.Region AS r
            ON r.RegionId = c.RegionId
    WHERE c.CustomerId = @CustomerId
          AND o.IsCancelled = 0
    GROUP BY c.CustomerName;
END
GO

-- Problem 2: a perfectly reasonable query with no index to support it,
-- so it reads all 400,000 rows to hand back a few hundred.
CREATE OR ALTER PROCEDURE dbo.usp_OrdersByDateRange
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT o.OrderId,
           o.CustomerId,
           o.OrderDate,
           o.Amount
    FROM dbo.Orders AS o
    WHERE o.OrderDate >= @StartDate
          AND o.OrderDate < @EndDate
    ORDER BY o.OrderDate;
END
GO

-- Problem 3: the parameter sniffing one. Same proc, wildly different
-- row counts depending on which StatusId gets compiled first.
CREATE OR ALTER PROCEDURE dbo.usp_OrdersByStatus
    @StatusId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT o.OrderId,
           o.CustomerId,
           o.OrderDate,
           o.Amount
    FROM dbo.Orders AS o
    WHERE o.StatusId = @StatusId;
END
GO
