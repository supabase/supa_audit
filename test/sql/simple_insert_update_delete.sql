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


    with remap as (
        select distinct on (u.id)
            u.id,
            row_number() over () stable_id
        from
            audit.record_version arv,
            unnest(array[arv.record_id, arv.old_record_id]) u(id)
        order by
            u.id asc
    )
    select
        arv.id,
        r.stable_id as remapped_record_id,
        ro.stable_id as remapped_old_record_id,
        op,
        table_schema,
        table_name,
        record
    from
        audit.record_version arv
        left join remap r
            on arv.record_id = r.id
        left join remap ro
            on arv.old_record_id = ro.id;
rollback;
