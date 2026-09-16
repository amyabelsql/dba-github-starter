# 03 — Automate Your Daily Checks

**Demo:** GitHub runs the backup check you do by hand, and opens an issue when a backup is late.

## How it runs

| Trigger | What it means |
|---|---|
| Schedule | 7:00 AM Boston time — `cron` is always UTC |
| Button | Actions tab → Run workflow, with your own thresholds |
| Pull request | checks changes before they merge |

The job runs on a **self-hosted runner inside your network**, so it can reach `SQL01`.

## What it checks

- Full backups within the last **26 hours**
- Log backups within the last **60 minutes**

Both numbers are inputs, so you can change them when you run it by hand.

## Files

| File | What it is |
|---|---|
| `.github/workflows/backup-check.yml` | the workflow |
| `scripts/Invoke-BackupCheck.ps1` | the PowerShell that queries `msdb` |

## Run it on stage

```bash
gh workflow run backup-check.yml -f full_hours=26 -f log_minutes=60
gh run watch
```

## Test the script by itself first

```powershell
./scripts/Invoke-BackupCheck.ps1 -SqlInstance SQL01 -FullBackupHours 26 -LogBackupMinutes 60
```

Run every workflow by hand once before you schedule it.
