begin;

    create table public.members(
        id int primary key,
        name text not null
    );

    select audit.enable_tracking('public.members');

    insert into public.members(id, name)
    values (1, 'foo');

    update public.members
        set name = 'bar'
        where id = 1;

    delete from public.members;

    select
        id,
        record_id,
        old_record_id,
        op,
        table_schema,
        table_name,
        record
    from
        audit.record_version;

rollback;
