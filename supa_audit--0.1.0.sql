
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
create type audit.operation as enum (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE'
);


create table audit.record_version(
    -- unique auto-incrementing id
    id             bigserial primary key,
    -- uniquely identifies a record by primary key [primary key + table_oid]
    record_id      uuid,
    -- uniquely identifies identity of record before update/delete before an update
    old_record_id  uuid,
    -- INSERT/UPDATE/DELETE/TRUNCATE/SNAPSHOT
    op             audit.operation not null,
    ts             timestamp not null default (now() at time zone 'utc'),
    table_oid      int not null,
    table_schema   name not null,
    table_name     name not null,
    -- contents of the record
    record         json,

    -- at least one of record_id and old_record id is populated, except for trucnates
    check (coalesce(record_id, old_record_id) is not null or op = 'TRUNCATE'),

    -- record_id must be populated for insert and update
    check (op in ('INSERT', 'UPDATE') = (record_id is not null)),

    -- old_record must be populated for update and delete
    check (op in ('UPDATE', 'DELETE') = (old_record_id is not null))
);


create index record_version_record_id
    on audit.record_version(record_id)
    where record_id is not null;


create index record_version_old_record_id
    on audit.record_version(record_id)
    where old_record_id is not null;


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
            ( jsonb_build_array(to_jsonb($1)) || jsonb_agg($3 ->> key_) )::text
        )
    from
        unnest($2) x(key_)
$$;


create or replace function audit.insert_update_delete_trigger()
    returns trigger
    security definer
    language plpgsql
as $$
declare
    pkey_cols text[] = audit.primary_key_columns(TG_RELID);
    record_jsonb jsonb = to_jsonb(new);
    old_record_jsonb jsonb = to_jsonb(old);
begin

    insert into audit.record_version(
        record_id,
        old_record_id,
        op,
        table_oid,
        table_schema,
        table_name,
        record
    )
    select
        case
            when new is null then null
            when pkey_cols = array[]::text[] then null
            else audit.to_record_id(TG_RELID, pkey_cols, record_jsonb)
        end as record_id,
        case
            when old is null then null
            when pkey_cols = array[]::text[] then null
            else audit.to_record_id(TG_RELID, pkey_cols, old_record_jsonb)
        end as old_record_id,
        TG_OP::audit.operation,
        TG_RELID,
        TG_TABLE_SCHEMA,
        TG_TABLE_NAME,
        record_jsonb;

    return coalesce(old, new);
end;
$$;
