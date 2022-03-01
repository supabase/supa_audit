alter table audit.record_version alter column record set data type jsonb;
alter table audit.record_version alter column old_record set data type jsonb;
alter table audit.record_version alter column table_oid set data type oid;
alter table audit.record_version alter column ts set data type timestamptz;
