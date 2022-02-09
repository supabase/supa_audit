create table public.members(
    id int primary key,
    name text not null
);

create trigger t
    before insert or update or delete
    on public.members
    for each row
    execute procedure audit.change_trigger();

insert into public.members(id, name)
values (1, 'foo');

select
    id,
    record_id,
    old_record_id,
    op,
    entity_oid::regclass,
    record
from
    audit.record_version_history;
