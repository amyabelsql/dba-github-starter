# Prove a performance change instead of arguing about it.
#
#   make up        start SQL Server 2022 in Docker
#   make data      build PerfDb, load 400k orders, deploy the slow procs
#   make before    measure the slow code
#   make fix       apply the rewrite and the index
#   make after     measure again
#   make compare   before vs after, plus proof the answer did not change
#   make sniff     the parameter sniffing demo
#   make qs        what Query Store recorded
#   make down      delete the container and everything in it
#   make all       the whole story, start to finish
#
# Needs: Docker, make, and a test-only password in .env (copy .env.example).

SHELL := /bin/bash

ifeq (,$(wildcard .env))
$(error No .env file. Run: cp .env.example .env)
endif

include .env
export

SQLCMD = docker exec -i $(SQL_CONTAINER) /opt/mssql-tools18/bin/sqlcmd \
	-S localhost -U sa -P "$(SA_PASSWORD)" -C -b
RUN    = $(SQLCMD) -d $(TEST_DB) -i /dev/stdin

.DEFAULT_GOAL := help
.PHONY: help up data before fix after compare sniff sniff-fixed qs ci down all clean

help: ## Show these commands
	@grep -hE '^[a-z-]+:.*##' Makefile | awk 'BEGIN{FS=":.*##"}{printf "  make %-11s %s\n", $$1, $$2}'

up: ## Start SQL Server and wait until it answers
	@docker compose up -d --quiet-pull
	@printf "Waiting for SQL Server"
	@for i in $$(seq 1 60); do \
		if $(SQLCMD) -Q "SELECT 1" >/dev/null 2>&1; then \
			echo " ready."; exit 0; \
		fi; \
		printf "."; sleep 2; \
	done; \
	echo; echo "SQL Server did not come up in time." >&2; exit 1

data: ## Build PerfDb, load 400k orders, deploy the slow procs
	@echo "Creating PerfDb with Query Store on ..."
	@$(SQLCMD) -i /dev/stdin < schema/01_create_database.sql
	@echo "Loading data (this takes about 30 seconds) ..."
	@$(RUN) < schema/02_tables_and_data.sql
	@$(RUN) < schema/03_baseline_procs.sql
	@$(RUN) < schema/04_measure_harness.sql
	@echo "Ready."

before: ## Measure the slow code
	@echo "Measuring BEFORE ..."
	@$(SQLCMD) -d $(TEST_DB) -v Label="before" -i /dev/stdin < bench/run_benchmark.sql > /dev/null
	@echo "Done."

fix: ## Apply the rewrite and the index
	@echo "Applying fixes ..."
	@$(RUN) < fixes/01_remove_unneeded_join.sql
	@$(RUN) < fixes/02_add_index.sql
	@echo "Done."

after: ## Measure again
	@echo "Measuring AFTER ..."
	@$(SQLCMD) -d $(TEST_DB) -v Label="after" -i /dev/stdin < bench/run_benchmark.sql > /dev/null
	@echo "Done."

compare: ## Before vs after, plus proof the answer did not change
	@echo
	@$(RUN) < bench/compare.sql
	@$(RUN) < bench/verify_same_results.sql

sniff: ## The parameter sniffing demo
	@echo "Running both compile orders ..."
	@$(RUN) < bench/parameter_sniffing.sql > /dev/null
	@echo
	@$(RUN) < bench/show_sniff.sql

sniff-fixed: ## Same demo again with OPTION (RECOMPILE) applied
	@$(RUN) < fixes/03_parameter_sniffing.sql
	@echo "Running both compile orders again ..."
	@$(RUN) < bench/parameter_sniffing.sql > /dev/null
	@echo
	@$(RUN) < bench/show_sniff.sql

qs: ## What Query Store recorded
	@echo
	@$(RUN) < bench/query_store_report.sql

ci: ## Before/after as a markdown table, for a pull request summary
	@echo "| Test | Before (reads) | After (reads) | Improvement | Verdict |"
	@echo "|---|---|---|---|---|"
	@$(SQLCMD) -d $(TEST_DB) -h -1 -W -i /dev/stdin < bench/compare_markdown.sql

down: ## Delete the container and everything in it
	@docker compose down -v --remove-orphans

all: up data before fix after compare sniff sniff-fixed qs down ## The whole story, start to finish

clean: down ## Same as down, here for muscle memory
	@true
