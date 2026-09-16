# 08 — Performance Testing: prove it, don't argue about it

Three performance problems, fixed and measured on a throwaway SQL Server.
Everything runs offline in Docker. Nothing touches a real server.

From the **repo root** (easiest — no need to be in this folder):

```bash
make perf
```

Or from inside this folder:

```bash
cp .env.example .env
make all
```

Both do the same thing, in about 40 seconds. `make down` has already cleaned up
after you when it finishes.

Every step below is also available from the root with a `perf-` prefix, so
`make sniff` here is `make perf-sniff` there.

---

## Why logical reads and not the clock

Wall clock time on a laptop running Docker, Teams, and a projector is noise.
Run the same query three times and get three numbers.

Logical reads are the count of 8KB pages the engine touched. Same number every
run, on your machine and on mine. That is what you want when you are proving
something to a room, and it is what you want in a pull request.

`make before` and `make after` both run each procedure five times, average the
reads, and stamp the result with a label. `make compare` puts them side by side.

---

## Demo 1 — the LEFT JOIN nobody needed

`dbo.usp_CustomerOrderSummary` joins to `OrderNote` and `Region`, then selects
nothing from either. Somebody needed the note text once, in 2019, and it never
came back out of the query.

| | Logical reads |
|---|---|
| Before | 13,488 |
| After | 1,372 |
| | **89.8% fewer** |

**The part worth pausing on.** Only one of those two joins was actually costing
anything.

SQL Server threw the `Region` join away by itself. `RegionId` is a primary key
and the foreign key guarantees a matching row exists, so the join cannot change
the result or the row count. That is **join elimination**, and it is free.

It could not do the same for `OrderNote`, because nothing in the schema promises
there is at most one note per order. So it had to go read all 400,000 of them.

Same "unused" join. One is free, one costs you 12,000 reads. The difference is
whether the database has been told about the relationship.

**Faster is only a win if the answer did not change.** `make compare` also runs
`bench/verify_same_results.sql`, which executes the original proc and the
rewritten one and compares every column:

```
CustomerName    OriginalCount  FixedCount  OriginalTotal  FixedTotal
Customer 42                19          19         988.00      988.00
Identical results. The rewrite is safe.
```

If they ever differ it raises an error, which fails the build.

---

## Demo 2 — the missing index

`dbo.usp_OrdersByDateRange` filters on `OrderDate`, which has no index, so it
reads all 400,000 rows to hand back a few hundred.

| | Logical reads |
|---|---|
| Before | 1,688 |
| After | 14 |
| | **99.2% fewer** |

The index leads on the filtered column and carries `CustomerId` and `Amount` in
`INCLUDE`, so the query never goes back to the clustered index for them:

```sql
CREATE NONCLUSTERED INDEX IX_Orders_OrderDate
    ON dbo.Orders (OrderDate)
    INCLUDE (CustomerId, Amount);
```

1,688 reads to 14 is the difference between reading the whole table and reading
the answer.

---

## Demo 3 — parameter sniffing

This is the one that makes people sit up.

`dbo.usp_OrdersByStatus` filters on `StatusId`. The data is deliberately
lopsided — 399,960 rows are status 1, and 40 rows are status 9. There is a
narrow, non-covering index on `StatusId`.

```bash
make sniff
```

```
Scenario                                        RunWith     LogicalReads  Comment
A. Plan compiled for StatusId 9 (40 rows)       StatusId 1       1275570  <-- 755x more reads for the same answer
B. Plan compiled for StatusId 1 (399,960 rows)  StatusId 1          1688  healthy
```

**Both rows ran with `StatusId = 1`.** Same procedure, same data, same
parameter, same answer. The only thing that differed is which value was in the
room when the plan got compiled.

When status 9 compiles first, the optimizer sees 40 rows and picks a seek plus
key lookups — a genuinely good plan for 40 rows. Then status 1 arrives, matches
399,960 rows, and inherits it. 399,960 key lookups is not a plan, it is a
punishment.

This is why "it was fine yesterday" is a real bug report. Nothing changed except
which query got there first after a restart, a failover, or a statistics update.

### The fix

```bash
make sniff-fixed
```

```
A. Plan compiled for StatusId 9 (40 rows)       StatusId 1          1688  healthy
B. Plan compiled for StatusId 1 (399,960 rows)  StatusId 1          1688  healthy
```

`OPTION (RECOMPILE)` — a fresh plan every call. You pay a small compile cost and
get a plan that matches the value actually passed.

The alternatives, and when to reach for them:

