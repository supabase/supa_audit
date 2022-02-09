
/*
    Generic Audit Trigger
    Linear Time Record Version History

    Date:
        2022-02-03

    Purpose:
        Generic audit history for tables including an indentifier
        to enable indexed linear time lookup of a primary key's version history
*/
-- Namespace to "audit"
create schema if not exists audit;

-- Create enum type for SQL operations to reduce disk/memory usage vs text
create type audit.operation as enum ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE');

-- Table for tracking version history for records
create table audit.record_version_history(
    id             bigserial primary key, -- unique auto-incrementing id
    record_id      uuid,                  -- uniquely identifies a record by primary key [primary key + table_oid]
    old_record_id  uuid,                  -- uniquely identifies identity of record before update/delete before an update
    op             audit.operation,       -- INSERT/UPDATE/DELETE/TRUNCATE
    ts             timestamp default (now() at time zone 'utc'),
    entity_oid     int,                   -- uid of table, robust to drop and re-create
    record         json                   -- contents of the record
);
create index record_version_history_record_id on audit.record_version_history(record_id) where record_id is not null;
create index record_version_history_old_record_id on audit.record_version_history(record_id) where old_record_id is not null;

create or replace function audit.primary_key_columns(entity_oid oid)
    returns text[]
    stable
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
        uuid_generate_v5(
            'fd62bc3d-8d6e-43c2-919c-802ba3762271',
            (select (jsonb_agg($3 ->> key_) || to_jsonb($1))::text from unnest($2) x(key_))
        )
$$;

create or replace function audit.change_trigger()
    returns trigger
    security definer
    language plpgsql
as $$
begin
    insert into audit.record_version_history(
        record_id,
        old_record_id,
        op,
        entity_oid,
        record
    )
    with pkey_cols as (
        select
            audit.primary_key_columns(TG_RELID) as column_names
    )
    select
        coalesce(ident.record_id, ident.old_record_id),
        ident.old_record_id,
        TG_OP::audit.operation,
        TG_RELID,
        rec.val
    from
        pkey_cols pk,
        lateral (
            -- new record as jsonb
            select
                to_jsonb(new) as val,
                to_jsonb(old) as old_val
        ) rec,
        lateral (
            select
                case
                    -- no primary key, use a UUID4
                    when pk.column_names = array[]::text[] then null
                    when new is null then null
                    else audit.to_record_id(TG_RELID, pk.column_names, rec.val)
                end as record_id,
                case
                    when old is null then null
                    when pk.column_names = array[]::text[] then null
                    else audit.to_record_id(TG_RELID, pk.column_names, rec.old_val)
                end as old_record_id
        ) ident;
    return case TG_OP
        when 'DELETE' then old
        else new
    end;
end;
$$;

create or replace function audit.get_version_history(record)
    returns setof audit.record_version_history
    stable
    language plpgsql
as $$
declare
    entity oid           = oid from pg_class where reltype = pg_typeof($1);
    pk_cols text[]       = audit.primary_key_columns(entity);
    input_record_id uuid = audit.to_record_id(entity, pk_cols, to_jsonb($1));
begin
    return query select
        *
    from
        audit.record_version_history vh
    where
        record_id = input_record_id; -- indexed condition
end;
$$;
