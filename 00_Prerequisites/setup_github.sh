#!/usr/bin/env bash
# One-time setup: commit, create a PRIVATE GitHub repo, push, and add labels.
# Without this, every `gh` command in the demos has nothing to talk to.
#
#   ./00_Prerequisites/setup_github.sh [repo-name]
#
# Safe to re-run: skips anything already done.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_NAME="${1:-dba-github-starter}"
cd "$REPO_ROOT"

command -v gh >/dev/null || { echo "gh is not installed. brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Not signed in. Run: gh auth login"; exit 1; }

# 1. Make sure there is at least one commit.
if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "==> First commit"
  git add -A
  git commit -q -m "Day of Data Boston 2026 demo repo"
else
  echo "==> Commits already exist"
  if [ -n "$(git status --porcelain)" ]; then
    git add -A
    git commit -q -m "Update demo repo"
    echo "    committed pending changes"
  fi
fi

# 2. Create the repo on GitHub if it isn't there yet. Private on purpose:
#    this repo has server names in it.
if git remote get-url origin >/dev/null 2>&1; then
  echo "==> Remote already set: $(git remote get-url origin)"
else
  echo "==> Creating private repo $REPO_NAME"
  gh repo create "$REPO_NAME" --private --source=. --remote=origin
fi

# 3. Push.
echo "==> Pushing"
BRANCH="$(git branch --show-current)"
git push -u origin "$BRANCH"

# 4. Labels the issue forms and the backup check expect.
echo "==> Creating labels"
"$REPO_ROOT/00_Prerequisites/create_labels.sh"

echo
echo "Done. Try it:"
echo "  gh repo view --web"
echo "  gh issue create --web"
echo "  ./06_Terminal_CLI/demo_commands.sh"
