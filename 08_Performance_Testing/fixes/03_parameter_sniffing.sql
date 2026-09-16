-- Fix 3: stop one parameter value from dictating everyone else's plan.
--
-- OPTION (RECOMPILE) means a fresh plan every call. You pay a small compile
-- cost, you get a plan that matches the value you actually passed. For a proc
-- that runs a few times a minute over wildly uneven data, that trade is easy.
--
-- The alternatives, and when to reach for them:
--   OPTIMIZE FOR (@StatusId = 1)  - you know the common value, pin it
--   OPTIMIZE FOR UNKNOWN          - use the average, please nobody, upset nobody
--   Query Store plan forcing      - fix it without shipping a code change
SET NOCOUNT ON;
GO

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
    WHERE o.StatusId = @StatusId
    OPTION (RECOMPILE);
END
GO
