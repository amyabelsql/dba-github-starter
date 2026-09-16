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

# -l 30 is a 30 second login timeout. SQL Server in a container will
# occasionally refuse a connection even when it is healthy, and the default
# timeout is short enough that one blip kills a demo. This rides it out.
SQLCMD = docker exec -i $(SQL_CONTAINER) /opt/mssql-tools18/bin/sqlcmd \
	-S localhost -U sa -P "$(SA_PASSWORD)" -C -b -l 30

# The readiness probe wants the opposite: fail fast so the wait loop can spin.
PROBE = docker exec -i $(SQL_CONTAINER) /opt/mssql-tools18/bin/sqlcmd \
	-S localhost -U sa -P "$(SA_PASSWORD)" -C -b -l 3 -t 3
RUN    = $(SQLCMD) -d $(TEST_DB) -i /dev/stdin

# A connection to SQL Server in a container will occasionally blip, even when
# the server is perfectly healthy. Losing a demo to that is not acceptable, so
# every script runs through this: try, wait, try again, then give up honestly.
define retry
@for attempt in 1 2 3; do \
	if $(1); then exit 0; fi; \
	echo "  connection blip, retry $$attempt of 3 ..." >&2; \
	sleep 5; \
done; \
echo "Failed after 3 attempts. Try: make down && make up" >&2; exit 1
endef

.DEFAULT_GOAL := help
.PHONY: help up data before fix after compare sniff sniff-fixed qs ci down all clean

help: ## Show these commands
	@grep -hE '^[a-z-]+:.*##' Makefile | awk 'BEGIN{FS=":.*##"}{printf "  make %-11s %s\n", $$1, $$2}'

up: ## Start SQL Server and wait until it is genuinely ready
	@docker compose up -d --quiet-pull
	@printf "Waiting for SQL Server"
	@ok=0; \
	for i in $$(seq 1 90); do \
		if $(PROBE) -Q "SELECT 1 FROM sys.databases WHERE name = 'tempdb' AND state_desc = 'ONLINE'" >/dev/null 2>&1; then \
			ok=$$((ok + 1)); \
		else \
			ok=0; \
		fi; \
		if [ $$ok -ge 3 ]; then echo " ready."; exit 0; fi; \
		printf "."; sleep 2; \
	done; \
	echo; echo "SQL Server did not come up in time. Try: make down && make up" >&2; exit 1

data: ## Build PerfDb, load 400k orders, deploy the slow procs
	@echo "Creating PerfDb with Query Store on ..."
	$(call retry,$(SQLCMD) -i /dev/stdin < schema/01_create_database.sql)
	@echo "Loading data (this takes about 30 seconds) ..."
	$(call retry,$(RUN) < schema/02_tables_and_data.sql)
	$(call retry,$(RUN) < schema/03_baseline_procs.sql)
	$(call retry,$(RUN) < schema/04_measure_harness.sql)
	@echo "Ready."

before: ## Measure the slow code
	@echo "Measuring BEFORE ..."
	$(call retry,$(SQLCMD) -d $(TEST_DB) -v Label="before" -i /dev/stdin < bench/run_benchmark.sql > /dev/null)
	@echo "Done."

fix: ## Apply the rewrite and the index
	@echo "Applying fixes ..."
	$(call retry,$(RUN) < fixes/01_remove_unneeded_join.sql)
	$(call retry,$(RUN) < fixes/02_add_index.sql)
	@echo "Done."

after: ## Measure again
	@echo "Measuring AFTER ..."
	$(call retry,$(SQLCMD) -d $(TEST_DB) -v Label="after" -i /dev/stdin < bench/run_benchmark.sql > /dev/null)
	@echo "Done."

compare: ## Before vs after, plus proof the answer did not change
	@echo
	$(call retry,$(RUN) < bench/compare.sql)
	$(call retry,$(RUN) < bench/verify_same_results.sql)

sniff: ## The parameter sniffing demo
	@echo "Running both compile orders ..."
	$(call retry,$(RUN) < bench/parameter_sniffing.sql > /dev/null)
	@echo
	$(call retry,$(RUN) < bench/show_sniff.sql)

sniff-fixed: ## Same demo again with OPTION (RECOMPILE) applied
	$(call retry,$(RUN) < fixes/03_parameter_sniffing.sql)
	@echo "Running both compile orders again ..."
	$(call retry,$(RUN) < bench/parameter_sniffing.sql > /dev/null)
	@echo
	$(call retry,$(RUN) < bench/show_sniff.sql)

qs: ## What Query Store recorded
	@echo
	$(call retry,$(RUN) < bench/query_store_report.sql)

ci: ## Before/after as a markdown table, for a pull request summary
	@echo "| Test | Before (reads) | After (reads) | Improvement | Verdict |"
	@echo "|---|---|---|---|---|"
	$(call retry,$(SQLCMD) -d $(TEST_DB) -h -1 -W -i /dev/stdin < bench/compare_markdown.sql)

down: ## Delete the container and everything in it
	@docker compose down -v --remove-orphans

all: up data before fix after compare sniff sniff-fixed qs down ## The whole story, start to finish

clean: down ## Same as down, here for muscle memory
	@true
