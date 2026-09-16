# 00 Prerequisites

## Two commands

```bash
./00_Prerequisites/check.sh          # what's missing, and how to fix it
./00_Prerequisites/setup_github.sh   # commit, create a private repo, push, add labels
```

`check.sh` changes nothing. `setup_github.sh` is safe to run twice.

## What the demos need

| Tool | Used by | Install |
|---|---|---|
| git | all | `xcode-select --install` |
| GitHub CLI | 01, 02, 03, 06, 07 | `brew install gh` |
| Docker | 04 | Docker Desktop or OrbStack |
| make | 04 | `xcode-select --install` |
| dotnet SDK | 01 database project | https://dotnet.microsoft.com/download |
| PowerShell 7 | 03 | `brew install powershell` |
| SqlServer module | 03 | `Install-Module SqlServer` |

On Windows, run section 04 from WSL.

## Sign in once

```bash
gh auth login
```

## Why the repo has to be on GitHub

`gh issue list`, `gh workflow run`, and the project board all act on a
repository. With no remote they fail with *could not determine base repository*.
`setup_github.sh` fixes that in one step.

The repo is created **private** on purpose — it has server names in it.

## Turn on Git inside SSMS

1. Open the Visual Studio Installer.
2. Click **Modify** next to SSMS.
3. Check **Code tools** — that's what adds Git.
4. Optional: **AI Assistance** adds Copilot; **Database DevOps (Preview)** adds
   schema projects (see `01_SSMS_GitHub/database_devops/`).
5. Restart SSMS. You now have a **Git** menu.

## Secrets

| Secret | Where it lives | Why |
|---|---|---|
| `SQL_CHECK_CONNECTION` | GitHub repo secrets | the backup check connects to SQL |
| `SA_PASSWORD` | local `.env` only, never committed | throwaway test container |

`.gitignore` already blocks `.env`. Push protection (section 07) is the backstop.
