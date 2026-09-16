#!/usr/bin/env bash
# Copies these docs into the repo wiki.
# Usage: ./publish_to_wiki.sh YOUR-ACCOUNT dba-github-starter
set -euo pipefail

OWNER="${1:?owner required}"
REPO="${2:?repo required}"
WORK="$(mktemp -d)"

git clone "https://github.com/$OWNER/$REPO.wiki.git" "$WORK"
cp server_diagram.md  "$WORK/Server-Layout.md"
cp restore_runbook.md "$WORK/Restore-Runbook.md"

cd "$WORK"
git add .
git commit -m "Publish server diagram and restore runbook"
git push

echo "Wiki updated: https://github.com/$OWNER/$REPO/wiki"
