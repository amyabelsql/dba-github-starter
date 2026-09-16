-- Throwaway database for the performance demo, with Query Store turned on.
IF DB_ID('PerfDb') IS NOT NULL
BEGIN
    ALTER DATABASE PerfDb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PerfDb;
END
GO

CREATE DATABASE PerfDb;
GO

-- INTERVAL_LENGTH_MINUTES = 1 is the smallest allowed. On a real server you
-- would leave it at 60. We want numbers to show up inside a demo slot.
-- QUERY_CAPTURE_MODE = ALL because AUTO ignores cheap queries, and half of
-- this demo is about queries that are cheap until they suddenly are not.
ALTER DATABASE PerfDb SET QUERY_STORE = ON
    (OPERATION_MODE = READ_WRITE,
     DATA_FLUSH_INTERVAL_SECONDS = 60,
     INTERVAL_LENGTH_MINUTES = 1,
     QUERY_CAPTURE_MODE = ALL,
     MAX_STORAGE_SIZE_MB = 200);
GO
