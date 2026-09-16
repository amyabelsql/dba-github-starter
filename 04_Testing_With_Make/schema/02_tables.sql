/* Tables. Written so the script can be run twice safely. */
IF OBJECT_ID('dbo.Orders', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Orders
    (
        OrderId     INT IDENTITY(1, 1) NOT NULL
            CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED,
        CustomerId  INT            NOT NULL,
        Amount      DECIMAL(19, 2) NOT NULL,
        IsCancelled BIT            NOT NULL
            CONSTRAINT DF_Orders_IsCancelled DEFAULT (0),
        CreatedAt   DATETIME2(0)   NOT NULL
            CONSTRAINT DF_Orders_CreatedAt DEFAULT (SYSUTCDATETIME())
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Orders_CustomerId')
BEGIN
    CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
        ON dbo.Orders (CustomerId)
        INCLUDE (Amount, IsCancelled);
END;
GO

PRINT 'Tables ready.';
GO
