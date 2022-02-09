# `supa_audit`

<p>
<a href=""><img src="https://img.shields.io/badge/postgresql-13+-blue.svg" alt="PostgreSQL version" height="18"></a>
<a href="https://github.com/supabase/supa_audit/blob/master/LICENSE"><img src="https://img.shields.io/pypi/l/markdown-subtemplate.svg" alt="License" height="18"></a>
<a href="https://github.com/supabase/supa_audit/actions"><img src="https://github.com/supabase/supa_audit/actions/workflows/test.yaml/badge.svg" alt="Tests" height="18"></a>

</p>

---

**Source Code**: <a href="https://github.com/supabase/supa_audit" target="_blank">https://github.com/supabase/supa_audit</a>

---

Generic table auditing


## Test

### Run the tests

```sh
nix-shell --run "pg_13_supa_audit make installcheck"
```

### Adding tests

Tests are located in `test/sql/` and the expected output is in `test/expected/`

The output of the most recent test run is stored in `results/`.

When the outputs for a test in `results/` is correct, copy it to `test/expected/` and the test will pass.