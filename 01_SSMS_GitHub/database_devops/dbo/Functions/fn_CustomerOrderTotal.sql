CREATE FUNCTION dbo.fn_CustomerOrderTotal
(
    @CustomerId INT
)
RETURNS DECIMAL (19, 2)
AS
BEGIN
    DECLARE @Total DECIMAL (19, 2);

    SELECT @Total = SUM(o.Amount)
    FROM dbo.Orders AS o
    WHERE o.CustomerId = @CustomerId
      AND o.IsCancelled = 0;

    RETURN ISNULL(@Total, 0.00);
END;
