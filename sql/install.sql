--------------------------------------------------------------------------------
-- ORAHomer :: master installer
--------------------------------------------------------------------------------
-- Run from this directory (sql/) as the schema that will own ORAHomer and that
-- is associated with the APEX workspace whose apps you want to surface, e.g.:
--   sqlplus orahomer/****@db @install.sql
--   -- or in SQLcl:  sql orahomer/****@db @install.sql
--
-- Requires Oracle 19c+ and an APEX installation (the views read the APEX
-- dictionary APEX_APPLICATIONS / APEX_APPLICATION_STATIC_FILES). Re-running on an
-- existing install: @uninstall.sql first (table DDL is not CREATE OR REPLACE).
--------------------------------------------------------------------------------

set define off
set serveroutput on size unlimited
set echo off
whenever sqlerror continue

prompt ============================================================
prompt  ORAHomer install
prompt ============================================================

prompt -- table HOM_LOG
@@ddl/tables/hom_log.sql
prompt -- table HOM_CONFIG
@@ddl/tables/hom_config.sql
prompt -- table HOM_CATEGORIES
@@ddl/tables/hom_categories.sql
prompt -- table HOM_ICONS
@@ddl/tables/hom_icons.sql
prompt -- table HOM_APP_CONFIG
@@ddl/tables/hom_app_config.sql
prompt -- table HOM_LINKS
@@ddl/tables/hom_links.sql

prompt -- package PCK_HOM_LOG
@@packages/pck_hom_log.sql
show errors

prompt -- package PCK_HOM_CONFIG_DML
@@packages/pck_hom_config_dml.sql
show errors

prompt -- package PCK_HOM_CATEGORIES_DML
@@packages/pck_hom_categories_dml.sql
show errors

prompt -- package PCK_HOM_ICONS_DML
@@packages/pck_hom_icons_dml.sql
show errors

prompt -- package PCK_HOM_APP_CONFIG_DML
@@packages/pck_hom_app_config_dml.sql
show errors

prompt -- package PCK_HOM_LINKS_DML
@@packages/pck_hom_links_dml.sql
show errors

prompt -- package PCK_HOM_API
@@packages/pck_hom_api.sql
show errors

prompt -- views (depend on PCK_HOM_API)
@@views/hom_views.sql
show errors

prompt -- seed default config rows (idempotent; preserves existing values)
begin
  pck_hom_config_dml.init_defaults;
  commit;
end;
/

prompt
prompt -- Object status (anything not VALID needs attention):
column object_name format a28
column object_type format a13
select object_name, object_type, status
  from user_objects
 where (object_name like 'HOM\_%' escape '\' or object_name like 'PCK\_HOM%' escape '\')
 order by object_type, object_name;

prompt
prompt ORAHomer installed.
prompt   Next: import the APEX app (apex_toolkit) and seed sample data:
prompt     apex import -input apex_toolkit
prompt     @../apex_toolkit/setup.sql
prompt ============================================================
