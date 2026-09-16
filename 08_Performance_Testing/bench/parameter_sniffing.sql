-- Parameter sniffing, demonstrated rather than described.
--
-- Same procedure. Same data. Same parameter value on the run we measure.
-- The only thing that changes is which value was in the room when the plan
-- got compiled.
--
-- Note what this script does NOT do: it never wraps the call in
-- INSERT #tmp EXEC. That was the first version, and it was wrong. Capturing
-- 400,000 rows into a temp table builds a worktable, and those reads get
-- charged to the procedure, so a proc doing 1,688 reads looked like it did
-- 1.1 million. The measurement drowned out the thing being measured.
-- Instead the rows stream to the client and the Makefile sends them to
-- /dev/null, so the only reads counted are the ones the plan really did.
SET NOCOUNT ON;
GO

IF OBJECT_ID('dbo.SniffResult') IS NOT NULL
    DROP TABLE dbo.SniffResult;
GO

CREATE TABLE dbo.SniffResult
(
    Seq          INT         NOT NULL,
    Scenario     VARCHAR(70) NOT NULL,
    RunWith      VARCHAR(12) NOT NULL,
    LogicalReads BIGINT      NOT NULL
);
GO

DECLARE @before BIGINT,
        @after  BIGINT;

------------------------------------------------------------------
-- Scenario A: the rare value gets there first.
-- StatusId 9 matches 40 rows, so the optimizer picks a seek plus key
-- lookups. Then StatusId 1 arrives, matches 399,960 rows, and inherits
-- that plan. 399,960 key lookups is not a plan, it is a punishment.
------------------------------------------------------------------
DBCC FREEPROCCACHE WITH NO_INFOMSGS;

EXEC dbo.usp_OrdersByStatus @StatusId = 9;

SELECT @before = ISNULL(SUM(ps.total_logical_reads), 0)
FROM sys.dm_exec_procedure_stats AS ps
WHERE ps.object_id = OBJECT_ID('dbo.usp_OrdersByStatus');

EXEC dbo.usp_OrdersByStatus @StatusId = 1;

SELECT @after = ISNULL(SUM(ps.total_logical_reads), 0)
FROM sys.dm_exec_procedure_stats AS ps
WHERE ps.object_id = OBJECT_ID('dbo.usp_OrdersByStatus');

INSERT dbo.SniffResult (Seq, Scenario, RunWith, LogicalReads)
VALUES (1, 'A. Plan compiled for StatusId 9 (40 rows)', 'StatusId 1', @after - @before);

------------------------------------------------------------------
-- Scenario B: the common value gets there first.
-- Identical call, identical data, plan compiled for the value that
-- actually shows up. The optimizer picks a scan and moves on.
------------------------------------------------------------------
DBCC FREEPROCCACHE WITH NO_INFOMSGS;

EXEC dbo.usp_OrdersByStatus @StatusId = 1;

SELECT @after = ISNULL(SUM(ps.total_logical_reads), 0)
FROM sys.dm_exec_procedure_stats AS ps
WHERE ps.object_id = OBJECT_ID('dbo.usp_OrdersByStatus');

INSERT dbo.SniffResult (Seq, Scenario, RunWith, LogicalReads)
VALUES (2, 'B. Plan compiled for StatusId 1 (399,960 rows)', 'StatusId 1', @after);
GO
