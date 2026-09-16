-- A small OLTP shape with enough rows that a bad plan actually hurts.
SET NOCOUNT ON;
GO

CREATE TABLE dbo.Region
(
    RegionId    INT           NOT NULL CONSTRAINT PK_Region PRIMARY KEY,
    RegionName  NVARCHAR(50)  NOT NULL
);
GO

CREATE TABLE dbo.Customer
(
    CustomerId   INT           NOT NULL CONSTRAINT PK_Customer PRIMARY KEY,
    CustomerName NVARCHAR(100) NOT NULL,
    RegionId     INT           NOT NULL
        CONSTRAINT FK_Customer_Region REFERENCES dbo.Region (RegionId)
);
GO

CREATE TABLE dbo.Orders
(
    OrderId     INT            NOT NULL IDENTITY (1, 1) CONSTRAINT PK_Orders PRIMARY KEY,
    CustomerId  INT            NOT NULL,
    OrderDate   DATE           NOT NULL,
    Amount      DECIMAL(10, 2) NOT NULL,
    StatusId    INT            NOT NULL,
    IsCancelled BIT            NOT NULL CONSTRAINT DF_Orders_IsCancelled DEFAULT (0)
);
GO

-- One note per order. No index on OrderId on purpose.
CREATE TABLE dbo.OrderNote
(
    OrderNoteId INT            NOT NULL IDENTITY (1, 1) CONSTRAINT PK_OrderNote PRIMARY KEY,
    OrderId     INT            NOT NULL,
    NoteText    NVARCHAR(200)  NOT NULL
);
GO

-- Where every measurement lands, so before and after sit side by side.
CREATE TABLE dbo.PerfResult
(
    PerfResultId INT           NOT NULL IDENTITY (1, 1) CONSTRAINT PK_PerfResult PRIMARY KEY,
    RunLabel     VARCHAR(20)   NOT NULL,
    TestName     VARCHAR(100)  NOT NULL,
    Executions   INT           NOT NULL,
    LogicalReads BIGINT        NOT NULL,
    ElapsedMs    DECIMAL(10, 2) NOT NULL,
    CapturedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_PerfResult_CapturedAt DEFAULT (SYSDATETIME())
);
GO

INSERT dbo.Region (RegionId, RegionName)
VALUES (1, N'Northeast'), (2, N'Southeast'), (3, N'Midwest'), (4, N'West');
GO

-- A tally built from cross joins. No loops, no numbers table to maintain.
WITH L0 AS (SELECT 1 AS c UNION ALL SELECT 1),
     L1 AS (SELECT a.c FROM L0 AS a CROSS JOIN L0 AS b),
     L2 AS (SELECT a.c FROM L1 AS a CROSS JOIN L1 AS b),
     L3 AS (SELECT a.c FROM L2 AS a CROSS JOIN L2 AS b),
     L4 AS (SELECT a.c FROM L3 AS a CROSS JOIN L3 AS b),
     L5 AS (SELECT a.c FROM L4 AS a CROSS JOIN L4 AS b),
     Nums AS (SELECT TOP (20000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM L5)
INSERT dbo.Customer (CustomerId, CustomerName, RegionId)
SELECT n, CONCAT(N'Customer ', n), (n % 4) + 1
FROM Nums;
GO

-- 400,000 orders. StatusId is deliberately lopsided: almost everything is 1,
-- and only 1 row in 10,000 is 9. That skew is the parameter sniffing demo.
WITH L0 AS (SELECT 1 AS c UNION ALL SELECT 1),
     L1 AS (SELECT a.c FROM L0 AS a CROSS JOIN L0 AS b),
     L2 AS (SELECT a.c FROM L1 AS a CROSS JOIN L1 AS b),
     L3 AS (SELECT a.c FROM L2 AS a CROSS JOIN L2 AS b),
     L4 AS (SELECT a.c FROM L3 AS a CROSS JOIN L3 AS b),
     L5 AS (SELECT a.c FROM L4 AS a CROSS JOIN L4 AS b),
     Nums AS (SELECT TOP (400000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n FROM L5)
INSERT dbo.Orders (CustomerId, OrderDate, Amount, StatusId, IsCancelled)
SELECT ((n - 1) % 20000) + 1,
       DATEADD(DAY, -(n % 900), CAST('2026-01-01' AS DATE)),
       CAST((n % 500) + 10 AS DECIMAL(10, 2)),
       CASE WHEN n % 10000 = 0 THEN 9 ELSE 1 END,
       CASE WHEN n % 37 = 0 THEN 1 ELSE 0 END
FROM Nums;
GO

-- Exactly one note per order, so joining to it cannot change a SUM.
-- It is wide enough to be worth thousands of reads when it gets dragged in.
INSERT dbo.OrderNote (OrderId, NoteText)
SELECT o.OrderId, REPLICATE(N'note ', 20)
FROM dbo.Orders AS o;
GO

-- A narrow, non-covering index on the skewed column. This is what makes the
-- parameter sniffing demo bite: seek plus key lookup is brilliant for 40 rows
-- and catastrophic for 399,960.
CREATE NONCLUSTERED INDEX IX_Orders_StatusId ON dbo.Orders (StatusId);
GO

SELECT 'Customer' AS TableName, COUNT(*) AS RowsLoaded FROM dbo.Customer
UNION ALL SELECT 'Orders', COUNT(*) FROM dbo.Orders
UNION ALL SELECT 'OrderNote', COUNT(*) FROM dbo.OrderNote
UNION ALL SELECT 'Orders StatusId=1', COUNT(*) FROM dbo.Orders WHERE StatusId = 1
UNION ALL SELECT 'Orders StatusId=9', COUNT(*) FROM dbo.Orders WHERE StatusId = 9;
GO
