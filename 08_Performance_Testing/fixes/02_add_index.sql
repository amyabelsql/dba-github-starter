-- Fix 2: give the date range query an index to stand on.
--
-- Leading column is the one being filtered. CustomerId and Amount ride along
-- in INCLUDE so the query never has to go back to the clustered index.
-- That is the difference between reading 400,000 rows and reading the few
-- hundred you asked for.
SET NOCOUNT ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_Orders_OrderDate'
                     AND object_id = OBJECT_ID('dbo.Orders'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
        ON dbo.Orders (OrderDate)
        INCLUDE (CustomerId, Amount);
END
GO
