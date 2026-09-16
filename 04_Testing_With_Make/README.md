# 04 — Test Changes Before Production

**Demo:** every change gets a brand new SQL Server, gets tested, and the server
is thrown away.

## Run it

From the repo root:

```bash
make test
```

Or from inside this folder:

```bash
cd 04_Testing_With_Make
cp .env.example .env
make all
```

That's the whole demo. It takes about a minute on a warm image and ends with:

```
|No|Test Case Name                                             |Dur(ms)|Result |
+--+-----------------------------------------------------------+-------+-------+
|1 |[OrderTests].[test a customer with no orders returns zero] |     39|Success|
|2 |[OrderTests].[test cancelled orders are left out]          |     42|Success|
|3 |[OrderTests].[test totals only the orders for one customer]|   2069|Success|
Test Case Summary: 3 test case(s) executed, 3 succeeded, 0 skipped, 0 failed, 0 errored.
```

## Four commands

| Command | What it does |
|---|---|
| `make up` | Starts SQL Server 2022 in Docker and waits until it answers |
| `make schema` | Creates `DemoDb` and runs the change scripts |
| `make test` | Downloads tSQLt, installs it, runs every test |
| `make down` | Deletes the container and everything in it |

From the repo root, prefix each with `test-`: `make test-up`, `make test-schema`,
`make test-test`, `make test-down`.

`make all` runs all four in order. `make clean` also drops the cached tSQLt copy.

## What you need

Docker, `make`, `curl`, and `unzip`. On Windows, run it from WSL.
The password in `.env` is for a throwaway container — never reuse a real one.

## The moment that sells it

Break the code on purpose and run the tests again:

```bash
# In 04_Testing_With_Make/schema/03_programmability.sql, delete this line:
#     AND o.IsCancelled = 0;
cd 04_Testing_With_Make
make up && make schema && make test
```

```
|3 |[OrderTests].[test cancelled orders are left out]          |     47|Failure|
make: *** [test] Error 1
```

Non-zero exit is what turns the pull request check red and blocks the merge.
Put the line back, re-run, green.

## Files

| Path | What it is |
|---|---|
| `Makefile` | the four commands |
| `docker-compose.yml` | the throwaway SQL Server 2022 |
| `schema/01_create_database.sql` | creates `DemoDb`, turns on CLR for tSQLt |
| `schema/02_tables.sql` | `dbo.Orders` |
| `schema/03_programmability.sql` | `dbo.fn_CustomerOrderTotal` — the code under test |
| `tests/OrderTests.sql` | the test class from the slide |
| `tests/run_tests.sql` | `tSQLt.RunAll` — fails the build on error |
| `tests/tSQLt.class.sql` | downloaded on first `make test`, not committed |

## The test pattern

```sql
-- Arrange: start with known data
EXEC tSQLt.FakeTable @TableName = 'dbo.Orders', @Defaults = 1;
INSERT dbo.Orders (CustomerId, Amount) VALUES (1, 10.00), (1, 15.50), (2, 99.00);

-- Act: run the code you're testing
SET @actual = dbo.fn_CustomerOrderTotal(1);

-- Assert: check the result
EXEC tSQLt.AssertEquals 25.50, @actual;
```

`FakeTable` swaps in an empty copy of the table, so the test never depends on
whatever data happens to be there.

**`@Defaults = 1` matters.** Without it `FakeTable` drops the DEFAULT on
`IsCancelled`, the column arrives NULL, the function's `IsCancelled = 0` filter
matches nothing, and the total comes back `0.00` instead of `25.50`. It's a good
thing to mention out loud — it's the first thing that bites people.

## The same thing on a pull request

`.github/workflows/pr-tests.yml` runs exactly these steps on every PR: style
check, start SQL Server, build the database, run the tests, tear it down.
A failure blocks the merge.
