-- Run every measured proc and stamp the results with a label.
-- Called twice: once as "before", once as "after".
SET NOCOUNT ON;
GO

DECLARE @Label VARCHAR(20) = '$(Label)';

DELETE FROM dbo.PerfResult WHERE RunLabel = @Label;

EXEC dbo.usp_Measure
    @Label    = @Label,
    @TestName = 'usp_CustomerOrderSummary (unused LEFT JOIN)',
    @ProcName = 'dbo.usp_CustomerOrderSummary',
    @Params   = N'@CustomerId = 42';

EXEC dbo.usp_Measure
    @Label    = @Label,
    @TestName = 'usp_OrdersByDateRange (missing index)',
    @ProcName = 'dbo.usp_OrdersByDateRange',
    @Params   = N'@StartDate = ''2025-06-01'', @EndDate = ''2025-06-08''';
GO
