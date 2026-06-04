--------------------------------------------------------------------------------
-- ORAHomer :: PCK_HOM_CATEGORIES_DML  (sole DML access to HOM_CATEGORIES)
--------------------------------------------------------------------------------
-- The only code allowed to write HOM_CATEGORIES. save() upserts (insert when
-- p_category_id is NULL, else update) and returns the id; del() removes a
-- category (tiles referencing it are set back to "uncategorised" first so the
-- FK never blocks the delete). Does NOT commit -- the caller owns the
-- transaction. Logs via PCK_HOM_LOG.
--------------------------------------------------------------------------------

create or replace package pck_hom_categories_dml
  authid definer
as
  c_pkg constant varchar2(30) := 'PCK_HOM_CATEGORIES_DML';

  function save(
    p_category_id in number   default null,
    p_name        in varchar2,
    p_icon_css    in varchar2 default null,
    p_display_seq in number   default 10,
    p_is_active   in varchar2 default 'Y'
  ) return number;

  procedure del(p_category_id in number);
end pck_hom_categories_dml;
/

create or replace package body pck_hom_categories_dml
as

  function save(
    p_category_id in number   default null,
    p_name        in varchar2,
    p_icon_css    in varchar2 default null,
    p_display_seq in number   default 10,
    p_is_active   in varchar2 default 'Y'
  ) return number is
    l_id hom_categories.category_id%type := p_category_id;
  begin
    if l_id is null then
      insert into hom_categories (name, icon_css, display_seq, is_active,
                                  created_at, created_by, updated_at, updated_by)
      values (p_name, p_icon_css, nvl(p_display_seq, 10), nvl(p_is_active, 'Y'),
              systimestamp, user, systimestamp, user)
      returning category_id into l_id;
    else
      update hom_categories
         set name        = p_name,
             icon_css    = p_icon_css,
             display_seq = nvl(p_display_seq, 10),
             is_active   = nvl(p_is_active, 'Y'),
             updated_at  = systimestamp,
             updated_by  = user
       where category_id = l_id;
    end if;
    pck_hom_log.info(c_pkg, 'save', 'category ' || l_id || ' (' || p_name || ')');
    return l_id;
  end save;


  procedure del(p_category_id in number) is
  begin
    -- detach tiles so the FK does not block the delete
    update hom_app_config set category_id = null, updated_at = systimestamp, updated_by = user
     where category_id = p_category_id;
    update hom_links      set category_id = null, updated_at = systimestamp, updated_by = user
     where category_id = p_category_id;

    delete from hom_categories where category_id = p_category_id;
    pck_hom_log.info(c_pkg, 'del', 'category ' || p_category_id);
  end del;

end pck_hom_categories_dml;
/
