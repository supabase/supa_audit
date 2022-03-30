begin;
    -- Check escaping rules for schemas not on the search path
    -- and tables containing capital letters

    create schema xyz;

    create table xyz."Members"(
        id int primary key,
        name text not null
    );

    select audit.enable_tracking('xyz."Members"');
    select audit.disable_tracking('xyz."Members"');

rollback;
