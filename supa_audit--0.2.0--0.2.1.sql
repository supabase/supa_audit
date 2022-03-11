drop index audit.record_version_old_record_id;

create index record_version_old_record_id
    on audit.record_version(old_record_id)
    where old_record_id is not null;
