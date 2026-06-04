--------------------------------------------------------------------------------
-- ORAHomer :: table HOM_APP_CONFIG
--------------------------------------------------------------------------------
-- Per-application overrides for the homepage. Apps are discovered live from
-- APEX_APPLICATIONS; this table only carries the *customisation* of an app, so a
-- missing row means "use defaults" (visible, auto icon, no category). That makes
-- the homepage opt-out: every workspace app shows up until it is hidden here.
-- The primary key IS the APEX application id. All DML goes through
-- PCK_HOM_APP_CONFIG_DML.
--------------------------------------------------------------------------------

create table hom_app_config (
  application_id  number         not null
                    constraint hom_app_config_pk primary key,  -- = APEX_APPLICATIONS.application_id
  category_id     number,
  display_name    varchar2(255),                       -- override for APEX_APPLICATIONS.application_name
  description     varchar2(400),                       -- optional tile subtitle shown under the name
  icon_id         number,                              -- uploaded icon (HOM_ICONS) replacing the app icon
  is_visible      varchar2(1)    default 'Y' not null, -- 'N' hides the app from the homepage
  display_seq     number         default 10 not null,  -- ordering within its category
  --- audit (auto-populated by PCK_HOM_APP_CONFIG_DML when passed NULL) ---------
  created_at      timestamp      default systimestamp,
  created_by      varchar2(128)  default user,
  updated_at      timestamp      default systimestamp,
  updated_by      varchar2(128)  default user,
  constraint hom_app_config_visible_ck check (is_visible in ('Y','N')),
  constraint hom_app_config_cat_fk  foreign key (category_id) references hom_categories (category_id),
  constraint hom_app_config_icon_fk foreign key (icon_id)     references hom_icons (icon_id) on delete set null
);

create index hom_app_config_cat_ix  on hom_app_config (category_id);
create index hom_app_config_icon_ix on hom_app_config (icon_id);

comment on table  hom_app_config                is 'ORAHomer per-application homepage overrides (opt-out: no row = default visible). DML only via PCK_HOM_APP_CONFIG_DML.';
comment on column hom_app_config.application_id is 'APEX_APPLICATIONS.application_id this row customises.';
comment on column hom_app_config.category_id    is 'Optional category the app is grouped under.';
comment on column hom_app_config.display_name   is 'Optional label overriding the real application name.';
comment on column hom_app_config.description    is 'Optional tile subtitle shown under the app name on the homepage.';
comment on column hom_app_config.icon_id        is 'Optional uploaded icon (HOM_ICONS) replacing the detected app icon.';
comment on column hom_app_config.is_visible     is 'Y = shown on the homepage; N = hidden.';
comment on column hom_app_config.display_seq    is 'Sort order within the category (ascending).';
