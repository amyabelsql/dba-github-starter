#!/usr/bin/env bash
# Creates the DBA board and the custom fields shown in the demo.
set -euo pipefail

OWNER="${1:-@me}"
TITLE="DBA Work"

# Project boards need a scope the default gh login does not ask for. Without
# this check the script dies on a JSON parse traceback, which tells you nothing.
if ! gh auth status 2>&1 | grep -q "project"; then
  cat >&2 <<'MSG'
Your gh token is missing the 'project' scope, so boards cannot be created
from the CLI.

Fix it once, then re-run this script:

    gh auth refresh -h github.com -s project

That prints a one-time code and opens a browser. Make sure the browser is
signed in as the same account gh is using.

Or build the board in the web UI instead - honestly the better demo, because
the audience watches the fields being added.
MSG
  exit 1
fi

echo "Creating project '$TITLE' for $OWNER ..."
JSON=$(gh project create --owner "$OWNER" --title "$TITLE" --format json)
NUMBER=$(printf '%s' "$JSON" | python3 -c 'import sys,json;print(json.load(sys.stdin)["number"])')

gh project field-create "$NUMBER" --owner "$OWNER" --name "Server"      --data-type TEXT
gh project field-create "$NUMBER" --owner "$OWNER" --name "Window date" --data-type DATE
gh project field-create "$NUMBER" --owner "$OWNER" --name "Environment" --data-type SINGLE_SELECT --single-select-options "DEV,TEST,PROD"
gh project field-create "$NUMBER" --owner "$OWNER" --name "Risk"        --data-type SINGLE_SELECT --single-select-options "Low,Medium,High"

echo "Project #$NUMBER ready."
echo "Set the Status options to: Requested, Scheduled, In Progress, Done"
gh project view "$NUMBER" --owner "$OWNER" --web
