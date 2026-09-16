#!/usr/bin/env bash
# Copies these docs into the repo wiki.
# Usage: ./publish_to_wiki.sh amyabelsql dba-github-starter
set -euo pipefail

OWNER="${1:?owner required}"
REPO="${2:?repo required}"
WORK="$(mktemp -d)"

# Resolve files next to this script, so it works from any directory.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# GitHub does not create the wiki git repo until the first page exists, so a
# brand new repo clones as "Repository not found". Say so plainly.
if ! git clone --quiet "https://github.com/$OWNER/$REPO.wiki.git" "$WORK" 2>/dev/null; then
  cat >&2 <<MSG
The wiki for $OWNER/$REPO does not exist yet.

GitHub only creates it once the first page has been saved. Do this once:

    1. open https://github.com/$OWNER/$REPO/wiki
    2. click "Create the first page"
    3. save anything at all

Then re-run this script and it will publish both pages.
MSG
  exit 1
fi

cp "$HERE/server_diagram.md"  "$WORK/Server-Layout.md"
cp "$HERE/restore_runbook.md" "$WORK/Restore-Runbook.md"

cd "$WORK"
git add .
git commit -m "Publish server diagram and restore runbook"
git push

echo "Wiki updated: https://github.com/$OWNER/$REPO/wiki"
