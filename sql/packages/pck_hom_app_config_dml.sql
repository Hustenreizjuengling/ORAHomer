--------------------------------------------------------------------------------
-- ORAHomer :: PCK_HOM_APP_CONFIG_DML  (sole DML access to HOM_APP_CONFIG)
--------------------------------------------------------------------------------
-- The only code allowed to write HOM_APP_CONFIG. The primary key is the APEX
-- application id (supplied by the caller, not generated). save() upserts the
-- override row; set_visibility() is a quick toggle used by the homepage admin;
-- reset() deletes the row so the app falls back to defaults (visible, auto
-- icon, no category). Does NOT commit.
--------------------------------------------------------------------------------

create or replace package pck_hom_app_config_dml
  authid definer
as
  c_pkg constant varchar2(30) := 'PCK_HOM_APP_CONFIG_DML';

  procedure save(
    p_application_id in number,
    p_category_id    in number   default null,
    p_display_name   in varchar2 default null,
    p_description    in varchar2 default null,
    p_icon_id        in number   default null,
    p_is_visible     in varchar2 default 'Y',
    p_display_seq    in number   default 10
  );

  procedure set_visibility(p_application_id in number, p_visible in varchar2);

  procedure reset(p_application_id in number);   -- back to defaults
end pck_hom_app_config_dml;
/

create or replace package body pck_hom_app_config_dml
as

  procedure save(
    p_application_id in number,
    p_category_id    in number   default null,
    p_display_name   in varchar2 default null,
    p_description    in varchar2 default null,
    p_icon_id        in number   default null,
    p_is_visible     in varchar2 default 'Y',
    p_display_seq    in number   default 10
  ) is
  begin
    merge into hom_app_config t
    using (select p_application_id as application_id from dual) s
       on (t.application_id = s.application_id)
    when matched then update set
        t.category_id  = p_category_id,
        t.display_name = p_display_name,
        t.description  = p_description,
        t.icon_id      = p_icon_id,
        t.is_visible   = nvl(p_is_visible, 'Y'),
        t.display_seq  = nvl(p_display_seq, 10),
        t.updated_at   = systimestamp,
        t.updated_by   = user
    when not matched then insert
        (application_id, category_id, display_name, description, icon_id, is_visible, display_seq,
         created_at, created_by, updated_at, updated_by)
      values
        (p_application_id, p_category_id, p_display_name, p_description, p_icon_id, nvl(p_is_visible, 'Y'), nvl(p_display_seq, 10),
         systimestamp, user, systimestamp, user);

    pck_hom_log.info(c_pkg, 'save', 'app ' || p_application_id || ' visible=' || nvl(p_is_visible, 'Y'));
  end save;


  procedure set_visibility(p_application_id in number, p_visible in varchar2) is
  begin
    -- upsert: a previously-default app needs a row to be marked hidden
    merge into hom_app_config t
    using (select p_application_id as application_id from dual) s
       on (t.application_id = s.application_id)
    when matched then update set
        t.is_visible = nvl(p_visible, 'Y'),
        t.updated_at = systimestamp,
        t.updated_by = user
    when not matched then insert
        (application_id, is_visible, display_seq, created_at, created_by, updated_at, updated_by)
      values
        (p_application_id, nvl(p_visible, 'Y'), 10, systimestamp, user, systimestamp, user);

    pck_hom_log.info(c_pkg, 'set_visibility', 'app ' || p_application_id || ' -> ' || nvl(p_visible, 'Y'));
  end set_visibility;


  procedure reset(p_application_id in number) is
  begin
    delete from hom_app_config where application_id = p_application_id;
    pck_hom_log.info(c_pkg, 'reset', 'app ' || p_application_id);
  end reset;

end pck_hom_app_config_dml;
/
