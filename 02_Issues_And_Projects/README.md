# 02 — Issues and Projects

**Demo:** turn a runbook into a form, then watch the work on one board.

## The form is a file in the repo

| File | Opens as |
|---|---|
| `.github/ISSUE_TEMPLATE/database_change_request.yml` | Database Change Request |
| `.github/ISSUE_TEMPLATE/restore_test.yml` | Restore Test |
| `.github/ISSUE_TEMPLATE/config.yml` | turns off blank issues |

Required fields can't be skipped, and labels are applied for you.

The four fields to point at on stage: **Environment, Risk, Rollback owner, Dual review.**

## Open the form during the demo

```bash
gh issue create --web
```

## Build the board

```bash
./setup_project_board.sh
```

Columns: **Requested → Scheduled → In Progress → Done**
Custom fields: **Server, Environment, Window date, Risk**
Views to flip between on stage: **Table, Board, Roadmap**

## Seed it so the board isn't empty

```bash
./seed_demo_issues.sh
```

## Ops work that fits in issues

- **Restore tests** — one issue per test, closed when the restore works
- **Patch nights** — every window visible on the roadmap
- **Vendor tickets** — case number and notes in one place
- **Shift handoffs** — comments record what happened
