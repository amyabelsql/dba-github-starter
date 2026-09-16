# 05 — Keep Docs Next to Your Code

**Demo:** draw your servers with text, and GitHub renders the picture.

## Files

| File | What it is |
|---|---|
| `server_diagram.md` | the Mermaid availability group diagram |
| `restore_runbook.md` | the runbook the restore-test issue form points at |

Mermaid works in issues, pull requests, wikis, and any Markdown file — open
`server_diagram.md` on GitHub to show it rendering.

## Three places docs can live

| Place | Best for |
|---|---|
| README files | live right next to the scripts |
| Wiki | runbooks, contacts, team notes |
| GitHub Pages | a simple website for the team |

Private Pages sites need GitHub Enterprise Cloud.

## Push these into the wiki

```bash
./publish_to_wiki.sh YOUR-ACCOUNT dba-github-starter
```

If you answer the same question twice, write it down.
