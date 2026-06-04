--------------------------------------------------------------------------------
-- ORAHomer :: PCK_HOM_ICONS_DML  (sole DML access to HOM_ICONS)
--------------------------------------------------------------------------------
-- The only code allowed to write HOM_ICONS. save() upserts an uploaded icon and
-- returns the id; on update a NULL p_blob keeps the existing image (so the user
-- can rename an icon without re-uploading). del() detaches the icon from any
-- app/link first so the FK never blocks the delete. Does NOT commit.
--------------------------------------------------------------------------------

create or replace package pck_hom_icons_dml
  authid definer
as
  c_pkg constant varchar2(30) := 'PCK_HOM_ICONS_DML';

  function save(
    p_icon_id   in number   default null,
    p_name      in varchar2,
    p_blob      in blob     default null,
    p_mime      in varchar2 default null,
    p_file_name in varchar2 default null
  ) return number;

  procedure del(p_icon_id in number);
end pck_hom_icons_dml;
/

create or replace package body pck_hom_icons_dml
as

  function save(
    p_icon_id   in number   default null,
    p_name      in varchar2,
    p_blob      in blob     default null,
    p_mime      in varchar2 default null,
    p_file_name in varchar2 default null
  ) return number is
    l_id hom_icons.icon_id%type := p_icon_id;
  begin
    if l_id is null then
      if p_blob is null then
        raise_application_error(-20901, 'An image file is required to create an icon.');
      end if;
      insert into hom_icons (name, file_name, mime_type, icon_blob,
                             created_at, created_by, updated_at, updated_by)
      values (p_name, p_file_name, nvl(p_mime, 'application/octet-stream'), p_blob,
              systimestamp, user, systimestamp, user)
      returning icon_id into l_id;
    else
      update hom_icons
         set name       = p_name,
             file_name  = nvl(p_file_name, file_name),
             mime_type  = case when p_blob is not null then nvl(p_mime, mime_type) else mime_type end,
             icon_blob  = nvl(p_blob, icon_blob),   -- keep existing image when no new upload
             updated_at = systimestamp,
             updated_by = user
       where icon_id = l_id;
    end if;
    pck_hom_log.info(c_pkg, 'save', 'icon ' || l_id || ' (' || p_name || ')');
    return l_id;
  end save;


  procedure del(p_icon_id in number) is
  begin
    update hom_app_config set icon_id = null, updated_at = systimestamp, updated_by = user
     where icon_id = p_icon_id;
    update hom_links      set icon_id = null, updated_at = systimestamp, updated_by = user
     where icon_id = p_icon_id;

    delete from hom_icons where icon_id = p_icon_id;
    pck_hom_log.info(c_pkg, 'del', 'icon ' || p_icon_id);
  end del;

end pck_hom_icons_dml;
/
