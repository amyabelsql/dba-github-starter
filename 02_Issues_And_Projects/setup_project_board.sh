#!/usr/bin/env bash
# Creates the DBA board and the custom fields shown in the demo.
set -euo pipefail

OWNER="${1:-@me}"
TITLE="DBA Work"

echo "Creating project '$TITLE' for $OWNER ..."
NUMBER=$(gh project create --owner "$OWNER" --title "$TITLE" --format json | python3 -c 'import sys,json;print(json.load(sys.stdin)["number"])')

gh project field-create "$NUMBER" --owner "$OWNER" --name "Server"      --data-type TEXT
gh project field-create "$NUMBER" --owner "$OWNER" --name "Window date" --data-type DATE
gh project field-create "$NUMBER" --owner "$OWNER" --name "Environment" --data-type SINGLE_SELECT --single-select-options "DEV,TEST,PROD"
gh project field-create "$NUMBER" --owner "$OWNER" --name "Risk"        --data-type SINGLE_SELECT --single-select-options "Low,Medium,High"

echo "Project #$NUMBER ready."
echo "Set the Status options to: Requested, Scheduled, In Progress, Done"
gh project view "$NUMBER" --owner "$OWNER" --web
