#!/usr/bin/env bash
# Terminal demo for section 06.
# Read-only by default. Pass --write to also create an issue and start a workflow.
set -euo pipefail

WRITE=false
[[ "${1:-}" == "--write" ]] && WRITE=true

step() { echo; echo "\$ $*"; }

step "gh auth status"
gh auth status

step "gh repo view --json nameWithOwner,visibility -q '.'"
gh repo view --json nameWithOwner,visibility -q '.'

step "gh issue list --limit 5"
gh issue list --limit 5

step "gh run list --limit 5"
gh run list --limit 5

if ! $WRITE; then
  echo
  echo "Read-only tour done. Re-run with --write to create an issue and start the backup check."
  exit 0
fi

step 'gh issue create --title "Patch SQL01"'
gh issue create --title "Patch SQL01" --label change-request --body "Created from the terminal during the demo."

step "gh workflow run backup-check.yml"
gh workflow run backup-check.yml -f full_hours=26 -f log_minutes=60

step "gh run watch"
sleep 5
gh run watch --exit-status || true
