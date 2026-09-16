# Test a database change on a throwaway SQL Server.
#
#   make up      start SQL Server 2022 in Docker
#   make schema  create the test database and apply the change scripts
#   make test    install tSQLt and run every test
#   make down    delete the container and everything in it
#   make all     all four, in order
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

TSQLT_URL = https://tsqlt.org/download/tsqlt/

.DEFAULT_GOAL := help
.PHONY: help up schema test down all clean

help: ## Show these commands
	@grep -hE '^[a-z]+:.*##' Makefile | sort | awk 'BEGIN{FS=":.*##"}{printf "  make %-7s %s\n", $$1, $$2}'

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

schema: ## Create the test database and apply the change scripts
	@$(SQLCMD) -i /dev/stdin < schema/01_create_database.sql
	@$(SQLCMD) -d $(TEST_DB) -i /dev/stdin < schema/02_tables.sql
	@$(SQLCMD) -d $(TEST_DB) -i /dev/stdin < schema/03_programmability.sql

# Downloaded once, then cached. `make clean` removes it.
# unzip exits 1 on the harmless "backslashes as path separators" warning,
# so check for the file instead of trusting the exit code.
tests/tSQLt.class.sql:
	@echo "Downloading tSQLt ..."
	@curl -sSL -o /tmp/tSQLt.zip $(TSQLT_URL)
	@unzip -o -q -j /tmp/tSQLt.zip 'tSQLt.class.sql' -d /tmp/tsqlt || true
	@test -f /tmp/tsqlt/tSQLt.class.sql \
		|| { echo "tSQLt.class.sql was not in the download - get it from https://tsqlt.org/downloads/" >&2; exit 1; }
	@cp /tmp/tsqlt/tSQLt.class.sql $@
	@rm -rf /tmp/tSQLt.zip /tmp/tsqlt
	@echo "tSQLt ready."

test: tests/tSQLt.class.sql ## Install tSQLt and run every test
	@$(SQLCMD) -d $(TEST_DB) -i /dev/stdin < tests/tSQLt.class.sql > /dev/null
	@$(SQLCMD) -d $(TEST_DB) -i /dev/stdin < tests/OrderTests.sql
	@$(SQLCMD) -d $(TEST_DB) -i /dev/stdin < tests/run_tests.sql

down: ## Delete the container and everything in it
	@docker compose down -v --remove-orphans

all: up schema test down ## The whole cycle, start to finish

clean: down ## Also remove the downloaded copy of tSQLt
	@rm -f tests/tSQLt.class.sql
