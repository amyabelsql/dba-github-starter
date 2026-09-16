#!/usr/bin/env bash
# Creates the labels the demo issue forms and workflows expect.
set -euo pipefail

create() {
  gh label create "$1" --color "$2" --description "$3" --force
}

create "change-request"  "1D76DB" "Database change request"
create "restore-test"    "0E8A16" "Restore verification test"
create "backup-alert"    "B60205" "Opened automatically by the backup check"
create "needs-review"    "FBCA04" "Waiting on DBA review"
create "prod"            "D93F0B" "Touches production"

echo "Labels created."
