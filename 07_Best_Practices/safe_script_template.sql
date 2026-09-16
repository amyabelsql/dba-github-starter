/*
================================================================================
    Change:      <short description>
    Issue:       #<issue number>
    Server:      SQL01
    Environment: PROD
    Author:      @amy
    Date:        2026-03-14
    Rollback:    see the bottom of this file
================================================================================
    Safe to run twice. Updates run in batches so the log doesn't fill.
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*------------------------------------------------------------------------------
    1. Guard — stop early if this has already been applied
------------------------------------------------------------------------------*/
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('dbo.Orders')
             AND name = 'IsCancelled')
BEGIN
    PRINT 'Already applied. Nothing to do.';
    RETURN;
END;
GO

/*------------------------------------------------------------------------------
    2. Schema change
------------------------------------------------------------------------------*/
BEGIN TRANSACTION;

ALTER TABLE dbo.Orders
    ADD IsCancelled BIT NOT NULL
        CONSTRAINT DF_Orders_IsCancelled DEFAULT (0);

COMMIT TRANSACTION;
GO

/*------------------------------------------------------------------------------
    3. Backfill in batches so the log stays small
------------------------------------------------------------------------------*/
DECLARE @BatchSize INT = 5000;
DECLARE @Rows      INT = 1;

WHILE @Rows > 0
BEGIN
    UPDATE TOP (@BatchSize) o
    SET o.IsCancelled = 1
    FROM dbo.Orders AS o
    WHERE o.Amount < 0
      AND o.IsCancelled = 0;

    SET @Rows = @@ROWCOUNT;

    IF @Rows > 0
    BEGIN
        RAISERROR('Updated %d rows.', 0, 1, @Rows) WITH NOWAIT;
        WAITFOR DELAY '00:00:00.100';   -- let the log back up
    END;
END;
GO

/*------------------------------------------------------------------------------
    4. Verify
------------------------------------------------------------------------------*/
SELECT Cancelled = COUNT_BIG(*)
FROM dbo.Orders
WHERE IsCancelled = 1;
GO

/*------------------------------------------------------------------------------
    5. Rollback — written now, not during the outage

    ALTER TABLE dbo.Orders DROP CONSTRAINT DF_Orders_IsCancelled;
    ALTER TABLE dbo.Orders DROP COLUMN IsCancelled;
------------------------------------------------------------------------------*/
