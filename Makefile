EXTENSION = supa_audit
DATA = supa_audit--0.1.0.sql

PG_CONFIG = pg_config

MODULE_big = supa_audit

TESTS = $(wildcard test/sql/*.sql)
REGRESS = $(patsubst test/sql/%.sql,%,$(TESTS))
REGRESS_OPTS = --use-existing --inputdir=test

PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
