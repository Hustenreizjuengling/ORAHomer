--------------------------------------------------------------------------------
-- ORAHomer :: table HOM_CONFIG
--------------------------------------------------------------------------------
-- Typed key/value store for application SETTINGs (e.g. the homepage title or the
-- default visibility of newly discovered apps). Exactly one value_* column is
-- populated per row, indicated by data_type. All DML goes through
-- PCK_HOM_CONFIG_DML; never write this table directly.
--------------------------------------------------------------------------------

create table hom_config (
  config_key       varchar2(100)  not null
                      constraint hom_config_pk primary key,
  category         varchar2(20)   default 'SETTING' not null,  -- SETTING | METRIC
  data_type        varchar2(20)   not null,                    -- STRING | NUMBER | TIMESTAMP | BOOLEAN
  value_string     varchar2(4000),
  value_number     number,
  value_timestamp  timestamp,
  description      varchar2(400),
  --- audit (auto-populated by PCK_HOM_CONFIG_DML when passed NULL) -------------
  created_at       timestamp      default systimestamp,
  created_by       varchar2(128)  default user,
  updated_at       timestamp      default systimestamp,
  updated_by       varchar2(128)  default user,
  constraint hom_config_category_ck
    check (category in ('SETTING','METRIC')),
  constraint hom_config_dtype_ck
    check (data_type in ('STRING','NUMBER','TIMESTAMP','BOOLEAN'))
);

create index hom_config_category_ix on hom_config (category);

comment on table  hom_config                 is 'ORAHomer typed key/value config. DML only via PCK_HOM_CONFIG_DML.';
comment on column hom_config.config_key      is 'Unique key, e.g. HOME_TITLE or DEFAULT_APP_VISIBLE.';
comment on column hom_config.category        is 'SETTING (configured) or METRIC (auto-maintained).';
comment on column hom_config.data_type       is 'Which value_* column carries the value: STRING/NUMBER/TIMESTAMP/BOOLEAN (BOOLEAN stored in value_string as Y/N).';
comment on column hom_config.value_string    is 'Value when data_type is STRING or BOOLEAN (Y/N).';
comment on column hom_config.value_number    is 'Value when data_type is NUMBER.';
comment on column hom_config.value_timestamp is 'Value when data_type is TIMESTAMP.';
comment on column hom_config.description      is 'Human-readable purpose of the key.';
