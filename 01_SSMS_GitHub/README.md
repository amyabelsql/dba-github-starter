# 01 — SSMS and GitHub

**Demo:** commit and share a script without leaving SSMS.

## The six steps on screen

| # | Step | Where in SSMS |
|---|---|---|
| 1 | Clone | Git menu → Clone Repository |
| 2 | Branch | status bar branch picker → New Branch |
| 3 | Edit | open the `.sql` file and change it |
| 4 | Commit | Git Changes → message → Commit All |
| 5 | Push | Git Changes → Push |
| 6 | Pull Request | SSMS prompts, or `gh pr create` |

Commit small changes often, and say **why** in the message.

## Script to edit during the demo

Open `scripts/usp_GetCustomerOrderTotal.sql` and add the `@IncludeCancelled`
parameter live — small, visible, and easy to explain in a diff.

Branch name to use on stage:

```
change/add-includecancelled-flag
```

## Same thing from the terminal, if SSMS misbehaves

```bash
git switch -c change/add-includecancelled-flag
git add scripts/usp_GetCustomerOrderTotal.sql
git commit -m "Add IncludeCancelled flag so Finance can reconcile refunds"
git push -u origin change/add-includecancelled-flag
gh pr create --fill
```

## Two extras to mention

- **GitHub Copilot in SSMS** — added by the AI Assistance workload. Always read
  the T-SQL it writes before running it.
- **Database DevOps (Preview)** — keeps the schema as a project and publishes
  from SSMS. Full demo in `database_devops/` — the build catches a bad column
  reference before it reaches a server.
