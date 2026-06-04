--------------------------------------------------------------------------------
-- ORAHomer :: PCK_HOM_LOG  (central logging + DML access for HOM_LOG)
--------------------------------------------------------------------------------
-- Package-wide logging used by every other ORAHomer package. Entries are written
-- in an autonomous transaction so they persist even when the caller rolls back.
-- This package is the *only* code that writes HOM_LOG.
--
-- Placeholder note: routing/retention (e.g. forwarding ERROR to a monitoring
-- system) belongs in WRITE_LOG -- extend there.
--------------------------------------------------------------------------------

create or replace package pck_hom_log
  authid definer
as
  c_error constant varchar2(10) := 'ERROR';
  c_warn  constant varchar2(10) := 'WARN';
  c_info  constant varchar2(10) := 'INFO';
  c_debug constant varchar2(10) := 'DEBUG';

  -- Only messages at or above this severity are persisted (ERROR=1 .. DEBUG=4).
  procedure set_threshold(p_level in varchar2);

  procedure log(
    p_level   in varchar2,
    p_package in varchar2,
    p_routine in varchar2,
    p_message in clob
  );

  procedure error(p_package in varchar2, p_routine in varchar2, p_message in clob);
  procedure warn (p_package in varchar2, p_routine in varchar2, p_message in clob);
  procedure info (p_package in varchar2, p_routine in varchar2, p_message in clob);
  procedure debug(p_package in varchar2, p_routine in varchar2, p_message in clob);
end pck_hom_log;
/

create or replace package body pck_hom_log
as
  g_threshold pls_integer := 3;   -- default: INFO

  function severity(p_level in varchar2) return pls_integer is
  begin
    return case upper(p_level)
             when c_error then 1
             when c_warn  then 2
             when c_info  then 3
             when c_debug then 4
             else 3
           end;
  end severity;

  procedure set_threshold(p_level in varchar2) is
  begin
    g_threshold := severity(p_level);
  end set_threshold;

  -- The single physical writer. Autonomous so logs survive caller rollback.
  procedure write_log(
    p_level   in varchar2,
    p_package in varchar2,
    p_routine in varchar2,
    p_message in clob
  ) is
    pragma autonomous_transaction;
  begin
    insert into hom_log (log_level, package_name, routine_name, message,
                         created_at, created_by, updated_at, updated_by)
    values (upper(p_level), p_package, p_routine, p_message,
            systimestamp, user, systimestamp, user);
    commit;
  exception
    when others then
      rollback;   -- never let logging break the caller
  end write_log;

  procedure log(
    p_level   in varchar2,
    p_package in varchar2,
    p_routine in varchar2,
    p_message in clob
  ) is
  begin
    if severity(p_level) <= g_threshold then
      write_log(p_level, p_package, p_routine, p_message);
    end if;
  end log;

  procedure error(p_package in varchar2, p_routine in varchar2, p_message in clob) is
  begin log(c_error, p_package, p_routine, p_message); end;

  procedure warn(p_package in varchar2, p_routine in varchar2, p_message in clob) is
  begin log(c_warn, p_package, p_routine, p_message); end;

  procedure info(p_package in varchar2, p_routine in varchar2, p_message in clob) is
  begin log(c_info, p_package, p_routine, p_message); end;

  procedure debug(p_package in varchar2, p_routine in varchar2, p_message in clob) is
  begin log(c_debug, p_package, p_routine, p_message); end;
end pck_hom_log;
/
