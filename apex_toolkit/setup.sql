--------------------------------------------------------------------------------
-- ORAHomer :: one-shot sample data
--------------------------------------------------------------------------------
-- Run as the schema that owns the ORAHomer objects, AFTER sql/install.sql and
-- after importing the APEX app:
--   sqlplus orahomer/****@db @setup.sql
--   -- or in SQLcl: sql orahomer/****@db @setup.sql
--
-- Seeds a handful of starter categories and one external link so the homepage
-- has structure immediately. Re-runnable: rows are only created when missing.
--------------------------------------------------------------------------------
set serveroutput on size unlimited
set echo off
whenever sqlerror continue

declare
  l_cat number;
  l_cnt number;

  -- create a category only if its name is not present yet
  function ensure_cat(p_name in varchar2, p_icon in varchar2, p_seq in number) return number is
    l_id number;
  begin
    select category_id into l_id from hom_categories where name = p_name;
    return l_id;
  exception
    when no_data_found then
      return pck_hom_categories_dml.save(
               p_name        => p_name,
               p_icon_css    => p_icon,
               p_display_seq => p_seq,
               p_is_active   => 'Y');
  end ensure_cat;
begin
  l_cat := ensure_cat('Fachanwendungen', 'fa-briefcase',  10);
  l_cat := ensure_cat('Verwaltung',      'fa-cogs',        20);
  l_cat := ensure_cat('Berichte',        'fa-bar-chart',   30);
  l_cat := ensure_cat('Werkzeuge',       'fa-wrench',      40);

  select count(*) into l_cnt from hom_links where url = 'https://apex.oracle.com';
  if l_cnt = 0 then
    l_cnt := pck_hom_links_dml.save(
               p_title           => 'Oracle APEX',
               p_url             => 'https://apex.oracle.com',
               p_description     => 'Offizielle Oracle-APEX-Website',
               p_open_in_new_tab => 'Y',
               p_is_visible      => 'Y',
               p_display_seq     => 10);
  end if;

  commit;
  dbms_output.put_line('--- ORAHomer sample data seeded; open the homepage to see the tiles ---');
end;
/
