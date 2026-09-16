CREATE TABLE dbo.Orders
(
    OrderId     INT IDENTITY (1, 1) NOT NULL,
    CustomerId  INT                 NOT NULL,
    Amount      DECIMAL (19, 2)     NOT NULL,
    IsCancelled BIT                 NOT NULL CONSTRAINT DF_Orders_IsCancelled DEFAULT (0),
    CreatedAt   DATETIME2 (0)       NOT NULL CONSTRAINT DF_Orders_CreatedAt DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT PK_Orders PRIMARY KEY CLUSTERED (OrderId)
);
GO

CREATE NONCLUSTERED INDEX IX_Orders_CustomerId
    ON dbo.Orders (CustomerId)
    INCLUDE (Amount, IsCancelled);
GO
