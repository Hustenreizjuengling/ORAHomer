--------------------------------------------------------------------------------
-- ORAHomer :: trigger HOM_ICONS_AUDIT
--------------------------------------------------------------------------------
-- Two jobs for the icon library, the one table also written by APEX (the
-- icon-upload page is a Form region with Automatic Row Processing -- the
-- APEXLang-sanctioned pattern for file uploads):
--   1. stamp the audit columns on every write (package OR APEX form);
--   2. derive MIME_TYPE from the uploaded image's magic bytes when it is not
--      supplied, because an APEX form fileUpload item cannot capture a MIME
--      column declaratively. A correct MIME keeps the homepage data-URI icons
--      rendering (PNG/JPEG/GIF/BMP/SVG).
--------------------------------------------------------------------------------

create or replace trigger hom_icons_audit
  before insert or update on hom_icons
  for each row
declare
  l_hdr raw(16);
begin
  if inserting then
    :new.created_at := nvl(:new.created_at, systimestamp);
    :new.created_by := nvl(:new.created_by, user);
  end if;
  :new.updated_at := systimestamp;
  :new.updated_by := user;

  if :new.mime_type is null
     and :new.icon_blob is not null
     and dbms_lob.getlength(:new.icon_blob) > 0 then
    l_hdr := dbms_lob.substr(:new.icon_blob, 16, 1);
    if    utl_raw.substr(l_hdr, 1, 4) = hextoraw('89504E47') then :new.mime_type := 'image/png';
    elsif utl_raw.substr(l_hdr, 1, 3) = hextoraw('FFD8FF')   then :new.mime_type := 'image/jpeg';
    elsif utl_raw.substr(l_hdr, 1, 3) = hextoraw('474946')   then :new.mime_type := 'image/gif';
    elsif utl_raw.substr(l_hdr, 1, 2) = hextoraw('424D')     then :new.mime_type := 'image/bmp';
    elsif utl_raw.substr(l_hdr, 1, 1) = hextoraw('3C')       then :new.mime_type := 'image/svg+xml';   -- '<' => XML/SVG
    elsif utl_raw.substr(l_hdr, 1, 3) = hextoraw('EFBBBF')   then :new.mime_type := 'image/svg+xml';   -- UTF-8 BOM, then XML/SVG
    else  :new.mime_type := 'application/octet-stream';
    end if;
  end if;
end;
/
