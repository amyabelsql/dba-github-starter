#!/usr/bin/env bash
# Applies the protections from section 07.
# Usage: ./harden_repo.sh YOUR-ACCOUNT dba-github-starter
set -euo pipefail

OWNER="${1:?owner required}"
REPO="${2:?repo required}"

echo "Enabling secret scanning and push protection ..."
gh api -X PATCH "repos/$OWNER/$REPO" \
  -f 'security_and_analysis[secret_scanning][status]=enabled' \
  -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled' >/dev/null

echo "Requiring review and passing checks on main ..."
gh api -X PUT "repos/$OWNER/$REPO/branches/main/protection" \
  --input - >/dev/null <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Style check", "Database tests"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON

echo "Done. main now requires a code owner review and green checks."
