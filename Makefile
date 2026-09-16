# Run any demo from the repo root, so you never have to remember which
# folder you are standing in.
#
#   make setup     create the .env files both Docker sections need
#   make check     preflight - is everything installed and signed in
#   make perf      the whole performance story (section 08)
#   make test      the tSQLt test run (section 04)
#
# Every section target is also available one step at a time:
#   make perf-up  perf-data  perf-before  perf-fix  perf-after
#   make perf-compare  perf-sniff  perf-sniff-fixed  perf-qs  perf-down
#   make test-up  test-schema  test-test  test-down
#
# Or cd into the section folder and use its own Makefile. Both work.

SHELL := /bin/bash

PERF_DIR := 08_Performance_Testing
TEST_DIR := 04_Testing_With_Make

.DEFAULT_GOAL := help
.PHONY: help setup check perf test down clean

help: ## Show these commands
	@echo
	@echo "  Demos"
	@echo "    make perf            performance: before/after, sniffing, Query Store"
	@echo "    make test            database tests with tSQLt"
	@echo
	@echo "  One step at a time (for the stage)"
	@echo "    make perf-up         start SQL Server"
	@echo "    make perf-data       load 400k orders"
	@echo "    make perf-before     measure the slow code"
	@echo "    make perf-fix        apply the rewrite and the index"
	@echo "    make perf-after      measure again"
	@echo "    make perf-compare    side by side + proof the answer is the same"
	@echo "    make perf-sniff      parameter sniffing"
	@echo "    make perf-sniff-fixed  same, with OPTION (RECOMPILE)"
	@echo "    make perf-qs         what Query Store recorded"
	@echo "    make perf-down       tear it down"
	@echo
	@echo "  Setup"
	@echo "    make setup           create the .env files"
	@echo "    make check           preflight check"
	@echo "    make down            tear down every container"
	@echo

setup: ## Create the .env files both Docker sections need
	@cp -n $(TEST_DIR)/.env.example $(TEST_DIR)/.env 2>/dev/null || true
	@cp -n $(PERF_DIR)/.env.example $(PERF_DIR)/.env 2>/dev/null || true
	@echo "Ready: $(TEST_DIR)/.env and $(PERF_DIR)/.env"

check: ## Preflight - is everything installed and signed in
	@./00_Prerequisites/check.sh

perf: setup ## The whole performance story (section 08)
	@$(MAKE) --no-print-directory -C $(PERF_DIR) all

test: setup ## The tSQLt test run (section 04)
	@$(MAKE) --no-print-directory -C $(TEST_DIR) all

# Anything after "perf-" is handed straight to section 08's Makefile.
perf-%: setup
	@$(MAKE) --no-print-directory -C $(PERF_DIR) $*

# Anything after "test-" is handed straight to section 04's Makefile.
test-%: setup
	@$(MAKE) --no-print-directory -C $(TEST_DIR) $*

down: setup ## Tear down every demo container
	@$(MAKE) --no-print-directory -C $(PERF_DIR) down
	@$(MAKE) --no-print-directory -C $(TEST_DIR) down

clean: down ## Same as down
	@true
