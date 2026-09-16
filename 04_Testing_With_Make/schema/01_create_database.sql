/*
    Creates the throwaway test database and turns on what tSQLt needs.
    Safe to run twice.
*/
IF DB_ID('DemoDb') IS NULL
BEGIN
    CREATE DATABASE DemoDb;
END;
GO

/* tSQLt ships as a CLR assembly, so these have to be on. */
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO

EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;
GO

/* SQL 2017+ only. Ignore the error on older builds. */
BEGIN TRY
    EXEC sp_configure 'clr strict security', 0;
    RECONFIGURE;
END TRY
BEGIN CATCH
    PRINT 'clr strict security not present on this build - continuing.';
END CATCH;
GO

ALTER DATABASE DemoDb SET TRUSTWORTHY ON;
GO

PRINT 'DemoDb ready.';
GO
