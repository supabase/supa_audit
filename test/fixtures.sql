-- Anything that needs to be executed prior to every test goes here
create extension if not exists "uuid-ossp";
create extension supa_audit cascade version '0.2.1';
