begin;

    create table public.dummy(
        id int primary key
    );


    insert into public.dummy(id)
    values (1);


    select audit.enable_tracking('public.dummy');


    insert into public.dummy(id)
    values (2);


    select audit.disable_tracking('public.dummy');


    insert into public.dummy(id)
    values (3);


    -- Only record with id = 2 should be present
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
