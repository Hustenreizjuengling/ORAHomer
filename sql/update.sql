--------------------------------------------------------------------------------
-- ORAHomer :: update (recompile code without touching data)
--------------------------------------------------------------------------------
-- Re-runs the CREATE OR REPLACE packages and views (and re-seeds any missing
-- config keys) without dropping tables -- safe on an existing install with data.
-- Use after pulling package/view changes. For table changes, hand-write an
-- ALTER here or do a full @uninstall.sql + @install.sql.
--------------------------------------------------------------------------------

set define off
set serveroutput on size unlimited
set echo off
whenever sqlerror continue

prompt -- schema migrations (idempotent: add columns introduced after first install)
declare
  l_n number;
begin
  select count(*) into l_n
    from user_tab_columns
   where table_name = 'HOM_APP_CONFIG' and column_name = 'DESCRIPTION';
  if l_n = 0 then
    execute immediate 'alter table hom_app_config add (description varchar2(400))';
    execute immediate q'[comment on column hom_app_config.description is 'Optional tile subtitle shown under the app name on the homepage.']';
  end if;
end;
/

prompt -- packages
@@packages/pck_hom_log.sql
show errors
@@packages/pck_hom_config_dml.sql
show errors
@@packages/pck_hom_categories_dml.sql
show errors
@@packages/pck_hom_icons_dml.sql
show errors
@@packages/pck_hom_app_config_dml.sql
show errors
@@packages/pck_hom_links_dml.sql
show errors
@@packages/pck_hom_api.sql
show errors

prompt -- views
@@views/hom_views.sql
show errors

prompt -- top up any newly added default config keys (existing values preserved)
begin
  pck_hom_config_dml.init_defaults;
  commit;
end;
/

prompt ORAHomer updated.
