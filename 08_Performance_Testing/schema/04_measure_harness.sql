-- The measuring tape. Logical reads, not the clock.
--
-- Wall clock time on a laptop running Docker, Teams and a projector is noise.
-- Logical reads are the same number every run, on your machine and on mine,
-- which is exactly what you want when you are proving something to a room.
SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Measure
    @Label    VARCHAR(20),
    @TestName VARCHAR(100),
    @ProcName SYSNAME,
    @Params   NVARCHAR(400),
    @Runs     INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID(@ProcName) IS NULL
    BEGIN
        RAISERROR('usp_Measure: %s does not exist.', 16, 1, @ProcName);
        RETURN;
    END

    -- Safe here because this container is thrown away at the end of the demo.
    -- Never, ever run this on a shared server.
    DBCC FREEPROCCACHE WITH NO_INFOMSGS;

    DECLARE @sql NVARCHAR(MAX) = N'EXEC ' + @ProcName + N' ' + @Params;
    DECLARE @i INT = 1;

    WHILE @i <= @Runs
    BEGIN
        EXEC sp_executesql @sql;
        SET @i += 1;
    END

    INSERT dbo.PerfResult (RunLabel, TestName, Executions, LogicalReads, ElapsedMs)
    SELECT @Label,
           @TestName,
           ps.execution_count,
           ps.total_logical_reads / ps.execution_count,
           CAST(ps.total_elapsed_time / 1000.0 / ps.execution_count AS DECIMAL(10, 2))
    FROM sys.dm_exec_procedure_stats AS ps
    WHERE ps.object_id = OBJECT_ID(@ProcName);
END
GO
