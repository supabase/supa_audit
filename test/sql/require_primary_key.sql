begin;
    -- prevent exceptions from failing the test
    set client_min_messages to error;
    set log_min_messages to panic;

    create table public.dummy(
        id int
    );


    -- Should raise exception that there is no primary key
    select audit.enable_tracking('public.dummy');

rollback;