| Option | Use when |
|---|---|
| `OPTION (RECOMPILE)` | Runs a few times a minute, data is very uneven |
| `OPTIMIZE FOR (@StatusId = 1)` | You know the common value and want to pin it |
| `OPTIMIZE FOR UNKNOWN` | Use the average — please nobody, upset nobody |
| Query Store plan forcing | Fix it tonight without shipping a code change |

---

## Demo 4 — what Query Store saw

```bash
make qs
```

```
ProcName                   QueryId  PlanId  Execs  AvgReads  AvgMs  Forced
usp_CustomerOrderSummary        14      14      5     13488   45.6       0
usp_CustomerOrderSummary        19      19      6      1373   31.2       0
usp_OrdersByDateRange           16      16      5      1688   39.7       0
usp_OrdersByDateRange           16      20      5        14    3.5       0
usp_OrdersByStatus              30      31      2    637864  416.8       0
usp_OrdersByStatus              30      32      1      1688 1212.8       0
```

One `QueryId`, two `PlanId`s, and a huge gap in `AvgReads` between them. That is
parameter sniffing on a plate, and it is the view you want on a real server at
9am when somebody says it was fine yesterday.

The second result set is the shortlist — every query that ended up with more
than one plan — and it hands you the exact command to pin the good one:

```sql
EXEC sys.sp_query_store_force_plan @query_id = 30, @plan_id = 32;
```

Ignore the `AvgMs` column while you are on stage. It includes compile time and
whatever else the laptop was doing, so it swings wildly between runs. `AvgReads`
is the column that says the same thing every time. That is the whole argument of
this section, showing up one more time.

Two notes that matter on a real server:

- The report runs `sys.sp_query_store_flush_db` first. Query Store writes
  asynchronously, so without it a demo that finished ten seconds ago shows you
  nothing and you look silly.
- `PerfDb` is created with `INTERVAL_LENGTH_MINUTES = 1` and
  `QUERY_CAPTURE_MODE = ALL`. That is a demo setting. On a real server leave the
  interval at 60, and know that `AUTO` capture mode ignores cheap queries —
  which is awkward, because half of this section is about queries that are cheap
  until suddenly they are not.

---

## Commands

| Command | What it does |
|---|---|
| `make up` | Start SQL Server 2022 in Docker |
| `make data` | Build PerfDb, load 400k orders, deploy the slow procs |
| `make before` | Measure the slow code |
| `make fix` | Apply the rewrite and the index |
| `make after` | Measure again |
| `make compare` | Before vs after, plus proof the answer did not change |
| `make sniff` | The parameter sniffing demo |
| `make sniff-fixed` | Same demo with `OPTION (RECOMPILE)` applied |
| `make qs` | What Query Store recorded |
| `make down` | Delete the container and everything in it |
| `make all` | The whole story, start to finish |

Run them one at a time on stage. `make all` is for proving it still works before
you walk into the room.

---

## The mistake in the first version of this harness

Worth telling the room, because it is the same mistake people make in their own
testing.

The sniffing script originally captured the rows with `INSERT #tmp EXEC` to keep
400,000 rows from scrolling past the screen. The numbers came out wrong —
scenario B reported 1.1 million reads for a plan that genuinely does 1,688.

`INSERT ... EXEC` builds a worktable, and the reads against that worktable get
charged to the procedure. The measurement was drowning out the thing being
measured.

The fix was to let the rows stream to the client and have the Makefile send them
to `/dev/null`. Now the only reads counted are the ones the plan really did.

**If your before-and-after numbers look absurd, suspect your measurement before
you suspect the engine.**

---

## Files

```
schema/01_create_database.sql    PerfDb + Query Store settings
schema/02_tables_and_data.sql    tables, 400k rows, the deliberate skew
schema/03_baseline_procs.sql     the "before" code
schema/04_measure_harness.sql    usp_Measure - runs a proc N times, records reads
fixes/01_remove_unneeded_join.sql
fixes/02_add_index.sql
fixes/03_parameter_sniffing.sql
bench/run_benchmark.sql          runs every measured proc under a label
bench/compare.sql                before vs after
bench/verify_same_results.sql    proves the rewrite returns the same answer
bench/parameter_sniffing.sql     the two compile orders
bench/show_sniff.sql             prints the sniffing result
bench/query_store_report.sql     plans per query, and how to force one
```

`DBCC FREEPROCCACHE` appears in the harness. It is safe here because the
container is destroyed at the end. **Never run it on a shared server.**
