# 07 — Best Practices

Simple habits that keep your servers and scripts safe.

## Protect the repo

| Habit | Why |
|---|---|
| Keep it private | it has server names and client details |
| Never store passwords in files | use GitHub secrets instead |
| Turn on push protection | GitHub blocks keys before they're saved |
| Require a review | nothing reaches `main` without approval |
| Add a `CODEOWNERS` file | the DBA team reviews every SQL change |
| Use a `.gitignore` | keep backups and temp files out |

Apply the branch rules and push protection:

```bash
./07_Best_Practices/harden_repo.sh amyabelsql dba-github-starter
```

## Keep automation safe

1. Give each workflow only the access it needs
2. Pin actions to an exact version
3. Use your own runners only with private repos
4. Give the runner account read-only access
5. Remember that schedules use UTC
6. Test every workflow by hand first

## Write safe scripts

| Do this | Instead of this |
|---|---|
| Scripts that can run twice safely | scripts that fail the second time |
| Write the rollback with the change | figuring it out during an outage |
| Add a test for each change | finding problems in production |
| One file per change, with the date | one big `fixes.sql` |
| Save scripts as UTF-8 | files Git can't compare |
| Update large tables in batches | one huge update that fills the log |

`safe_script_template.sql` is the pattern to start from.

## Files in the repo root

- `.github/CODEOWNERS` — the DBA team reviews every `.sql` change
- `.gitignore` — keeps `.bak`, `.trn`, and `.env` out
