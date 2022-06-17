create or replace function audit.primary_key_columns(entity_oid oid)
    returns text[]
    stable
    security definer
    set search_path = ''
    language sql
as $$
    -- Looks up the names of a table's primary key columns
    select
        coalesce(
            array_agg(pa.attname::text order by pa.attnum),
            array[]::text[]
        ) column_names
    from
        pg_index pi
        join pg_attribute pa
            on pi.indrelid = pa.attrelid
            and pa.attnum = any(pi.indkey)

    where
        indrelid = $1
        and indisprimary
$$;


create or replace function audit.to_record_id(entity_oid oid, pkey_cols text[], rec jsonb)
    returns uuid
    stable
    language sql
as $$
    select
        case
            when rec is null then null
            when pkey_cols = array[]::text[] then uuid_generate_v4()
            else (
                select
                    uuid_generate_v5(
                        'fd62bc3d-8d6e-43c2-919c-802ba3762271',
                        ( jsonb_build_array(to_jsonb($1)) || jsonb_agg($3 ->> key_) )::text
                    )
                from
                    unnest($2) x(key_)
            )
        end
$$;


create or replace function audit.insert_update_delete_trigger()
    returns trigger
    security definer
    -- can not use search_path = '' here because audit.to_record_id requires
    -- uuid_generate_v4, which may be installed in a user-defined schema
    language plpgsql
as $$
declare
    pkey_cols text[] = audit.primary_key_columns(TG_RELID);

    record_jsonb jsonb = to_jsonb(new);
    record_id uuid = audit.to_record_id(TG_RELID, pkey_cols, record_jsonb);

    old_record_jsonb jsonb = to_jsonb(old);
    old_record_id uuid = audit.to_record_id(TG_RELID, pkey_cols, old_record_jsonb);
begin

    insert into audit.record_version(
        record_id,
        old_record_id,
        op,
        table_oid,
        table_schema,
        table_name,
        record,
        old_record
    )
    select
        record_id,
        old_record_id,
        TG_OP::audit.operation,
        TG_RELID,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        record_jsonb,
        old_record_jsonb;

    return coalesce(new, old);
end;
$$;


create or replace function audit.truncate_trigger()
    returns trigger
    security definer
    set search_path = ''
    language plpgsql
as $$
begin
    insert into audit.record_version(
        op,
        table_oid,
        table_schema,
        table_name
    )
    select
        TG_OP::audit.operation,
        TG_RELID,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME;

    return coalesce(old, new);
end;
$$;


create or replace function audit.enable_tracking(regclass)
    returns void
    volatile
    security definer
    set search_path = ''
    language plpgsql
as $$
declare
    statement_row text = format('
        create trigger audit_i_u_d
            after insert or update or delete
            on %s
            for each row
            execute procedure audit.insert_update_delete_trigger();',
        $1
    );

    statement_stmt text = format('
        create trigger audit_t
            after truncate
            on %s
            for each statement
            execute procedure audit.truncate_trigger();',
        $1
    );

    pkey_cols text[] = audit.primary_key_columns($1);
begin
    if pkey_cols = array[]::text[] then
        raise exception 'Table % can not be audited because it has no primary key', $1;
    end if;

    if not exists(select 1 from pg_trigger where tgrelid = $1 and tgname = 'audit_i_u_d') then
        execute statement_row;
    end if;

    if not exists(select 1 from pg_trigger where tgrelid = $1 and tgname = 'audit_t') then
        execute statement_stmt;
    end if;
end;
$$;


create or replace function audit.disable_tracking(regclass)
    returns void
    volatile
    security definer
    set search_path = ''
    language plpgsql
as $$
declare
    statement_row text = format(
        'drop trigger if exists audit_i_u_d on %s;',
        $1
    );

    statement_stmt text = format(
        'drop trigger if exists audit_t on %s;',
        $1
    );
begin
    execute statement_row;
    execute statement_stmt;
end;
$$;


/*
    Transition Existing audit_i_u_d and audit_t triggers from "before" to "after"
*/

do $$
    declare
        tab regclass;
    begin
        -- find all existing audit triggers
        for tab in select tgrelid::regclass from pg_trigger where tgname = 'audit_i_u_d' loop
            -- remove the "before" triggers"
            perform audit.disable_tracking(tab);
            -- create the "after" triggers
            perform audit.enable_tracking(tab);
        end loop;
    end
$$;
