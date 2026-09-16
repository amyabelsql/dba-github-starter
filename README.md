# Creative GitHub Strategies for the Modern Database Professional

Demo repo for **Days of Data Boston 2026** — Amy Abel.

Every folder is one section of the talk, in the order you present it.

**Run everything from this folder.** `make` on its own lists every demo:

```bash
make          # show all commands
make perf     # the performance demos
make test     # the database tests
```

---

## Start here

**1. Check your machine.** Read-only, changes nothing:

```bash
./00_Prerequisites/check.sh
```

It tells you exactly what's missing and the command to fix it.

**2. Put this repo on GitHub.** Nothing with `gh` in it works until you do —
there's no repo for the commands to talk to:

```bash
./00_Prerequisites/setup_github.sh
```

That commits, creates a **private** repo, pushes, and adds the labels the issue
forms and workflows expect. Safe to run twice.

> Already done — this repo is live at
> **https://github.com/amyabelsql/dba-github-starter** (private).
>
> Your `gh` token needs the **`workflow`** scope or the push is rejected the
> moment it hits `.github/workflows/`. If you hit that:
> `gh auth refresh -h github.com -s workflow`, and make sure the browser is
> signed in as the **same account** `gh` is using.

**3. Set up the test passwords** for the two Docker sections:

```bash
make setup
```

Re-run `make check` — everything should be green.

`make perf` and `make test` call `make setup` for you, so if you forget this
step nothing breaks.

---

## What needs what

| Section | Needs Docker | Needs the repo on GitHub |
|---|---|---|
| 01 SSMS and GitHub | no | yes, to open the PR |
| 01 database project | no | no |
| 02 Issues and Projects | no | **yes** |
| 03 Actions | no | **yes**, plus a self-hosted runner |
| 04 Testing with Make | **yes** | no |
| 05 Docs and Wikis | no | yes, to see it render |
| 06 Terminal CLI | no | **yes** |
| 07 Best Practices | no | yes |
| 08 Performance Testing | **yes** | no |

Sections 04, 08 and the database project run fully offline. Everything else talks to
GitHub.

---

## The demos

### 01 — SSMS and GitHub → `01_SSMS_GitHub/`

Clone, branch, edit, commit, push, PR — without leaving SSMS. Edit
`scripts/usp_GetCustomerOrderTotal.sql` live.

Bonus deep-dive in `01_SSMS_GitHub/database_devops/` — schema as a project.
Runs offline:

```bash
cd 01_SSMS_GitHub/database_devops
dotnet build            # produces bin/Debug/DemoDb.dacpac
```

Break a column name and rebuild to show `SQL71501` catching it.

### 02 — Issues and Projects → `02_Issues_And_Projects/`

```bash
gh issue create --web                        # show the change request form
./02_Issues_And_Projects/setup_project_board.sh   # board + custom fields
./02_Issues_And_Projects/seed_demo_issues.sh      # so the board isn't empty
```

The forms are real files in `.github/ISSUE_TEMPLATE/`.

### 03 — Actions → `03_Actions_Automation/`

```bash
gh workflow run backup-check.yml -f full_hours=26 -f log_minutes=60
gh run watch
```

The workflow targets a **self-hosted runner** (`runs-on: [self-hosted, windows, sql]`)
because it has to reach your SQL Servers. Without a runner it queues forever —
that's expected, not a bug. To demo the PowerShell alone:

```powershell
./03_Actions_Automation/scripts/Invoke-BackupCheck.ps1 -SqlInstance SQL01
```

### 04 — Testing with Make → `04_Testing_With_Make/`

From the repo root: `make test`, or step by step with `make test-up`,
`make test-schema`, `make test-test`, `make test-down`.

The one that runs fully offline. Docker must be running.

```bash
cd 04_Testing_With_Make
make all
```

Verified end to end: starts SQL Server 2022, builds `DemoDb`, installs tSQLt,
runs 3 tests, tears the container down, exits 0.

```
|1 |[OrderTests].[test a customer with no orders returns zero] |     39|Success|
|2 |[OrderTests].[test cancelled orders are left out]          |     42|Success|
|3 |[OrderTests].[test totals only the orders for one customer]|   2069|Success|
Test Case Summary: 3 test case(s) executed, 3 succeeded, 0 skipped, 0 failed, 0 errored.
```

Run `make` on its own to list the commands.

### 05 — Docs and Wikis → `05_Docs_And_Wikis/`

Open `server_diagram.md` **on GitHub** to show Mermaid rendering — it won't
render in a plain text editor.

```bash
./05_Docs_And_Wikis/publish_to_wiki.sh amyabelsql dba-github-starter
```

The wiki must be created once in the repo's web UI first.

### 06 — Terminal → `06_Terminal_CLI/`

```bash
./06_Terminal_CLI/demo_commands.sh           # read-only, safe on stage
./06_Terminal_CLI/demo_commands.sh --write   # also creates an issue
```

### 07 — Best Practices → `07_Best_Practices/`

```bash
./07_Best_Practices/harden_repo.sh amyabelsql dba-github-starter
```

Turns on push protection and requires a code owner review on `main`.

### 08 — Performance Testing → `08_Performance_Testing/`

Prove a performance change instead of arguing about it. Runs offline.

```bash
make perf          # the whole story, about 40 seconds
```

One step at a time, which is how you want it on stage:

```bash
make perf-up            # start SQL Server
make perf-data          # 400,000 orders, deliberately skewed
make perf-before        # measure the slow code
make perf-fix           # remove the unused LEFT JOIN, add the index
make perf-after         # measure again
make perf-compare       # side by side + proof the answer didn't change
make perf-sniff         # parameter sniffing: 755x more reads, same answer
make perf-sniff-fixed   # OPTION (RECOMPILE)
make perf-qs            # what Query Store recorded
make perf-down          # tear it down
```

Measured in logical reads, not wall clock, so the numbers are identical every
run — on your laptop and in CI.

| Fix | Before | After |
|---|---|---|
| Removed unused LEFT JOIN | 13,488 reads | 1,372 reads |
| Added covering index | 1,688 reads | 14 reads |
| Parameter sniffing | 1,275,570 reads | 1,688 reads |

---

## If something doesn't work

| What you see | Fix |
|---|---|
| `Cannot connect to the Docker daemon` | start Docker Desktop or `open -a OrbStack` |
| `No .env file` | `make setup` from the repo root |
| `No rule to make target` | you're in the wrong folder — run `make` from the repo root |
| `Login timeout expired` | a container blip; it retries 3 times, then `make down && make perf` |
| `could not determine base repository` | run `./00_Prerequisites/setup_github.sh` |
| `gh: Not Found` on a workflow | push first — workflows must exist on GitHub |
| `refusing to allow an OAuth App to ... workflow` | `gh auth refresh -h github.com -s workflow` |
| `remote rejected` / `Repository not found` | `gh` account and SSH key are different people — use HTTPS: `gh auth setup-git` |
| A workflow run sits queued forever | section 03 needs a self-hosted runner |
| `make: *** [test] Error 1` | a test failed — that's the demo working |

Start with `./00_Prerequisites/check.sh`; it catches most of these.
