create table public.members(
    id int primary key,
    name text not null
);

create trigger t
    before insert or update or delete
    on public.members
    for each row
    execute procedure audit.insert_update_delete_trigger();

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
    table_oid,
    table_schema,
    table_name,
    record
from
    audit.record_version;
