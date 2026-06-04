--------------------------------------------------------------------------------
-- ORAHomer :: PCK_HOM_LINKS_DML  (sole DML access to HOM_LINKS)
--------------------------------------------------------------------------------
-- The only code allowed to write HOM_LINKS. save() upserts (insert when
-- p_link_id is NULL, else update) and returns the id; del() removes a link.
-- Does NOT commit -- the caller owns the transaction. Logs via PCK_HOM_LOG.
--------------------------------------------------------------------------------

create or replace package pck_hom_links_dml
  authid definer
as
  c_pkg constant varchar2(30) := 'PCK_HOM_LINKS_DML';

  function save(
    p_link_id         in number   default null,
    p_title           in varchar2,
    p_url             in varchar2,
    p_description     in varchar2 default null,
    p_category_id     in number   default null,
    p_icon_id         in number   default null,
    p_open_in_new_tab in varchar2 default 'Y',
    p_is_visible      in varchar2 default 'Y',
    p_display_seq     in number   default 10
  ) return number;

  procedure del(p_link_id in number);
end pck_hom_links_dml;
/

create or replace package body pck_hom_links_dml
as

  function save(
    p_link_id         in number   default null,
    p_title           in varchar2,
    p_url             in varchar2,
    p_description     in varchar2 default null,
    p_category_id     in number   default null,
    p_icon_id         in number   default null,
    p_open_in_new_tab in varchar2 default 'Y',
    p_is_visible      in varchar2 default 'Y',
    p_display_seq     in number   default 10
  ) return number is
    l_id hom_links.link_id%type := p_link_id;
  begin
    if l_id is null then
      insert into hom_links (title, url, description, category_id, icon_id,
                             open_in_new_tab, is_visible, display_seq,
                             created_at, created_by, updated_at, updated_by)
      values (p_title, p_url, p_description, p_category_id, p_icon_id,
              nvl(p_open_in_new_tab, 'Y'), nvl(p_is_visible, 'Y'), nvl(p_display_seq, 10),
              systimestamp, user, systimestamp, user)
      returning link_id into l_id;
    else
      update hom_links
         set title           = p_title,
             url             = p_url,
             description     = p_description,
             category_id     = p_category_id,
             icon_id         = p_icon_id,
             open_in_new_tab = nvl(p_open_in_new_tab, 'Y'),
             is_visible      = nvl(p_is_visible, 'Y'),
             display_seq     = nvl(p_display_seq, 10),
             updated_at      = systimestamp,
             updated_by      = user
       where link_id = l_id;
    end if;
    pck_hom_log.info(c_pkg, 'save', 'link ' || l_id || ' (' || p_title || ')');
    return l_id;
  end save;


  procedure del(p_link_id in number) is
  begin
    delete from hom_links where link_id = p_link_id;
    pck_hom_log.info(c_pkg, 'del', 'link ' || p_link_id);
  end del;

end pck_hom_links_dml;
/
