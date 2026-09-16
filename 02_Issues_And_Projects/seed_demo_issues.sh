#!/usr/bin/env bash
# Puts a few realistic items on the board so it isn't empty on stage.
set -euo pipefail

gh issue create --title "[Change] Add a login for the BI team"       --label change-request --body "Server: SQL01
Environment: PROD
Risk: Low - read only or additive
Rollback owner: @amy"

gh issue create --title "[Change] Grow the log drive on SQL03"       --label change-request,prod --body "Server: SQL03
Environment: PROD
Risk: Medium - changes existing objects
Rollback owner: @amy"

gh issue create --title "[Change] Patch SQL01"                       --label change-request,prod --body "Scheduled maintenance window."

gh issue create --title "[Restore Test] Sales monthly restore check" --label restore-test --body "Source: SQL01
Database: Sales
Target: SQLTEST01"

gh issue list --limit 10
