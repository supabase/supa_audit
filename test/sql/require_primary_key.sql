begin;

    create table public.dummy(
        id int
    );


    -- Should raise exception that there is no primary key
    select audit.enable_tracking('public.dummy');

rollback;
