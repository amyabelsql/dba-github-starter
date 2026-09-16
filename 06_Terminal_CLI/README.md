# 06 — Work from the Terminal

**Demo:** the same work, with a few typed commands.

## Everyday commands

| Command | What it does | Safe? |
|---|---|---|
| `gh issue list` | see the open issues | read only |
| `gh issue create --title "Patch SQL01"` | create a new issue | makes a change |
| `gh workflow run backup-check.yml` | start the backup check | makes a change |
| `gh run watch` | watch a run as it happens | read only |
| `gh pr create --fill` | open a pull request | makes a change |
| `gh pr checks` | see if the tests passed | read only |

## Run the demo

```bash
./06_Terminal_CLI/demo_commands.sh          # read-only tour, safe on stage
./06_Terminal_CLI/demo_commands.sh --write  # also creates an issue
```

## Gists for your favourite queries

A gist is a small repo for one or a few files — a good home for wait stats
queries, login audits, and quick fixes.

```bash
gh gist create 06_Terminal_CLI/gists/top-waits.sql --desc "Top waits since restart"
gh gist list
```

**Secret gists are not private.** Anyone with the link can see them.

## Codespaces

`.devcontainer/devcontainer.json` gives everyone the same tools in the browser:
PowerShell, GitHub CLI, SQL Server tools, and SQLFluff. Nothing to install on a
laptop, and you delete it when you're done.
