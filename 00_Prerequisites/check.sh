#!/usr/bin/env bash
# Checks everything the demos need. Read-only - changes nothing.
# Run from anywhere:  ./00_Prerequisites/check.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0

ok()   { printf "  \033[32mok\033[0m    %s\n" "$1"; PASS=$((PASS+1)); }
bad()  { printf "  \033[31mMISSING\033[0m %s\n        -> %s\n" "$1" "$2"; FAIL=$((FAIL+1)); }

have() { command -v "$1" >/dev/null 2>&1; }

echo
echo "Tools"
have git    && ok "git"    || bad "git"    "xcode-select --install"
have gh     && ok "gh"     || bad "gh"     "brew install gh"
have docker && ok "docker" || bad "docker" "install Docker Desktop or OrbStack"
have make   && ok "make"   || bad "make"   "xcode-select --install"
have curl   && ok "curl"   || bad "curl"   "comes with macOS"
have unzip  && ok "unzip"  || bad "unzip"  "comes with macOS"
have dotnet && ok "dotnet (section 01 database project)" \
            || bad "dotnet" "https://dotnet.microsoft.com/download - only needed for the database project demo"

echo
echo "Docker engine"
if docker info >/dev/null 2>&1; then
  ok "docker is running"
else
  bad "docker is not running" "open -a OrbStack   (or start Docker Desktop), then re-run this"
fi

echo
echo "GitHub"
if gh auth status >/dev/null 2>&1; then
  ok "signed in as $(gh api user -q .login 2>/dev/null)"
else
  bad "not signed in" "gh auth login"
fi

cd "$REPO_ROOT"
if git rev-parse HEAD >/dev/null 2>&1; then
  ok "repo has commits"
else
  bad "repo has no commits yet" "./00_Prerequisites/setup_github.sh"
fi

if git remote get-url origin >/dev/null 2>&1; then
  ok "remote: $(git remote get-url origin)"
else
  bad "no GitHub remote" "./00_Prerequisites/setup_github.sh   <- gh commands fail without this"
fi

echo
echo "Section 04 config"
if [ -f "$REPO_ROOT/04_Testing_With_Make/.env" ]; then
  ok ".env exists"
else
  bad "04_Testing_With_Make/.env missing" "cd 04_Testing_With_Make && cp .env.example .env"
fi

echo
if [ "$FAIL" -eq 0 ]; then
  printf "\033[32mAll %d checks passed. You can run every demo.\033[0m\n\n" "$PASS"
else
  printf "\033[31m%d thing(s) to fix above.\033[0m (%d passed)\n\n" "$FAIL" "$PASS"
  exit 1
fi
