--------------------------------------------------------------------------------
-- ORAHomer :: views
--------------------------------------------------------------------------------
-- Read-only views over the live APEX dictionary (APEX_APPLICATIONS) merged with
-- the ORAHomer override tables. Depend on PCK_HOM_API -> create after the
-- packages. APEX_APPLICATIONS is automatically scoped to the current workspace
-- inside an authenticated APEX session, so the homepage only ever lists apps of
-- the workspace it runs in. nv('APP_ID') excludes the homepage app itself.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- HOM_TILES_V :: the homepage feed (workspace apps + external links, unified)
--------------------------------------------------------------------------------
-- NOTE: set operators (UNION ALL) are not allowed on LOB columns, so the BLOB
-- is NOT projected inside the CTE. The union carries only the icon *source*
-- columns (icon_id / icon_app_id / icon_label); the resolved ICON_BLOB / ICON_MIME
-- are computed once in the outer query, outside the set operator.
create or replace view hom_tiles_v as
with tiles as (
  ---- workspace applications (opt-out: visible unless explicitly hidden) -------
  select 'APP'                                       as tile_kind,
         a.application_id                            as ref_id,
         'APP:' || a.application_id                  as tile_id,
         nvl(c.display_name, a.application_name)     as title,
         cast(null as varchar2(400))                 as subtitle,
         pck_hom_api.app_url(a.application_id)       as url,
         'N'                                         as new_tab,
         c.category_id                               as category_id,
         c.icon_id                                   as icon_id,
         a.application_id                            as icon_app_id,
         nvl(c.display_name, a.application_name)     as icon_label,
         nvl(c.display_seq, 10)                      as display_seq
    from apex_applications a
    left join hom_app_config c on c.application_id = a.application_id
   where a.application_id <> nvl(nv('APP_ID'), -1)
     and nvl(c.is_visible,
             nvl((select value_string from hom_config where config_key = 'DEFAULT_APP_VISIBLE'), 'Y')) = 'Y'
  union all
  ---- external link tiles ------------------------------------------------------
  select 'LINK'                                      as tile_kind,
         l.link_id                                   as ref_id,
         'LINK:' || l.link_id                        as tile_id,
         l.title                                     as title,
         l.description                               as subtitle,
         l.url                                       as url,
         l.open_in_new_tab                           as new_tab,
         l.category_id                               as category_id,
         l.icon_id                                   as icon_id,
         cast(null as number)                        as icon_app_id,
         l.title                                     as icon_label,
         nvl(l.display_seq, 10)                      as display_seq
    from hom_links l
   where l.is_visible = 'Y'
)
select t.tile_kind,
       t.ref_id,
       t.tile_id,
       t.title,
       t.subtitle,
       t.url,
       t.new_tab,
       t.category_id,
       nvl(cat.name, 'Sonstige')   as category_label,
       nvl(cat.display_seq, 9999)  as category_seq,
       t.display_seq,
       pck_hom_api.tile_icon_blob(t.icon_id, t.icon_app_id, t.icon_label) as icon_blob,
       pck_hom_api.tile_icon_mime(t.icon_id, t.icon_app_id)               as icon_mime
  from tiles t
  left join hom_categories cat on cat.category_id = t.category_id
 where (t.category_id is null
        and nvl((select value_string from hom_config where config_key = 'SHOW_UNCATEGORISED'), 'Y') = 'Y')
    or (cat.category_id is not null and cat.is_active = 'Y');


--------------------------------------------------------------------------------
-- HOM_APP_CONFIG_V :: admin list of every workspace app + its (optional) config
--------------------------------------------------------------------------------
create or replace view hom_app_config_v as
select a.application_id,
       a.application_name,
       a.alias,
       nvl(c.display_name, a.application_name)   as effective_name,
       c.display_name,
       c.category_id,
       cat.name                                  as category_name,
       c.icon_id,
       i.name                                    as icon_name,
       nvl(c.is_visible,
           nvl((select value_string from hom_config where config_key = 'DEFAULT_APP_VISIBLE'), 'Y')) as is_visible,
       nvl(c.display_seq, 10)                     as display_seq,
       case when c.application_id is not null then 'Y' else 'N' end as is_customised,
       a.last_updated_on
  from apex_applications a
  left join hom_app_config c on c.application_id = a.application_id
  left join hom_categories cat on cat.category_id = c.category_id
  left join hom_icons     i   on i.icon_id     = c.icon_id
 where a.application_id <> nvl(nv('APP_ID'), -1);
