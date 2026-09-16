/*
    usp_GetCustomerOrderTotal
    Demo script for section 01 (SSMS + GitHub).
    Edit this live on a branch so the diff is easy to read on stage.
*/
CREATE OR ALTER PROCEDURE dbo.usp_GetCustomerOrderTotal
    @CustomerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        o.CustomerId,
        OrderCount = COUNT_BIG(*),
        OrderTotal = SUM(o.Amount)
    FROM dbo.Orders AS o
    WHERE o.CustomerId = @CustomerId
    GROUP BY o.CustomerId;
END;
GO
