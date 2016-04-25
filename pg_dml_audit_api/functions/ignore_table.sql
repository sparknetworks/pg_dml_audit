--
-- ignore_table removes the audit-triggers fron a table
-- recorded events remain in events-table
-- set search_path to _pg_dml_audit_api;
--

CREATE OR REPLACE FUNCTION ignore_table(tableident REGCLASS)
  RETURNS VOID AS $body$
DECLARE
BEGIN
  EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || tableident;
  EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || tableident;
END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION ignore_table(REGCLASS) IS $body$
Remove auditing triggers from a table. Recorded events remain in the database.
The function has no effect on tables without audit_triggers

Arguments:
   target_table:     Table name, schema qualified if not on search_path
$body$;
