--
-- save full tabel as json-array
-- set search_path to _pg_dml_audit_api;
--


CREATE OR REPLACE FUNCTION watch_table(tableident REGCLASS)
  RETURNS VOID AS $body$
DECLARE
  query_text TEXT;

BEGIN
  EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_row ON ' || tableident;
  EXECUTE 'DROP TRIGGER IF EXISTS audit_trigger_stm ON ' || tableident;

  query_text = 'CREATE TRIGGER audit_trigger_row AFTER INSERT OR UPDATE OR DELETE ON ' || tableident ||
               ' FOR EACH ROW EXECUTE PROCEDURE _pg_dml_audit_model.if_modified_func();';
  RAISE DEBUG '%', query_text;
  EXECUTE query_text;

  query_text = 'CREATE TRIGGER audit_trigger_stm BEFORE TRUNCATE ON ' || tableident ||
               ' FOR EACH STATEMENT EXECUTE PROCEDURE _pg_dml_audit_model.if_modified_func();';
  RAISE DEBUG '%', query_text;
  EXECUTE query_text;

  PERFORM _pg_dml_audit_api.take_snapshot(tableident);

END;
$body$
LANGUAGE 'plpgsql';

COMMENT ON FUNCTION watch_table(REGCLASS) IS $body$
Add auditing triggers to a table and take a initial snapshot.

Arguments:
   target_table:     Table name, schema qualified if not on search_path
$body$;
