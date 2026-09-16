# Database DevOps (Preview) — schema as a project

Optional deep-dive for slide 11.

## What it actually is

The **Database DevOps (Preview)** workload in the Visual Studio Installer adds
**SQL database projects** to SSMS. A database project is a folder of `CREATE`
scripts — one file per object — plus a `.sqlproj` file.

You stop writing *change* scripts and start describing the *finished shape* of
the database. The tooling works out the difference.

| | Migration style (section 04) | Project style (this folder) |
|---|---|---|
| What you write | `ALTER TABLE ... ADD ...` | the full `CREATE TABLE`, edited |
| What Git shows | a new file each time | a one-line diff on `Orders.sql` |
| Order matters | yes | no |
| Change script | you write it | SqlPackage generates it |

Both are valid. Migration style is easier to reason about in an outage;
project style is far easier to review and catches broken references at build.

## Why a DBA should care

`dotnet build` on the project **compiles** your schema. A typo that SSMS would
happily let you save becomes a build error:

```
Build error SQL71501: Function: [dbo].[fn_CustomerOrderTotal] contains an
unresolved reference to an object.
```

That's the whole pitch — a bad column reference fails on a pull request instead
of at 2am.

## What's in here

| File | What it is |
|---|---|
| `DemoDb.sqlproj` | SDK-style project, targets SQL Server 2022 |
| `dbo/Tables/Orders.sql` | one file per object |
| `dbo/Functions/fn_CustomerOrderTotal.sql` | the code under test |
| `DemoDb.publish.xml` | publish profile — blocks data loss by default |
| `.github/workflows/dacpac-build.yml` | builds the dacpac on every PR |

## The demo (about 4 minutes)

**1. Show the shape.** Open the folder. One file per object. Say: *this is why
the diff is readable.*

**2. Build it.** In SSMS right-click the project → **Build**. Or:

```bash
cd 01_SSMS_GitHub/database_devops
dotnet build
```

Point at the output — `bin/Debug/DemoDb.dacpac`. That single file is the
compiled schema.

**3. Break it on purpose.** This is the moment that lands. In
`fn_CustomerOrderTotal.sql`, change `o.IsCancelled` to `o.IsCancelledd` and
build again:

```
Build error SQL71501 ... unresolved reference to an object
```

Fix it, rebuild, green. Say: *SSMS would have let me save that.*

**4. Compare against a real database.** In SSMS: **Tools → SQL Schema Compare**,
source = the project, target = `DemoDb`. Show the drift.

**5. Publish — but generate the script first.** Right-click the project →
**Publish** → **Generate Script**, not Publish. Read the generated `ALTER` out
loud, *then* run it. From the terminal:

```bash
sqlpackage /Action:Script \
  /SourceFile:bin/Debug/DemoDb.dacpac \
  /Profile:DemoDb.publish.xml \
  /TargetConnectionString:"$SQL_CONNECTION" \
  /OutputPath:DemoDb.sql
```

**6. Tie it back to GitHub.** Commit the project. The PR shows the schema change
as a one-line diff, and `dacpac-build.yml` compiles it before anyone approves.

## Set it up without SSMS

The same project builds anywhere, which is how the Linux runner does it:

```bash
dotnet new install Microsoft.Build.Sql.Templates::2.2.0
dotnet new sqlproj -n DemoDb
dotnet tool install -g microsoft.sqlpackage
```

To start from a database you already have, use **Schema Compare** in SSMS with
the project as the target, or extract it:

```bash
sqlpackage /Action:Extract \
  /SourceConnectionString:"$SQL_CONNECTION" \
  /TargetFile:DemoDb.dacpac \
  /p:ExtractTarget=SchemaObjectType
```

## Say this out loud during the demo

- It's **Preview** — don't hand it prod on Monday.
- Always **Generate Script** and read it. Never publish blind to production.
- Renaming a column looks like *drop and add* to a schema comparison. That's
  data loss. `BlockOnPossibleDataLoss` is on in the profile for a reason.
- Data changes still need pre/post-deployment scripts. The project handles
  shape, not contents.

## Versions used here

| Thing | Version |
|---|---|
| `Microsoft.Build.Sql` | 2.2.0 |
| `Microsoft.Build.Sql.Templates` | 2.2.0 |
| `microsoft.sqlpackage` | 170.5.76 |
