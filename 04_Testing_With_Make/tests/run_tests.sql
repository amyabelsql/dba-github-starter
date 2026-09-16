/*
    Runs every test class and fails the build when a test fails.
    tSQLt.RunAll raises an error on failure, which sqlcmd -b turns into a
    non-zero exit code, which makes the pull request check go red.
*/
SET NOCOUNT ON;
GO

EXEC tSQLt.RunAll;
GO
