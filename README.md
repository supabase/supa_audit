# `supa_audit`

<p>
<a href=""><img src="https://img.shields.io/badge/postgresql-13+-blue.svg" alt="PostgreSQL version" height="18"></a>
<a href="https://github.com/supabase/supa_audit/actions"><img src="https://github.com/supabase/supa_audit/actions/workflows/test.yaml/badge.svg" alt="Tests" height="18"></a>

</p>

---

**Source Code**: <a href="https://github.com/supabase/supa_audit" target="_blank">https://github.com/supabase/supa_audit</a>

---

Generic table auditing


## Usage

```sql
create extension supa_audit;

create table public.account(
    id int primary key,
    name text not null
);

-- Enable auditing
select audit.enable_tracking('public.account'::regclass);

-- Insert a record
insert into public.account(id, name)
values (1, 'Foo Barsworth');

-- Update a record
update public.account
set name = 'Foo Barsworht III'
where id = 1;

-- Delete a record
delete from public.account
where id = 1;

-- Truncate the table
truncate table public.account;

-- Review the history
select
    *
from
    audit.record_version;

/*
 id |              record_id               |            old_record_id             |    op    |               ts                | table_oid | table_schema | table_name |                 record                 |             old_record
----+--------------------------------------+--------------------------------------+----------+---------------------------------+-----------+--------------+------------+----------------------------------------+------------------------------------
  1 | 57ca384e-f24c-5af5-b361-a057aeac506c |                                      | INSERT   | Thu Feb 10 17:02:25.621095 2022 |     16439 | public       | account    | {"id": 1, "name": "Foo Barsworth"}     |
  2 | 57ca384e-f24c-5af5-b361-a057aeac506c | 57ca384e-f24c-5af5-b361-a057aeac506c | UPDATE   | Thu Feb 10 17:02:25.622151 2022 |     16439 | public       | account    | {"id": 1, "name": "Foo Barsworht III"} | {"id": 1, "name": "Foo Barsworth"}
  3 |                                      | 57ca384e-f24c-5af5-b361-a057aeac506c | DELETE   | Thu Feb 10 17:02:25.622495 2022 |     16439 | public       | account    |                                        | {"id": 1, "name": "Foo Barsworth"}
  4 |                                      |                                      | TRUNCATE | Thu Feb 10 17:02:25.622779 2022 |     16439 | public       | account    |                                        |
(4 rows)
*/

-- Disable auditing
select audit.disable_tracking('public.account'::regclass);
```

## Test

### Run the tests

```sh
nix-shell --run "pg_13_supa_audit make installcheck"
```

### Adding tests

Tests are located in `test/sql/` and the expected output is in `test/expected/`

The output of the most recent test run is stored in `results/`.

When the output for a test in `results/` is correct, copy it to `test/expected/` and the test will pass.

## Interactive Prompt

```sh
nix-shell --run "pg_13_supa_audit psql"
```

## Performance

Auditing tables reduces throughput of inserts, updates, and deletes.

It is not reccomended to enable tracking on tables with a peak write throughput over 3k ops/second.
