/*
    OrderTests - the test class shown on the slide.

    FakeTable replaces dbo.Orders with an empty copy, so the test never
    depends on whatever data happens to be sitting in the real table.

    @Defaults = 1 keeps the DEFAULT constraints. Without it IsCancelled
    arrives NULL, the function's "IsCancelled = 0" filter matches nothing,
    and every total comes back 0.00.
*/
IF SCHEMA_ID('OrderTests') IS NULL
    EXEC ('EXEC tSQLt.NewTestClass ''OrderTests'';');
GO

CREATE OR ALTER PROCEDURE OrderTests.[test totals only the orders for one customer]
AS
BEGIN
    -- Arrange: start with known data
    EXEC tSQLt.FakeTable @TableName = 'dbo.Orders', @Defaults = 1;

    INSERT dbo.Orders (CustomerId, Amount)
    VALUES (1, 10.00), (1, 15.50), (2, 99.00);

    -- Act: run the code you're testing
    DECLARE @actual DECIMAL(19, 2) = dbo.fn_CustomerOrderTotal(1);

    -- Assert: check the result
    EXEC tSQLt.AssertEquals 25.50, @actual;
END;
GO

CREATE OR ALTER PROCEDURE OrderTests.[test cancelled orders are left out]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'dbo.Orders', @Defaults = 1;

    INSERT dbo.Orders (CustomerId, Amount, IsCancelled)
    VALUES (1, 10.00, 0), (1, 40.00, 1);

    DECLARE @actual DECIMAL(19, 2) = dbo.fn_CustomerOrderTotal(1);

    EXEC tSQLt.AssertEquals 10.00, @actual;
END;
GO

CREATE OR ALTER PROCEDURE OrderTests.[test a customer with no orders returns zero]
AS
BEGIN
    EXEC tSQLt.FakeTable @TableName = 'dbo.Orders', @Defaults = 1;

    DECLARE @actual DECIMAL(19, 2) = dbo.fn_CustomerOrderTotal(999);

    EXEC tSQLt.AssertEquals 0.00, @actual;
END;
GO

PRINT 'OrderTests loaded.';
GO
