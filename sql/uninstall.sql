--------------------------------------------------------------------------------
-- ORAHomer :: uninstaller
--------------------------------------------------------------------------------
-- Drops every ORAHomer database object. Run as the owning schema. This removes
-- all configuration (categories, icons, app overrides, links) -- export first if
-- you want to keep it. Does NOT touch the APEX application (remove that in the
-- App Builder).
--------------------------------------------------------------------------------

set define off
set echo off
whenever sqlerror continue

prompt -- views
drop view hom_app_config_v;
drop view hom_tiles_v;

prompt -- packages
drop package pck_hom_api;
drop package pck_hom_links_dml;
drop package pck_hom_app_config_dml;
drop package pck_hom_icons_dml;
drop package pck_hom_categories_dml;
drop package pck_hom_config_dml;
drop package pck_hom_log;

prompt -- tables (children first for the FKs)
drop table hom_links cascade constraints purge;
drop table hom_app_config cascade constraints purge;
drop table hom_icons cascade constraints purge;
drop table hom_categories cascade constraints purge;
drop table hom_config purge;
drop table hom_log purge;

prompt ORAHomer uninstalled.
